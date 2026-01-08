import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/managers/color_manager.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../core/routes/get_routes.dart';
import 'driver_trips_controller.dart';

class DriverTripsView extends StatelessWidget {
  const DriverTripsView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DriverTripsController>(
      init: DriverTripsController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: ColorManager.scaffoldBackground,
          body: Stack(
            children: [
              const _HeroGradient(),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
                      child: const _TripsHeader(),
                    ),
                    Expanded(
                      child: Obx(() {
                        if (controller.isLoading.value) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (controller.errorMessage.isNotEmpty) {
                          return _buildErrorState(controller);
                        }

                        return Column(
                          children: [
                            SizedBox(height: 8.h),
                            //_buildStatsRow(controller),
                            SizedBox(height: 16.h),
                            _buildTabBar(controller),
                            SizedBox(height: 16.h),
                            Expanded(child: _buildTripList(controller)),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(DriverTripsController controller) {
    final stats = [
      _TripStatData(
        label: 'pending'.tr,
        value: controller.pendingTrips.length,
        icon: Icons.hourglass_bottom_rounded,
        color: ColorManager.warning,
      ),
      _TripStatData(
        label: 'upcoming'.tr,
        value: controller.upcomingTrips.length,
        icon: Icons.directions_car_filled_rounded,
        color: ColorManager.primaryColor,
      ),
      _TripStatData(
        label: 'past'.tr,
        value: controller.pastTrips.length,
        icon: Icons.check_circle_rounded,
        color: ColorManager.success,
      ),
    ];

    return SizedBox(
      height: 150.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final data = stats[index];
          return _TripStatCard(data: data);
        },
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemCount: stats.length,
      ),
    );
  }

  Widget _buildErrorState(DriverTripsController controller) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber, size: 48.sp, color: ColorManager.warning),
            SizedBox(height: 12.h),
            Text(
              controller.errorMessage.value,
              style: TextStyle(
                fontSize: 16.sp,
                color: ColorManager.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: controller.fetchTrips,
              child: Text('retry'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(DriverTripsController controller) {
    return Obx(() {
      final tabs = [
        _TripTabData(
          tab: DriverTripsTab.pending,
          label: 'pending'.tr,
          icon: Icons.hourglass_bottom_rounded,
          count: controller.pendingTrips.length,
          color: ColorManager.warning,
        ),
        _TripTabData(
          tab: DriverTripsTab.upcoming,
          label: 'upcoming'.tr,
          icon: Icons.directions_car_filled_rounded,
          count: controller.upcomingTrips.length,
          color: ColorManager.primaryColor,
        ),
        _TripTabData(
          tab: DriverTripsTab.past,
          label: 'past'.tr,
          icon: Icons.check_circle_rounded,
          count: controller.pastTrips.length,
          color: ColorManager.success,
        ),
      ];

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: tabs.map((data) {
                  final isSelected = controller.selectedTab.value == data.tab;
                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16.r),
                      onTap: () => controller.changeTab(data.tab),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        padding: EdgeInsets.symmetric(
                          vertical: 12.h,
                          horizontal: 8.w,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    data.color,
                                    data.color.withValues(alpha: 0.8),
                                  ],
                                )
                              : null,
                          color: isSelected ? null : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : ColorManager.divider.withValues(alpha: 0.4),
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: data.color.withValues(alpha: 0.25),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : data.color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                data.icon,
                                size: 18.sp,
                                color: isSelected ? Colors.white : data.color,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              data.label,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : ColorManager.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '${data.count} ${'trips'.tr}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : ColorManager.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTripList(DriverTripsController controller) {
    final trips = _tripsForTab(controller);

    if (trips.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: ColorManager.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_car_outlined,
                  size: 48.sp,
                  color: ColorManager.primaryColor,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'no_trips_available'.tr,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: ColorManager.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'check_back_later'.tr,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: ColorManager.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              OutlinedButton.icon(
                onPressed: controller.fetchTrips,
                icon: Icon(
                  Icons.refresh_rounded,
                  color: ColorManager.primaryColor,
                ),
                label: Text(
                  'refresh'.tr,
                  style: TextStyle(
                    color: ColorManager.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: ColorManager.primaryColor.withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 24.h),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      itemCount: trips.length,
      separatorBuilder: (context, _) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final trip = trips[index];
        return _TripCard(trip: trip, controller: controller);
      },
    );
  }

  List<TripModel> _tripsForTab(DriverTripsController controller) {
    switch (controller.selectedTab.value) {
      case DriverTripsTab.pending:
        return controller.pendingTrips;
      case DriverTripsTab.upcoming:
        return controller.upcomingTrips;
      case DriverTripsTab.past:
        return controller.pastTrips;
    }
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.controller});

  final TripModel trip;
  final DriverTripsController controller;

  @override
  Widget build(BuildContext context) {
    final isPending = trip.status == TripStatus.awaitingDriverResponse;
    final isProcessing = controller.processingTripIds.contains(trip.id);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.r),
          gradient: LinearGradient(
            colors: [
              _tripStatusColor(trip.status).withValues(alpha: 0.15),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          margin: EdgeInsets.all(1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            color: Colors.white,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20.r),
            child: InkWell(
              onTap: () {
                Get.toNamed(AppRoutes.driverTripDetail, arguments: trip);
              },
              borderRadius: BorderRadius.circular(20.r),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatusChip(status: trip.status),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: ColorManager.primaryColor.withValues(
                              alpha: 0.08,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: ColorManager.primaryColor,
                            size: 16.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    _TripLocationRow(
                      icon: Icons.location_on_rounded,
                      label: 'pickup'.tr,
                      value: trip.pickupLocation.name,
                      color: ColorManager.primaryColor,
                    ),
                    SizedBox(height: 14.h),
                    _TripLocationRow(
                      icon: Icons.flag_rounded,
                      label: 'dropoff'.tr,
                      value: trip.dropoffLocation.name,
                      color: ColorManager.secondaryColor,
                    ),
                    SizedBox(height: 18.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 12.h,
                        horizontal: 16.w,
                      ),
                      decoration: BoxDecoration(
                        color: ColorManager.scaffoldBackground,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 16.sp,
                                  color: ColorManager.primaryColor,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  trip.pickupTime.formattedString,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: ColorManager.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 20.h,
                            color: ColorManager.divider,
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.child_care_rounded,
                                  size: 16.sp,
                                  color: ColorManager.secondaryColor,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  '${trip.kidIds.length} ${'kids'.tr}',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: ColorManager.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isPending) ...[
                      SizedBox(height: 18.h),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isProcessing
                                  ? null
                                  : () {
                                      Get.dialog(
                                        AlertDialog(
                                          title: Text('decline_trip'.tr),
                                          content: Text(
                                            'confirm_decline_trip'.tr,
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Get.back(),
                                              child: Text('cancel'.tr),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Get.back();
                                                controller.declineTrip(trip);
                                              },
                                              child: Text(
                                                'decline'.tr,
                                                style: TextStyle(
                                                  color: ColorManager.error,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: ColorManager.error,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                              ),
                              child: isProcessing
                                  ? SizedBox(
                                      height: 20.h,
                                      width: 20.w,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              ColorManager.error,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      'decline'.tr,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: ColorManager.error,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: isProcessing
                                  ? null
                                  : () {
                                      Get.dialog(
                                        AlertDialog(
                                          title: Text('accept_trip'.tr),
                                          content: Text(
                                            'confirm_accept_trip'.tr,
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Get.back(),
                                              child: Text('cancel'.tr),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Get.back();
                                                controller.acceptTrip(trip);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    ColorManager.primaryColor,
                                              ),
                                              child: Text('accept'.tr),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorManager.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                elevation: 2,
                              ),
                              child: isProcessing
                                  ? SizedBox(
                                      height: 20.h,
                                      width: 20.w,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          size: 18.sp,
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          'accept'.tr,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (!isPending &&
                        (trip.status == TripStatus.completed ||
                            trip.status == TripStatus.rejected ||
                            trip.status == TripStatus.cancelled)) ...[
                      SizedBox(height: 12.h),
                      OutlinedButton.icon(
                        onPressed: isProcessing
                            ? null
                            : () {
                                Get.dialog(
                                  AlertDialog(
                                    title: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          color: ColorManager.error,
                                          size: 24.sp,
                                        ),
                                        SizedBox(width: 8.w),
                                        Expanded(child: Text('delete_trip'.tr)),
                                      ],
                                    ),
                                    content: Text('confirm_delete_trip'.tr),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Get.back(),
                                        child: Text('cancel'.tr),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Get.back();
                                          controller.deleteTrip(trip);
                                        },
                                        child: Text(
                                          'delete'.tr,
                                          style: TextStyle(
                                            color: ColorManager.error,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: ColorManager.error.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: 12.h,
                            horizontal: 8.w,
                          ),
                        ),
                        icon: isProcessing
                            ? SizedBox(
                                height: 18.h,
                                width: 18.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    ColorManager.error,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.delete_outline,
                                size: 18.sp,
                                color: ColorManager.error,
                              ),
                        label: Text(
                          'delete_trip'.tr,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: ColorManager.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TripsHeader extends StatelessWidget {
  const _TripsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'your_trips'.tr,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'trips'.tr,
              style: TextStyle(
                fontSize: 26.sp,
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

class _TripLocationRow extends StatelessWidget {
  const _TripLocationRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 18.sp, color: color),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: ColorManager.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: ColorManager.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _tripStatusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.85)],
        ),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.brightness_1, size: 10.sp, color: Colors.white),
          SizedBox(width: 8.w),
          Text(
            _tripStatusLabel(status),
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripStatData {
  const _TripStatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
}

class _TripStatCard extends StatelessWidget {
  const _TripStatCard({required this.data});

  final _TripStatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170.w,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          colors: [
            data.color.withValues(alpha: 0.9),
            data.color.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: data.color.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: Colors.white, size: 20.sp),
          ),
          SizedBox(height: 16.h),
          Text(
            '${data.value}',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            data.label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripTabData {
  const _TripTabData({
    required this.tab,
    required this.label,
    required this.icon,
    required this.count,
    required this.color,
  });

  final DriverTripsTab tab;
  final String label;
  final IconData icon;
  final int count;
  final Color color;
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

Color _tripStatusColor(TripStatus status) {
  switch (status) {
    case TripStatus.awaitingDriverResponse:
      return ColorManager.warning;
    case TripStatus.accepted:
    case TripStatus.enRoutePickup:
    case TripStatus.enRouteDropoff:
      return ColorManager.primaryColor;
    case TripStatus.rejected:
    case TripStatus.cancelled:
      return ColorManager.error;
    case TripStatus.completed:
      return ColorManager.success;
  }
}

String _tripStatusLabel(TripStatus status) {
  switch (status) {
    case TripStatus.awaitingDriverResponse:
      return 'awaiting_driver'.tr;
    case TripStatus.accepted:
      return 'driver_accepted'.tr;
    case TripStatus.rejected:
      return 'driver_rejected'.tr;
    case TripStatus.enRoutePickup:
      return 'en_route_pickup'.tr;
    case TripStatus.enRouteDropoff:
      return 'en_route_dropoff'.tr;
    case TripStatus.completed:
      return 'completed'.tr;
    case TripStatus.cancelled:
      return 'cancelled'.tr;
  }
}
