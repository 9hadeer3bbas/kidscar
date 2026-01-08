import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:kidscar/core/managers/color_manager.dart';
import 'package:kidscar/core/managers/assets_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/trip_model.dart';
import 'parent_activity_controller.dart';

class ParentActivityView extends GetView<ParentActivityController> {
  const ParentActivityView({super.key});

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
                  padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 12.h),
                  child: _ActivityHeader(),
                ),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: ColorManager.primaryColor,
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => controller.refreshTrips(),
                      color: ColorManager.primaryColor,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 8.h,
                        ),
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatsSection(),
                            SizedBox(height: 20.h),
                            _buildTripsSection(),
                            SizedBox(height: 20.h),
                          ],
                        ),
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

  Widget _buildStatsSection() {
    return Obx(() {
          final totalTrips = controller.totalTripsCount.value;
          final thisMonthTrips = controller.thisMonthTripsCount.value;
          final upcomingTripsCount = controller.upcomingTrips.length;
          
          return Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'total_trips'.tr,
                  value: totalTrips.toString(),
                  icon: AssetsManager.carIcon,
                  color: ColorManager.primaryColor,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _StatCard(
                  title: 'this_month'.tr,
                  value: thisMonthTrips.toString(),
                  icon: AssetsManager.tripsIcon,
                  color: ColorManager.secondaryColor,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _StatCard(
                  title: 'upcoming'.tr,
                  value: upcomingTripsCount.toString(),
                  icon: AssetsManager.mapIcon,
                  color: ColorManager.accent,
                ),
              ),
            ],
          );
        });
  }

  Widget _buildTripsSection() {
    return Obx(() {
      if (controller.trips.isEmpty) {
        return _buildEmptyState();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'recent_trips'.tr,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: ColorManager.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.trips.length > 10 ? 10 : controller.trips.length,
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final trip = controller.trips[index];
              return _TripCard(trip: trip, controller: controller);
            },
          ),
        ],
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 60.h),
        child: Column(
          children: [
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColorManager.primaryColor.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.directions_car_outlined,
                size: 50.sp,
                color: ColorManager.primaryColor.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'no_trips_yet'.tr,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: ColorManager.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'no_trips_desc'.tr,
              style: TextStyle(
                fontSize: 14.sp,
                color: ColorManager.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

class _ActivityHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'activity_overview'.tr,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'activity'.tr,
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            color: Colors.white.withValues(alpha: 0.9),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  icon,
                  width: 20.w,
                  height: 20.h,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: ColorManager.textPrimary,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: ColorManager.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
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

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.controller,
  });

  final TripModel trip;
  final ParentActivityController controller;

  @override
  Widget build(BuildContext context) {
    final locale = Get.locale?.languageCode ?? 'en';
    final dayLabel = DateFormat('EEE', locale).format(trip.scheduledDate);
    final dayNumber = DateFormat('d', locale).format(trip.scheduledDate);
    final monthLabel = DateFormat('MMM', locale).format(trip.scheduledDate);
    final statusColor = controller.getStatusColor(trip.status);
    final statusText = controller.getStatusText(trip.status);
    final formattedTime = controller.formatTime(
      trip.pickupTime.hour,
      trip.pickupTime.minute,
    );

    return GestureDetector(
      onTap: () => controller.openTripDetail(trip),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DateBadge(
            day: dayLabel,
            dayNumber: dayNumber,
            month: monthLabel,
            color: statusColor,
          ),
          SizedBox(width: 12.w),
          Expanded(
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
                      color: statusColor.withValues(alpha: 0.18),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 18,
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
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: statusColor.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.access_time,
                            size: 16.sp,
                            color: ColorManager.textSecondary,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: ColorManager.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      _TimelineRoute(
                        pickupLabel: 'pickup_location'.tr,
                        pickupValue: trip.pickupLocation.name,
                        dropoffLabel: 'dropoff_location'.tr,
                        dropoffValue: trip.dropoffLocation.name,
                        accentColor: statusColor,
                      ),
                      SizedBox(height: 14.h),
                      Wrap(
                        spacing: 10.w,
                        runSpacing: 8.h,
                        children: [
                          _InfoPill(
                            icon: Icons.navigation_outlined,
                            label:
                                '${trip.pickupLocation.name} → ${trip.dropoffLocation.name}',
                          ),
                          if (trip.kidIds.isNotEmpty)
                            _InfoPill(
                              icon: Icons.child_care_outlined,
                              label: '${trip.kidIds.length} ${'kids'.tr}',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({
    required this.day,
    required this.dayNumber,
    required this.month,
    required this.color,
  });

  final String day;
  final String dayNumber;
  final String month;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64.w,
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.08),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            day.toUpperCase(),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.85),
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            dayNumber,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: ColorManager.textPrimary,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            month,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: ColorManager.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRoute extends StatelessWidget {
  const _TimelineRoute({
    required this.pickupLabel,
    required this.pickupValue,
    required this.dropoffLabel,
    required this.dropoffValue,
    required this.accentColor,
  });

  final String pickupLabel;
  final String pickupValue;
  final String dropoffLabel;
  final String dropoffValue;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TimelineLocationRow(
          label: pickupLabel,
          value: pickupValue,
          iconColor: ColorManager.primaryColor,
          isFirst: true,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: _TimelineConnector(color: accentColor),
        ),
        _TimelineLocationRow(
          label: dropoffLabel,
          value: dropoffValue,
          iconColor: ColorManager.secondaryColor,
          isFirst: false,
        ),
      ],
    );
  }
}

class _TimelineLocationRow extends StatelessWidget {
  const _TimelineLocationRow({
    required this.label,
    required this.value,
    required this.iconColor,
    required this.isFirst,
  });

  final String label;
  final String value;
  final Color iconColor;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isFirst ? Icons.radio_button_checked : Icons.flag_outlined,
            size: 16.sp,
            color: iconColor,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: ColorManager.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: ColorManager.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      height: 24.h,
      width: 2.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2.r),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.05),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: ColorManager.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: ColorManager.primaryColor),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: ColorManager.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}