import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/managers/color_manager.dart';
import '../../../custom_widgets/wave_header.dart';
import '../../../custom_widgets/custom_button.dart';
import '../../../custom_widgets/custom_text_field.dart';
import 'driver_vehicle_documents_controller.dart';

class DriverVehicleDocumentsView
    extends GetView<DriverVehicleDocumentsController> {
  const DriverVehicleDocumentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.backgroundColor,
      body: Column(
        children: [
          WaveHeader(
            showBackButton: true,
            title: 'vehicle_documents'.tr,
            onBackTap: () => Get.back(),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              return SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'manage_vehicle_documents'.tr,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: ColorManager.textSecondary,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    _buildDocumentCard(
                      title: 'driving_license'.tr,
                      subtitle: 'driving_license_subtitle'.tr,
                      imageUrl: controller.drivingLicenseUrl.value,
                      onTap: () => _handleDocumentAction(context, 'drivingLicense', controller),
                      onView: controller.drivingLicenseUrl.value != null
                          ? () => _showDocumentDialog(
                                context,
                                controller.drivingLicenseUrl.value!,
                                'driving_license'.tr,
                              )
                          : null,
                    ),
                    SizedBox(height: 16.h),
                    _buildDocumentCard(
                      title: 'vehicle_registration'.tr,
                      subtitle: 'vehicle_registration_subtitle'.tr,
                      imageUrl: controller.vehicleRegistrationUrl.value,
                      onTap: () => _handleDocumentAction(context, 'vehicleRegistration', controller),
                      onView: controller.vehicleRegistrationUrl.value != null
                          ? () => _showDocumentDialog(
                                context,
                                controller.vehicleRegistrationUrl.value!,
                                'vehicle_registration'.tr,
                              )
                          : null,
                    ),
                    SizedBox(height: 16.h),
                    _buildDocumentCard(
                      title: 'driver_photo'.tr,
                      subtitle: 'driver_photo_subtitle'.tr,
                      imageUrl: controller.driverPhotoUrl.value,
                      onTap: () => _handleDocumentAction(context, 'driverPhoto', controller),
                      onView: controller.driverPhotoUrl.value != null
                          ? () => _showDocumentDialog(
                                context,
                                controller.driverPhotoUrl.value!,
                                'driver_photo'.tr,
                              )
                          : null,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String subtitle,
    String? imageUrl,
    required VoidCallback onTap,
    VoidCallback? onView,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: ColorManager.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: ColorManager.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (imageUrl != null && imageUrl.isNotEmpty)
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24.sp,
                )
              else
                Icon(
                  Icons.upload_file,
                  color: ColorManager.textSecondary,
                  size: 24.sp,
                ),
            ],
          ),
          SizedBox(height: 16.h),
          if (imageUrl != null && imageUrl.isNotEmpty)
            Container(
              height: 200.h,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: ColorManager.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: ColorManager.primaryColor,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48.sp,
                  ),
                ),
              ),
            ),
          SizedBox(height: 16.h),
          Row(
            children: [
              if (onView != null) ...[
                Expanded(
                  child: CustomButton(
                    text: 'view'.tr,
                    onPressed: onView,
                    height: 40.h,
                    color: ColorManager.primaryColor.withValues(alpha: 0.1),
                    textStyle: TextStyle(
                      color: ColorManager.primaryColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
              ],
              Expanded(
                child: CustomButton(
                  text: imageUrl != null && imageUrl.isNotEmpty
                      ? 'update'.tr
                      : 'upload'.tr,
                  onPressed: onTap,
                  height: 40.h,
                  color: ColorManager.primaryColor,
                  textStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDocumentDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: ColorManager.primaryColor,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48.sp,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              CustomButton(
                text: 'close'.tr,
                onPressed: () => Get.back(),
                width: double.infinity,
                height: 40.h,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDocumentAction(
    BuildContext context,
    String documentType,
    DriverVehicleDocumentsController controller,
  ) async {
    // If document exists, require password verification
    if (controller.documentExists(documentType)) {
      final verified = await _showPasswordVerificationDialog(context, controller);
      if (verified) {
        await controller.pickDocument(documentType);
      }
    } else {
      // First time upload, no password needed
      await controller.pickDocument(documentType);
    }
  }

  Future<bool> _showPasswordVerificationDialog(
    BuildContext context,
    DriverVehicleDocumentsController controller,
  ) async {
    final passwordController = TextEditingController();
    final passwordFocusNode = FocusNode();
    bool showPassword = false;
    bool isVerifying = false;
    String? errorMessage;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Container(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: ColorManager.primaryColor,
                      size: 24.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'verify_password'.tr,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: ColorManager.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 20.sp),
                      onPressed: isVerifying
                          ? null
                          : () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  'password_required_to_replace_document'.tr,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: ColorManager.textSecondary,
                  ),
                ),
                SizedBox(height: 24.h),
                CustomTextField(
                  controller: passwordController,
                  focusNode: passwordFocusNode,
                  hintText: 'enter_password'.tr,
                  obscureText: !showPassword,
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: ColorManager.textSecondary,
                    size: 20.sp,
                  ),
                  suffixIcon: Icon(
                    showPassword ? Icons.visibility : Icons.visibility_off,
                    color: ColorManager.textSecondary,
                    size: 20.sp,
                  ),
                  onSuffixTap: () {
                    setState(() {
                      showPassword = !showPassword;
                    });
                  },
                  errorText: errorMessage,
                  onFieldSubmitted: (_) async {
                    if (!isVerifying) {
                      await _verifyAndClose(
                        context,
                        controller,
                        passwordController.text,
                        setState,
                        (verifying) => isVerifying = verifying,
                        (error) => errorMessage = error,
                      );
                    }
                  },
                ),
                SizedBox(height: 24.h),
                Obx(
                  () => CustomButton(
                    text: 'verify'.tr,
                    onPressed: (controller.isVerifyingPassword.value || isVerifying)
                        ? null
                        : () async {
                            await _verifyAndClose(
                              context,
                              controller,
                              passwordController.text,
                              setState,
                              (verifying) => isVerifying = verifying,
                              (error) => errorMessage = error,
                            );
                          },
                    isLoading: controller.isVerifyingPassword.value,
                    width: double.infinity,
                    height: 40.h,
                    color: ColorManager.primaryColor,
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                TextButton(
                  onPressed: isVerifying
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Text(
                    'cancel'.tr,
                    style: TextStyle(
                      color: ColorManager.textSecondary,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ) ?? false;
  }

  Future<void> _verifyAndClose(
    BuildContext context,
    DriverVehicleDocumentsController controller,
    String password,
    StateSetter setState,
    Function(bool) setIsVerifying,
    Function(String?) setErrorMessage,
  ) async {
    if (password.isEmpty) {
      setState(() {
        setErrorMessage('enter_password'.tr);
      });
      return;
    }

    setState(() {
      setIsVerifying(true);
      setErrorMessage(null);
    });

    final verified = await controller.verifyPassword(password);
    
    setState(() {
      setIsVerifying(false);
    });

    if (verified) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        setErrorMessage('incorrect_password'.tr);
      });
    }
  }
}

