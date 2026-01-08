import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../core/controllers/language_controller.dart';
import '../../../../core/managers/assets_manager.dart';
import '../../../../core/managers/color_manager.dart';
import '../../../../core/routes/get_routes.dart';
import '../../../custom_widgets/custom_button.dart';
import '../parent_main/parent_main_controller.dart';

class ParentAccountView extends StatelessWidget {
  const ParentAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    final ParentMainController controller = Get.find<ParentMainController>();

    return Scaffold(
      backgroundColor: ColorManager.scaffoldBackground,
      body: Stack(
        children: [
          const _HeroGradient(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
                  child: _ProfileHeader(),
                ),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 8.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProfileCard(controller: controller),
                          SizedBox(height: 20.h),
                          const _QuickActions(),
                          SizedBox(height: 20.h),
                          _SettingsSection(controller: controller),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroGradient extends StatelessWidget {
  const _HeroGradient();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorManager.primaryColor.withValues(alpha: 0.85),
              ColorManager.primaryColor.withValues(alpha: 0.45),
              Colors.transparent,
            ],
            stops: const [0.0, 0.35, 0.7],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'account_overview'.tr,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'parent_account'.tr,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.controller});

  final ParentMainController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.currentUser.value;
      final name = user?.fullName ?? 'parent_name_placeholder'.tr;
      final email = user?.email ?? 'parent_email_placeholder'.tr;

      return ClipRRect(
        borderRadius: BorderRadius.circular(28.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28.r),
              color: Colors.white.withValues(alpha: 0.9),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 32.r,
                      backgroundColor: ColorManager.primaryColor.withValues(
                        alpha: 0.14,
                      ),
                      child: SvgPicture.asset(
                        AssetsManager.userIcon,
                        width: 24.w,
                        height: 24.h,
                        colorFilter: ColorFilter.mode(
                          ColorManager.primaryColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  overflow: TextOverflow.ellipsis,
                                  color: ColorManager.textPrimary,
                                ),
                              ),
                              _StatusChip(
                                icon: Icons.verified_user,
                                label: 'account_verified'.tr,
                                color: Colors.green,
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 14.sp,
                              overflow: TextOverflow.ellipsis,
                              color: ColorManager.textSecondary,
                            ),
                          ),
                          SizedBox(height: 6.h),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                CustomButton(
                  text: 'edit_profile'.tr,
                  textStyle: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  onPressed: () => Get.toNamed(AppRoutes.parentEditProfile),
                  height: 24.h,
                  width: 110.w,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'quick_actions'.tr,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: ColorManager.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            _QuickActionTile(
              icon: Icons.notifications_outlined,
              label: 'view_notifications'.tr,
              onTap: () => Get.toNamed(AppRoutes.parentNotifications),
            ),
            SizedBox(width: 8.w),
            _QuickActionTile(
              icon: Icons.language_outlined,
              label: 'change_language'.tr,
              onTap: () => _showLanguageDialog(context),
            ),
            SizedBox(width: 8.w),
            _QuickActionTile(
              icon: Icons.policy_outlined,
              label: 'privacy_policy'.tr,
              onTap: () => Get.toNamed(AppRoutes.privacySecurity),
            ),
          ],
        ),
      ],
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final languageController = Get.find<LanguageController>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'select_language'.tr,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: ColorManager.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 24.sp),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Obx(
                () => Column(
                  children: languageController.languages.map((language) {
                    final code = language['code']!;
                    final name = language['name']!;
                    final flag = language['flag']!;
                    final isSelected =
                        languageController.currentLanguage.value == code;

                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: InkWell(
                        onTap: () {
                          languageController.changeLanguage(code);
                          Get.back();
                        },
                        borderRadius: BorderRadius.circular(16.r),
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? ColorManager.primaryColor.withValues(
                                    alpha: 0.1,
                                  )
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isSelected
                                  ? ColorManager.primaryColor
                                  : ColorManager.divider.withValues(alpha: 0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48.w,
                                height: 48.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ColorManager.primaryColor.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    flag,
                                    style: TextStyle(fontSize: 28.sp),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: ColorManager.textPrimary,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: ColorManager.primaryColor,
                                  size: 24.sp,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 110.h,
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 12.h),
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorManager.primaryColor.withValues(alpha: 0.12),
                ),
                child: Icon(icon, color: ColorManager.primaryColor),
              ),
              SizedBox(height: 12.h),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: ColorManager.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.controller});

  final ParentMainController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'account_settings'.tr,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: ColorManager.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        _SettingsTile(
          icon: Icons.person_outline,
          title: 'view_profile'.tr,
          subtitle: 'view_profile_subtitle'.tr,
          onTap: () => Get.toNamed(AppRoutes.parentViewProfile),
        ),
        _SettingsTile(
          icon: Icons.notifications_active_outlined,
          title: 'notification_settings'.tr,
          subtitle: 'notification_settings_subtitle'.tr,
          onTap: () => Get.toNamed(AppRoutes.parentNotifications),
        ),
        _SettingsTile(
          icon: Icons.security_outlined,
          title: 'privacy_policy'.tr,
          subtitle: 'privacy_policy_subtitle'.tr,
          onTap: () => Get.toNamed(AppRoutes.privacySecurity),
        ),
        _SettingsTile(
          icon: Icons.lock_outline,
          title: 'change_password'.tr,
          subtitle: 'change_password_subtitle'.tr,
          onTap: () => Get.toNamed(AppRoutes.changePassword),
        ),
        _SettingsTile(
          icon: Icons.logout,
          title: 'logout'.tr,
          subtitle: 'logout_subtitle'.tr,
          onTap: () => _showLogoutDialog(context, controller),
        ),
      ],
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    ParentMainController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text('logout'.tr),
          content: Text('logout_confirmation'.tr),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
            TextButton(
              onPressed: () {
                Get.back();
                controller.logout();
              },
              child: Text('confirm'.tr),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ColorManager.primaryColor.withValues(alpha: 0.12),
        ),
        child: Icon(icon, color: ColorManager.primaryColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: ColorManager.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12.sp, color: ColorManager.textSecondary),
      ),
      trailing: Icon(Icons.chevron_right, color: ColorManager.textSecondary),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        color: color.withValues(alpha: 0.12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
