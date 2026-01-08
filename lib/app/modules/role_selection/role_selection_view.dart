import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kidscar/app/custom_widgets/custom_button.dart';
import 'package:kidscar/core/routes/get_routes.dart';
import '../../custom_widgets/wave_header.dart';
import '../../../core/managers/color_manager.dart';
import '../../../core/managers/assets_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RoleSelectionView extends StatelessWidget {
  const RoleSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.backgroundColor,
      body: Column(
        children: [
          WaveHeader(
            logoPath: AssetsManager.logoImage,
            showBackButton: false,
            showLanguageButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 40.h),
                    Text(
                      'welcome'.tr,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w600,
                        color: ColorManager.black,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'select_role'.tr,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: ColorManager.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'choose_role_desc'.tr,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: ColorManager.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 30.h),
                    _roleCard(
                      context: context,
                      title: 'parent_role'.tr,
                      subtitle: 'parent_role_desc'.tr,
                      iconPath: AssetsManager.userIcon,
                      color: ColorManager.primaryColor,
                      onTap: () => Get.toNamed(AppRoutes.signUpParent),
                    ),
                    SizedBox(height: 20.h),
                    _roleCard(
                      context: context,
                      title: 'driver_role'.tr,
                      subtitle: 'driver_role_desc'.tr,
                      iconPath: AssetsManager.carIcon,
                      color: ColorManager.secondaryColor,
                      onTap: () => Get.toNamed(AppRoutes.signUpDriver),
                    ),
                    SizedBox(height: 32.h),
                    _SignInCard(),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String iconPath,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 18.w),
        margin: EdgeInsets.symmetric(vertical: 0.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.05),
              color.withValues(alpha: 0.12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: SvgPicture.asset(
                iconPath,
                width: 38.w,
                height: 38.w,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: ColorManager.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 24.sp),
          ],
        ),
      ),
    );
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
