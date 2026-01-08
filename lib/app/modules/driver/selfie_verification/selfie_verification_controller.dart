import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/selfie_verification_service.dart';
import '../../../../core/services/permission_service.dart';
import '../../../custom_widgets/custom_toast.dart';

class SelfieVerificationController extends GetxController {
  final SelfieVerificationService _verificationService =
      Get.find<SelfieVerificationService>();


  // Camera controller
  CameraController? _cameraController;
  CameraController? get cameraController => _cameraController;

  // Observable states
  final RxBool isInitializing = true.obs;
  final RxBool isCapturing = false.obs;
  final RxBool isVerifying = false.obs;
  final Rx<File?> capturedImage = Rx<File?>(null);
  final RxString errorMessage = ''.obs;
  final Rx<double?> verificationScore = Rx<double?>(null);

  List<CameraDescription>? _cameras;

  @override
  void onInit() {
    super.onInit();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      isInitializing.value = true;
      errorMessage.value = '';

      // Check camera permission
      final hasPermission = await PermissionService.requestCameraPermission();
      if (!hasPermission) {
        errorMessage.value = 'camera_permission_denied'.tr;
        isInitializing.value = false;
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        errorMessage.value = 'no_camera_available'.tr;
        isInitializing.value = false;
        return;
      }

      // Initialize front camera (for selfies)
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      isInitializing.value = false;
    } catch (e) {
      errorMessage.value = 'camera_initialization_failed'.tr;
      if (kDebugMode) {
        debugPrint('Camera initialization error: $e');
      }
      isInitializing.value = false;
    }
  }

  Future<void> captureSelfie() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      CustomToasts(
        message: 'camera_not_ready'.tr,
        type: CustomToastType.error,
      ).show();
      return;
    }

    try {
      isCapturing.value = true;
      errorMessage.value = '';

      final image = await _cameraController!.takePicture();
      final imageFile = File(image.path);
      capturedImage.value = imageFile;
    } catch (e) {
      errorMessage.value = 'capture_failed'.tr;
      if (kDebugMode) {
        debugPrint('Capture error: $e');
      }
    } finally {
      isCapturing.value = false;
    }
  }

  Future<void> retakeSelfie() async {
    capturedImage.value = null;
    verificationScore.value = null;
    errorMessage.value = '';
  }

  Future<bool> verifySelfie() async {
    if (capturedImage.value == null) {
      CustomToasts(
        message: 'please_capture_selfie_first'.tr,
        type: CustomToastType.warning,
      ).show();
      return false;
    }

    try {
      isVerifying.value = true;
      errorMessage.value = '';

      final score = await _verificationService.verifyDriverSelfie(
        capturedImage.value!,
      );

      verificationScore.value = score;

      final threshold = AppConfig.similarityThreshold;
      if (score >= threshold) {
        CustomToasts(
          message: 'selfie_verification_success'.tr,
          type: CustomToastType.success,
        ).show();
        return true;
      } else {
        // Notify parent about verification failure
        errorMessage.value = 'selfie_verification_failed'.tr;
        CustomToasts(
          message: 'selfie_verification_failed_details'.tr,
          type: CustomToastType.error,
          duration: const Duration(seconds: 5),
        ).show();
        return false;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      CustomToasts(
        message: 'verification_error'.tr,
        type: CustomToastType.error,
      ).show();
      return false;
    } finally {
      isVerifying.value = false;
    }
  }

  @override
  void onClose() {
    _cameraController?.dispose();
    super.onClose();
  }
}

