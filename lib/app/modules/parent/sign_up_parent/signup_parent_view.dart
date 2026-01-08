import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kidscar/app/custom_widgets/custom_button.dart';
import 'package:kidscar/app/custom_widgets/custom_text_field.dart';
import 'package:kidscar/app/custom_widgets/wave_header.dart';
import 'package:kidscar/app/modules/parent/sign_up_parent/signup_parent_controller.dart';
import 'package:kidscar/core/managers/assets_manager.dart';
import 'package:kidscar/core/managers/color_manager.dart';
import 'package:kidscar/core/managers/font_manager.dart';
import 'package:kidscar/core/controllers/language_controller.dart';
import 'package:kidscar/core/routes/get_routes.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SignupParentView extends GetView<SignupParentController> {
  const SignupParentView({super.key});

  @override
  Widget build(BuildContext context) {
    final LanguageController languageController =
        Get.find<LanguageController>();
    final currentLocale = languageController.currentLanguage.value == 'ar'
        ? const Locale('ar')
        : const Locale('en');

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
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'welcome'.tr,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),
                    Obx(
                      () => CustomTextField(
                        hintText: 'full_name'.tr,
                        controller: controller.nameController,
                        keyboardType: TextInputType.name,
                        prefixIcon: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: SvgPicture.asset(
                            AssetsManager.userIcon,
                            width: 20.w,
                            height: 20.w,
                          ),
                        ),
                        errorText: controller.nameError.value.isNotEmpty
                            ? controller.nameError.value
                            : null,
                        focusNode: controller.nameFocusNode,
                        onFieldSubmitted: (_) => FocusScope.of(
                          context,
                        ).requestFocus(controller.emailFocusNode),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Obx(
                      () => CustomTextField(
                        hintText: 'email'.tr,
                        controller: controller.emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: SvgPicture.asset(
                            AssetsManager.emailIcon,
                            width: 20.w,
                            height: 20.w,
                          ),
                        ),
                        errorText: controller.emailError.value.isNotEmpty
                            ? controller.emailError.value
                            : null,
                        focusNode: controller.emailFocusNode,
                        onFieldSubmitted: (_) => FocusScope.of(
                          context,
                        ).requestFocus(controller.phoneFocusNode),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Obx(
                      () => CustomTextField(
                        hintText: 'phone'.tr,
                        controller: controller.phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: SvgPicture.asset(
                            AssetsManager.phoneIcon,
                            width: 20.w,
                            height: 20.w,
                          ),
                        ),
                        errorText: controller.phoneError.value.isNotEmpty
                            ? controller.phoneError.value
                            : null,
                        focusNode: controller.phoneFocusNode,
                        onFieldSubmitted: (_) => FocusScope.of(
                          context,
                        ).requestFocus(controller.passwordFocusNode),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Obx(
                      () => CustomTextField(
                        hintText: 'password'.tr,
                        controller: controller.passwordController,
                        keyboardType: TextInputType.visiblePassword,
                        obscureText: !controller.showPassword.value,
                        prefixIcon: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: SvgPicture.asset(
                            AssetsManager.lockIcon,
                            width: 20.w,
                            height: 20.w,
                          ),
                        ),
                        suffixIcon: Icon(
                          controller.showPassword.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: ColorManager.textSecondary,
                        ),
                        onSuffixTap: controller.togglePasswordVisibility,
                        errorText: controller.passwordError.value.isNotEmpty
                            ? controller.passwordError.value
                            : null,
                        focusNode: controller.passwordFocusNode,
                        onFieldSubmitted: (_) => FocusScope.of(
                          context,
                        ).requestFocus(controller.confirmPasswordFocusNode),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Obx(
                      () => CustomTextField(
                        hintText: 'confirm_password'.tr,
                        controller: controller.confirmPasswordController,
                        keyboardType: TextInputType.visiblePassword,
                        obscureText: !controller.showConfirmPassword.value,
                        prefixIcon: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: SvgPicture.asset(
                            AssetsManager.lockIcon,
                            width: 20.w,
                            height: 20.w,
                          ),
                        ),
                        suffixIcon: Icon(
                          controller.showConfirmPassword.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: ColorManager.textSecondary,
                        ),
                        onSuffixTap: controller.toggleConfirmPasswordVisibility,
                        errorText:
                            controller.confirmPasswordError.value.isNotEmpty
                            ? controller.confirmPasswordError.value
                            : null,
                        focusNode: controller.confirmPasswordFocusNode,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).unfocus(),
                      ),
                    ),
                    SizedBox(height: 8.h),

                    // Privacy Policy Agreement
                    Obx(
                      () => Row(
                        children: [
                          Checkbox(
                            value: controller.agreeToPolicy.value,
                            onChanged: controller.togglePolicy,
                            activeColor: ColorManager.primaryColor,
                            checkColor: ColorManager.white,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Get.toNamed('/privacy-security'),
                              child: RichText(
                                text: TextSpan(
                                  style: FontManager.getTextSpanStyle(
                                    currentLocale,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    color: ColorManager.textSecondary,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'privacy_policy_agreement'.tr,
                                    ),
                                    TextSpan(
                                      text: ' ${'see_more'.tr}',
                                      style: FontManager.getTextSpanStyle(
                                        currentLocale,
                                        fontSize: 12.sp,

                                        color: ColorManager.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    /// Sign Up button
                    Obx(
                      () => CustomButton(
                        text: 'sign_up'.tr,
                        onPressed: controller.signUp,
                        isLoading: controller.isLoading.value,
                        height: 30.0.h,
                        width: 250.0.w,
                        textStyle: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    /// Divider and Login Redirect
                    Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: Text(
                            'or'.tr,
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 18.h,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18.r),
                        gradient: LinearGradient(
                          colors: [
                            ColorManager.primaryColor.withValues(alpha: 0.08),
                            ColorManager.primaryColor.withValues(alpha: 0.02),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: ColorManager.primaryColor.withValues(
                            alpha: 0.2,
                          ),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ColorManager.primaryColor.withValues(
                              alpha: 0.08,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44.w,
                            height: 44.w,
                            decoration: BoxDecoration(
                              color: ColorManager.white,
                              borderRadius: BorderRadius.circular(14.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.login_rounded,
                              color: ColorManager.primaryColor,
                              size: 22.sp,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'already_have_account'.tr,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: ColorManager.textSecondary,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                CustomButton(
                                  text: 'sign_in'.tr,
                                  onPressed: () =>
                                      Get.toNamed(AppRoutes.signIn),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
