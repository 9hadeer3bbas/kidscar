import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../custom_widgets/wave_header.dart';
import '../../../custom_widgets/custom_button.dart';
import '../../../custom_widgets/custom_text_field.dart';
import '../../location_selection/location_selection_page.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/managers/assets_manager.dart';
import '../../../../core/managers/color_manager.dart';
import 'subscription_controller.dart';
import '../../../../data/models/subscription_model.dart';
import '../../../../data/models/kid_model.dart';
import '../../../../domain/entities/place_details.dart';
import '../../../../domain/repositories/location_repository.dart';
import '../../../../data/repos/location_repo.dart';
import '../../../../domain/usecases/location/search_location_suggestions_usecase.dart';
import '../../../../domain/usecases/location/get_place_details_usecase.dart';

class SubscriptionView extends GetView<SubscriptionController> {
  const SubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          WaveHeader(title: 'subscription'.tr, onBackTap: () => Get.back()),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Duration Section
                  _buildDurationSection(),
                  SizedBox(height: 20.h),

                  // Trip Type Section
                  _buildTripTypeSection(),
                  SizedBox(height: 20.h),

                  // Service Days Section
                  _buildServiceDaysSection(),
                  SizedBox(height: 20.h),

                  // Children Section
                  _buildChildrenSection(),
                  SizedBox(height: 20.h),

                  // Location Section
                  _buildLocationSection(),
                  SizedBox(height: 20.h),

                  // Time Section
                  _buildTimeSection(),
                  SizedBox(height: 20.h),

                  // Price Summary
                  _buildPriceSummary(),
                  SizedBox(height: 30.h),

