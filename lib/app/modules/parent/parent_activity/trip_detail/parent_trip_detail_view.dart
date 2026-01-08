import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kidscar/app/custom_widgets/wave_header.dart';
import 'package:kidscar/core/managers/color_manager.dart';
import 'package:kidscar/data/models/trip_model.dart';
import 'package:kidscar/core/services/rtc_streaming_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import 'parent_trip_detail_controller.dart';

class ParentTripDetailView extends GetView<ParentTripDetailController> {
  const ParentTripDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.scaffoldBackground,
      body: Stack(
        children: [
          const _HeroGradient(),
          Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.errorMessage.isNotEmpty) {
              return _ErrorState(
                message: controller.errorMessage.value,
                onRetry: controller.refreshTrip,
              );
            }

            return Column(
              children: [
                WaveHeader(
                  title: 'trip_detail'.tr,
                  showBackButton: true,
                  onBackTap: () => Get.back(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20.h),
                        _TripSummaryCard(controller: controller),
                        SizedBox(height: 18.h),
                        _RouteCard(controller: controller),
                        SizedBox(height: 18.h),
                        _MapSection(controller: controller),
                        SizedBox(height: 18.h),
                        Obx(() {
                          if (controller.currentTrip.value.status ==
                              TripStatus.completed) {
                            return Column(
                              children: [
                                _RouteLegend(controller: controller),
                                SizedBox(height: 18.h),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                        SizedBox(height: 18.h),
                        Obx(() {
                          if (controller.isActiveTrip) {
                            return Column(
                              children: [
                                _RealTimeTrackingCard(controller: controller),
                                SizedBox(height: 18.h),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                        Obx(() {
                          if (controller.safetyEvents.isNotEmpty) {
                            return Column(
                              children: [
                                _SafetyEventsCard(controller: controller),
                                SizedBox(height: 18.h),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                        _AdditionalInfo(controller: controller),
                        SizedBox(height: 18.h),
                        _DriverInfoCard(controller: controller),
                        SizedBox(height: 48.h),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
      // Emergency Button - Floating Action Button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Obx(
        () => controller.isActiveTrip
            ? Padding(
                padding: EdgeInsets.all(8.0.w),
                child: FloatingActionButton.extended(
                  onPressed: controller.callEmergency,
                  backgroundColor: Colors.red,
                  icon: const Icon(Icons.emergency, color: Colors.white),
                  label: Text(
                    'emergency_911'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber, size: 48.sp, color: ColorManager.warning),
            SizedBox(height: 12.h),
            Text(
              message,
              style: TextStyle(
                fontSize: 16.sp,
                color: ColorManager.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(onPressed: onRetry, child: Text('retry'.tr)),
          ],
        ),
      ),
    );
  }
}

class _TripSummaryCard extends StatelessWidget {
  const _TripSummaryCard({required this.controller});

  final ParentTripDetailController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(22.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
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
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: controller.statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: controller.statusColor,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          controller.statusText,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: controller.statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.calendar_today,
                    size: 16.sp,
                    color: ColorManager.textSecondary,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    controller.formattedDate(),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: ColorManager.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                controller.currentTrip.value.dropoffLocation.name,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: ColorManager.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16.sp,
                    color: ColorManager.textSecondary,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    controller.formattedTime(),
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: ColorManager.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: [
                  _InfoChip(
                    icon: Icons.child_care_outlined,
                    label: 'kids'.tr,
                    value: '${controller.currentTrip.value.kidIds.length}',
                  ),
                  if (controller.distanceText.isNotEmpty)
                    _InfoChip(
                      icon: Icons.straighten,
                      label: 'distance'.tr,
                      value: controller.distanceText,
                    ),
                  if (controller.durationText.isNotEmpty)
                    _InfoChip(
                      icon: Icons.timer_outlined,
                      label: 'duration'.tr,
                      value: controller.durationText,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.controller});

  final ParentTripDetailController controller;

  @override
  Widget build(BuildContext context) {
    final trip = controller.currentTrip.value;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LocationRow(
                icon: Icons.radio_button_checked,
                iconColor: ColorManager.primaryColor,
                title: 'pickup_location'.tr,
                value: trip.pickupLocation.name,
                subtitle: trip.pickupLocation.address,
              ),
              SizedBox(height: 14.h),
              _LocationRow(
                icon: Icons.flag,
                iconColor: ColorManager.secondaryColor,
                title: 'dropoff_location'.tr,
                value: trip.dropoffLocation.name,
                subtitle: trip.dropoffLocation.address,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapSection extends StatelessWidget {
  const _MapSection({required this.controller});

  final ParentTripDetailController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        height: 320.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Obx(() {
              // Access reactive sets directly to ensure GetX tracks them
              final markers = controller.markerSet.toSet();
              final polylines = controller.polylineSet.toSet();
              return GoogleMap(
                initialCameraPosition: controller.initialCameraPosition,
                onMapCreated: controller.onMapCreated,
                markers: markers,
                polylines: polylines,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              );
            }),
            Positioned(
              top: 12.h,
              right: 12.w,
              child: FloatingActionButton.small(
                heroTag: 'refresh-route-button',
                onPressed: controller.refreshTrip,
                backgroundColor: Colors.white,
                child: controller.isRouteLoading.value
                    ? SizedBox(
                        height: 16.w,
                        width: 16.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            ColorManager.primaryColor,
                          ),
                        ),
                      )
                    : Icon(Icons.refresh, color: ColorManager.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdditionalInfo extends StatelessWidget {
  const _AdditionalInfo({required this.controller});

  final ParentTripDetailController controller;

  @override
  Widget build(BuildContext context) {
    final trip = controller.currentTrip.value;
    final notesWidgets = <Widget>[];

    if ((trip.parentNotes ?? '').isNotEmpty) {
      notesWidgets.add(
        _NotesCard(
          icon: Icons.notes_outlined,
          title: 'parent_notes'.tr,
          value: trip.parentNotes!,
          color: ColorManager.primaryColor,
        ),
      );
    }

    if ((trip.driverNotes ?? '').isNotEmpty) {
      notesWidgets.add(
        _NotesCard(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'driver_notes'.tr,
          value: trip.driverNotes!,
          color: ColorManager.secondaryColor,
        ),
      );
    }

    if (notesWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'details'.tr,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: ColorManager.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        ...notesWidgets,
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: iconColor, size: 20.sp),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: ColorManager.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: ColorManager.textPrimary,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: ColorManager.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: ColorManager.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: ColorManager.primaryColor),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: ColorManager.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: ColorManager.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(icon, color: color, size: 20.sp),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: ColorManager.textPrimary,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        value,
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
          ),
        ),
      ),
    );
  }
}

class _RealTimeTrackingCard extends StatelessWidget {
  const _RealTimeTrackingCard({required this.controller});

  final ParentTripDetailController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: ColorManager.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: ColorManager.primaryColor,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'real_time_tracking'.tr,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: ColorManager.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Obx(() {
                          if (controller.currentDriverLocation.value != null) {
                            return Text(
                              'tracking_active'.tr,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: const Color(0xFF43A047),
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }
                          return Text(
                            'waiting_for_location'.tr,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: ColorManager.textSecondary,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  Obx(() {
                    if (controller.currentDriverLocation.value != null) {
                      return Container(
                        width: 12.w,
                        height: 12.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFF43A047),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF43A047,
                              ).withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
              if (controller.kidsLocations.isNotEmpty) ...[
                SizedBox(height: 16.h),
                Divider(height: 1.h),
                SizedBox(height: 12.h),
                Text(
                  'kids_locations'.tr,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: ColorManager.textSecondary,
                  ),
                ),
                SizedBox(height: 8.h),
                ...controller.kidsLocations.entries.map((entry) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Row(
                      children: [
                        Icon(
                          Icons.child_care,
                          size: 16.sp,
                          color: ColorManager.primaryColor,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'kid_location_tracked'.tr,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: ColorManager.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SafetyEventsCard extends StatelessWidget {
  const _SafetyEventsCard({required this.controller});

  final ParentTripDetailController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Text(
                      'safety_events'.tr,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Obx(() {
                return Column(
                  children: controller.safetyEvents.take(5).map((event) {
                    final eventType = event['type'] as String? ?? '';
                    final message = event['message'] as String? ?? '';
                    final timestamp = event['timestamp'];
                    DateTime? eventTime;
                    if (timestamp != null) {
                      if (timestamp is String) {
                        eventTime = DateTime.tryParse(timestamp);
                      } else if (timestamp is Timestamp) {
                        eventTime = timestamp.toDate();
                      }
                    }

                    IconData icon;
                    Color color;
                    String title;
                    switch (eventType) {
                      case 'loudSound':
                        icon = Icons.volume_up;
                        color = Colors.orange;
                        title = 'loud_sound_detected'.tr;
                        break;
                      case 'offRoad':
                        icon = Icons.warning;
                        color = Colors.red;
                        title = 'off_road_detected'.tr;
                        break;
                      case 'unexpectedStop':
                        icon = Icons.error;
                        color = Colors.deepOrange;
                        title = 'unexpected_stop_detected'.tr;
                        break;
                      default:
                        icon = Icons.info;
                        color = Colors.blue;
                        title = 'safety_event'.tr;
                    }

                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(icon, color: color, size: 18.sp),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: ColorManager.textPrimary,
                                  ),
                                ),
                                if (message.isNotEmpty) ...[
                                  SizedBox(height: 4.h),
                                  Text(
                                    message,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: ColorManager.textSecondary,
                                    ),
                                  ),
                                ],
                                if (eventTime != null) ...[
                                  SizedBox(height: 4.h),
                                  Text(
                                    DateFormat(
                                      'MMM d, h:mm a',
                                    ).format(eventTime),
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: ColorManager.textSecondary
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteLegend extends StatelessWidget {
  const _RouteLegend({required this.controller});

  final ParentTripDetailController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: ColorManager.primaryColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: ColorManager.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.route,
                      color: ColorManager.primaryColor,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Text(
                      'route_information'.tr,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: ColorManager.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Obx(() {
                final polylines = controller.polylines;
                final hasActualRoute = polylines.any(
                  (polyline) => polyline.polylineId.value == 'actual_route',
                );
                final hasPlannedRoute = polylines.any(
                  (polyline) => polyline.polylineId.value == 'planned_route',
                );

                return Column(
                  children: [
                    if (hasActualRoute)
                      _LegendItem(
                        color: const Color(0xFF43A047),
                        label: 'actual_route_taken'.tr,
                        icon: Icons.check_circle_outline,
                      ),
                    if (hasActualRoute && hasPlannedRoute)
                      SizedBox(height: 12.h),
                    if (hasPlannedRoute)
                      _LegendItem(
                        color: ColorManager.primaryColor.withValues(alpha: 0.5),
                        label: 'planned_route'.tr,
                        icon: Icons.map_outlined,
                      ),
                    if (!hasActualRoute && !hasPlannedRoute)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        child: Text(
                          'route_information_not_available'.tr,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: ColorManager.textSecondary,
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.icon,
  });

  final Color color;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24.w,
          height: 4.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 12.w),
        Icon(icon, size: 18.sp, color: color),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: ColorManager.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

void _showCameraViewDialog(ParentTripDetailController controller) {
  // Show dialog immediately (will show loading state)
  Get.dialog(const _CameraViewDialog(), barrierDismissible: false);

  // Request camera access
  controller.requestDriverCamera();
}

class _DriverInfoCard extends StatelessWidget {
  const _DriverInfoCard({required this.controller});

  final ParentTripDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingDriver.value) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        );
      }

      if (controller.driverInfo.value == null) {
        return const SizedBox.shrink();
      }

      final driver = controller.driverInfo.value!;

      return ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: ColorManager.primaryColor.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.person,
                        color: ColorManager.primaryColor,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'driver_information'.tr,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: ColorManager.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'contact_driver'.tr,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: ColorManager.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Divider(height: 1.h),
                SizedBox(height: 16.h),
                _DriverInfoRow(
                  icon: Icons.person_outline,
                  label: 'driver_name'.tr,
                  value: driver.fullName,
                ),
                SizedBox(height: 12.h),
                _DriverInfoRow(
                  icon: Icons.email_outlined,
                  label: 'email'.tr,
                  value: driver.email,
                ),
                SizedBox(height: 12.h),
                _DriverInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'phone_number'.tr,
                  value: driver.phoneNumber,
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: controller.callDriver,
                        icon: Icon(Icons.phone, size: 18.sp),
                        label: Text('call_driver'.tr),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Obx(() {
                      final isActive = controller.isActiveTrip;
                      return Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isActive
                              ? () => _showCameraViewDialog(controller)
                              : null,
                          icon: Icon(Icons.videocam, size: 18.sp),
                          label: Text('view_camera'.tr),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isActive
                                ? ColorManager.secondaryColor
                                : ColorManager.textDisabled,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _DriverInfoRow extends StatelessWidget {
  const _DriverInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18.sp, color: ColorManager.textSecondary),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: ColorManager.textSecondary,
                  fontWeight: FontWeight.w600,
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
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CameraViewDialog extends StatefulWidget {
  const _CameraViewDialog();

  @override
  State<_CameraViewDialog> createState() => _CameraViewDialogState();
}

class _CameraViewDialogState extends State<_CameraViewDialog> {
  rtc.RTCVideoRenderer? _renderer;
  final rtcService = Get.find<RtcStreamingService>();

  @override
  void initState() {
    super.initState();
    _initializeRenderer();
  }

  Future<void> _initializeRenderer() async {
    _renderer = rtc.RTCVideoRenderer();
    await _renderer!.initialize();

    // Listen to remote stream changes
    rtcService.remoteStream.listen((stream) {
      if (stream != null && mounted) {
        _renderer!.srcObject = stream;
        setState(() {});
      }
    });

    // Set initial stream if available
    if (rtcService.remoteStream.value != null) {
      _renderer!.srcObject = rtcService.remoteStream.value;
    }
  }

  @override
  void dispose() {
    _renderer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.black87],
          ),
        ),
        child: Stack(
          children: [
            // Video stream
            Obx(() {
              final remoteStream = rtcService.remoteStream.value;
              final phase = rtcService.phase.value;

              if (phase == RtcStreamingPhase.idle ||
                  phase == RtcStreamingPhase.acquiringMedia ||
                  phase == RtcStreamingPhase.signaling) {
                return _buildLoadingState(phase);
              }

              if (remoteStream == null || phase == RtcStreamingPhase.error) {
                return _buildErrorState();
              }

              if (_renderer == null) {
                return Center(
                  child: CircularProgressIndicator(
                    color: ColorManager.primaryColor,
                    strokeWidth: 3,
                  ),
                );
              }

              return Stack(
                children: [
                  Center(
                    child: rtc.RTCVideoView(
                      _renderer!,
                      mirror: false,
                      objectFit: rtc
                          .RTCVideoViewObjectFit
                          .RTCVideoViewObjectFitContain,
                    ),
                  ),
                  // Connection status indicator
                  if (phase == RtcStreamingPhase.connected)
                    Positioned(
                      top: 50.h,
                      left: 20.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'live'.tr,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }),
            // Header with title
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 16.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.videocam_rounded,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'driver_camera_view'.tr,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'viewing_your_kids'.tr,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                          onPressed: () {
                            rtcService.stopStreaming();
                            Get.back();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(RtcStreamingPhase phase) {
    String message = 'connecting_to_driver_camera'.tr;
    if (phase == RtcStreamingPhase.acquiringMedia) {
      message = 'requesting_camera_access'.tr;
    } else if (phase == RtcStreamingPhase.signaling) {
      message = 'establishing_connection'.tr;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: ColorManager.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: ColorManager.primaryColor,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            message,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'please_wait'.tr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 48.sp,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'failed_to_connect_camera'.tr,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              'camera_connection_error_desc'.tr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: () {
                Get.back();
              },
              icon: Icon(Icons.close, size: 18.sp),
              label: Text('close'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
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
}
