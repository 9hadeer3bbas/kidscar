import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kidscar/core/managers/color_manager.dart';
import 'package:kidscar/core/utils/polyline_utils.dart';
import 'package:kidscar/core/utils/marker_utils.dart';
import 'package:kidscar/data/models/subscription_model.dart';
import 'package:kidscar/data/models/trip_model.dart';
import 'package:kidscar/data/models/user_model.dart';
import 'package:kidscar/domain/core/result.dart';
import 'package:kidscar/domain/entities/route_path.dart';
import 'package:kidscar/domain/usecases/location/get_route_path_usecase.dart';
import 'package:kidscar/domain/value_objects/geo_point.dart' as domain_geo;
import 'package:url_launcher/url_launcher.dart';
import 'package:kidscar/core/services/rtc_streaming_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kidscar/core/utils/firestore_retry_helper.dart';

class ParentTripDetailController extends GetxController {
  ParentTripDetailController(this.trip);

  final TripModel trip;

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
  final RxBool isRouteLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxSet<Marker> markerSet = <Marker>{}.obs;
  final RxSet<Polyline> polylineSet = <Polyline>{}.obs;

  bool _isInitializing = false;

  // Real-time tracking
  final Rx<LatLng?> currentDriverLocation = Rx<LatLng?>(null);
  final RxList<Map<String, dynamic>> safetyEvents =
      <Map<String, dynamic>>[].obs;
  final RxMap<String, LatLng> kidsLocations = <String, LatLng>{}.obs;

  // Driver information
  final Rx<UserModel?> driverInfo = Rx<UserModel?>(null);
  final RxBool isLoadingDriver = false.obs;

  StreamSubscription<QuerySnapshot>? _locationSubscription;
  StreamSubscription<QuerySnapshot>? _safetyEventsSubscription;
  StreamSubscription<DocumentSnapshot>? _tripSubscription;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GetRoutePathUseCase _getRoutePathUseCase =
      Get.find<GetRoutePathUseCase>();
  final RtcStreamingService _rtcService = Get.find<RtcStreamingService>();
  GoogleMapController? _mapController;

  StreamSubscription<DocumentSnapshot>? _rtcSignalingSubscription;

  bool get isActiveTrip {
    final status = currentTrip.value.status;
    return status == TripStatus.accepted ||
        status == TripStatus.enRoutePickup ||
        status == TripStatus.enRouteDropoff;
  }

  @override
  void onInit() {
    super.onInit();
    currentTrip.value = trip;
    _initializeMap();
    _listenToTripUpdates();
    _loadDriverInfo();
    // Check if trip is active after setting currentTrip
    if (isActiveTrip) {
      _startRealTimeTracking();
    }
  }

  @override
  void onClose() {
    _locationSubscription?.cancel();
    _safetyEventsSubscription?.cancel();
    _tripSubscription?.cancel();
    _rtcSignalingSubscription?.cancel();
    _mapController?.dispose();
    super.onClose();
  }

