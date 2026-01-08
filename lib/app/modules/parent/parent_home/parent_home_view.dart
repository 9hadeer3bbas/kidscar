import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:kidscar/core/managers/color_manager.dart';
import 'package:kidscar/app/custom_widgets/language_toggle_button.dart';
import 'package:kidscar/data/models/trip_model.dart';
import '../parent_activity/parent_activity_controller.dart';
import '../parent_main/parent_main_controller.dart';
import 'parent_home_controller.dart';

class ParentHomeView extends GetView<ParentHomeController> {
  const ParentHomeView({super.key});

  @override
  Widget build(BuildContext context) {
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
                  child: _HomeHeader(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 8.h,
                    ),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Message
                        _buildWelcomeMessage(),

                        SizedBox(height: 24.h),

                        // Current Trip Card
                        Obx(() {
                          final currentTrip = controller.currentTrip.value;
                          if (currentTrip != null) {
                            return Column(
                              children: [
                                _CurrentTripCard(
                                  trip: currentTrip,
                                  onTap: controller.viewCurrentTrip,
                                ),
                                SizedBox(height: 24.h),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        }),

                        // Main Action Cards
                        _buildActionCards(),

                        SizedBox(height: 32.h),

                        // Upcoming Trips Section
                        _buildUpcomingTripsSection(),

                        SizedBox(height: 32.h),

                        // Recent Trips Section
                        _buildRecentTripsSection(),

                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'welcome_back_subtitle'.tr,
          style: TextStyle(
            fontSize: 16.sp,
            color: ColorManager.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCards() {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.calendar_today_rounded,
            title: 'schedule_trips'.tr,
            subtitle: 'subscription'.tr,
            onTap: controller.onSubscriptionTap,
            color: ColorManager.primaryColor,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _ActionCard(
            icon: Icons.people_outline,
            title: 'manage_kids'.tr,
            subtitle: 'my_kids'.tr,
            onTap: controller.onMyKidsTap,
            color: ColorManager.secondaryColor,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _ActionCard(
            icon: Icons.directions_car_rounded,
            title: 'ride'.tr,
            subtitle: 'instant_ride'.tr,
            onTap: controller.onRideTap,
            color: ColorManager.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingTripsSection() {
    try {
      // Use putIfAbsent to ensure controller is initialized even if not on activity tab
      if (!Get.isRegistered<ParentActivityController>()) {
        Get.put(ParentActivityController());
      }
      final activityController = Get.find<ParentActivityController>();
      return Obx(() {
        // Get upcoming trips (next 3)
        final upcomingTrips = activityController.upcomingTrips.take(3).toList();

        if (upcomingTrips.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: ColorManager.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.upcoming_outlined,
                        color: ColorManager.primaryColor,
                        size: 20.w,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'upcoming_trips'.tr,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: ColorManager.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (activityController.upcomingTrips.length > 3)
                  TextButton(
                    onPressed: () {
                      Get.find<ParentMainController>().selectedIndex.value = 1;
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'view_all'.tr,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: ColorManager.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12.sp,
                          color: ColorManager.primaryColor,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.h),
            ...upcomingTrips.map(
              (trip) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _TripCard(trip: trip, controller: activityController),
              ),
            ),
          ],
        );
      });
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildRecentTripsSection() {
    try {
      // Use putIfAbsent to ensure controller is initialized even if not on activity tab
      if (!Get.isRegistered<ParentActivityController>()) {
        Get.put(ParentActivityController());
      }
      final activityController = Get.find<ParentActivityController>();
      return Obx(() {
        // Show loading if trips are still being loaded
        if (activityController.isLoading.value &&
            activityController.completedTrips.isEmpty) {
          return SizedBox(
            height: 100.h,
            child: Center(
              child: CircularProgressIndicator(
                color: ColorManager.primaryColor,
              ),
            ),
          );
        }

        // Get recent completed trips (last 5)
        final recentTrips = activityController.completedTrips.take(5).toList();

        if (recentTrips.isEmpty) {
          return _buildRecentEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: ColorManager.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        color: ColorManager.success,
                        size: 20.w,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'recent_trips'.tr,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: ColorManager.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (activityController.completedTrips.length > 5)
                  TextButton(
                    onPressed: () {
                      Get.find<ParentMainController>().selectedIndex.value = 1;
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'view_all'.tr,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: ColorManager.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12.sp,
                          color: ColorManager.primaryColor,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.h),
            ...recentTrips.map(
              (trip) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _DetailedTripCard(
                  trip: trip,
                  controller: activityController,
                ),
              ),
            ),
          ],
        );
      });
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildRecentEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorManager.primaryColor.withValues(alpha: 0.12),
            ),
            child: Icon(
              Icons.history_toggle_off_outlined,
              color: ColorManager.primaryColor,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'no_trips_yet'.tr,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: ColorManager.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'no_trips_desc'.tr,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: ColorManager.textSecondary,
                    height: 1.4,
                  ),
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

class _HomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'home'.tr,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'welcome_back'.tr,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const LanguageToggleButton(),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(12.w),
            height: 140.h, // Fixed height to ensure all cards are the same size
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.2),
                        color.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(icon, color: color, size: 24.sp),
                ),
                SizedBox(height: 12.h),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: ColorManager.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacer(),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: ColorManager.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.controller});

  final dynamic trip;
  final dynamic controller;

  @override
  Widget build(BuildContext context) {
    final statusColor = controller.getStatusColor(trip.status);
    final statusText = controller.getStatusText(trip.status);
    final formattedDate = controller.formatDate(trip.scheduledDate);
    final formattedTime = controller.formatTime(
      trip.pickupTime.hour,
      trip.pickupTime.minute,
    );

    return GestureDetector(
      onTap: () => controller.openTripDetail(trip),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withValues(alpha: 0.2),
                        statusColor.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: statusColor,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.dropoffLocation.name,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                          color: ColorManager.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14.sp,
                            color: ColorManager.textSecondary,
                          ),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              '$formattedDate • $formattedTime',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: ColorManager.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentTripCard extends StatelessWidget {
  const _CurrentTripCard({required this.trip, required this.onTap});

  final TripModel trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(trip.status);
    final statusText = _getStatusText(trip.status);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withValues(alpha: 0.15),
                  statusColor.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(
                        Icons.directions_car_rounded,
                        color: statusColor,
                        size: 28.sp,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'current_trip'.tr,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            trip.dropoffLocation.name,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: ColorManager.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8.w,
                            height: 8.h,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16.sp,
                      color: ColorManager.textSecondary,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        trip.pickupLocation.name,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: ColorManager.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14.sp,
                      color: ColorManager.textSecondary,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        trip.dropoffLocation.name,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: ColorManager.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 14.sp,
                      color: statusColor,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'tap_to_view_details'.tr,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.accepted:
      case TripStatus.enRoutePickup:
      case TripStatus.enRouteDropoff:
        return const Color(0xFF2196F3);
      case TripStatus.awaitingDriverResponse:
        return const Color(0xFFFF9800);
      default:
        return ColorManager.primaryColor;
    }
  }

  String _getStatusText(TripStatus status) {
    switch (status) {
      case TripStatus.awaitingDriverResponse:
        return 'awaiting_driver'.tr;
      case TripStatus.accepted:
        return 'accepted'.tr;
      case TripStatus.enRoutePickup:
        return 'en_route_pickup'.tr;
      case TripStatus.enRouteDropoff:
        return 'en_route_dropoff'.tr;
      default:
        return 'active'.tr;
    }
  }
}

class _DetailedTripCard extends StatelessWidget {
  const _DetailedTripCard({required this.trip, required this.controller});

  final dynamic trip;
  final dynamic controller;

  @override
  Widget build(BuildContext context) {
    final statusColor = controller.getStatusColor(trip.status);
    final statusText = controller.getStatusText(trip.status);
    final formattedDate = controller.formatDate(trip.scheduledDate);
    final formattedTime = controller.formatTime(
      trip.pickupTime.hour,
      trip.pickupTime.minute,
    );

    // Format distance and duration
    String distanceText = '';
    if (trip.distanceMeters != null && trip.distanceMeters! > 0) {
      if (trip.distanceMeters! >= 1000) {
        distanceText =
            '${(trip.distanceMeters! / 1000).toStringAsFixed(1)} ${'km_short'.tr}';
      } else {
        distanceText = '${trip.distanceMeters} ${'meter_short'.tr}';
      }
    }

    String durationText = '';
    if (trip.durationSeconds != null && trip.durationSeconds! > 0) {
      final minutes = (trip.durationSeconds! / 60).round();
      if (minutes >= 60) {
        final hours = minutes ~/ 60;
        final mins = minutes % 60;
        durationText = '${hours}${'hour_short'.tr} ${mins}${'minute_short'.tr}';
      } else {
        durationText = '${minutes}${'minute_short'.tr}';
      }
    }

    return GestureDetector(
      onTap: () => controller.openTripDetail(trip),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statusColor.withValues(alpha: 0.2),
                            statusColor.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: statusColor,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.dropoffLocation.name,
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w700,
                              color: ColorManager.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 13.sp,
                                color: ColorManager.textSecondary,
                              ),
                              SizedBox(width: 4.w),
                              Flexible(
                                child: Text(
                                  '$formattedDate • $formattedTime',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: ColorManager.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Route Information
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: ColorManager.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ColorManager.primaryColor,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'pickup_location'.tr,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: ColorManager.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  trip.pickupLocation.name,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: ColorManager.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ColorManager.accent,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'dropoff_location'.tr,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: ColorManager.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  trip.dropoffLocation.name,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: ColorManager.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),

                // Trip Details Row
                Wrap(
                  spacing: 12.w,
                  runSpacing: 8.h,
                  children: [
                    if (trip.kidIds.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.child_care_outlined,
                            size: 16.sp,
                            color: ColorManager.textSecondary,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '${trip.kidIds.length} ${'kids'.tr}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: ColorManager.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    if (distanceText.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.straighten_outlined,
                            size: 16.sp,
                            color: ColorManager.textSecondary,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            distanceText,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: ColorManager.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    if (durationText.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 16.sp,
                            color: ColorManager.textSecondary,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            durationText,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: ColorManager.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
