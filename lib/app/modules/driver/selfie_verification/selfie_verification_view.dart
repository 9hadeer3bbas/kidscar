import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/managers/color_manager.dart';
import '../../../../core/services/selfie_verification_service.dart';
import '../../../custom_widgets/custom_button.dart';
import '../../../custom_widgets/wave_header.dart';
import 'selfie_verification_controller.dart';

class SelfieVerificationView extends GetView<SelfieVerificationController> {
  const SelfieVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            WaveHeader(
              title: 'selfie_verification'.tr,
              showBackButton: true,
            ),
            Expanded(
              child: Obx(() {
                if (controller.isInitializing.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: ColorManager.primaryColor,
                        ),
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

                if (controller.errorMessage.value.isNotEmpty &&
                    controller.capturedImage.value == null) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64.sp,
                            color: ColorManager.error,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            controller.errorMessage.value,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: ColorManager.textPrimary,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          CustomButton(
                            text: 'retry'.tr,
                            onPressed: () {
                              controller.initializeCamera();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Show captured image preview
                if (controller.capturedImage.value != null) {
                  return _buildPreviewSection();
                }

                // Show camera preview
                return _buildCameraSection();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraSection() {
    if (controller.cameraController == null ||
        !controller.cameraController!.value.isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64.sp,
              color: ColorManager.textSecondary.withOpacity(0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              'camera_not_available'.tr,
              style: TextStyle(
                fontSize: 14.sp,
                color: ColorManager.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Camera preview with modern frame
              Padding(
                padding: EdgeInsets.all(24.w),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24.r),
                    child: AspectRatio(
                      aspectRatio: controller.cameraController!.value.aspectRatio,
                      child: CameraPreview(controller.cameraController!),
                    ),
                  ),
                ),
              ),
              
              // Face frame guide
              Container(
                margin: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: ColorManager.primaryColor,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: AspectRatio(
                  aspectRatio: 0.75,
                  child: Container(),
                ),
              ),
              
              // Friendly instructions card
              Positioned(
                bottom: 120.h,
                left: 20.w,
                right: 20.w,
                child: Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.face_rounded,
                        size: 32.sp,
                        color: ColorManager.primaryColor,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'selfie_verification_instructions'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: ColorManager.textPrimary,
                          fontWeight: FontWeight.w600,
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Modern capture button
        Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              Obx(() => Container(
                    width: double.infinity,
                    height: 56.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ColorManager.primaryColor,
                          ColorManager.primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: ColorManager.primaryColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: controller.isCapturing.value
                            ? null
                            : controller.captureSelfie,
                        borderRadius: BorderRadius.circular(16.r),
                        child: Center(
                          child: controller.isCapturing.value
                              ? SizedBox(
                                  height: 24.h,
                                  width: 24.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 24.sp,
                                    ),
                                    SizedBox(width: 12.w),
                                    Text(
                                      'capture_selfie'.tr,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.r),
              child: Image.file(
                controller.capturedImage.value!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
        ),
        Obx(() {
          final score = controller.verificationScore.value;
          if (score == null) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: ColorManager.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: ColorManager.primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: ColorManager.primaryColor,
                      size: 24.sp,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'tap_verify_to_continue'.tr,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: ColorManager.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          final threshold = AppConfig.similarityThreshold;
          final isVerified = score >= threshold;
          
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: isVerified
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isVerified ? Colors.green : Colors.red,
                  width: 2.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: isVerified
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isVerified ? Icons.check_circle : Icons.cancel,
                          color: isVerified ? Colors.green : Colors.red,
                          size: 28.sp,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isVerified ? 'verified'.tr : 'not_verified'.tr,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: isVerified ? Colors.green : Colors.red,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${'similarity_score'.tr}: ${(score * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: isVerified ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              Obx(() => Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.isVerifying.value
                              ? null
                              : controller.retakeSelfie,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: ColorManager.textSecondary,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 20.sp,
                                color: ColorManager.textSecondary,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'retake'.tr,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: ColorManager.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 56.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: controller.verificationScore.value != null &&
                                      controller.verificationScore.value! >=
                                          AppConfig.similarityThreshold
                                  ? [
                                      Colors.green,
                                      Colors.green.withOpacity(0.8),
                                    ]
                                  : [
                                      ColorManager.primaryColor,
                                      ColorManager.primaryColor.withOpacity(0.8),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: (controller.verificationScore.value != null &&
                                        controller.verificationScore.value! >=
                                            AppConfig.similarityThreshold
                                    ? Colors.green
                                    : ColorManager.primaryColor)
                                    .withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: controller.isVerifying.value
                                  ? null
                                  : () async {
                                      final score = controller.verificationScore.value;
                                      if (score == null) {
                                        final verified =
                                            await controller.verifySelfie();
                                        if (verified) {
                                          Get.back(result: true);
                                        }
                                      } else {
                                        final threshold = AppConfig.similarityThreshold;
                                        if (score >= threshold) {
                                          Get.back(result: true);
                                        }
                                      }
                                    },
                              borderRadius: BorderRadius.circular(16.r),
                              child: Center(
                                child: controller.isVerifying.value
                                    ? SizedBox(
                                        height: 24.h,
                                        width: 24.w,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            controller.verificationScore.value == null
                                                ? Icons.verified_user_rounded
                                                : Icons.check_circle_rounded,
                                            color: Colors.white,
                                            size: 22.sp,
                                          ),
                                          SizedBox(width: 10.w),
                                          Text(
                                            controller.verificationScore.value == null
                                                ? 'verify'.tr
                                                : 'continue'.tr,
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

