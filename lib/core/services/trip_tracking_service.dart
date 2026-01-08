import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/models/route_poi.dart';
import '../../data/models/trip_model.dart';
import '../../data/models/subscription_model.dart';
import '../config/app_config.dart';
import '../utils/polyline_utils.dart';
import 'notification_service.dart';
import 'safety_event_service.dart';
import 'audio_monitoring_service.dart';

enum SimulationScenario { normalRoute, offRoute, heavyTraffic }

class TripSimulationConfig {
  const TripSimulationConfig({
    required this.scenario,
    this.tick = const Duration(seconds: 2),
    this.deviationMeters = 180,
  });

  final SimulationScenario scenario;
  final Duration tick;
  final double deviationMeters;
}

class TripTrackingService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService =
      Get.find<NotificationService>();

  SafetyEventService? _safetyEventServiceInstance;

  SafetyEventService? get _safetyEventService {
    _safetyEventServiceInstance ??= Get.isRegistered<SafetyEventService>()
        ? Get.find<SafetyEventService>()
        : null;
    return _safetyEventServiceInstance;
  }

  AudioMonitoringService? _audioMonitoringServiceInstance;

  AudioMonitoringService? get _audioMonitoringService {
    _audioMonitoringServiceInstance ??= Get.isRegistered<AudioMonitoringService>()
        ? Get.find<AudioMonitoringService>()
        : null;
    return _audioMonitoringServiceInstance;
  }

  StreamSubscription<Position>? _positionSubscription;
  TripModel? _activeTrip;
  List<LatLng> _routePoints = [];
  List<RoutePoi> _routePois = [];
  final List<StreamSubscription<bool>> _poiSubscriptions = [];
  bool _isCurrentlyOffRoute = false;
  DateTime? _lastDeviationNotificationAt;
  DateTime? _lastRoadUpdateAt;
  DateTime? _lastStopDetectionAt;
  Timer? _simulationTimer;
  int _simulationIndex = 0;
  int _trafficStallCounter = 0;

  final double deviationThresholdMeters = 120;
  final double poiRadiusMeters = 120;
  final double unexpectedStopThresholdMeters = 10; // Within 10 meters = stopped
  final Duration roadNameRefreshInterval = const Duration(seconds: 45);
  final Duration deviationNotificationCooldown = const Duration(minutes: 3);
  final Duration unexpectedStopCooldown = const Duration(minutes: 5);
  final Duration unexpectedStopDetectionDuration = const Duration(seconds: 30);

  final Rx<LatLng?> currentDriverPosition = Rx<LatLng?>(null);
  final RxString currentRoadName = ''.obs;
  final RxList<RoutePoi> livePois = <RoutePoi>[].obs;
  final RxBool trackingActive = false.obs;
  final RxMap<String, bool> poiProgress = <String, bool>{}.obs;
  final Rx<SimulationScenario?> activeSimulationScenario =
      Rx<SimulationScenario?>(null);
  final RxBool simulationModeActive = false.obs;
  final RxInt simulationProgress = 0.obs;
  final RxInt simulationTotal = 0.obs;
  final RxDouble simulationSpeedMetersPerSecond = 0.0.obs;

  Future<void> startTracking({
    required TripModel trip,
    required List<LatLng> routePoints,
    required List<RoutePoi> pois,
    TripSimulationConfig? simulationConfig,
  }) async {
    await stopTracking();

    _activeTrip = trip;
    _routePoints = routePoints;
    _routePois = pois;
    activeSimulationScenario.value = simulationConfig?.scenario;
    simulationModeActive.value = simulationConfig != null;
    livePois.assignAll(pois);
    poiProgress.clear();
    for (final poi in pois) {
      poiProgress[poi.placeId] = poi.reached.value;
      final subscription = poi.reached.listen((reached) {
        poiProgress[poi.placeId] = reached;
      });
      _poiSubscriptions.add(subscription);
    }
    trackingActive.value = true;
    _isCurrentlyOffRoute = false;
    _lastDeviationNotificationAt = null;
    _lastStopDetectionAt = null;

    // Start audio monitoring for loud sound detection
    if (_audioMonitoringService != null) {
      try {
        await _audioMonitoringService!.startMonitoring(trip);
      } catch (e) {
        if (AppConfig.isDebugMode) {
          debugPrint('⚠️ Failed to start audio monitoring: $e');
        }
      }
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied ||
          requested == LocationPermission.deniedForever) {
        trackingActive.value = false;
        throw Exception('Location permission not granted');
      }
    }

    if (simulationConfig != null && AppConfig.isDebugMode) {
      _startSimulatedStream(simulationConfig);
      return;
    }

    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 15,
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          _handlePositionUpdate,
          onError: (error) {
            if (AppConfig.isDebugMode) {
              debugPrint('Trip tracking error: $error');
            }
          },
        );
  }

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await Future.wait(
      _poiSubscriptions.map((sub) => sub.cancel()),
    ).catchError((_) => <void>[]);
    _poiSubscriptions.clear();
    _activeTrip = null;
    _routePoints = [];
    _routePois = [];
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _simulationIndex = 0;
    _trafficStallCounter = 0;
    livePois.clear();
    poiProgress.clear();
    trackingActive.value = false;
    activeSimulationScenario.value = null;
    simulationModeActive.value = false;

    // Stop audio monitoring
    if (_audioMonitoringService != null) {
      try {
        await _audioMonitoringService!.stopMonitoring();
      } catch (e) {
        if (AppConfig.isDebugMode) {
          debugPrint('⚠️ Failed to stop audio monitoring: $e');
        }
      }
    }
  }

  Future<void> seedInitialPosition(LatLng position) async {
    currentDriverPosition.value = position;
    await _maybeUpdateRoadName(position);
  }

  Future<void> _handlePositionUpdate(Position position) async {
    final trip = _activeTrip;
    if (trip == null) {
      return;
    }

    final latLng = LatLng(position.latitude, position.longitude);
    currentDriverPosition.value = latLng;

    await _persistLocationSample(trip, position);
    _updatePoiProgress(latLng, trip.id);
    await _detectDeviation(latLng, trip);
    await _detectUnexpectedStop(position, trip);
    await _maybeUpdateRoadName(latLng);
  }

  void _startSimulatedStream(TripSimulationConfig config) {
    if (_routePoints.isEmpty) {
      return;
    }

    _simulationTimer?.cancel();
    _simulationIndex = 0;
    _trafficStallCounter = 0;
    simulationTotal.value = _routePoints.length;
    simulationProgress.value = 0;

    // Set initial position to pickup location (first waypoint)
    if (_routePoints.isNotEmpty) {
      final startPoint = _routePoints.first;
      currentDriverPosition.value = startPoint;
    }

    _simulationTimer = Timer.periodic(config.tick, (timer) {
      if (_simulationIndex >= _routePoints.length) {
        timer.cancel();
        trackingActive.value = false;
        activeSimulationScenario.value = null;
        simulationModeActive.value = false;
        simulationProgress.value = 0;
        simulationTotal.value = 0;
        simulationSpeedMetersPerSecond.value = 0.0;
        return;
      }

      final basePoint = _routePoints[_simulationIndex];
      final simulatedPoint = _applyScenarioToPoint(
        basePoint,
        _simulationIndex,
        config,
      );

      final speed = config.scenario == SimulationScenario.heavyTraffic ? 2.0 : 8.5;
      simulationSpeedMetersPerSecond.value = speed;

      final position = Position(
        latitude: simulatedPoint.latitude,
        longitude: simulatedPoint.longitude,
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: _calculateHeading(_simulationIndex),
        headingAccuracy: 0,
        speed: speed,
        speedAccuracy: 0.5,
        timestamp: DateTime.now(),
        isMocked: true,
      );

      unawaited(_handlePositionUpdate(position));

      if (config.scenario == SimulationScenario.heavyTraffic) {
        if (_trafficStallCounter < 2) {
          _trafficStallCounter++;
        } else {
          _trafficStallCounter = 0;
          _simulationIndex++;
          simulationProgress.value = _simulationIndex;
        }
      } else {
        _simulationIndex++;
        simulationProgress.value = _simulationIndex;
      }
    });
  }

  double _calculateHeading(int index) {
    if (index >= _routePoints.length - 1) return 0;
    
    final current = _routePoints[index];
    final next = _routePoints[index + 1];
    
    final dLon = next.longitude - current.longitude;
    final dLat = next.latitude - current.latitude;
    
    final heading = math.atan2(dLon, dLat) * 180 / math.pi;
    return (heading + 360) % 360;
  }

  LatLng _applyScenarioToPoint(
    LatLng point,
    int index,
    TripSimulationConfig config,
  ) {
    if (config.scenario != SimulationScenario.offRoute) {
      return point;
    }

    final deviationStartIndex = (_routePoints.length * 0.6).round();
    if (index < deviationStartIndex) {
      return point;
    }

    final metersPerDegreeLatitude = 111320.0;
    final rawCos = math.cos(point.latitude * math.pi / 180.0);
    final stableCos = rawCos < 0.2
        ? 0.2
        : rawCos > 1.0
        ? 1.0
        : rawCos;
    final metersPerDegreeLongitude = metersPerDegreeLatitude * stableCos;

    final deviationInDegreesLat =
        (config.deviationMeters / metersPerDegreeLatitude);
    final deviationInDegreesLng =
        (config.deviationMeters / metersPerDegreeLongitude);

    final oscillation = math.sin(index * 0.35);

    return LatLng(
      point.latitude + deviationInDegreesLat * oscillation,
      point.longitude + deviationInDegreesLng * oscillation,
    );
  }

  Future<void> _persistLocationSample(TripModel trip, Position position) async {
    try {
      final collection = _firestore
          .collection('trips')
          .doc(trip.id)
          .collection('locations');

      await collection.add({
        'timestamp': DateTime.now().toIso8601String(),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': position.speed,
        'heading': position.heading,
        'accuracy': position.accuracy,
      });
    } catch (e) {
      if (AppConfig.isDebugMode) {
        debugPrint('Failed to persist trip location: $e');
      }
    }
  }

  void _updatePoiProgress(LatLng driverPosition, String tripId) {
    final updatedPois = <RoutePoi>[];
    bool changed = false;

    for (final poi in _routePois) {
      if (poi.reached.value) {
        updatedPois.add(poi);
        continue;
      }

      final distance = PolylineUtils.distanceBetween(
        driverPosition,
        poi.location,
      );
      if (distance <= poiRadiusMeters) {
        poi.reached.value = true;
        changed = true;
        poiProgress[poi.placeId] = true;
        _persistPoiReached(tripId, poi, distance);
      }
      updatedPois.add(poi);
    }

    if (changed) {
      livePois.assignAll(updatedPois);
    }
  }

  Future<void> _persistPoiReached(
    String tripId,
    RoutePoi poi,
    double distance,
  ) async {
    try {
      final doc = _firestore
          .collection('trips')
          .doc(tripId)
          .collection('poi_progress')
          .doc(poi.placeId);

      await doc.set({
        ...poi.toJson(),
        'reachedAt': DateTime.now().toIso8601String(),
        'distanceMeters': distance,
      });
    } catch (e) {
      if (AppConfig.isDebugMode) {
        debugPrint('Failed to persist POI progress: $e');
      }
    }
  }

  Future<void> _detectDeviation(LatLng driverPos, TripModel trip) async {
    if (_routePoints.isEmpty) {
      return;
    }

    final distance = PolylineUtils.distanceToPolyline(driverPos, _routePoints);
    final bool isOffRoute = distance > deviationThresholdMeters;

    if (isOffRoute) {
      final now = DateTime.now();
      final shouldNotify =
          !_isCurrentlyOffRoute ||
          _lastDeviationNotificationAt == null ||
          now.difference(_lastDeviationNotificationAt!) >=
              deviationNotificationCooldown;

      if (shouldNotify) {
        _lastDeviationNotificationAt = now;
        await _notifyParentOffRoute(trip, driverPos, distance);
        
        // Also log as safety event if service is available
        await _logOffRoadSafetyEvent(trip, driverPos, distance);
      }
    }

    _isCurrentlyOffRoute = isOffRoute;
  }

  /// Log off-road detection as a safety event
  Future<void> _logOffRoadSafetyEvent(
    TripModel trip,
    LatLng position,
    double distanceMeters,
  ) async {
    final safetyService = _safetyEventService;
    if (safetyService == null) {
      // Safety event service not available, skip
      return;
    }

    try {
      final event = SafetyEvent(
        type: SafetyEventType.offRoad,
        tripId: trip.id,
        driverId: trip.driverId,
        parentId: trip.parentId,
        message: 'off_road_detected_description'.tr,
        location: {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      );

      await safetyService.logSafetyEvent(event);
    } catch (e) {
      if (AppConfig.isDebugMode) {
        debugPrint('Failed to log off-road safety event: $e');
      }
      // Don't throw - safety event logging failure shouldn't block tracking
    }
  }

  /// Detect unexpected stops during trip
  Future<void> _detectUnexpectedStop(Position position, TripModel trip) async {
    // Check if vehicle has stopped (speed near zero)
    if (position.speed > 1.0) {
      // Vehicle is moving, reset stop detection
      _lastStopDetectionAt = null;
      return;
    }

    // Vehicle appears to be stopped
    final now = DateTime.now();
    if (_lastStopDetectionAt == null) {
      // Just started stopping, mark the time
      _lastStopDetectionAt = now;
      return;
    }

    // Check if we've been stopped for longer than the threshold
    final stopDuration = now.difference(_lastStopDetectionAt!);
    if (stopDuration < unexpectedStopDetectionDuration) {
      // Not stopped long enough yet
      return;
    }

    // Check if we're near expected stops (pickup/dropoff locations)
    final distanceToPickup = PolylineUtils.distanceBetween(
      LatLng(position.latitude, position.longitude),
      LatLng(trip.pickupLocation.latitude, trip.pickupLocation.longitude),
    );
    final distanceToDropoff = PolylineUtils.distanceBetween(
      LatLng(position.latitude, position.longitude),
      LatLng(trip.dropoffLocation.latitude, trip.dropoffLocation.longitude),
    );

    // If we're near pickup or dropoff, this is an expected stop
    if (distanceToPickup < 50 || distanceToDropoff < 50) {
      _lastStopDetectionAt = null; // Reset, this is expected
      return;
    }

    // Check cooldown to avoid spamming notifications
    final lastStopEvent = _lastStopDetectionAt;
    if (lastStopEvent != null &&
        now.difference(lastStopEvent) < unexpectedStopCooldown) {
      return;
    }

    // Log unexpected stop safety event
    await _logUnexpectedStopSafetyEvent(trip, position);
    _lastStopDetectionAt = now; // Update to prevent duplicate events
  }

  /// Log unexpected stop as a safety event
  Future<void> _logUnexpectedStopSafetyEvent(
    TripModel trip,
    Position position,
  ) async {
    final safetyService = _safetyEventService;
    if (safetyService == null) {
      return;
    }

    try {
      final event = SafetyEvent(
        type: SafetyEventType.unexpectedStop,
        tripId: trip.id,
        driverId: trip.driverId,
        parentId: trip.parentId,
        message: 'unexpected_stop_detected_description'.tr,
        location: {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      );

      await safetyService.logSafetyEvent(event);
    } catch (e) {
      if (AppConfig.isDebugMode) {
        debugPrint('Failed to log unexpected stop safety event: $e');
      }
      // Don't throw - safety event logging failure shouldn't block tracking
    }
  }

  Future<void> _notifyParentOffRoute(
    TripModel trip,
    LatLng position,
    double distanceMeters,
  ) async {
    final roadName = await _reverseGeocodeRoad(position);

    try {
      await _firestore.collection('trip_deviation_logs').add({
        'tripId': trip.id,
        'subscriptionId': trip.subscriptionId,
        'driverId': trip.driverId,
        'parentId': trip.parentId,
        'createdAt': DateTime.now().toIso8601String(),
        'distanceMeters': distanceMeters,
        'roadName': roadName,
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      });
    } catch (e) {
      if (AppConfig.isDebugMode) {
        debugPrint('Failed to log deviation: $e');
      }
    }

    await _notificationService.sendNotificationToUser(
      userId: trip.parentId,
      title: 'driver_off_route_title'.tr,
      body: 'driver_off_route_message'.trParams({
        'distance': distanceMeters.toStringAsFixed(0),
        'road': roadName ?? 'unknown_road'.tr,
      }),
      type: NotificationService.driverAssignedType,
      data: {
        'tripId': trip.id,
        'subscriptionId': trip.subscriptionId,
        'event': 'off_route',
      },
    );
  }

  Future<void> _maybeUpdateRoadName(LatLng position) async {
    final now = DateTime.now();
    if (_lastRoadUpdateAt != null &&
        now.difference(_lastRoadUpdateAt!) < roadNameRefreshInterval) {
      return;
    }

    final roadName = await _reverseGeocodeRoad(position);
    if (roadName != null) {
      currentRoadName.value = roadName;
      _lastRoadUpdateAt = now;
    }
  }

  Future<String?> _reverseGeocodeRoad(LatLng position) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return placemark.street?.isNotEmpty == true
            ? placemark.street
            : placemark.name;
      }
    } catch (e) {
      if (AppConfig.isDebugMode) {
        debugPrint('Reverse geocode failed: $e');
      }
    }
    return null;
  }

  Future<void> runTripStatusTransition(
    TripModel trip,
    TripStatus newStatus,
    SubscriptionStatus subscriptionStatus,
  ) async {
    final doc = _firestore.collection('trips').doc(trip.id);
    final subscriptionDoc = _firestore
        .collection('subscriptions')
        .doc(trip.subscriptionId);

    await _firestore.runTransaction((transaction) async {
      transaction.update(doc, {
        'status': newStatus.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      transaction.update(subscriptionDoc, {
        'status': subscriptionStatus.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });
  }
}
