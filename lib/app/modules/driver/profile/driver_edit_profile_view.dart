import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/managers/color_manager.dart';
import '../../../../core/managers/font_manager.dart';
import '../../../custom_widgets/custom_button.dart';
import '../../../custom_widgets/custom_text_field.dart';
import '../../../custom_widgets/wave_header.dart';
import 'driver_edit_profile_controller.dart';

class DriverEditProfileView extends GetView<DriverEditProfileController> {
  const DriverEditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.backgroundColor,
      body: Column(
        children: [
          WaveHeader(
            showBackButton: true,
            title: 'edit_profile'.tr,
            onBackTap: () => Get.back(),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(),
                    SizedBox(height: 24.h),
                    Obx(
                      () => CustomTextField(
                        controller: controller.fullNameController,
                        focusNode: controller.fullNameFocusNode,
                        hintText: 'full_name'.tr,
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: ColorManager.textSecondary,
                          size: 20.sp,
                        ),
                        errorText:
                            controller.fullNameError.value.isNotEmpty
                                ? controller.fullNameError.value
                                : null,
                        onFieldSubmitted: (_) => FocusScope.of(context)
                            .requestFocus(controller.phoneFocusNode),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Obx(
                      () => CustomTextField(
                        controller: controller.phoneController,
                        focusNode: controller.phoneFocusNode,
                        hintText: 'phone_number'.tr,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                          color: ColorManager.textSecondary,
                          size: 20.sp,
                        ),
                        errorText: controller.phoneError.value.isNotEmpty
                            ? controller.phoneError.value
                            : null,
                        onFieldSubmitted: (_) => FocusScope.of(context)
                            .requestFocus(controller.cityFocusNode),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Obx(
                      () => CustomTextField(
                        controller: controller.cityController,
                        focusNode: controller.cityFocusNode,
                        hintText: 'city'.tr,
                        prefixIcon: Icon(
                          Icons.location_city_outlined,
                          color: ColorManager.textSecondary,
                          size: 20.sp,
                        ),
                        errorText: controller.cityError.value.isNotEmpty
                            ? controller.cityError.value
                            : null,
                        onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                      ),
                    ),
                    SizedBox(height: 32.h),
                    Obx(
                      () => CustomButton(
                        text: 'save_changes'.tr,
                        onPressed: controller.isSaving.value
                            ? null
                            : controller.saveProfile,
                        isLoading: controller.isSaving.value,
                        width: double.infinity,
                        height: 32.h,
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

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: ColorManager.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'profile_details'.tr,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontManager.semiBold,
              color: ColorManager.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'profile_details_hint'.tr,
            style: TextStyle(
              fontSize: 12.sp,
              color: ColorManager.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

