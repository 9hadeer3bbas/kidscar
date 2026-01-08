import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:kidscar/core/managers/color_manager.dart';
import 'package:kidscar/core/managers/assets_manager.dart';
import 'package:kidscar/app/custom_widgets/wave_header.dart';

class PrivacyAndSecurityView extends StatelessWidget {
  const PrivacyAndSecurityView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.backgroundColor,
      body: Column(
        children: [
          WaveHeader(
            logoPath: AssetsManager.logoImage,
            showBackButton: true,
            showLanguageButton: true,
            title: 'privacy_and_security'.tr,
            onBackTap: () => Get.back(),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with shield icon
                    // Center(
                    //   child: Column(
                    //     children: [
                    //       Container(
                    //         width: 80.w,
                    //         height: 80.h,
                    //         decoration: BoxDecoration(
                    //           color: ColorManager.primaryColor.withValues(
                    //             alpha: 0.1,
                    //           ),
                    //           borderRadius: BorderRadius.circular(40.r),
                    //         ),
                    //         child: Icon(
                    //           Icons.security,
                    //           color: ColorManager.primaryColor,
                    //           size: 40.sp,
                    //         ),
                    //       ),
                    //       SizedBox(height: 16.h),
                    //     ],
                    //   ),
                    // ),
                    // SizedBox(height: 24.h),

                    // Introduction text
                    // Footer note
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: ColorManager.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: ColorManager.primaryColor.withValues(
                            alpha: 0.3,
                          ),
                          width: 1.w,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: ColorManager.primaryColor,
                            size: 20.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'privacy_policy_intro'.tr,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: ColorManager.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Data Privacy and Protection section
                    _buildSection(
                      'data_privacy_protection'.tr,
                      [
                        'data_privacy_point_1'.tr,
                        'data_privacy_point_2'.tr,
                        'data_privacy_point_3'.tr,
                        'data_privacy_point_4'.tr,
                      ],
                      Icons.security,
                      ColorManager.primaryColor,
                    ),
                    SizedBox(height: 16.h),

                    // Safety During Trip section
                    _buildSection(
                      'safety_during_trip'.tr,
                      [
                        'safety_point_1'.tr,
                        'safety_point_2'.tr,
                        'safety_point_3'.tr,
                        'safety_point_4'.tr,
                      ],
                      Icons.child_care,
                      ColorManager.success,
                    ),
                    SizedBox(height: 16.h),

                    // User Obligations section
                    _buildSection(
                      'user_obligations'.tr,
                      ['obligations_point_1'.tr, 'obligations_point_2'.tr],
                      Icons.rule,
                      ColorManager.warning,
                    ),
                    SizedBox(height: 18.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<String> points,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ColorManager.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: ColorManager.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.h,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(icon, color: color, size: 18.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: ColorManager.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Points
            ...points
                .map(
                  (point) => Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Text(
                      point,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: ColorManager.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }
}
