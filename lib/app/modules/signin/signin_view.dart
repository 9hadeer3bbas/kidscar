import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kidscar/core/routes/get_routes.dart';
import '../../custom_widgets/custom_text_field.dart';
import '../../custom_widgets/custom_button.dart';
import '../../custom_widgets/wave_header.dart';
import '../../../core/managers/color_manager.dart';
import '../../../core/managers/assets_manager.dart';
import '../../../core/managers/font_manager.dart';
import 'signin_controller.dart';

class SigninView extends GetView<SignInController> {
  const SigninView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controllers are properly initialized
    controller.ensureControllersInitialized();
    return Scaffold(
      backgroundColor: ColorManager.backgroundColor,
      body: Column(
        children: [
          WaveHeader(
            logoPath: AssetsManager.logoImage,
            showBackButton: true,
            showLanguageButton: true,
            onBackTap: () => Get.back(),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    // Welcome message
                    Text(
                      'welcome_to_kidscar'.tr,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontManager.bold,
                        color: ColorManager.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 30.h),

                    // Email/phone field
                    Obx(() {
                      // Ensure controllers are initialized
                      controller.ensureControllersInitialized();
                      return CustomTextField(
                        hintText: 'email'.tr,
                        controller: controller.emailController,
                        prefixIcon: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: Icon(
                            Icons.person_outline,
                            color: ColorManager.textSecondary,
                            size: 20.sp,
                          ),
                        ),
                        errorText: controller.emailError.value.isNotEmpty
                            ? controller.emailError.value
                            : null,
                        focusNode: controller.emailFocusNode,
                        onFieldSubmitted: (_) {
                          try {
                            if (controller.passwordFocusNode.canRequestFocus) {
                              FocusScope.of(
                                context,
                              ).requestFocus(controller.passwordFocusNode);
                            }
                          } catch (e) {
                            // Focus node might be disposed, just unfocus
                            FocusScope.of(context).unfocus();
                          }
                        },
                      );
                    }),
                    SizedBox(height: 16.h),

                    // Password field with toggle
                    Obx(() {
                      // Ensure controllers are initialized
                      controller.ensureControllersInitialized();
                      return CustomTextField(
                        hintText: 'password'.tr,
                        controller: controller.passwordController,
                        obscureText: !controller.showPassword.value,
                        prefixIcon: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: Icon(
                            Icons.lock_outline,
                            color: ColorManager.textSecondary,
                            size: 20.sp,
                          ),
                        ),
                        suffixIcon: Icon(
                          controller.showPassword.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: ColorManager.textSecondary,
                          size: 20.sp,
                        ),
                        onSuffixTap: controller.togglePasswordVisibility,
                        errorText: controller.passwordError.value.isNotEmpty
                            ? controller.passwordError.value
                            : null,
                        focusNode: controller.passwordFocusNode,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).unfocus(),
                      );
                    }),

                    SizedBox(height: 24.h),

                    // Sign In button
                    Obx(
                      () => CustomButton(
                        text: 'sign_in'.tr,
                        onPressed: controller.signIn,
                        isLoading: controller.isLoading.value,
                        height: 30.0.h,
                        width: 250.0.w,
                        color: ColorManager.primaryColor,
                        textStyle: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontManager.bold,
                          color: ColorManager.white,
                        ),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Forget password / Reset link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'forget_password'.tr,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: ColorManager.textSecondary,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Obx(
                          () => TextButton(
                            onPressed: controller.isSendingReset.value
                                ? null
                                : controller.resetPassword,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: controller.isSendingReset.value
                                ? SizedBox(
                                    width: 16.w,
                                    height: 16.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: ColorManager.primaryColor,
                                    ),
                                  )
                                : Text(
                                    'reset_password'.tr,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: ColorManager.primaryColor,
                                      fontWeight: FontManager.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8.h),

                    // Resend verification email
                    GestureDetector(
                      onTap: controller.resendVerificationEmail,
                      child: Text(
                        'resend_verification_email'.tr,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: ColorManager.primaryColor,
                          fontWeight: FontManager.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Divider with "or"
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: ColorManager.divider,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            'or'.tr,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: ColorManager.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: ColorManager.divider,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${'dont_have_account'.tr} ',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: ColorManager.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Get.toNamed(AppRoutes.roleSelection),
                          child: Text(
                            'sign_up'.tr,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: ColorManager.primaryColor,
                              fontWeight: FontManager.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
