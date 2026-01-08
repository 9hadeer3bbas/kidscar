import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kidscar/app/modules/driver/driver_home/driver_home_controller.dart';
import 'package:kidscar/app/modules/driver/driver_main/driver_main_controller.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/managers/color_manager.dart';
import '../../../../core/utils/marker_utils.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../data/models/subscription_model.dart';
import '../../../custom_widgets/custom_toast.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/polyline_utils.dart';
import '../../../../domain/core/result.dart';
import '../../../../domain/entities/route_path.dart';
import '../../../../domain/usecases/location/get_route_path_usecase.dart';
import '../../../../domain/value_objects/geo_point.dart' as domain_geo;

enum TripActionType { accept, reject, startPickup, pickedUp, complete }

class TripAction {
  TripAction({required this.type, required this.label});

  final TripActionType type;
  final String label;
}

class TripDetailController extends GetxController {
  TripDetailController(this.trip);

  final TripModel trip;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService =
      Get.find<NotificationService>();
  final GetRoutePathUseCase _getRoutePathUseCase =
      Get.find<GetRoutePathUseCase>();

  final Rx<TripModel> currentTrip = Rx<TripModel>(
    TripModel(
      id: '',
      subscriptionId: '',
      driverId: '',
      parentId: '',
      kidIds: const [],
      pickupLocation: LocationData(
        name: '',
        address: '',
        latitude: 0,
        longitude: 0,
      ),
      dropoffLocation: LocationData(
        name: '',
        address: '',
        latitude: 0,
        longitude: 0,
      ),
      pickupTime: const CustomTimeOfDay(hour: 0, minute: 0),
      status: TripStatus.awaitingDriverResponse,
      scheduledDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  );

  final RxBool isLoading = false.obs;
  final RxBool isProcessing = false.obs;
  final RxString errorMessage = ''.obs;
  final RxSet<Marker> markerSet = <Marker>{}.obs;
  final RxSet<Polyline> polylineSet = <Polyline>{}.obs;
  final Rx<TripActionType?> pendingAction = Rx<TripActionType?>(null);
  GoogleMapController? _mapController;
  final RxBool isRouteLoading = false.obs;

  // Expose map controller for external access
  GoogleMapController? get mapController => _mapController;

  @override
  void onInit() {
    super.onInit();
    currentTrip.value = trip;
    _initializeMap();
  }

  CameraPosition get initialCameraPosition {
    return CameraPosition(
      target: LatLng(
        trip.pickupLocation.latitude,
        trip.pickupLocation.longitude,
      ),
      zoom: 13,
    );
  }

  Set<Marker> get markers => markerSet;
  Set<Polyline> get polylines => polylineSet;

  Color get statusColor => _statusColor(currentTrip.value.status);
  String get statusText => _statusLabel(currentTrip.value.status);

  String formattedDate() {
    final date = currentTrip.value.scheduledDate;
    final formatter = DateFormat('EEE, MMM d, yyyy');
    return formatter.format(date.toLocal());
  }

  String formattedTime() {
    final pickup = currentTrip.value.pickupTime;
    final period = pickup.hour >= 12 ? 'PM' : 'AM';
    final displayHour = pickup.hour > 12
        ? pickup.hour - 12
        : (pickup.hour == 0 ? 12 : pickup.hour);
    return '${displayHour.toString().padLeft(2, '0')}:${pickup.minute.toString().padLeft(2, '0')} $period';
  }

  String get distanceText {
    final distance = currentTrip.value.distanceMeters;
    if (distance == null || distance <= 0) return '';
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
    return '$distance m';
  }

  String get durationText {
    final duration = currentTrip.value.durationSeconds;
    if (duration == null || duration <= 0) return '';
    final minutes = (duration / 60).round();
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    }
    return '${minutes}m';
  }