  CameraPosition get initialCameraPosition {
    final pickup = currentTrip.value.pickupLocation;
    return CameraPosition(
      target: LatLng(pickup.latitude, pickup.longitude),
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

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Ensure route is loaded when map is ready
    if (polylineSet.isEmpty) {
      _initializeMap();
    }
    _fitCameraToBounds();
  }

  Future<void> refreshTrip() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('trips')
          .doc(trip.id)
          .get();
      if (doc.exists) {
        currentTrip.value = TripModel.fromFirestore(doc);
        await _initializeMap(force: true);
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _initializeMap({bool force = false}) async {
    // Prevent duplicate initialization unless forced
    if (_isInitializing && !force) return;
    _isInitializing = true;

    try {
      polylineSet.clear();

      // For completed trips, try to load actual route from locations collection
      if (currentTrip.value.status == TripStatus.completed) {
        await _loadActualRouteFromLocations();
      }

      // If no actual route found or trip not completed, use planned route
      if (polylineSet.isEmpty) {
        if (currentTrip.value.encodedPolyline?.isNotEmpty == true) {
          _addPolylineFromEncoded(
            currentTrip.value.encodedPolyline!,
            isActualRoute: false,
          );
        } else {
          await _loadRouteFromApi();
        }
      }

      _updateMarkers();
      _fitCameraToBounds();
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _loadActualRouteFromLocations() async {
    try {
      final locationsSnapshot = await _firestore
          .collection('trips')
          .doc(trip.id)
          .collection('locations')
          .orderBy('timestamp', descending: false)
          .get();

      if (locationsSnapshot.docs.isNotEmpty) {
        final routePoints = <LatLng>[];
        for (var doc in locationsSnapshot.docs) {
          final data = doc.data();
          final lat = data['latitude'] as double?;
          final lng = data['longitude'] as double?;
          if (lat != null && lng != null) {
            routePoints.add(LatLng(lat, lng));
          }
        }

        if (routePoints.length >= 2) {
          // Add actual route polyline
          polylineSet.add(
            Polyline(
              polylineId: const PolylineId('actual_route'),
              color: const Color(0xFF43A047), // Green for actual route
              width: 6,
              points: routePoints,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            ),
          );

          // Also add planned route if available for comparison
          if (currentTrip.value.encodedPolyline?.isNotEmpty == true) {
            _addPolylineFromEncoded(
              currentTrip.value.encodedPolyline!,
              isActualRoute: false,
            );
          }

          polylineSet.refresh();
        }
      }
    } catch (e) {
      // If loading actual route fails, fall back to planned route
      if (currentTrip.value.encodedPolyline?.isNotEmpty == true) {
        _addPolylineFromEncoded(
          currentTrip.value.encodedPolyline!,
          isActualRoute: false,
        );
      }
    }
  }

  void _addPolylineFromEncoded(String encoded, {bool isActualRoute = false}) {
    final points = PolylineUtils.decodePolyline(encoded);
    polylineSet.add(
      Polyline(
        polylineId: PolylineId(
          isActualRoute ? 'actual_route' : 'planned_route',
        ),
        color: isActualRoute
            ? const Color(0xFF43A047) // Green for actual route
            : ColorManager.primaryColor.withValues(
                alpha: 0.5,
              ), // Lighter for planned
        width: isActualRoute ? 6 : 4,
        points: points,
        patterns: isActualRoute
            ? [PatternItem.dash(20), PatternItem.gap(10)]
            : [],
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
        _addPolylineFromEncoded(route.encodedPolyline, isActualRoute: false);
        currentTrip.value = currentTrip.value.copyWith(
          encodedPolyline: route.encodedPolyline,
          distanceMeters: route.distanceMeters,
          durationSeconds: route.durationSeconds,
        );
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isRouteLoading.value = false;
    }
  }

  Future<void> _fitCameraToBounds() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_mapController == null || markerSet.length < 2) return;

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
    try {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 60),
      );
    } catch (_) {
      // ignore fit errors
    }
  }

  Color _statusColor(TripStatus status) {
    switch (status) {
      case TripStatus.completed:
        return const Color(0xFF43A047);
      case TripStatus.accepted:
      case TripStatus.enRoutePickup:
      case TripStatus.enRouteDropoff:
        return const Color(0xFF2196F3);
      case TripStatus.awaitingDriverResponse:
        return const Color(0xFFFF9800);
      case TripStatus.rejected:
      case TripStatus.cancelled:
        return const Color(0xFFF44336);
    }
  }

  String _statusLabel(TripStatus status) {
    switch (status) {
      case TripStatus.awaitingDriverResponse:
        return 'awaiting_driver'.tr;
      case TripStatus.accepted:
        return 'accepted'.tr;
      case TripStatus.rejected:
        return 'rejected'.tr;
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

  void _listenToTripUpdates() {
    _tripSubscription = _firestore
        .collection('trips')
        .doc(trip.id)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final updatedTrip = TripModel.fromFirestore(snapshot);
            final wasActive = isActiveTrip;
            currentTrip.value = updatedTrip;

            // Start tracking if trip just became active
            if (!wasActive && isActiveTrip) {
              _startRealTimeTracking();
            }
            // Stop tracking if trip is no longer active
            if (wasActive && !isActiveTrip) {
              _stopRealTimeTracking();
            }
          }
        });
  }

  void _startRealTimeTracking() {
    _listenToDriverLocation();
    _listenToSafetyEvents();
    _listenToKidsLocations();
  }

  void _stopRealTimeTracking() {
    _locationSubscription?.cancel();
    _safetyEventsSubscription?.cancel();
    currentDriverLocation.value = null;
    safetyEvents.clear();
    kidsLocations.clear();
    _updateMarkers();
  }

