import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../custom_widgets/wave_header.dart';
import '../../../custom_widgets/custom_button.dart';
import '../../location_selection/location_selection_page.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/managers/color_manager.dart';
import '../../../../data/models/kid_model.dart';
import '../../../../data/models/subscription_model.dart';
import 'instant_ride_controller.dart';
import '../../../../domain/entities/place_details.dart';
import '../../../../domain/repositories/location_repository.dart';
import '../../../../data/repos/location_repo.dart';
import '../../../../domain/usecases/location/search_location_suggestions_usecase.dart';
import '../../../../domain/usecases/location/get_place_details_usecase.dart';

class InstantRideView extends GetView<InstantRideController> {
  const InstantRideView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.scaffoldBackground,
      body: Column(
        children: [
          WaveHeader(title: 'instant_ride'.tr, onBackTap: () => Get.back()),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoBanner(),
                  SizedBox(height: 20.h),
                  _buildChildrenSection(),
                  SizedBox(height: 20.h),
                  _buildLocationSection(),
                  SizedBox(height: 20.h),
                  _buildTimeSection(),
                  SizedBox(height: 20.h),
                  _buildPriceSummary(),
                  SizedBox(height: 30.h),
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

  Widget _buildInfoBanner() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorManager.primaryColor.withValues(alpha: 0.1),
            ColorManager.secondaryColor.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: ColorManager.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: ColorManager.primaryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.flash_on,
              color: ColorManager.primaryColor,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'instant_ride_title'.tr,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: ColorManager.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'instant_ride_description'.tr,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: ColorManager.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            const Spacer(),
            Obx(
              () => Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: ColorManager.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '${controller.selectedChildrenIds.length} ${'selected'.tr}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: ColorManager.primaryColor,
                  ),
                ),
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
          child: Obx(() {
            if (controller.isLoadingChildren.value) {
              return SizedBox(
                height: 100.h,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (controller.availableChildren.isEmpty) {
              return SizedBox(
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
              runSpacing: 12.h,
              children: controller.availableChildren.map((KidModel child) {
                final isSelected = controller.selectedChildrenIds.contains(
                  child.id,
                );
                return _buildChildChip(child, isSelected);
              }).toList(),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildChildChip(KidModel child, bool isSelected) {
    return GestureDetector(
      onTap: () => controller.toggleChildSelection(child.id),
      child: Container(
        width: 70.w,
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28.r,
                  backgroundColor: ColorManager.divider,
                  backgroundImage: child.profileImageUrl != null
                      ? NetworkImage(child.profileImageUrl!)
                      : null,
                  child: child.profileImageUrl == null
                      ? Icon(
                          Icons.person,
                          size: 28.sp,
                          color: ColorManager.textSecondary,
                        )
                      : null,
                ),
                if (isSelected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 22.w,
                      height: 22.h,
                      decoration: BoxDecoration(
                        color: ColorManager.success,
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
            SizedBox(height: 6.h),
            Text(
              child.name,
              style: TextStyle(
                fontSize: 11.sp,
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
        InkWell(
          onTap: () => _selectPickupLocation(),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: ColorManager.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: controller.selectedPickupLocation.value != null
                    ? ColorManager.success.withValues(alpha: 0.5)
                    : ColorManager.divider,
                width: controller.selectedPickupLocation.value != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color:
                        (controller.selectedPickupLocation.value != null
                                ? ColorManager.success
                                : ColorManager.primaryColor)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    controller.selectedPickupLocation.value != null
                        ? Icons.check_circle
                        : Icons.location_on,
                    color: controller.selectedPickupLocation.value != null
                        ? ColorManager.success
                        : ColorManager.primaryColor,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Obx(() {
                    final location = controller.selectedPickupLocation.value;
                    final hasSelection = location != null;
                    final address = location?.address ?? '';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location?.name ?? 'select_pickup_location'.tr,
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
                    );
                  }),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: ColorManager.textSecondary,
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
        Obx(
          () => controller.pickupLocationError.value.isNotEmpty
              ? Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(
                    controller.pickupLocationError.value,
                    style: TextStyle(
                      color: ColorManager.error,
                      fontSize: 12.sp,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        SizedBox(height: 16.h),
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
        InkWell(
          onTap: () => _selectDropoffLocation(),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: ColorManager.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: controller.selectedDropoffLocation.value != null
                    ? ColorManager.secondaryColor.withValues(alpha: 0.5)
                    : ColorManager.divider,
                width: controller.selectedDropoffLocation.value != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color:
                        (controller.selectedDropoffLocation.value != null
                                ? ColorManager.secondaryColor
                                : ColorManager.primaryColor)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    controller.selectedDropoffLocation.value != null
                        ? Icons.flag
                        : Icons.location_on,
                    color: controller.selectedDropoffLocation.value != null
                        ? ColorManager.secondaryColor
                        : ColorManager.primaryColor,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Obx(() {
                    final location = controller.selectedDropoffLocation.value;
                    final hasSelection = location != null;
                    final address = location?.address ?? '';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location?.name ?? 'select_dropoff_location'.tr,
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
                    );
                  }),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: ColorManager.textSecondary,
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
        Obx(
          () => controller.dropoffLocationError.value.isNotEmpty
              ? Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(
                    controller.dropoffLocationError.value,
                    style: TextStyle(
                      color: ColorManager.error,
                      fontSize: 12.sp,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 20.sp,
              color: ColorManager.primaryColor,
            ),
            SizedBox(width: 8.w),
            Text(
              'pickup_time'.tr,
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
        Obx(
          () => controller.pickupTimeError.value.isNotEmpty
              ? Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    controller.pickupTimeError.value,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: ColorManager.error,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildPriceSummary() {
    return Obx(
      () => Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: ColorManager.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: ColorManager.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'estimated_price'.tr,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: ColorManager.textPrimary,
                  ),
                ),
                Text(
                  '${controller.estimatedPrice.value.toStringAsFixed(2)} ${'sar'.tr}',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: ColorManager.primaryColor,
                  ),
                ),
              ],
            ),
            if (controller.routeDistanceMeters.value != null ||
                controller.isCalculatingRoute.value) ...[
              SizedBox(height: 12.h),
              Divider(color: ColorManager.divider, height: 1),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.straighten,
                        size: 16.sp,
                        color: ColorManager.textSecondary,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'route_distance'.tr,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: ColorManager.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  controller.isCalculatingRoute.value
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12.w,
                              height: 12.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ColorManager.primaryColor,
                                ),
                              ),
                            ),
                            SizedBox(width: 6.w),
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
                            fontWeight: FontWeight.w600,
                            color: ColorManager.primaryColor,
                          ),
                        ),
                ],
              ),
              if (controller.routeDistanceMeters.value != null) ...[
                SizedBox(height: 8.h),
                Text(
                  '${(controller.routeDistanceMeters.value! / 1000.0).toStringAsFixed(1)} km × ${InstantRideController.pricePerKilometer.toInt()} ${'sar'.tr} ${'per_km'.tr}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: ColorManager.textSecondary.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Obx(
      () => CustomButton(
        height: 30.0.h,
        width: double.infinity,
        text: 'choose_driver'.tr,
        onPressed: controller.canProceed
            ? () => controller.proceedToDriverSelection()
            : null,
        isLoading: controller.isSubmitting.value,
        textStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: ColorManager.white,
        ),
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
      debugPrint('Error in location selection: $e');
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
