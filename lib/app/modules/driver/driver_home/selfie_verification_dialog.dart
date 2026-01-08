import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/managers/color_manager.dart';
import '../../../../core/services/selfie_verification_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/rtc_streaming_service.dart';
import '../../../../data/models/trip_model.dart';
import '../../../custom_widgets/custom_toast.dart';

/// Dialog for selfie verification before starting a trip
class SelfieVerificationDialog extends StatefulWidget {
  const SelfieVerificationDialog({
    super.key,
    required this.trip,
    required this.onVerified,
  });

  final TripModel trip;
  final VoidCallback onVerified;

  @override
  State<SelfieVerificationDialog> createState() =>
      _SelfieVerificationDialogState();
}

class _SelfieVerificationDialogState extends State<SelfieVerificationDialog> {
  final SelfieVerificationService _verificationService =
      Get.find<SelfieVerificationService>();
  final NotificationService _notificationService =
      Get.find<NotificationService>();
  final RtcStreamingService _rtcService = Get.find<RtcStreamingService>();
  final ImagePicker _imagePicker = ImagePicker();

  CameraController? _cameraController;
  File? _capturedImage;
  bool _isInitializing = false;
  bool _isVerifying = false;
  String? _errorMessage;
  bool _wasRtcStreaming = false; // Track if WebRTC was streaming before

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    // Restart WebRTC streaming if it was active before
    if (_wasRtcStreaming && _rtcService.streamingActive.value == false) {
      // WebRTC will restart automatically when parent requests camera
      // No need to manually restart here
    }
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      // ALWAYS stop WebRTC to ensure camera is released (even if not actively streaming,
      // the camera might still be locked from a previous session)
      _wasRtcStreaming = _rtcService.streamingActive.value;
      if (kDebugMode) {
        debugPrint('📹 Stopping WebRTC to release camera (was streaming: $_wasRtcStreaming)...');
      }
      
      // Stop WebRTC regardless of streaming state to ensure camera is free
      await _rtcService.stopStreaming();
      
      // Wait for streaming to actually stop (polling with timeout)
      int waitAttempts = 0;
      const maxWaitAttempts = 15; // 3 seconds total
      while (_rtcService.streamingActive.value && waitAttempts < maxWaitAttempts) {
        await Future.delayed(const Duration(milliseconds: 200));
        waitAttempts++;
        if (kDebugMode && waitAttempts % 5 == 0) {
          debugPrint('📹 Still waiting for WebRTC to stop... (attempt $waitAttempts/$maxWaitAttempts)');
        }
      }
      
      // Additional wait for camera hardware to be fully released
      // WebRTC getUserMedia might take time to release the camera hardware
      if (kDebugMode) {
        debugPrint('📹 Waiting for camera hardware to be released...');
      }
      await Future.delayed(const Duration(milliseconds: 2000)); // Increased to 2 seconds
      