  void _listenToDriverLocation() {
    _locationSubscription?.cancel();
    _locationSubscription = _firestore
        .collection('trips')
        .doc(trip.id)
        .collection('locations')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final locationData = snapshot.docs.first.data();
            final lat = locationData['latitude'] as double?;
            final lng = locationData['longitude'] as double?;
            if (lat != null && lng != null) {
              currentDriverLocation.value = LatLng(lat, lng);
              _updateMarkers();
              _updateCameraToDriver();
            }
          }
        });
  }

  void _listenToSafetyEvents() {
    _safetyEventsSubscription?.cancel();
    _safetyEventsSubscription = _firestore
        .collection('trips')
        .doc(trip.id)
        .collection('safety_events')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
          final events = <Map<String, dynamic>>[];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            events.add({
              'id': doc.id,
              'type': data['type'] ?? '',
              'message': data['message'] ?? '',
              'location': data['location'],
              'timestamp': data['timestamp'] ?? data['createdAt'],
            });
          }
          safetyEvents.value = events;
          _updateMarkers();
        });
  }

  void _listenToKidsLocations() {
    // Listen to kids locations if they're tracked
    // This would be in a subcollection like trips/{tripId}/kids_locations/{kidId}
    for (final kidId in trip.kidIds) {
      _firestore
          .collection('trips')
          .doc(trip.id)
          .collection('kids_locations')
          .doc(kidId)
          .snapshots()
          .listen((snapshot) {
            if (snapshot.exists) {
              final data = snapshot.data();
              final lat = data?['latitude'] as double?;
              final lng = data?['longitude'] as double?;
              if (lat != null && lng != null) {
                kidsLocations[kidId] = LatLng(lat, lng);
                _updateMarkers();
              }
            }
          });
    }
  }

  void _updateMarkers() {
    markerSet.clear();

    // Pickup marker
    final pickup = currentTrip.value.pickupLocation;
    markerSet.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(pickup.latitude, pickup.longitude),
        infoWindow: InfoWindow(title: pickup.name),
        icon: MarkerUtils.getPickupMarker(),
      ),
    );

    // Dropoff marker
    final dropoff = currentTrip.value.dropoffLocation;
    markerSet.add(
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(dropoff.latitude, dropoff.longitude),
        infoWindow: InfoWindow(title: dropoff.name),
        icon: MarkerUtils.getDropoffMarker(),
      ),
    );

    // Driver location marker (if available)
    if (currentDriverLocation.value != null) {
      markerSet.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: currentDriverLocation.value!,
          infoWindow: const InfoWindow(title: 'Driver Location'),
          icon: MarkerUtils.getDriverMarker(),
        ),
      );
    }

    // Kids location markers
    kidsLocations.forEach((kidId, location) {
      markerSet.add(
        Marker(
          markerId: MarkerId('kid_$kidId'),
          position: location,
          infoWindow: const InfoWindow(title: 'Kid Location'),
          icon: MarkerUtils.getKidMarker(),
        ),
      );
    });

    // Safety event markers
    for (var i = 0; i < safetyEvents.length; i++) {
      final event = safetyEvents[i];
      final location = event['location'] as Map<String, dynamic>?;
      if (location != null) {
        final lat = location['latitude'] as double?;
        final lng = location['longitude'] as double?;
        if (lat != null && lng != null) {
          final eventType = event['type'] as String? ?? '';
          double hue;
          if (eventType == 'loudSound') {
            hue = BitmapDescriptor.hueOrange;
          } else if (eventType == 'offRoad') {
            hue = BitmapDescriptor.hueRed;
          } else {
            hue = BitmapDescriptor.hueRed;
          }

          markerSet.add(
            Marker(
              markerId: MarkerId('safety_event_$i'),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: _getSafetyEventTitle(eventType),
                snippet: event['message'] as String? ?? '',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            ),
          );
        }
      }
    }

    markerSet.refresh();
  }

  String _getSafetyEventTitle(String eventType) {
    switch (eventType) {
      case 'loudSound':
        return 'loud_sound_detected'.tr;
      case 'offRoad':
        return 'off_road_detected'.tr;
      case 'unexpectedStop':
        return 'unexpected_stop_detected'.tr;
      default:
        return 'safety_event'.tr;
    }
  }

  Future<void> _updateCameraToDriver() async {
    if (_mapController == null || currentDriverLocation.value == null) return;

    try {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(currentDriverLocation.value!, 15),
      );
    } catch (_) {
      // ignore camera update errors
    }
  }

  Future<void> _loadDriverInfo() async {
    if (currentTrip.value.driverId.isEmpty) return;

    isLoadingDriver.value = true;
    try {
      final driverDoc = await _firestore
          .collection('users')
          .doc(currentTrip.value.driverId)
          .get();

      if (driverDoc.exists) {
        driverInfo.value = UserModel.fromFirestore(driverDoc);
      }
    } catch (e) {
      print('Error loading driver info: $e');
    } finally {
      isLoadingDriver.value = false;
    }
  }

  Future<void> callEmergency() async {
    final Uri phoneUri = Uri.parse('tel:911');
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'error'.tr,
          'cannot_make_phone_call'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_call_emergency'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> callDriver() async {
    if (driverInfo.value?.phoneNumber.isEmpty ?? true) {
      Get.snackbar(
        'error'.tr,
        'driver_phone_not_available'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final Uri phoneUri = Uri.parse('tel:${driverInfo.value!.phoneNumber}');
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'error'.tr,
          'cannot_make_phone_call'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_call_driver'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Request driver's camera stream
  Future<void> requestDriverCamera() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        Get.snackbar(
          'error'.tr,
          'user_not_authenticated'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (!isActiveTrip) {
        Get.snackbar(
          'error'.tr,
          'camera_only_available_active_trip'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Check network connectivity before attempting signaling
      print('🌐 Checking network connectivity...');
      final hasConnection = await FirestoreRetryHelper.hasConnectivity();
      if (!hasConnection) {
        Get.snackbar(
          'error'.tr,
          'no_internet_connection'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
        _rtcService.phase.value = RtcStreamingPhase.error;
        return;
      }
      print('✅ Network connectivity confirmed');

      final trip = currentTrip.value;
      final sessionId = '${trip.id}_${DateTime.now().millisecondsSinceEpoch}';

      // Create session metadata
      final metadata = RtcSessionMetadata(
        tripId: trip.id,
        driverId: trip.driverId,
        parentId: currentUser.uid,
        sessionId: sessionId,
      );

      // Request parent viewer (this will wait for driver's offer)
      final signalingPath = 'rtc_sessions/$sessionId';
      final signalingDoc = _firestore.doc(signalingPath);

      // Listen for driver's offer
      _rtcSignalingSubscription?.cancel();
      _rtcSignalingSubscription = signalingDoc.snapshots().listen(
        (snapshot) async {
          if (!snapshot.exists) return;

          final data = snapshot.data();
          if (data == null) return;

          final type = data['type'] as String?;
          final from = data['from'] as String?;
          final to = data['to'] as String?;
          final messageSessionId = data['sessionId'] as String?;

          // CRITICAL FIX: Check sessionId first to prevent cross-session message processing
          if (messageSessionId != null && messageSessionId != sessionId) {
            print('📹 Parent: Ignoring message from different session: $messageSessionId != $sessionId');
            return;
          }

          // CRITICAL FIX: Check 'to' field to ensure message is intended for this parent
          // Messages intended for parent should have to == currentUser.uid
          if (to != null && to != currentUser.uid) {
            print('📹 Parent: Ignoring message not intended for this parent: to=$to != parent.uid=$currentUser.uid');
            return;
          }

          // Only process messages from driver
          if (from != null && from != trip.driverId) {
            print('📹 Parent: Ignoring message from different driver: $from != ${trip.driverId}');
            return;
          }

          // Ignore messages from ourselves (parent)
          if (from == currentUser.uid) {
            print('📹 Parent: Ignoring own message (from parent)');
            return;
          }

          try {
            print('📹 Parent: Received signaling message: type=$type, from=$from, to=$to, sessionId=$messageSessionId');

            if (type == 'offer' && data['sdp'] != null) {
              print('📹 Driver sent offer, creating answer...');
              // Driver sent an offer, create answer
              final offer = rtc.RTCSessionDescription(
                data['sdp'] as String,
                data['sdpType'] as String? ?? 'offer',
              );

              // Set up ICE candidate listener BEFORE creating answer
              // This ensures we don't miss any candidates generated during answer creation
              _rtcService.onIceCandidate.listen((candidate) async {
                try {
                  print('📹 Sending ICE candidate to driver');
                  await FirestoreRetryHelper.executeWithRetry(
                    operation: () => signalingDoc.set({
                      'iceCandidate': {
                        'candidate': candidate.candidate,
                        'sdpMid': candidate.sdpMid,
                        'sdpMLineIndex': candidate.sdpMLineIndex,
                      },
                      'type': 'ice-candidate',
                      'from': currentUser.uid,
                      'to': trip.driverId,
                      'sessionId': sessionId,
                      'timestamp': DateTime.now().toIso8601String(),
                    }, SetOptions(merge: true)),
                    operationName: 'send-ice-candidate',
                    maxRetries: 2,
                  );
                } catch (e) {
                  print('❌ Error sending ICE candidate: $e');
                }
              });

              await _rtcService.requestParentViewer(metadata, offer);
              print('📹 Answer created and sent to driver');

              // Send answer back to driver
              // Use update() instead of set() to ensure answer isn't overwritten by ICE candidates
              final answerPayload = await _rtcService.buildSignalingPayload(
                extra: {
                  'type': 'answer',
                  'sdpType': 'answer', // Explicitly set sdpType as backup
                  'from': currentUser.uid,
                  'to': trip.driverId,
                  'sessionId': sessionId,
                  'timestamp': DateTime.now().toIso8601String(),
                },
              );

              // First send answer without merge to ensure it's set
              await FirestoreRetryHelper.executeWithRetry(
                operation: () => signalingDoc.set(answerPayload),
                operationName: 'send-answer',
                maxRetries: 3,
              );
              print(
                '📹 Answer sent to driver (SDP length: ${answerPayload['sdp']?.toString().length ?? 0})',
              );

              // Then allow ICE candidates to merge
            } else if (type == 'ice-candidate' &&
                data['iceCandidate'] != null) {
              print('📹 Parent: Received ICE candidate from driver (from=$from, to=$to)');
              // Add ICE candidate from driver
              final candidateData =
                  data['iceCandidate'] as Map<String, dynamic>;
              final candidate = rtc.RTCIceCandidate(
                candidateData['candidate'] as String,
                candidateData['sdpMid'] as String?,
                candidateData['sdpMLineIndex'] as int?,
              );
              await _rtcService.addRemoteIceCandidate(candidate);
            } else {
              print('📹 Parent: Unknown signaling message type: $type, hasSdp=${data['sdp'] != null}, hasIceCandidate=${data['iceCandidate'] != null}');
            }
          } catch (e) {
            print('❌ Error processing RTC signaling: $e');
            print('❌ Stack trace: ${StackTrace.current}');
            _rtcService.phase.value = RtcStreamingPhase.error;
          }
        },
        onError: (error) {
          print('❌ RTC signaling stream error: $error');

          // Provide user-friendly error message
          final errorMessage = FirestoreRetryHelper.getUserFriendlyErrorMessage(
            error,
          );
          Get.snackbar(
            'error'.tr,
            errorMessage,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 4),
          );

          _rtcService.phase.value = RtcStreamingPhase.error;
        },
      );

      // Send camera request to driver
      print('📹 Sending camera request to driver: ${trip.driverId}');
      print('📹 Session ID: $sessionId');
      print('📹 Trip ID: ${trip.id}');

      await FirestoreRetryHelper.executeWithRetry(
        operation: () => signalingDoc.set({
          'type': 'camera-request',
          'from': currentUser.uid,
          'to': trip.driverId,
          'tripId': trip.id,
          'sessionId': sessionId,
          'timestamp': DateTime.now().toIso8601String(),
          'metadata': metadata.toJson(),
        }),
        operationName: 'send-camera-request',
        maxRetries: 3,
      );

      print('📹 Camera request sent, waiting for driver response...');
      _rtcService.phase.value = RtcStreamingPhase.signaling;

      // Set timeout to clean up if no response (increased to 60s for NAT traversal)
      // Only delete if still in signaling phase (not connecting/connected)
      Future.delayed(const Duration(seconds: 60), () {
        final currentPhase = _rtcService.phase.value;
        if (currentPhase != RtcStreamingPhase.connected &&
            currentPhase != RtcStreamingPhase.signaling) {
          // Only timeout if we're in error state or still in signaling
          // If we're connecting, give it more time
          print('⏱️ Camera request timeout - phase: $currentPhase');
          if (currentPhase == RtcStreamingPhase.error) {
            signalingDoc.delete();
          }
        } else if (currentPhase == RtcStreamingPhase.signaling) {
          // Still in signaling after 60s - likely no response from driver
          print('⏱️ Camera request timeout - no response from driver');
          _rtcService.phase.value = RtcStreamingPhase.error;
          signalingDoc.delete();
        }
      });
    } catch (e, stackTrace) {
      print('❌ Error requesting driver camera: $e');
      print('❌ Stack trace: $stackTrace');

      final errorMessage = FirestoreRetryHelper.getUserFriendlyErrorMessage(e);
      Get.snackbar(
        'error'.tr,
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
      _rtcService.phase.value = RtcStreamingPhase.error;
    }
  }
}
