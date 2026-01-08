import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:kidscar/app/custom_widgets/custom_button.dart';
import 'package:kidscar/app/custom_widgets/custom_text_field.dart';
import 'package:kidscar/app/custom_widgets/wave_header.dart';
import 'package:kidscar/core/managers/color_manager.dart';
import 'package:kidscar/core/managers/font_manager.dart';

import 'change_password_controller.dart';

class ChangePasswordView extends GetView<ChangePasswordController> {
  const ChangePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.backgroundColor,
      body: Column(
        children: [
          WaveHeader(
            showBackButton: true,
            title: 'change_password'.tr,
            onBackTap: () => Get.back(),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(),
                    SizedBox(height: 24.h),

                    // Old password
                    Obx(
                      () => CustomTextField(
                        controller: controller.oldPasswordController,
                        focusNode: controller.oldPasswordFocusNode,
                        hintText: 'current_password'.tr,
                        obscureText: !controller.showOldPassword.value,
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: ColorManager.textSecondary,
                          size: 20.sp,
                        ),
                        suffixIcon: Icon(
                          controller.showOldPassword.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: ColorManager.textSecondary,
                          size: 20.sp,
                        ),
                        onSuffixTap: controller.toggleOldPasswordVisibility,
                        onFieldSubmitted: (_) => FocusScope.of(context)
                            .requestFocus(controller.newPasswordFocusNode),
                        errorText: controller.oldPasswordError.value.isNotEmpty
                            ? controller.oldPasswordError.value
                            : null,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // New password
                    Obx(
                      () => CustomTextField(
                        controller: controller.newPasswordController,
                        focusNode: controller.newPasswordFocusNode,
                        hintText: 'new_password'.tr,
                        obscureText: !controller.showNewPassword.value,
                        prefixIcon: Icon(
                          Icons.lock_reset,
                          color: ColorManager.textSecondary,
                          size: 20.sp,
                        ),
                        suffixIcon: Icon(
                          controller.showNewPassword.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: ColorManager.textSecondary,
                          size: 20.sp,
                        ),
                        onSuffixTap: controller.toggleNewPasswordVisibility,
                        onFieldSubmitted: (_) => FocusScope.of(context)
                            .requestFocus(controller.confirmPasswordFocusNode),
                        errorText: controller.newPasswordError.value.isNotEmpty
                            ? controller.newPasswordError.value
                            : null,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Confirm password
                    Obx(
                      () => CustomTextField(
                        controller: controller.confirmPasswordController,
                        focusNode: controller.confirmPasswordFocusNode,
                        hintText: 'confirm_password'.tr,
                        obscureText: !controller.showConfirmPassword.value,
                        prefixIcon: Icon(
                          Icons.check_circle_outline,
                          color: ColorManager.textSecondary,
                          size: 20.sp,
                        ),
                        suffixIcon: Icon(
                          controller.showConfirmPassword.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: ColorManager.textSecondary,
                          size: 20.sp,
                        ),
                        onSuffixTap:
                            controller.toggleConfirmPasswordVisibility,
                        onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                        errorText:
                            controller.confirmPasswordError.value.isNotEmpty
                                ? controller.confirmPasswordError.value
                                : null,
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Update button
                    Obx(
                      () => CustomButton(
                        text: 'update_password'.tr,
                        onPressed: controller.isSubmitting.value
                            ? null
                            : controller.changePassword,
                        isLoading: controller.isSubmitting.value,
                        height: 32.h,
                        width: double.infinity,
                        color: ColorManager.primaryColor,
                        textStyle: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontManager.bold,
                          color: ColorManager.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: ColorManager.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: ColorManager.primaryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(8.w),
            child: Icon(
              Icons.lock_outline,
              color: ColorManager.primaryColor,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'password_requirements'.tr,
              style: TextStyle(
                fontSize: 12.sp,
                color: ColorManager.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

