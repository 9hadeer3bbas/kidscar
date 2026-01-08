import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/managers/color_manager.dart';
import '../../../../core/services/trip_tracking_service.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../data/repos/location_repo.dart';
import '../../../../domain/repositories/location_repository.dart';
import '../../../../domain/usecases/location/get_route_path_usecase.dart';
import '../../../../domain/usecases/location/get_route_pois_usecase.dart';

import 'driver_home_controller.dart';
import 'driver_home_state.dart';

/// Modern, friendly, and simple driver home view
class DriverHomeView extends StatelessWidget {
  const DriverHomeView({super.key});

  /// Ensure required dependencies are available before creating controller
  void _ensureDependencies() {
    // Ensure LocationRepository is available
    if (!Get.isRegistered<LocationRepository>()) {
      Get.put<LocationRepositoryImpl>(LocationRepositoryImpl());
      Get.lazyPut<LocationRepository>(() => Get.find<LocationRepositoryImpl>());
    }

    // Ensure GetRoutePathUseCase is available
    if (!Get.isRegistered<GetRoutePathUseCase>()) {
      Get.lazyPut<GetRoutePathUseCase>(
        () => GetRoutePathUseCase(Get.find<LocationRepository>()),
        fenix: true, // Recreate if disposed
      );
    }

    // Ensure GetRoutePoisUseCase is available
    if (!Get.isRegistered<GetRoutePoisUseCase>()) {
      Get.lazyPut<GetRoutePoisUseCase>(
        () => GetRoutePoisUseCase(Get.find<LocationRepository>()),
        fenix: true, // Recreate if disposed
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure dependencies are available before creating controller
    _ensureDependencies();

    final controller = Get.isRegistered<DriverHomeController>()
        ? Get.find<DriverHomeController>()
        : Get.put(DriverHomeController());
    return Scaffold(
      backgroundColor: ColorManager.scaffoldBackground,
      body: SafeArea(
        child: Obx(() {
          final state = controller.uiState.value;
          return Stack(
            children: [
              // Full-screen map
              _DriverHomeMap(state: state, controller: controller),

              // Modern minimal header
              _ModernHeader(state: state, controller: controller),

              // Active trip card (when trip is active)
              if (state.isTracking || state.isSimulating)
                _ActiveTripCard(state: state, controller: controller),

              // Bottom trips panel
              _TripBottomPanel(state: state, controller: controller),

              // Loading overlay
              if (state.showLoadingOverlay) const _LoadingOverlay(),

              // Error banner
              if (state.status == DriverHomeScreenStatus.error)
                Positioned(
                  top: 80.h,
                  left: 12.w,
                  right: 12.w,
                  child: _ErrorBanner(
                    message: state.errorMessage ?? 'unknown_error'.tr,
                    onRetry: controller.retry,
                  ),
                ),
            ],
          );
        }),
      ),
      floatingActionButton: Obx(() {
        final state = controller.uiState.value;
        if (!state.showSimulationFab) return const SizedBox.shrink();
        return _SafetyFab(controller: controller, state: state);
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _DriverHomeMap extends StatelessWidget {
  const _DriverHomeMap({required this.state, required this.controller});

  final DriverHomeViewState state;
  final DriverHomeController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GoogleMap(
        onMapCreated: controller.onMapCreated,
        myLocationButtonEnabled: false,
        myLocationEnabled: true,
        compassEnabled: true,
        trafficEnabled: true,
        mapType: MapType.normal,
        markers: state.mapMarkers,
        polylines: state.polylines,
        initialCameraPosition: CameraPosition(
          target: state.cameraTarget,
          zoom: 15,
        ),
        onTap: (_) {},
      ),
    );
  }
}

/// Modern, clean header
class _ModernHeader extends StatelessWidget {
  const _ModernHeader({required this.state, required this.controller});

  final DriverHomeViewState state;
  final DriverHomeController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: EdgeInsets.all(12.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Driver status indicator
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: state.isOnline ? Colors.green : Colors.grey,
                boxShadow: [
                  BoxShadow(
                    color: (state.isOnline ? Colors.green : Colors.grey)
                        .withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),

            // Driver info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'driver_dashboard'.tr,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: ColorManager.textPrimary,
                    ),
                  ),
                  if (state.roadName.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      state.roadName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: ColorManager.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Online/Offline toggle - Modern Switch
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.isOnline ? 'status_online'.tr : 'status_offline'.tr,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: ColorManager.textSecondary,
                  ),
                ),
                SizedBox(width: 8.w),
                Switch(
                  value: state.isOnline,
                  onChanged: (value) => controller.toggleAvailability(),
                  activeColor: Colors.green,
                  activeTrackColor: Colors.green.withOpacity(0.5),
                  inactiveThumbColor: Colors.grey.shade400,
                  inactiveTrackColor: Colors.grey.shade300,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Active trip info card - shows when trip is active
class _ActiveTripCard extends StatelessWidget {
  const _ActiveTripCard({required this.state, required this.controller});

  final DriverHomeViewState state;
  final DriverHomeController controller;

  @override
  Widget build(BuildContext context) {
    final activeTrip = state.inProgressTrips.isNotEmpty
        ? state.inProgressTrips.first
        : null;

    if (activeTrip == null) return const SizedBox.shrink();

    return Positioned(
      top: 80.h,
      left: 12.w,
      right: 12.w,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: ColorManager.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.navigation_rounded,
                    color: ColorManager.primaryColor,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'active_trip'.tr,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: ColorManager.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        activeTrip.pickupLocation.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: ColorManager.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.isSimulating)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'simulation_running'.tr,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (state.polylines.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: ColorManager.scaffoldBackground,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.route,
                      size: 16.sp,
                      color: ColorManager.primaryColor,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'route_active'.tr,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: ColorManager.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TripBottomPanel extends StatelessWidget {
  const _TripBottomPanel({required this.state, required this.controller});

  final DriverHomeViewState state;
  final DriverHomeController controller;

  List<TripModel> get _visibleTrips {
    switch (state.activeTab) {
      case DriverHomeTripTab.scheduled:
        return state.scheduledTrips;
      case DriverHomeTripTab.instant:
        return state.instantTrips;
      case DriverHomeTripTab.inProgress:
        return state.inProgressTrips;
    }
  }

  @override
  Widget build(BuildContext context) {
    final trips = _visibleTrips;
    final collapsed = state.isTripPanelCollapsed;
    // Add bottom padding when FAB is visible to avoid overlap
    final bottomPadding = state.showSimulationFab ? 80.h : 0.h;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: EdgeInsets.only(bottom: bottomPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32.r),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 6.h, bottom: 3.h),
                width: 40.w,
                height: 3.h,
                decoration: BoxDecoration(
                  color: ColorManager.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 12.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: ColorManager.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.list_alt_rounded,
                          color: ColorManager.primaryColor,
                          size: 16.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'your_trips'.tr,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: ColorManager.textPrimary,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: ColorManager.scaffoldBackground,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'focus_driver'.tr,
                          onPressed: controller.focusOnDriver,
                          icon: Icon(
                            Icons.my_location_rounded,
                            color: ColorManager.primaryColor,
                            size: 18.sp,
                          ),
                          padding: EdgeInsets.all(6.w),
                        ),
                        Container(
                          width: 1,
                          height: 20.h,
                          color: ColorManager.divider,
                        ),
                        IconButton(
                          tooltip: collapsed
                              ? 'expand_panel'.tr
                              : 'collapse_panel'.tr,
                          onPressed: controller.toggleTripPanelCollapsed,
                          icon: Icon(
                            collapsed
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: ColorManager.primaryColor,
                            size: 20.sp,
                          ),
                          padding: EdgeInsets.all(6.w),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!collapsed) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _TripTabSwitcher(controller: controller, state: state),
              ),
              SizedBox(height: 12.h),
              if (trips.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _EmptyTripPlaceholder(state: state),
                )
              else
                SizedBox(
                  height: 240.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      return _TripCard(
                        trip: trip,
                        state: state,
                        controller: controller,
                      );
                    },
                    separatorBuilder: (_, __) => SizedBox(width: 12.w),
                    itemCount: trips.length,
                  ),
                ),
              SizedBox(height: 16.h),
            ],
          ],
        ),
      ),
    );
  }
}

