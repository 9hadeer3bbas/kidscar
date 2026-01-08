import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../custom_widgets/wave_header.dart';
import '../../../custom_widgets/custom_button.dart';
import '../../../../core/managers/color_manager.dart';
import '../../../../data/models/kid_model.dart';
import 'my_kids_controller.dart';

class MyKidsView extends GetView<MyKidsController> {
  const MyKidsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Modern Header
          WaveHeader(title: 'my_kids'.tr, onBackTap: () => Get.back()),
          // Content
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(
                    color: ColorManager.primaryColor,
                  ),
                );
              }

              if (controller.kids.isEmpty) {
                return _buildEmptyState();
              }

              return _buildKidsList();
            }),
          ),
        ],
      ),
      floatingActionButton: _buildModernFloatingButton(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                color: ColorManager.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(60.r),
                border: Border.all(
                  color: ColorManager.primaryColor.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.child_care_rounded,
                size: 60.sp,
                color: ColorManager.primaryColor,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'no_kids_yet'.tr,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: ColorManager.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'add_your_first_kid'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: ColorManager.textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'add_your_first_kid_button'.tr,
                onPressed: controller.showAddKidDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKidsList() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern Header with count
          Container(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: ColorManager.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '${controller.kids.length} ${controller.kids.length == 1 ? 'kid'.tr : 'kids'.tr}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: ColorManager.primaryColor,
                    ),
                  ),
                ),
                Spacer(),
                Text(
                  'tap_to_manage'.tr,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: ColorManager.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // Kids Grid
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
              childAspectRatio: 0.75, // Increased from 0.75 to give more height
            ),
            itemCount: controller.kids.length,
            itemBuilder: (context, index) {
              final kid = controller.kids[index];
              return _buildModernKidCard(kid);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernKidCard(KidModel kid) {
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: ColorManager.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: ColorManager.primaryColor.withValues(alpha: 0.1),
            offset: Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Image
          Expanded(
            flex: 2, // Reduced from 3 to give more space for details
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ColorManager.primaryColor.withValues(alpha: 0.1),
                    ColorManager.secondaryColor.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Profile Image
                  Center(
                    child: kid.profileImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20.r),
                              topRight: Radius.circular(20.r),
                            ),
                            child: Image.network(
                              kid.profileImageUrl!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultAvatar();
                              },
                            ),
                          )
                        : _buildDefaultAvatar(),
                  ),

                  // Gender Badge
                  Positioned(
                    top: 12.h,
                    right: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: kid.gender == Gender.male
                            ? ColorManager.primaryColor
                            : ColorManager.secondaryColor,
                        borderRadius: BorderRadius.circular(15.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            kid.gender == Gender.male
                                ? Icons.male
                                : Icons.female,
                            size: 16.sp,
                            color: ColorManager.white,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            kid.gender == Gender.male ? 'male'.tr : 'female'.tr,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: ColorManager.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Action Menu
                  Positioned(
                    top: 12.h,
                    left: 12.w,
                    child: PopupMenuButton<String>(
                      borderRadius: BorderRadius.circular(22.r),
                      icon: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: ColorManager.white.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.more_vert,
                          size: 18.sp,
                          color: ColorManager.textPrimary,
                        ),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            controller.showEditKidDialog(kid);
                            break;
                          case 'delete':
                            controller.showDeleteKidDialog(kid);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit,
                                size: 18.sp,
                                color: ColorManager.primaryColor,
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                'edit'.tr,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: ColorManager.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete,
                                size: 18.sp,
                                color: Colors.red,
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                'delete'.tr,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Kid Info Section
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.all(14.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Name Section
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kid.name.isNotEmpty ? kid.name : 'unknown_kid'.tr,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: ColorManager.textPrimary,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${'age'.tr}: ${kid.age}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: ColorManager.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Details Section
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // School Info
                        Row(
                          children: [
                            Icon(
                              Icons.school,
                              size: 14.sp,
                              color: ColorManager.textSecondary,
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                kid.schoolName,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: ColorManager.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),

                        // Grade Info
                        Row(
                          children: [
                            Icon(
                              Icons.grade,
                              size: 14.sp,
                              color: ColorManager.textSecondary,
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                '${'grade_class'.tr}: ${kid.grade}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: ColorManager.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
        color: ColorManager.divider.withValues(alpha: 0.3),
      ),
      child: Icon(Icons.person, size: 40.sp, color: ColorManager.textSecondary),
    );
  }

  Widget _buildModernFloatingButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: ColorManager.primaryColor.withValues(alpha: 0.3),
            offset: Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: controller.showAddKidDialog,
        backgroundColor: ColorManager.primaryColor,
        foregroundColor: ColorManager.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        icon: Icon(Icons.add_rounded, size: 20.sp),
        label: Text(
          'add_kid'.tr,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