      if (kDebugMode) {
        debugPrint('📹 Camera should be released now, attempting to open...');
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'no_camera_available'.tr;
          _isInitializing = false;
        });
        return;
      }

      // Find front camera for selfie
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () =>
            cameras.first, // Fallback to first camera if no front camera found
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
      );

      // Retry logic with exponential backoff if camera is still in use
      int retries = 5; // Increased retries
      bool initialized = false;
      Exception? lastError;
      while (retries > 0 && !initialized) {
        try {
          if (kDebugMode) {
            debugPrint('📷 Attempting to initialize camera (attempt ${6 - retries}/5)...');
          }
          await _cameraController!.initialize();
          initialized = true;
          if (kDebugMode) {
            debugPrint('✅ Camera initialized successfully!');
          }
        } catch (e) {
          lastError = e is Exception ? e : Exception(e.toString());
          if (kDebugMode) {
            debugPrint('❌ Camera initialization attempt failed: $e (retries left: ${retries - 1})');
          }
          retries--;
          if (retries > 0) {
            // Wait longer before retry (exponential backoff)
            final delayMs = (6 - retries) * 1000; // 1s, 2s, 3s, 4s, 5s
            if (kDebugMode) {
              debugPrint('⏳ Waiting ${delayMs}ms before retry...');
            }
            await Future.delayed(Duration(milliseconds: delayMs));
          }
        }
      }
      
      if (!initialized && lastError != null) {
        throw lastError;
      }

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Camera initialization error after retries: $e');
      }
      setState(() {
        _errorMessage = 'camera_initialization_failed'.tr;
        _isInitializing = false;
      });
      
      // If camera initialization failed and WebRTC was streaming, try to restart it
      if (_wasRtcStreaming) {
        if (kDebugMode) {
          debugPrint('📹 Attempting to restart WebRTC streaming after camera error...');
        }
        // WebRTC will restart automatically when parent requests camera again
      }
    }
  }

  Future<void> _captureSelfie() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      // If camera not available, use image picker
      await _pickImageFromGallery();
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = File(image.path);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'capture_failed'.tr;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _capturedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'failed_to_pick_image'.tr;
      });
    }
  }

  Future<void> _verifyAndStartTrip() async {
    if (_capturedImage == null) {
      CustomToasts(
        message: 'please_capture_selfie_first'.tr,
        type: CustomToastType.warning,
      ).show();
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      // Verify selfie with threshold 0.55
      final similarityScore = await _verificationService.verifyDriverSelfie(
        _capturedImage!,
      );

      final threshold = AppConfig.similarityThreshold; // Use 0.7 as specified
      final isVerified = similarityScore >= threshold;

      if (isVerified) {
        // Verification successful - start trip
        CustomToasts(
          message: 'selfie_verification_success'.tr,
          type: CustomToastType.success,
        ).show();
        
        // Dispose camera before closing dialog
        await _cameraController?.dispose();
        _cameraController = null;
        
        Get.back(); // Close dialog
        
        // WebRTC will restart automatically when parent requests camera
        // No need to manually restart here
        
        widget.onVerified(); // Start the trip
      } else {
        // Verification failed - notify parent
        await _notifyParentVerificationFailed(similarityScore);
        CustomToasts(
          message: 'selfie_verification_failed_details'.tr,
          type: CustomToastType.error,
          duration: const Duration(seconds: 5),
        ).show();
        setState(() {
          _isVerifying = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isVerifying = false;
      });
      CustomToasts(
        message: 'verification_error'.tr,
        type: CustomToastType.error,
      ).show();
    }
  }

  Future<void> _notifyParentVerificationFailed(double similarityScore) async {
    try {
      await _notificationService.sendNotificationToUser(
        userId: widget.trip.parentId,
        title: 'selfie_verification_failed_title'.tr,
        body: 'selfie_verification_failed_notification'.tr,
        type: NotificationService.emergencyType,
        data: {
          'tripId': widget.trip.id,
          'similarityScore': similarityScore,
          'threshold': AppConfig.similarityThreshold,
        },
      );
    } catch (e) {
      if (AppConfig.isDebugMode) {
        debugPrint('Failed to notify parent: $e');
      }
    }
  }

  void _retakeSelfie() {
    setState(() {
      _capturedImage = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(20.w),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorManager.primaryColor,
                    ColorManager.primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.face_rounded,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'selfie_verification_required'.tr,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'tap_to_capture_selfie'.tr,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                    onPressed: () async {
                      await _cameraController?.dispose();
                      Get.back();
                    },
                  ),
                ],
              ),
            ),

            // Content
            Padding(padding: EdgeInsets.all(20.w), child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isInitializing) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: ColorManager.primaryColor),
            SizedBox(height: 16.h),
            Text(
              'initializing_camera'.tr,
              style: TextStyle(
                fontSize: 14.sp,
                color: ColorManager.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && _capturedImage == null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: ColorManager.error),
            SizedBox(height: 16.h),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: ColorManager.textPrimary,
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: _initializeCamera,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              child: Text('retry'.tr),
            ),
          ],
        ),
      );
    }

    if (_capturedImage != null) {
      return _buildPreviewSection();
    }

    return _buildCameraSection();
  }

  Widget _buildCameraSection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: ColorManager.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: 48.sp,
                color: ColorManager.primaryColor,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'tap_anywhere_to_capture'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: ColorManager.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'selfie_verification_info'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: ColorManager.textSecondary,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: _pickImageFromGallery,
              icon: Icon(Icons.photo_library_rounded, size: 20.sp),
              label: Text('pick_from_gallery'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _captureSelfie,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 300.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: ColorManager.primaryColor, width: 3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13.r),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(_cameraController!),
                  // Face guide overlay
                  Container(
                    margin: EdgeInsets.all(40.w),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                  ),
                  // Tap overlay hint
                  Positioned.fill(
                    child: Container(
                      color: Colors.transparent,
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.touch_app_rounded,
                                color: Colors.white,
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'tap_to_capture'.tr,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'tap_anywhere_to_capture'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: ColorManager.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 300.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: ColorManager.primaryColor, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: Image.file(_capturedImage!, fit: BoxFit.cover),
          ),
        ),
        SizedBox(height: 20.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isVerifying ? null : _retakeSelfie,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: ColorManager.textSecondary),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh_rounded, size: 18.sp),
                    SizedBox(width: 8.w),
                    Text('retake'.tr),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _verifyAndStartTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                child: _isVerifying
                    ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_user_rounded, size: 18.sp),
                          SizedBox(width: 8.w),
                          Text('submit'.tr),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