class _TripTabSwitcher extends StatelessWidget {
  const _TripTabSwitcher({required this.controller, required this.state});

  final DriverHomeController controller;
  final DriverHomeViewState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: ColorManager.scaffoldBackground,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: ColorManager.primaryColor.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Row(
        children: DriverHomeTripTab.values.map((tab) {
          final isSelected = state.activeTab == tab;
          final label = switch (tab) {
            DriverHomeTripTab.scheduled => 'scheduled_tab'.tr,
            DriverHomeTripTab.instant => 'instant_tab'.tr,
            DriverHomeTripTab.inProgress => 'in_progress_tab'.tr,
          };
          final icon = switch (tab) {
            DriverHomeTripTab.scheduled => Icons.calendar_today_rounded,
            DriverHomeTripTab.instant => Icons.flash_on_rounded,
            DriverHomeTripTab.inProgress => Icons.navigation_rounded,
          };
          return Expanded(
            child: GestureDetector(
              onTap: () => controller.changeTab(tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            ColorManager.primaryColor,
                            ColorManager.primaryColor.withOpacity(0.85),
                          ],
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: ColorManager.primaryColor.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 14.sp,
                      color: isSelected
                          ? Colors.white
                          : ColorManager.textSecondary,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : ColorManager.textSecondary,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.state,
    required this.controller,
  });

  final TripModel trip;
  final DriverHomeViewState state;
  final DriverHomeController controller;

  bool get _isHighlighted => state.highlightedTrip?.id == trip.id;

  @override
  Widget build(BuildContext context) {
    final tripDate = DateFormat.yMMMd().format(trip.scheduledDate);
    final pickupTime = trip.pickupTime.formattedString;

    return GestureDetector(
      onTap: () => controller.selectTrip(trip),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 260.w,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: _isHighlighted
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ColorManager.primaryColor,
                    ColorManager.primaryColor.withOpacity(0.8),
                  ],
                )
              : null,
          color: _isHighlighted ? null : Colors.white,
          border: _isHighlighted
              ? null
              : Border.all(
                  color: ColorManager.primaryColor.withOpacity(0.15),
                  width: 1.5,
                ),
          boxShadow: [
            BoxShadow(
              color: _isHighlighted
                  ? ColorManager.primaryColor.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: _isHighlighted ? 16 : 10,
              offset: Offset(0, _isHighlighted ? 8 : 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _StatusDot(status: trip.status, highlighted: _isHighlighted),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    trip.pickupLocation.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: _isHighlighted
                          ? Colors.white
                          : ColorManager.textPrimary,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                Icon(
                  Icons.arrow_downward_rounded,
                  size: 12.sp,
                  color: _isHighlighted
                      ? Colors.white.withOpacity(0.7)
                      : ColorManager.textSecondary,
                ),
                SizedBox(width: 5.w),
                Expanded(
                  child: Text(
                    trip.dropoffLocation.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: _isHighlighted
                          ? Colors.white.withOpacity(0.9)
                          : ColorManager.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: _isHighlighted
                    ? Colors.white.withOpacity(0.15)
                    : ColorManager.scaffoldBackground,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12.sp,
                          color: _iconColor,
                        ),
                        SizedBox(width: 5.w),
                        Flexible(
                          child: Text(
                            tripDate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: _textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 14.h,
                    color: _isHighlighted
                        ? Colors.white.withOpacity(0.3)
                        : ColorManager.divider,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12.sp,
                          color: _iconColor,
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          pickupTime,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            _TripActions(
              trip: trip,
              controller: controller,
              state: state,
              highlighted: _isHighlighted,
            ),
          ],
        ),
      ),
    );
  }

  Color get _textColor =>
      _isHighlighted ? Colors.white : ColorManager.textPrimary;
  Color get _iconColor =>
      _isHighlighted ? Colors.white70 : ColorManager.primaryColor;
}

class _TripActions extends StatelessWidget {
  const _TripActions({
    required this.trip,
    required this.controller,
    required this.state,
    required this.highlighted,
  });

  final TripModel trip;
  final DriverHomeController controller;
  final DriverHomeViewState state;
  final bool highlighted;

  bool get _isInstant => trip.subscriptionId == 'instant_ride';

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];

    actions.add(
      Expanded(
        child: Obx(() {
          final isLoading =
              controller.focusingTripId.value != null &&
              controller.focusingTripId.value == trip.id;
          return ElevatedButton(
            onPressed: isLoading
                ? null
                : () => controller.focusOnTrip(trip, collapsePanel: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: highlighted
                  ? Colors.white.withOpacity(0.25)
                  : ColorManager.primaryColor.withOpacity(0.1),
              foregroundColor: highlighted
                  ? Colors.white
                  : ColorManager.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(vertical: 8.h),
              elevation: 0,
            ),
            child: isLoading
                ? SizedBox(
                    width: 14.w,
                    height: 14.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        highlighted ? Colors.white : ColorManager.primaryColor,
                      ),
                    ),
                  )
                : Text('view_route'.tr, style: TextStyle(fontSize: 11.sp)),
          );
        }),
      ),
    );

    if (state.activeTab == DriverHomeTripTab.instant && _isInstant) {
      // Instant ride requests - show accept/decline
      if (trip.status == TripStatus.awaitingDriverResponse) {
        actions.add(SizedBox(width: 8.w));
        actions.add(
          Expanded(
            child: ElevatedButton(
              onPressed: () => controller.acceptInstantRide(trip),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: ColorManager.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                elevation: 0,
              ),
              child: Text('accept'.tr, style: TextStyle(fontSize: 11.sp)),
            ),
          ),
        );
        actions.add(SizedBox(width: 8.w));
        actions.add(
          Expanded(
            child: ElevatedButton(
              onPressed: () => controller.declineInstantRide(trip),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.85),
                foregroundColor: ColorManager.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                elevation: 0,
              ),
              child: Text('decline'.tr, style: TextStyle(fontSize: 11.sp)),
            ),
          ),
        );
      } else if (trip.status == TripStatus.accepted) {
        // Accepted instant ride - show start/simulate
        actions.add(SizedBox(width: 8.w));
        actions.add(
          Expanded(
            child: ElevatedButton(
              onPressed: () => controller.startTrip(trip),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: ColorManager.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                elevation: 0,
              ),
              child: Text('start_trip'.tr, style: TextStyle(fontSize: 11.sp)),
            ),
          ),
        );
        if (AppConfig.isDebugMode) {
          actions.add(SizedBox(width: 8.w));
          actions.add(
            Expanded(
              child: OutlinedButton(
                onPressed: () => controller.startSimulation(
                  trip,
                  SimulationScenario.normalRoute,
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: ColorManager.secondaryColor,
                    width: 1.5,
                  ),
                  foregroundColor: ColorManager.secondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                ),
                child: Text('simulate'.tr, style: TextStyle(fontSize: 11.sp)),
              ),
            ),
          );
        }
      }
    } else if (state.activeTab == DriverHomeTripTab.inProgress) {
      // In progress trips - show complete and simulation controls if applicable
      actions.add(SizedBox(width: 8.w));
      actions.add(
        Expanded(
          child: Obx(() {
            final isLoading =
                controller.isCompletingTrip.value ||
                controller.busyTripActions.contains(trip.id);
            return ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () => controller.completeActiveTrip(trip),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: ColorManager.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                elevation: 0,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 18.w,
                      height: 14.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ColorManager.success,
                        ),
                      ),
                    )
                  : Text('complete_trip'.tr, style: TextStyle(fontSize: 10.sp)),
            );
          }),
        ),
      );

      // Show simulation controls if trip is being simulated
      if (AppConfig.isDebugMode && state.isSimulating) {
        actions.add(SizedBox(width: 8.w));
        actions.add(
          Expanded(
            child: OutlinedButton(
              onPressed: () => controller.stopSimulation(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: ColorManager.warning, width: 1.5),
                foregroundColor: ColorManager.warning,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 8.h),
              ),
              child: Text(
                'simulation_stop'.tr,
                style: TextStyle(fontSize: 11.sp),
              ),
            ),
          ),
        );
      }
    } else {
      // Scheduled tab - show start/simulate for accepted trips, or accept/decline for pending
      if (trip.status == TripStatus.accepted) {
        // Accepted trip - show start and simulate buttons
        actions.add(SizedBox(width: 8.w));
        actions.add(
          Expanded(
            child: ElevatedButton(
              onPressed: () => controller.startTrip(trip),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: ColorManager.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                elevation: 0,
              ),
              child: Text('start_trip'.tr, style: TextStyle(fontSize: 11.sp)),
            ),
          ),
        );
        if (AppConfig.isDebugMode) {
          actions.add(SizedBox(width: 8.w));
          actions.add(
            Expanded(
              child: OutlinedButton(
                onPressed: () => controller.startSimulation(
                  trip,
                  SimulationScenario.normalRoute,
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: ColorManager.secondaryColor,
                    width: 1.5,
                  ),
                  foregroundColor: ColorManager.secondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                ),
                child: Text('simulate'.tr, style: TextStyle(fontSize: 11.sp)),
              ),
            ),
          );
        }
      } else {
        // Pending trip - show start button (will handle accept if needed)
        actions.add(SizedBox(width: 8.w));
        actions.add(
          Expanded(
            child: ElevatedButton(
              onPressed: () => controller.startTrip(trip),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: ColorManager.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                elevation: 0,
              ),
              child: Text('start_trip'.tr, style: TextStyle(fontSize: 11.sp)),
            ),
          ),
        );
      }
    }

    return Row(children: actions);
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status, required this.highlighted});

  final TripStatus status;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      TripStatus.awaitingDriverResponse => Colors.orangeAccent,
      TripStatus.accepted => Colors.lightBlueAccent,
      TripStatus.enRoutePickup => Colors.greenAccent,
      TripStatus.enRouteDropoff => Colors.green,
      TripStatus.completed => Colors.grey,
      TripStatus.rejected => Colors.redAccent,
      TripStatus.cancelled => Colors.red,
    };

    return Container(
      width: 10.w,
      height: 10.w,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: highlighted
            ? Border.all(color: Colors.white, width: 1.5)
            : Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );
  }
}

