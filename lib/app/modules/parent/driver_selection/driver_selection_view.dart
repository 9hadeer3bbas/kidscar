import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../custom_widgets/wave_header.dart';
import '../../../custom_widgets/custom_button.dart';
import '../../../../core/managers/color_manager.dart';
import '../../../../data/models/subscription_model.dart';
import 'driver_selection_controller.dart';

class DriverSelectionView extends GetView<DriverSelectionController> {
  const DriverSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.scaffoldBackground,
      body: Column(
        children: [
          // Header
          WaveHeader(title: 'Driver Selection', onBackTap: () => Get.back()),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'The best drivers at your service',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: ColorManager.textPrimary,
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Drivers List
                  Obx(() {
                    print(
                      'Driver selection UI - Loading: ${controller.isLoading.value}, Drivers count: ${controller.availableDrivers.length}',
                    ); // Debug print

                    if (controller.isLoading.value) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: ColorManager.primaryColor,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'Loading drivers...',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: ColorManager.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (controller.availableDrivers.isEmpty) {
                      return Center(
                        child: Column(
                          children: [
                            SizedBox(height: 50.h),
                            Icon(
                              Icons.drive_eta,
                              size: 64.sp,
                              color: ColorManager.textSecondary,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'No drivers available at the moment',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: ColorManager.textSecondary,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Please try again later',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: ColorManager.textSecondary,
                              ),
                            ),
                            SizedBox(height: 20.h),
                            ElevatedButton(
                              onPressed: () =>
                                  controller.loadAvailableDrivers(),
                              child: Text('refresh'.tr),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: controller.availableDrivers.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final driver = controller.availableDrivers[index];
                        return Obx(() {
                          final isSelected =
                              controller.selectedDriverId.value == driver.id;
                          print(
                            'Building driver card for ${driver.fullName}, isSelected: $isSelected, selectedId: ${controller.selectedDriverId.value}',
                          ); // Debug print
                          return _buildDriverCard(driver, isSelected);
                        });
                      },
                    );
                  }),

                  SizedBox(height: 30.h),

                  // Pay Now Button
                  Obx(() {
                    print(
                      'Pay Now button - Selected driver ID: ${controller.selectedDriverId.value}',
                    ); // Debug print
                    return CustomButton(
                      text: 'Pay Now',
                      onPressed: controller.selectedDriverId.value.isNotEmpty
                          ? () => controller.proceedToPayment()
                          : null,
                      isLoading: controller.isProcessing.value,
                      textStyle: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: ColorManager.white,
                      ),
                    );
                  }),

                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(DriverModel driver, bool isSelected) {
    return GestureDetector(
      onTap: () {
        print(
          'Driver card tapped: ${driver.id} - ${driver.fullName}',
        ); // Debug print
        controller.selectDriver(driver.id);
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorManager.primaryColor.withOpacity(0.1)
              : ColorManager.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? ColorManager.primaryColor
                : ColorManager.divider,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ColorManager.primaryColor.withOpacity(0.3),
                    offset: Offset(0, 4),
                    blurRadius: 12,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: Row(
          children: [
            // Driver Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 30.r,
                  backgroundColor: ColorManager.divider,
                  backgroundImage: driver.profileImageUrl != null
                      ? NetworkImage(driver.profileImageUrl!)
                      : null,
                  child: driver.profileImageUrl == null
                      ? Icon(
                          Icons.person,
                          size: 30.sp,
                          color: ColorManager.textSecondary,
                        )
                      : null,
                ),
                if (isSelected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 20.w,
                      height: 20.h,
                      decoration: BoxDecoration(
                        color: ColorManager.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: ColorManager.white, width: 2),
                      ),
                      child: Icon(
                        Icons.check,
                        size: 12.sp,
                        color: ColorManager.white,
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(width: 16.w),

            // Driver Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.fullName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: ColorManager.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Age ${driver.age}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: ColorManager.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Rating
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16.sp,
                        color: ColorManager.secondaryColor,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${driver.rating}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: ColorManager.textPrimary,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '(${driver.totalTrips} trips)',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: ColorManager.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (isSelected) ...[
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: ColorManager.primaryColor,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        'SELECTED',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: ColorManager.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Selection Indicator
            Container(
              width: 24.w,
              height: 24.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? ColorManager.primaryColor
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? ColorManager.primaryColor
                      : ColorManager.divider,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 16.sp, color: ColorManager.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
