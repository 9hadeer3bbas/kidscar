import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../custom_widgets/wave_header.dart';
import '../../../custom_widgets/custom_button.dart';
import '../../../../core/managers/color_manager.dart';
import '../../../../data/models/subscription_model.dart';
import 'instant_ride_driver_selection_controller.dart';

class InstantRideDriverSelectionView
    extends GetView<InstantRideDriverSelectionController> {
  const InstantRideDriverSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.scaffoldBackground,
      body: Column(
        children: [
          WaveHeader(
            title: 'select_driver'.tr,
            onBackTap: () => Get.back(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: ColorManager.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: ColorManager.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: ColorManager.success,
                          size: 20.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'instant_ride_driver_info'.tr,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: ColorManager.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'online_drivers_available'.tr,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: ColorManager.textPrimary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Obx(() {
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
                              'loading_drivers'.tr,
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
                              Icons.drive_eta_outlined,
                              size: 64.sp,
                              color: ColorManager.textSecondary,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'no_online_drivers'.tr,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: ColorManager.textSecondary,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'try_again_later'.tr,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: ColorManager.textSecondary,
                              ),
                            ),
                            SizedBox(height: 20.h),
                            CustomButton(
                              text: 'refresh'.tr,
                              onPressed: () => controller.loadAvailableDrivers(),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.availableDrivers.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final driver = controller.availableDrivers[index];
                        return Obx(() {
                          final isSelected =
                              controller.selectedDriverId.value == driver.id;
                          return _buildDriverCard(driver, isSelected);
                        });
                      },
                    );
                  }),
                  SizedBox(height: 30.h),
                  Obx(() {
                    return CustomButton(
                      text: 'confirm_ride'.tr,
                      onPressed: controller.selectedDriverId.value.isNotEmpty
                          ? () => controller.createInstantRide()
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
      onTap: () => controller.selectDriver(driver.id),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorManager.primaryColor.withValues(alpha: 0.1)
              : ColorManager.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color:
                isSelected ? ColorManager.primaryColor : ColorManager.divider,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ColorManager.primaryColor.withValues(alpha: 0.2),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 32.r,
                  backgroundColor: ColorManager.divider,
                  backgroundImage: driver.profileImageUrl != null
                      ? NetworkImage(driver.profileImageUrl!)
                      : null,
                  child: driver.profileImageUrl == null
                      ? Icon(
                          Icons.person,
                          size: 32.sp,
                          color: ColorManager.textSecondary,
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16.w,
                    height: 16.h,
                    decoration: BoxDecoration(
                      color: ColorManager.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: ColorManager.white, width: 2),
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 22.w,
                      height: 22.h,
                      decoration: BoxDecoration(
                        color: ColorManager.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: ColorManager.white, width: 2),
                      ),
                      child: Icon(
                        Icons.check,
                        size: 14.sp,
                        color: ColorManager.white,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          driver.fullName,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: ColorManager.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: ColorManager.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 8.sp,
                              color: ColorManager.success,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'online'.tr,
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: ColorManager.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16.sp,
                        color: ColorManager.secondaryColor,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${driver.rating.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: ColorManager.textPrimary,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Icon(
                        Icons.local_taxi,
                        size: 14.sp,
                        color: ColorManager.textSecondary,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${driver.totalTrips} ${'trips'.tr}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: ColorManager.textSecondary,
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
    );
  }
}