class _EmptyTripPlaceholder extends StatelessWidget {
  const _EmptyTripPlaceholder({required this.state});

  final DriverHomeViewState state;

  @override
  Widget build(BuildContext context) {
    final text = switch (state.activeTab) {
      DriverHomeTripTab.scheduled => 'no_scheduled_trips'.tr,
      DriverHomeTripTab.instant => 'no_instant_requests'.tr,
      DriverHomeTripTab.inProgress => 'no_active_trips'.tr,
    };
    final icon = switch (state.activeTab) {
      DriverHomeTripTab.scheduled => Icons.calendar_today_outlined,
      DriverHomeTripTab.instant => Icons.flash_on_outlined,
      DriverHomeTripTab.inProgress => Icons.navigation_outlined,
    };

    return Container(
      height: 180.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ColorManager.scaffoldBackground,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: ColorManager.primaryColor.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: ColorManager.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32.sp,
              color: ColorManager.primaryColor.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            text,
            style: TextStyle(
              color: ColorManager.textSecondary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SafetyFab extends StatelessWidget {
  const _SafetyFab({required this.controller, required this.state});

  final DriverHomeController controller;
  final DriverHomeViewState state;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: controller.openSafetyActions,
      backgroundColor: ColorManager.warning,
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
      label: Text(
        state.isSimulating ? 'simulation_controls'.tr : 'safety_actions'.tr,
        style: TextStyle(color: Colors.white, fontSize: 12.sp),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.1),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(strokeWidth: 2.5),
              SizedBox(width: 12.w),
              Text(
                'loading'.tr,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: ColorManager.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ColorManager.error.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      elevation: 8,
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 18.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: Text('retry'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
