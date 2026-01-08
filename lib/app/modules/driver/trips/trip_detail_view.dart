import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kidscar/app/modules/driver/driver_home/driver_home_controller.dart';
import 'package:kidscar/app/modules/driver/driver_main/driver_main_controller.dart';

import '../../../../core/managers/color_manager.dart';
import '../../../../core/services/trip_tracking_service.dart';
import '../../../../data/models/trip_model.dart';
import '../../../custom_widgets/custom_button.dart';
import '../../../custom_widgets/custom_toast.dart';
import '../../../custom_widgets/wave_header.dart';
import 'trip_detail_controller.dart';

class TripDetailView extends GetView<TripDetailController> {
  const TripDetailView({super.key});

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
                onRetry: controller.fetchLatestTrip,
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
                        _AdditionalInfo(controller: controller),
                        SizedBox(height: 18.h),
                        _ActionBar(controller: controller),
                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
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

  final TripDetailController controller;

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

  final TripDetailController controller;

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

  final TripDetailController controller;

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

class _RouteLegend extends StatelessWidget {
  const _RouteLegend({required this.controller});

  final TripDetailController controller;

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
                // Access reactive set directly to ensure GetX tracks it
                final polylines = controller.polylineSet.toSet();
                final hasRoute = polylines.isNotEmpty;

                return Column(
                  children: [
                    if (hasRoute)
                      _LegendItem(
                        color: ColorManager.primaryColor,
                        label: 'planned_route'.tr,
                        icon: Icons.map_outlined,
                      ),
                    if (!hasRoute)
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

class _AdditionalInfo extends StatelessWidget {
  const _AdditionalInfo({required this.controller});

  final TripDetailController controller;

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

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.controller});

  final TripDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final trip = controller.currentTrip.value;
      final actions = controller.availableActions;
      final isAccepted = trip.status == TripStatus.accepted;

      if (actions.isEmpty) {
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: ColorManager.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: ColorManager.warning.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 18.sp,
                color: ColorManager.warning,
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  'start_trip_from_home'.tr,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: ColorManager.warning,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Row(
            children: actions.asMap().entries.map((entry) {
              final index = entry.key;
              final action = entry.value;
              final isReject = action.type == TripActionType.reject;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < actions.length - 1 ? 12.w : 0,
                  ),
                  child: CustomButton(
                    text: action.label,
                    onPressed: controller.isProcessing.value
                        ? null
                        : () => controller.handleAction(action.type),
                    isLoading:
                        controller.isProcessing.value &&
                        controller.pendingAction.value == action.type,
                    color: isReject
                        ? ColorManager.error
                        : ColorManager.primaryColor,
                  ),
                ),
              );
            }).toList(),
          ),
          if (isAccepted) ...[
            SizedBox(height: 12.h),
            OutlinedButton.icon(
              onPressed: controller.isProcessing.value
                  ? null
                  : () => _showSimulationDialog(trip),
              icon: Icon(Icons.play_circle_outline, size: 18.sp),
              label: Text('start_simulation'.tr),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: ColorManager.secondaryColor,
                  width: 1.5,
                ),
                foregroundColor: ColorManager.secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
            ),
          ],
        ],
      );
    });
  }

  void _showSimulationDialog(TripModel trip) {
    Get.dialog(
      AlertDialog(
        title: Text('start_simulation'.tr),
        content: Text('select_simulation_scenario'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () async {
              Get.back();
              Get.back(); // Close trip detail

              // Switch to home tab if we're on driver main view
              if (Get.isRegistered<DriverMainController>()) {
                final mainController = Get.find<DriverMainController>();
                if (mainController.selectedIndex.value != 0) {
                  mainController.changeTabIndex(0);
                }
              }

              // Wait for the controller to be ready (with retries)
              DriverHomeController? driverHomeController;
              for (int i = 0; i < 5; i++) {
                await Future.delayed(const Duration(milliseconds: 200));
                if (Get.isRegistered<DriverHomeController>()) {
                  try {
                    driverHomeController = Get.find<DriverHomeController>();
                    break;
                  } catch (e) {
                    // Controller not ready yet, continue waiting
                  }
                }
              }

              if (driverHomeController != null) {
                driverHomeController.startSimulation(
                  trip,
                  SimulationScenario.normalRoute,
                );
              } else {
                CustomToasts(
                  message: 'failed_to_start_simulation'.tr,
                  type: CustomToastType.error,
                ).show();
              }
            },
            child: Text('normal_route'.tr),
          ),
        ],
      ),
    );
  }
}
