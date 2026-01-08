import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/managers/color_manager.dart';
import '../../../custom_widgets/wave_header.dart';
import '../parent_main/parent_main_controller.dart';

class ParentViewProfileView extends GetView<ParentMainController> {
  const ParentViewProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.backgroundColor,
      body: Column(
        children: [
          WaveHeader(
            showBackButton: true,
            title: 'view_profile'.tr,
            onBackTap: () => Get.back(),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final user = controller.currentUser.value;
              if (user == null) {
                return Center(
                  child: Text(
                    'no_profile_data'.tr,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: ColorManager.textSecondary,
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(user.fullName, user.email),
                    SizedBox(height: 24.h),
                    _buildProfileSection(
                      title: 'personal_information'.tr,
                      children: [
                        _buildInfoTile(
                          icon: Icons.person_outline,
                          label: 'full_name'.tr,
                          value: user.fullName,
                        ),
                        _buildInfoTile(
                          icon: Icons.email_outlined,
                          label: 'email'.tr,
                          value: user.email,
                        ),
                        _buildInfoTile(
                          icon: Icons.phone_outlined,
                          label: 'phone_number'.tr,
                          value: user.phoneNumber,
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    _buildProfileSection(
                      title: 'account_information'.tr,
                      children: [
                        _buildInfoTile(
                          icon: Icons.badge_outlined,
                          label: 'role'.tr,
                          value: user.role.toUpperCase(),
                        ),
                        _buildInfoTile(
                          icon: Icons.verified_user_outlined,
                          label: 'account_status'.tr,
                          value: 'verified'.tr,
                          valueColor: Colors.green,
                        ),
                        _buildInfoTile(
                          icon: Icons.calendar_today_outlined,
                          label: 'member_since'.tr,
                          value: _formatDate(user.createdAt),
                        ),
                      ],
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

  Widget _buildProfileHeader(String name, String email) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50.r,
            backgroundColor: ColorManager.primaryColor.withValues(alpha: 0.1),
            child: Icon(
              Icons.person,
              size: 50.sp,
              color: ColorManager.primaryColor,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            name,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: ColorManager.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            email,
            style: TextStyle(
              fontSize: 14.sp,
              color: ColorManager.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
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
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: ColorManager.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorManager.primaryColor.withValues(alpha: 0.12),
            ),
            child: Icon(
              icon,
              color: ColorManager.primaryColor,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: ColorManager.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? ColorManager.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