  Color _statusColor(TripStatus status) {
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

  String _statusLabel(TripStatus status) {
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

  List<TripAction> get availableActions {
    switch (currentTrip.value.status) {
      case TripStatus.awaitingDriverResponse:
        return [
          TripAction(type: TripActionType.reject, label: 'reject'.tr),
          TripAction(type: TripActionType.accept, label: 'accept'.tr),
        ];
      case TripStatus.accepted:
        return [
          TripAction(type: TripActionType.startPickup, label: 'start_trip'.tr),
        ];
      case TripStatus.enRoutePickup:
      case TripStatus.enRouteDropoff:
        // In-progress trips are managed from driver home page
        return [];
      case TripStatus.rejected:
      case TripStatus.cancelled:
      case TripStatus.completed:
        return [];
    }
  }

  Future<void> fetchLatestTrip() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final doc = await _firestore.collection('trips').doc(trip.id).get();
      if (doc.exists) {
        currentTrip.value = TripModel.fromFirestore(doc);
        await _initializeMap();
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshTrip() async {
    await fetchLatestTrip();
  }

  Future<void> handleAction(TripActionType type) async {
    final user = _auth.currentUser;
    if (user == null) {
      CustomToasts(
        message: 'user_not_authenticated'.tr,
        type: CustomToastType.error,
      ).show();
      return;
    }

    isProcessing.value = true;
    pendingAction.value = type;

    try {
      switch (type) {
        case TripActionType.accept:
          await _updateTripStatus(
            TripStatus.accepted,
            SubscriptionStatus.driverAssigned,
            notificationMessage: 'driver_accepted_trip'.tr,
          );
          break;
        case TripActionType.reject:
          await _updateTripStatus(
            TripStatus.rejected,
            SubscriptionStatus.driverRejected,
            notificationMessage: 'driver_rejected_trip'.tr,
          );
          break;
        case TripActionType.startPickup:
          // Navigate to driver home and start trip
          Get.back(); // Close trip detail page

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
                if (AppConfig.isDebugMode) {
                  debugPrint('DriverHomeController not ready, retrying...');
                }
              }
            }
          }

          if (driverHomeController != null) {
            await driverHomeController.startTrip(currentTrip.value);
          } else {
            CustomToasts(
              message: 'failed_to_start_trip'.tr,
              type: CustomToastType.error,
            ).show();
          }
          break;
        case TripActionType.pickedUp:
        case TripActionType.complete:
          // These actions are handled on the driver home page
          CustomToasts(
            message: 'start_trip_from_home'.tr,
            type: CustomToastType.success,
          ).show();
          break;
      }
    } catch (e) {
      CustomToasts(message: e.toString(), type: CustomToastType.error).show();
    } finally {
      isProcessing.value = false;
      pendingAction.value = null;
    }
  }