                  // Continue Button
                  _buildContinueButton(),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'duration'.tr,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: ColorManager.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        CustomTextField(
          controller: controller.durationController,
          hintText: 'enter_number_of_weeks'.tr,
          keyboardType: TextInputType.number,
          errorText: controller.durationError.value.isNotEmpty
              ? controller.durationError.value
              : null,
        ),
      ],
    );
  }

  Widget _buildTripTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.asset(
              AssetsManager.carIcon,
              width: 20.w,
              height: 20.h,
              colorFilter: ColorFilter.mode(
                ColorManager.primaryColor,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              'trip_type'.tr,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: ColorManager.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: _buildTripTypeOption(
                  TripType.oneWay,
                  'one_way'.tr,
                  controller.selectedTripType.value == TripType.oneWay,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildTripTypeOption(
                  TripType.roundTrip,
                  'round_trip'.tr,
                  controller.selectedTripType.value == TripType.roundTrip,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTripTypeOption(
    TripType tripType,
    String label,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => controller.selectTripType(tripType),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: isSelected ? ColorManager.primaryColor : ColorManager.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? ColorManager.primaryColor
                : ColorManager.divider,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 16.w,
              height: 16.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? ColorManager.white : Colors.transparent,
                border: Border.all(
                  color: isSelected ? ColorManager.white : ColorManager.divider,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 10.sp,
                      color: ColorManager.primaryColor,
                    )
                  : null,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? ColorManager.white
                    : ColorManager.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 20.sp,
              color: ColorManager.primaryColor,
            ),
            SizedBox(width: 8.w),
            Text(
              'service_days'.tr,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: ColorManager.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: ColorManager.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: ColorManager.divider),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'select_days_of_week'.tr,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: ColorManager.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: controller.selectAllServiceDays,
                    child: Text(
                      'select_all'.tr,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: ColorManager.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Obx(
                () => Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: DayOfWeek.values.map((day) {
                    final isSelected = controller.selectedServiceDays.contains(
                      day,
                    );
                    return _buildDayChip(day, isSelected);
                  }).toList(),
                ),
              ),
              if (controller.serviceDaysError.value.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(
                    controller.serviceDaysError.value,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: ColorManager.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayChip(DayOfWeek day, bool isSelected) {
    return GestureDetector(
      onTap: () => controller.toggleServiceDay(day),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? ColorManager.primaryColor : ColorManager.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? ColorManager.primaryColor
                : ColorManager.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 12.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? ColorManager.white : Colors.transparent,
                border: Border.all(
                  color: isSelected ? ColorManager.white : ColorManager.divider,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 8.sp,
                      color: ColorManager.primaryColor,
                    )
                  : null,
            ),
            SizedBox(width: 6.w),
            Text(
              controller.getDayName(day),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? ColorManager.white
                    : ColorManager.textPrimary,
              ),
            ),
            SizedBox(width: 4.w),
            Text(
              '${controller.pricePerTrip.value.toInt()} ${'sar'.tr}',
              style: TextStyle(
                fontSize: 10.sp,
                color: isSelected
                    ? ColorManager.white
                    : ColorManager.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildrenSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.child_care,
              size: 20.sp,
              color: ColorManager.primaryColor,
            ),
            SizedBox(width: 8.w),
            Text(
              'children'.tr,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: ColorManager.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: ColorManager.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: ColorManager.divider),
          ),
          child: Column(
            children: [
              // Number of children
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'no_of_kids'.tr,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: ColorManager.textPrimary,
                    ),
                  ),
                  Obx(
                    () => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: ColorManager.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: ColorManager.primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'selected_kids_count'.tr,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: ColorManager.textPrimary,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ColorManager.primaryColor,
                            ),
                            child: Text(
                              '${controller.selectedChildrenIds.length}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: ColorManager.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Choose children
              Text(
                'choose_your_kids'.tr,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: ColorManager.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),
              Obx(() {
                if (controller.isLoadingChildren.value) {
                  return Container(
                    height: 100.h,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 30.w,
                            height: 30.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: ColorManager.primaryColor,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'loading_children'.tr,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: ColorManager.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (controller.availableChildren.isEmpty) {
                  return Container(
                    height: 100.h,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.child_care_outlined,
                            size: 40.sp,
                            color: ColorManager.textSecondary,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'no_children_found'.tr,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: ColorManager.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Wrap(
                  spacing: 12.w,
                  children: controller.availableChildren.map((KidModel child) {
                    final isSelected = controller.selectedChildrenIds.contains(
                      child.id,
                    );
                    return _buildChildChip(child, isSelected);
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChildChip(KidModel child, bool isSelected) {
    return GestureDetector(
      onTap: () => controller.toggleChildSelection(child.id),
      child: Container(
        width: 60.w,
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 25.r,
                  backgroundColor: ColorManager.divider,
                  backgroundImage: child.profileImageUrl != null
                      ? NetworkImage(child.profileImageUrl!)
                      : null,
                  child: child.profileImageUrl == null
                      ? Icon(
                          Icons.person,
                          size: 25.sp,
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
            SizedBox(height: 4.h),
            Text(
              child.name,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: ColorManager.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pickup Location
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: 20.sp,
              color: ColorManager.primaryColor,
            ),
            SizedBox(width: 8.w),
            Text(
              'pickup_location'.tr,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: ColorManager.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Obx(() {
          final location = controller.selectedPickupLocation.value;
          final hasSelection = location != null;
          final locationName = location?.name ?? 'select_pickup_location'.tr;
          final address = location?.address ?? '';
          return InkWell(
            onTap: _selectPickupLocation,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: ColorManager.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: hasSelection
                      ? ColorManager.primaryColor.withValues(alpha: 0.5)
                      : ColorManager.divider,
                  width: hasSelection ? 1.5 : 1,
                ),
                boxShadow: hasSelection
                    ? [
                        BoxShadow(
                          color: ColorManager.primaryColor.withValues(
                            alpha: 0.12,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color:
                          (hasSelection
                                  ? ColorManager.success
                                  : ColorManager.primaryColor)
                              .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      hasSelection ? Icons.check_circle : Icons.location_on,
                      color: hasSelection
                          ? ColorManager.success
                          : ColorManager.primaryColor,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locationName,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: hasSelection
                                ? ColorManager.textPrimary
                                : ColorManager.textSecondary,
                          ),
                        ),
                        if (hasSelection && address.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Text(
                            address,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: ColorManager.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (location != null && AppConfig.isDebugMode) ...[
                          SizedBox(height: 4.h),
                          Text(
                            '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontFamily: 'monospace',
                              color: ColorManager.success,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: ColorManager.textSecondary.withValues(alpha: 0.5),
                    size: 16.sp,
                  ),
                ],
              ),
            ),
          );
        }),
        if (controller.pickupLocationError.value.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(
              controller.pickupLocationError.value,
              style: TextStyle(color: ColorManager.error, fontSize: 12.sp),
            ),
          ),
        SizedBox(height: 16.h),

        // Drop-off Location
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: 20.sp,
              color: ColorManager.primaryColor,
            ),
            SizedBox(width: 8.w),
            Text(
              'dropoff_location'.tr,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: ColorManager.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Obx(() {
          final location = controller.selectedDropoffLocation.value;
          final hasSelection = location != null;
          final locationName = location?.name ?? 'select_dropoff_location'.tr;
          final address = location?.address ?? '';
          return InkWell(
            onTap: _selectDropoffLocation,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: ColorManager.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: hasSelection
                      ? ColorManager.secondaryColor.withValues(alpha: 0.5)
                      : ColorManager.divider,
                  width: hasSelection ? 1.5 : 1,
                ),
                boxShadow: hasSelection
                    ? [
                        BoxShadow(
                          color: ColorManager.secondaryColor.withValues(
                            alpha: 0.15,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color:
                          (hasSelection
                                  ? ColorManager.secondaryColor
                                  : ColorManager.primaryColor)
                              .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      hasSelection ? Icons.flag : Icons.location_on,
                      color: hasSelection
                          ? ColorManager.secondaryColor
                          : ColorManager.primaryColor,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locationName,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: hasSelection
                                ? ColorManager.textPrimary
                                : ColorManager.textSecondary,
                          ),
                        ),
                        if (hasSelection && address.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Text(
                            address,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: ColorManager.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (location != null && AppConfig.isDebugMode) ...[
                          SizedBox(height: 4.h),
                          Text(
                            '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontFamily: 'monospace',
                              color: ColorManager.secondaryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: ColorManager.textSecondary.withValues(alpha: 0.5),
                    size: 16.sp,
                  ),
                ],
              ),
            ),
          );
        }),
        if (controller.dropoffLocationError.value.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(
              controller.dropoffLocationError.value,
              style: TextStyle(color: ColorManager.error, fontSize: 12.sp),
            ),
          ),
      ],
    );
  }

  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pickup Time
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 20.sp,
              color: ColorManager.primaryColor,
            ),
            SizedBox(width: 8.w),
            Text(
              'select_pickup_time'.tr,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: ColorManager.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Obx(
          () => GestureDetector(
            onTap: () => controller.selectPickupTime(Get.context!),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: ColorManager.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: ColorManager.divider),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    controller.selectedPickupTime.value?.formattedString ??
                        'select_pickup_time'.tr,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: controller.selectedPickupTime.value != null
                          ? ColorManager.textPrimary
                          : ColorManager.textSecondary,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: ColorManager.textSecondary,
                    size: 20.sp,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (controller.pickupTimeError.value.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              controller.pickupTimeError.value,
              style: TextStyle(fontSize: 10.sp, color: ColorManager.error),
            ),
          ),

        // Return Pickup Time (for round trip)
        Obx(() {
          if (controller.selectedTripType.value == TripType.roundTrip) {
            return Column(
              children: [
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 20.sp,
                      color: ColorManager.primaryColor,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'select_return_pickup_time'.tr,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: ColorManager.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                GestureDetector(
                  onTap: () => controller.selectReturnPickupTime(Get.context!),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: ColorManager.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: ColorManager.divider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          controller
                                  .selectedReturnPickupTime
                                  .value
                                  ?.formattedString ??
                              'select_return_pickup_time'.tr,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color:
                                controller.selectedReturnPickupTime.value !=
                                    null
                                ? ColorManager.textPrimary
                                : ColorManager.textSecondary,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: ColorManager.textSecondary,
                          size: 20.sp,
                        ),
                      ],
                    ),
                  ),
                ),
                if (controller.returnPickupTimeError.value.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      controller.returnPickupTimeError.value,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: ColorManager.error,
                      ),
                    ),
                  ),
              ],
            );
          }
          return SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildPriceSummary() {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: ColorManager.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: ColorManager.divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: ColorManager.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: ColorManager.primaryColor,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: ColorManager.white,
                      size: 18.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'subscription_summary'.tr,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: ColorManager.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subscription Details Section
                  _buildSummarySection(
                    title: 'subscription_details'.tr,
                    children: [
                      _buildEnhancedSummaryRow(
                        icon: Icons.directions_car,
                        iconColor: ColorManager.primaryColor,
                        label: 'trip_type'.tr,
                        value: controller.getTripTypeText(
                          controller.selectedTripType.value,
                        ),
                        showBadge: true,
                      ),
                      SizedBox(height: 12.h),
                      _buildEnhancedSummaryRow(
                        icon: Icons.calendar_today,
                        iconColor: ColorManager.primaryColor,
                        label: 'subscription_duration'.tr,
                        value:
                            '${controller.durationController.text.isEmpty ? '0' : controller.durationController.text} ${'weeks'.tr}',
                      ),
                      SizedBox(height: 12.h),
                      _buildEnhancedSummaryRow(
                        icon: Icons.event,
                        iconColor: ColorManager.primaryColor,
                        label: 'total_selected_days'.tr,
                        value:
                            '${controller.selectedServiceDays.length} ${'days'.tr}',
                      ),
                      SizedBox(height: 12.h),
                      _buildEnhancedSummaryRow(
                        icon: Icons.child_care,
                        iconColor: ColorManager.primaryColor,
                        label: 'number_of_children'.tr,
                        value: '${controller.selectedChildrenIds.length}',
                      ),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  // Location Details Section
                  if (controller.selectedPickupLocation.value != null ||
                      controller.selectedDropoffLocation.value != null)
                    _buildSummarySection(
                      title: 'location_details'.tr,
                      children: [
                        if (controller.selectedPickupLocation.value !=
                            null) ...[
                          _buildEnhancedSummaryRow(
                            icon: Icons.location_on,
                            iconColor: ColorManager.success,
                            label: 'pickup_location'.tr,
                            value: controller.pickupLocationDisplay,
                            isLocation: true,
                          ),
                          SizedBox(height: 12.h),
                        ],
                        if (controller.selectedDropoffLocation.value !=
                            null) ...[
                          _buildEnhancedSummaryRow(
                            icon: Icons.flag,
                            iconColor: ColorManager.secondaryColor,
                            label: 'dropoff_location'.tr,
                            value: controller.dropoffLocationDisplay,
                            isLocation: true,
                          ),
                          SizedBox(height: 12.h),
                        ],
                        _buildEnhancedSummaryRow(
                          icon: Icons.straighten,
                          iconColor: ColorManager.primaryColor,
                          label: 'route_distance'.tr,
                          value: controller.isCalculatingRoute.value
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 14.w,
                                      height: 14.h,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              ColorManager.primaryColor,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'calculating'.tr,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: ColorManager.textSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  controller.routeDistanceDisplay,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: ColorManager.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),

                  SizedBox(height: 20.h),

                  // Pricing Section
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: ColorManager.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: ColorManager.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.attach_money,
                              size: 16.sp,
                              color: ColorManager.primaryColor,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'price_breakdown'.tr,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: ColorManager.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        if (controller.routeDistanceMeters.value != null) ...[
                          _buildPriceBreakdownRow(
                            'distance_cost'.tr,
                            '${((controller.routeDistanceMeters.value! / 1000.0) * SubscriptionController.pricePerKilometer).toStringAsFixed(2)} ${'sar'.tr}',
                            '${(controller.routeDistanceMeters.value! / 1000.0).toStringAsFixed(1)} km × ${SubscriptionController.pricePerKilometer.toInt()} ${'sar'.tr} ${'per_km'.tr}',
                          ),
                          SizedBox(height: 12.h),
                          Divider(color: ColorManager.divider, height: 1),
                          SizedBox(height: 12.h),
                        ],
                        _buildPriceRow(
                          'price_per_trip'.tr,
                          '${controller.pricePerTrip.value.toStringAsFixed(2)} ${'sar'.tr}',
                          isHighlighted: true,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Total Price Section
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ColorManager.primaryColor,
                          ColorManager.primaryColor.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: ColorManager.primaryColor.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'estimated_price'.tr,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: ColorManager.white.withValues(
                                  alpha: 0.9,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '${controller.estimatedTotalPrice.value.toStringAsFixed(2)} ${'sar'.tr}',
                              style: TextStyle(
                                fontSize: 24.sp,
                                color: ColorManager.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: ColorManager.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(
                            Icons.verified,
                            color: ColorManager.white,
                            size: 24.sp,
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
    );
  }

  Widget _buildSummarySection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: ColorManager.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 12.h),
        ...children,
      ],
    );
  }

  Widget _buildEnhancedSummaryRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required dynamic value,
    bool showBadge = false,
    bool isLocation = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 16.sp, color: iconColor),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: ColorManager.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (showBadge) ...[
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: ColorManager.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        controller.selectedTripType.value == TripType.roundTrip
                            ? '2x'
                            : '1x',
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: ColorManager.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 4.h),
              value is Widget
                  ? value
                  : Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: isLocation ? 12.sp : 13.sp,
                        color: ColorManager.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: isLocation ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceBreakdownRow(String label, String value, String subtext) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: ColorManager.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtext,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: ColorManager.textSecondary.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            color: ColorManager.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isHighlighted ? 14.sp : 13.sp,
            color: isHighlighted
                ? ColorManager.primaryColor
                : ColorManager.textSecondary,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlighted ? 16.sp : 15.sp,
            color: ColorManager.primaryColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return Obx(
      () => Center(
        child: Column(
          children: [
            // Show validation status when button is disabled
            if (!controller.canProceed) ...[
              Container(
                padding: EdgeInsets.all(12.w),
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: ColorManager.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: ColorManager.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'complete_following_to_continue'.tr,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: ColorManager.warning,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    if (controller.durationController.text.isEmpty)
                      _buildMissingField('duration_number_of_weeks'.tr),
                    if (controller.selectedServiceDays.isEmpty)
                      _buildMissingField('service_days_field'.tr),
                    if (controller.selectedPickupTime.value == null)
                      _buildMissingField('pickup_time_field'.tr),
                    if (controller.selectedPickupLocation.value == null)
                      _buildMissingField('pickup_location_field'.tr),
                    if (controller.selectedDropoffLocation.value == null)
                      _buildMissingField('dropoff_location_field'.tr),
                    if (controller.selectedChildrenIds.isEmpty)
                      _buildMissingField('children_selection'.tr),
                    if (controller.selectedTripType.value ==
                            TripType.roundTrip &&
                        controller.selectedReturnPickupTime.value == null)
                      _buildMissingField('return_pickup_time_field'.tr),
                  ],
                ),
              ),
            ],
            CustomButton(
              height: 30.0.h,
              width: 250.0.w,
              text: 'continue'.tr,
              onPressed: controller.canProceed
                  ? () => controller.submitSubscription()
                  : null,
              isLoading: controller.isSubmitting.value,
              textStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: ColorManager.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingField(String fieldName) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6.sp, color: ColorManager.warning),
          SizedBox(width: 6.w),
          Text(
            fieldName,
            style: TextStyle(fontSize: 11.sp, color: ColorManager.warning),
          ),
        ],
      ),
    );
  }

  Future<void> _selectPickupLocation() async {
    try {
      final result = await Get.to<PlaceDetails?>(
        () => const LocationSelectionPage(
          title: 'select_pickup_location',
          hintText: 'search_pickup_location',
        ),
        binding: BindingsBuilder(() {
          // Ensure LocationRepository is available
          if (!Get.isRegistered<LocationRepository>()) {
            Get.lazyPut<LocationRepository>(
              () => Get.find<LocationRepositoryImpl>(),
            );
          }
          // Ensure use cases are available
          if (!Get.isRegistered<SearchLocationSuggestionsUseCase>()) {
            Get.put(
              SearchLocationSuggestionsUseCase(Get.find<LocationRepository>()),
            );
          }
          if (!Get.isRegistered<GetPlaceDetailsUseCase>()) {
            Get.put(GetPlaceDetailsUseCase(Get.find<LocationRepository>()));
          }
          Get.put(LocationSelectionController());
        }),
      );

      if (result == null) {
        return;
      }

      final locationData = LocationData(
        name: result.name,
        address: result.address,
        latitude: result.location.latitude,
        longitude: result.location.longitude,
        placeId: result.placeId.isEmpty ? null : result.placeId,
      );

      if (AppConfig.isDebugMode) {
        debugPrint(
          '✅ Selected pickup location: ${locationData.name} (${locationData.latitude}, ${locationData.longitude})',
        );
      }

      controller.setPickupLocation(locationData);
    } catch (e) {
      debugPrint('Error in pickup location selection: $e');
    }
  }

  Future<void> _selectDropoffLocation() async {
    try {
      final result = await Get.to<PlaceDetails?>(
        () => const LocationSelectionPage(
          title: 'select_dropoff_location',
          hintText: 'search_dropoff_location',
        ),
        binding: BindingsBuilder(() {
          // Ensure LocationRepository is available
          if (!Get.isRegistered<LocationRepository>()) {
            Get.lazyPut<LocationRepository>(
              () => Get.find<LocationRepositoryImpl>(),
            );
          }
          // Ensure use cases are available
          if (!Get.isRegistered<SearchLocationSuggestionsUseCase>()) {
            Get.put(
              SearchLocationSuggestionsUseCase(Get.find<LocationRepository>()),
            );
          }
          if (!Get.isRegistered<GetPlaceDetailsUseCase>()) {
            Get.put(GetPlaceDetailsUseCase(Get.find<LocationRepository>()));
          }
          Get.put(LocationSelectionController());
        }),
      );

      if (result == null) {
        return;
      }

      final locationData = LocationData(
        name: result.name,
        address: result.address,
        latitude: result.location.latitude,
        longitude: result.location.longitude,
        placeId: result.placeId.isEmpty ? null : result.placeId,
      );

      if (AppConfig.isDebugMode) {
        debugPrint(
          '✅ Selected drop-off location: ${locationData.name} (${locationData.latitude}, ${locationData.longitude})',
        );
      }

      controller.setDropoffLocation(locationData);
    } catch (e) {
      debugPrint('Error in dropoff location selection: $e');
    }
  }
}
