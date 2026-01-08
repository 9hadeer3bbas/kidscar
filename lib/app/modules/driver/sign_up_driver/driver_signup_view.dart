import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kidscar/app/custom_widgets/custom_button.dart';
import 'package:kidscar/app/custom_widgets/custom_text_field.dart';
import 'package:kidscar/app/custom_widgets/wave_header.dart';
import 'package:kidscar/core/managers/assets_manager.dart';
import 'package:kidscar/core/managers/color_manager.dart';
import 'package:kidscar/core/managers/font_manager.dart';
import 'package:kidscar/core/controllers/language_controller.dart';
import 'package:kidscar/core/routes/get_routes.dart';
import 'driver_signup_controller.dart';
import 'package:kidscar/app/modules/driver/file_attach_driver/file_attach_driver_view.dart';

class DriverSignUpView extends GetView<DriverSignUpController> {
  const DriverSignUpView({super.key});

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
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),
                    Center(
                      child: Text(
                        'earn_by_driving'.tr,
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: ColorManager.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'driver_register_greeting'.tr,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: ColorManager.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'driver_register_desc'.tr,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: ColorManager.textSecondary,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        Expanded(
                          child: Obx(
                            () => CustomTextField(
                              hintText: 'first_name'.tr,
                              controller: controller.firstNameController,
                              keyboardType: TextInputType.name,
                              focusNode: controller.firstNameFocusNode,
                              errorText:
                                  controller.firstNameError.value.isNotEmpty
                                  ? controller.firstNameError.value
                                  : null,
                              onFieldSubmitted: (_) => FocusScope.of(
                                context,
                              ).requestFocus(controller.lastNameFocusNode),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Obx(
                            () => CustomTextField(
                              hintText: 'last_name'.tr,
                              controller: controller.lastNameController,
                              keyboardType: TextInputType.name,
                              focusNode: controller.lastNameFocusNode,
                              errorText:
                                  controller.lastNameError.value.isNotEmpty
                                  ? controller.lastNameError.value
                                  : null,
                              onFieldSubmitted: (_) => FocusScope.of(
                                context,
                              ).requestFocus(controller.phoneFocusNode),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Obx(
                      () => CustomTextField(
                        hintText: 'phone_number'.tr,
                        controller: controller.phoneController,
                        keyboardType: TextInputType.phone,
                        focusNode: controller.phoneFocusNode,
                        errorText: controller.phoneError.value.isNotEmpty
                            ? controller.phoneError.value
                            : null,
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
                        focusNode: controller.emailFocusNode,
                        errorText: controller.emailError.value.isNotEmpty
                            ? controller.emailError.value
                            : null,
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
                        focusNode: controller.passwordFocusNode,
                        obscureText: !controller.showPassword.value,
                        errorText: controller.passwordError.value.isNotEmpty
                            ? controller.passwordError.value
                            : null,
                        suffixIcon: Icon(
                          controller.showPassword.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: ColorManager.textSecondary,
                        ),
                        onSuffixTap: controller.togglePasswordVisibility,
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
                        focusNode: controller.confirmPasswordFocusNode,
                        obscureText: !controller.showConfirmPassword.value,
                        errorText:
                            controller.confirmPasswordError.value.isNotEmpty
                            ? controller.confirmPasswordError.value
                            : null,
                        suffixIcon: Icon(
                          controller.showConfirmPassword.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: ColorManager.textSecondary,
                        ),
                        onSuffixTap: controller.toggleConfirmPasswordVisibility,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).unfocus(),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'photos_to_attach'.tr + ' *',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: ColorManager.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _photoButton(context, 'driver_photo'.tr),
                    SizedBox(height: 8.h),
                    _photoButton(context, 'driving_license'.tr),
                    SizedBox(height: 8.h),
                    _photoButton(context, 'vehicle_registration'.tr),
                    SizedBox(height: 24.h),
                    Text(
                      'city_to_work'.tr,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: ColorManager.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Obx(
                      () => SizedBox(
                        height: 28.0.h,
                        width: 240.0.w,
                        child: DropdownButtonFormField<String>(
                          // Remove or set itemHeight to 48.0
                          itemHeight: 48.0,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20.w,
                            color: ColorManager.textSecondary,
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                          decoration: InputDecoration(
                            hintText: 'select_city'.tr,
                            hintStyle: TextStyle(
                              fontSize: 14.sp,
                              color: ColorManager.textPrimary,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 5.h,
                            ),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: BorderSide(
                                color: ColorManager.divider,
                                width: 1.0.w,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: BorderSide(
                                color: ColorManager.primaryColor,
                                width: 1.0.w,
                              ),
                            ),
                          ),
                          initialValue: controller.selectedCity.value.isEmpty
                              ? null
                              : controller.selectedCity.value,
                          items: [
                            DropdownMenuItem(
                              value: 'Riyadh',
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Riyadh'.tr,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: ColorManager.textPrimary,
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Dammam',
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Dammam'.tr,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: ColorManager.textPrimary,
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Mecca',
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Mecca'.tr,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: ColorManager.textPrimary,
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              controller.selectedCity.value = value;
                            }
                          },
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'select_city_required'.tr
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

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
                                    color: ColorManager.textSecondary,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'privacy_policy_agreement'.tr,
                                    ),
                                    TextSpan(
                                      text: ' ${'see_more'.tr}',
                                      style:
                                          FontManager.getTextSpanStyle(
                                            currentLocale,
                                            color: ColorManager.primaryColor,
                                            fontSize: 12.sp,

                                            fontWeight: FontWeight.w600,
                                          ).copyWith(
                                            decoration:
                                                TextDecoration.underline,
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

                    Align(
                      alignment: Alignment.center,
                      child: Obx(
                        () => CustomButton(
                          height: 30.0.h,
                          width: 250.0.w,
                          text: 'sign_up'.tr,
                          isLoading: controller.isLoading.value,
                          onPressed: controller.registerDriver,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
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
                    _SignInCard(),
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

  Widget _photoButton(BuildContext context, String text) {
    return Obx(() {
      bool isAttached = false;
      if (text == 'driver_photo'.tr) {
        isAttached = controller.driverPhoto.value != null;
      } else if (text == 'driving_license'.tr) {
        isAttached = controller.drivingLicense.value != null;
      } else if (text == 'vehicle_registration'.tr) {
        isAttached = controller.vehicleRegistration.value != null;
      }
      return SizedBox(
        height: 28.0.h,
        width: 240.0.w,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlue[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
              side: BorderSide(
                color: isAttached
                    ? ColorManager.success.withValues(alpha: 0.8)
                    : ColorManager.divider.withValues(alpha: 0.8),
                width: 1.0.w,
              ),
            ),
          ),
          onPressed: () async {
            // Determine which button was pressed and set custom title/instructions/handler
            String attachTitle = '';
            List<String> attachInstructions = [];
            Function(dynamic)? onResult;
            bool isPhoto = false;
            if (text == 'driver_photo'.tr) {
              attachTitle = 'attach_driver_photo_title'.tr;
              attachInstructions = [
                'attach_driver_photo_instruction_1'.tr,
                'attach_driver_photo_instruction_2'.tr,
                'attach_driver_photo_instruction_3'.tr,
                'attach_driver_photo_instruction_4'.tr,
              ];
              onResult = (image) {
                if (image != null) controller.driverPhoto.value = image;
              };
              isPhoto = true;
            } else if (text == 'driving_license'.tr) {
              attachTitle = 'attach_driving_license_title'.tr;
              attachInstructions = [
                'attach_driving_license_instruction_1'.tr,
                'attach_driving_license_instruction_2'.tr,
                'attach_driving_license_instruction_3'.tr,
                'attach_driving_license_instruction_4'.tr,
              ];
              onResult = (image) {
                if (image != null) controller.drivingLicense.value = image;
              };
            } else if (text == 'vehicle_registration'.tr) {
              attachTitle = 'attach_vehicle_registration_title'.tr;
              attachInstructions = [
                'attach_vehicle_registration_instruction_1'.tr,
                'attach_vehicle_registration_instruction_2'.tr,
                'attach_vehicle_registration_instruction_3'.tr,
                'attach_vehicle_registration_instruction_4'.tr,
                'attach_vehicle_registration_instruction_5'.tr,
              ];
              onResult = (image) {
                if (image != null) controller.vehicleRegistration.value = image;
              };
            }

            final image = await Get.to(
              () => FileAttachDriverView(
                title: attachTitle,
                instructions: attachInstructions,
                isPhoto: isPhoto,
              ),
            );
            if (onResult != null) onResult(image);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: ColorManager.black,
                ),
              ),
              if (isAttached) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.check_circle,
                  color: ColorManager.success,
                  size: 20.sp,
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _SignInCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
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
          color: ColorManager.primaryColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorManager.primaryColor.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: Row(
        mainAxisSize: MainAxisSize.max,
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
          Expanded(
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
                  onPressed: () => Get.toNamed(AppRoutes.signIn),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