  Future<void> _updateTripStatus(
    TripStatus tripStatus,
    SubscriptionStatus subscriptionStatus, {
    required String notificationMessage,
  }) async {
    final tripDoc = _firestore.collection('trips').doc(currentTrip.value.id);
    final subscriptionDoc = _firestore
        .collection('subscriptions')
        .doc(currentTrip.value.subscriptionId);

    await _firestore.runTransaction((transaction) async {
      transaction.update(tripDoc, {
        'status': tripStatus.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      transaction.update(subscriptionDoc, {
        'status': subscriptionStatus.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });

    currentTrip.value = currentTrip.value.copyWith(
      status: tripStatus,
      updatedAt: DateTime.now(),
    );

    await _notificationService.sendNotificationToUser(
      userId: currentTrip.value.parentId,
      title: 'trip_update'.tr,
      body: notificationMessage,
      type: NotificationService.driverAssignedType,
      data: {
        'tripId': currentTrip.value.id,
        'subscriptionId': currentTrip.value.subscriptionId,
        'status': tripStatus.name,
      },
    );

    CustomToasts(
      message: 'status_updated'.tr,
      type: CustomToastType.success,
    ).show();
  }

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _fitCameraToBounds();
  }

  Future<void> _initializeMap() async {
    markerSet.clear();
    markerSet.refresh();
    polylineSet.clear();
    polylineSet.refresh();

    final pickupMarker = Marker(
      markerId: const MarkerId('pickup'),
      position: LatLng(
        currentTrip.value.pickupLocation.latitude,
        currentTrip.value.pickupLocation.longitude,
      ),
      infoWindow: InfoWindow(title: currentTrip.value.pickupLocation.name),
      icon: MarkerUtils.getPickupMarker(),
    );

    final dropoffMarker = Marker(
      markerId: const MarkerId('dropoff'),
      position: LatLng(
        currentTrip.value.dropoffLocation.latitude,
        currentTrip.value.dropoffLocation.longitude,
      ),
      infoWindow: InfoWindow(title: currentTrip.value.dropoffLocation.name),
      icon: MarkerUtils.getDropoffMarker(),
    );

    markerSet.addAll([pickupMarker, dropoffMarker]);
    markerSet.refresh();

    if (currentTrip.value.encodedPolyline?.isNotEmpty == true) {
      _addPolylineFromEncoded(currentTrip.value.encodedPolyline!);
    } else {
      await _loadRouteFromApi();
    }

    _fitCameraToBounds();
  }

  void _addPolylineFromEncoded(String encoded) {
    final points = PolylineUtils.decodePolyline(encoded);
    polylineSet
      ..clear()
      ..add(
        Polyline(
          polylineId: const PolylineId('route'),
          color: ColorManager.primaryColor,
          width: 5,
          points: points,
        ),
      );
    polylineSet.refresh();
  }

  Future<void> _loadRouteFromApi() async {
    if (isRouteLoading.value) return;
    isRouteLoading.value = true;

    try {
      final pickup = currentTrip.value.pickupLocation;
      final dropoff = currentTrip.value.dropoffLocation;

      final routeResult = await _getRoutePathUseCase(
        GetRoutePathParams(
          origin: domain_geo.GeoPoint(
            latitude: pickup.latitude,
            longitude: pickup.longitude,
          ),
          destination: domain_geo.GeoPoint(
            latitude: dropoff.latitude,
            longitude: dropoff.longitude,
          ),
        ),
      );

      if (routeResult is ResultSuccess<RoutePath>) {
        final route = routeResult.data;
        _addPolylineFromEncoded(route.encodedPolyline);

        final updatedTrip = currentTrip.value.copyWith(
          encodedPolyline: route.encodedPolyline,
          distanceMeters: route.distanceMeters,
          durationSeconds: route.durationSeconds,
        );
        currentTrip.value = updatedTrip;

        if (updatedTrip.id.isNotEmpty) {
          await _firestore.collection('trips').doc(updatedTrip.id).update({
            'encodedPolyline': route.encodedPolyline,
            'distanceMeters': route.distanceMeters,
            'durationSeconds': route.durationSeconds,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }

        _fitCameraToBounds();
      } else if (routeResult is ResultFailure<RoutePath>) {
        if (AppConfig.isDebugMode) {
          debugPrint('Failed to load route: ${routeResult.failure.message}');
        }
      }
    } catch (e) {
      if (AppConfig.isDebugMode) {
        debugPrint('Failed to load route: $e');
      }
    } finally {
      isRouteLoading.value = false;
    }
  }

  Future<void> _fitCameraToBounds() async {
    if (_mapController == null) return;

    final pickup = currentTrip.value.pickupLocation;
    final dropoff = currentTrip.value.dropoffLocation;

    final southWest = LatLng(
      pickup.latitude < dropoff.latitude ? pickup.latitude : dropoff.latitude,
      pickup.longitude < dropoff.longitude
          ? pickup.longitude
          : dropoff.longitude,
    );
    final northEast = LatLng(
      pickup.latitude > dropoff.latitude ? pickup.latitude : dropoff.latitude,
      pickup.longitude > dropoff.longitude
          ? pickup.longitude
          : dropoff.longitude,
    );

    final bounds = LatLngBounds(southwest: southWest, northeast: northEast);

    await Future.delayed(const Duration(milliseconds: 200));
    try {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 60),
      );
    } catch (_) {
      // If bounds are invalid (identical points), fallback to focusing pickup
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(initialCameraPosition),
      );
    }
  }

  List<LatLng> decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}
