import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/utils/polyline_utils.dart';
import '../../../../core/utils/marker_utils.dart';
import '../../../../core/services/trip_tracking_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/rtc_streaming_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import '../../../../core/utils/firestore_retry_helper.dart';
import '../../../../data/models/route_poi.dart';
import '../../../../data/models/subscription_model.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../domain/core/result.dart';
import '../../../../domain/entities/route_path.dart';
import '../../../../domain/entities/route_poi_entity.dart';
import '../../../../domain/usecases/location/get_route_path_usecase.dart';
import '../../../../domain/usecases/location/get_route_pois_usecase.dart';
import '../../../../domain/value_objects/geo_point.dart' as domain_geo;
import '../../../custom_widgets/custom_toast.dart';
import '../safety_event_dialog/safety_event_dialog_view.dart';
import 'driver_home_state.dart';
import 'selfie_verification_dialog.dart';

class DriverHomeController extends GetxController {
  DriverHomeController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TripTrackingService _trackingService = Get.find<TripTrackingService>();
  final GetRoutePathUseCase _getRoutePathUseCase =
      Get.find<GetRoutePathUseCase>();
  final GetRoutePoisUseCase _getRoutePoisUseCase =
      Get.find<GetRoutePoisUseCase>();

  final Rx<DriverHomeViewState> uiState = DriverHomeViewState.initial().obs;
  final Rx<GoogleMapController?> mapController = Rx<GoogleMapController?>(null);
  final RxBool isTogglingAvailability = false.obs;
  final RxSet<String> busyTripActions = <String>{}.obs;
  final RxBool isRefreshing = false.obs;
  final Rx<String?> focusingTripId = Rx<String?>(null);
  final RxBool isCompletingTrip = false.obs;

  final Map<String, List<LatLng>> _routePointsCache = {};
  final Map<String, Set<Marker>> _tripMarkersCache = {};
  final Map<String, Set<Polyline>> _tripPolylinesCache = {};
  final Map<String, List<RoutePoi>> _tripPoisCache = {};
  final Set<String> _knownInstantTripIds = <String>{};

  StreamSubscription<QuerySnapshot>? _tripsSubscription;
  StreamSubscription<DocumentSnapshot>? _driverProfileSubscription;
  StreamSubscription<QuerySnapshot>? _cameraRequestsSubscription;

  TripModel? _activeTrip;
  TripModel? _highlightedTrip;

  final RtcStreamingService _rtcService = Get.find<RtcStreamingService>();

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _tripsSubscription?.cancel();
    _driverProfileSubscription?.cancel();
    _cameraRequestsSubscription?.cancel();
    mapController.value?.dispose();
    super.onClose();
  }

  Future<void> _initialize() async {
    await Future.wait([_initLocation(), _listenToDriverProfile()]);
    _listenToTrips();
    _bindTrackingStreams();
    _listenToCameraRequests();
  }

  Future<void> _initLocation() async {
    try {
      uiState.value = uiState.value.copyWith(isLoadingLocation: true);

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position;
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (AppConfig.isDebugMode) {
          debugPrint('📍 Location permission denied, using fallback');
        }
        position = _fallbackPosition();
      } else {
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.best,
            ),
          ).timeout(const Duration(seconds: 8), onTimeout: _fallbackPosition);
        } catch (error) {
          if (AppConfig.isDebugMode) {
            debugPrint('⚠️ Failed to fetch location, fallback: $error');
          }
          position = _fallbackPosition();
        }
      }

      final target = LatLng(position.latitude, position.longitude);
      _updateDriverLocation(target);

      uiState.value = uiState.value.copyWith(
        driverLocation: target,
        cameraTarget: target,
        isLoadingLocation: false,
        resetError: true,
      );
      _updateScreenStatus();
    } catch (error) {
      if (AppConfig.isDebugMode) {
        debugPrint('❌ initLocation error: $error');
      }
      uiState.value = uiState.value.copyWith(
        isLoadingLocation: false,
        errorMessage: error.toString(),
      );
      _updateScreenStatus();
    }
  }

  Future<void> _listenToDriverProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    _driverProfileSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
          final data = snapshot.data();
          if (data == null) return;

          final isOnline = data['isOnline'] == true;
          uiState.value = uiState.value.copyWith(isOnline: isOnline);
        });
  }

  void _listenToTrips() {
    final user = _auth.currentUser;
    if (user == null) {
      uiState.value = uiState.value.copyWith(
        isLoadingTrips: false,
        errorMessage: 'user_not_authenticated'.tr,
      );
      _updateScreenStatus();
      return;
    }

    uiState.value = uiState.value.copyWith(isLoadingTrips: true);
    _tripsSubscription = _firestore
        .collection('trips')
        .where('driverId', isEqualTo: user.uid)
        .snapshots()
        .listen(
          (snapshot) async {
            final trips = snapshot.docs.map(TripModel.fromFirestore).toList();
            final scheduled = <TripModel>[];
            final instant = <TripModel>[];
            final inProgress = <TripModel>[];
            TripModel? active;

            for (final trip in trips) {
              if (trip.subscriptionId == 'instant_ride') {
                if (_isAwaitingStatus(trip.status)) {
                  instant.add(trip);
                } else if (_isInProgressStatus(trip.status)) {
                  inProgress.add(trip);
                }
              } else {
                // Only show accepted trips in scheduled, not awaitingDriverResponse
                // awaitingDriverResponse trips should only show in pending tab (trips page)
                if (trip.status == TripStatus.accepted) {
                  scheduled.add(trip);
                } else if (_isInProgressStatus(trip.status)) {
                  inProgress.add(trip);
                }
              }

              if (_isInProgressStatus(trip.status)) {
                active ??= trip;
              }
            }

            scheduled.sort(
              (a, b) => a.scheduledDate.compareTo(b.scheduledDate),
            );
            instant.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
            inProgress.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

            _activeTrip = active;
            final highlighted = _determineHighlightedTrip(
              scheduled: scheduled,
              instant: instant,
              inProgress: inProgress,
            );
            _highlightedTrip = highlighted;

            uiState.value = uiState.value.copyWith(
              scheduledTrips: scheduled,
              instantTrips: instant,
              inProgressTrips: inProgress,
              highlightedTrip: highlighted,
              activeTab: _determineActiveTab(highlighted),
              isLoadingTrips: false,
            );

            _refreshTripVisuals(highlighted);
            _updateInstantRideNotifications(instant);
            _updateScreenStatus();
          },
          onError: (error) {
            uiState.value = uiState.value.copyWith(
              isLoadingTrips: false,
              errorMessage: error.toString(),
            );
            _updateScreenStatus();
          },
        );
  }

  void _bindTrackingStreams() {
    ever<LatLng?>(_trackingService.currentDriverPosition, (position) {
      if (position == null) return;
      _updateDriverLocation(position);
      _refreshTripVisuals(_highlightedTrip);
    });

    ever<String>(_trackingService.currentRoadName, (road) {
      uiState.value = uiState.value.copyWith(roadName: road);
    });

    ever<bool>(_trackingService.trackingActive, (tracking) {
      uiState.value = uiState.value.copyWith(
        isTracking: tracking,
        showSimulationFab: tracking || AppConfig.isDebugMode,
      );
      if (!tracking) {
        _activeTrip = null;
      }
    });

    ever<bool>(_trackingService.simulationModeActive, (simActive) {
      uiState.value = uiState.value.copyWith(
        isSimulating: simActive,
        showSimulationFab:
            simActive || uiState.value.isTracking || AppConfig.isDebugMode,
      );
    });

    ever<int>(_trackingService.simulationProgress, (progress) {
      uiState.value = uiState.value.copyWith(simulationStep: progress);
    });

    ever<int>(_trackingService.simulationTotal, (total) {
      uiState.value = uiState.value.copyWith(simulationTotal: total);
    });

    ever<double>(_trackingService.simulationSpeedMetersPerSecond, (speed) {
      uiState.value = uiState.value.copyWith(simulationSpeedKmh: (speed * 3.6));
    });

    ever<List<RoutePoi>>(_trackingService.livePois, (pois) {
      uiState.value = uiState.value.copyWith(pois: pois);
    });
  }

  void _listenToCameraRequests() {
    final driver = _auth.currentUser;
    if (driver == null) return;

    // Listen for camera requests sent to this driver
    _cameraRequestsSubscription = _firestore
        .collection('rtc_sessions')
        .where('to', isEqualTo: driver.uid)
        .where('type', isEqualTo: 'camera-request')
        .snapshots()
        .listen(
          (snapshot) async {
            for (final doc in snapshot.docs) {
              final data = doc.data();
              final tripId = data['tripId'] as String?;
              final sessionId = data['sessionId'] as String?;
              final from = data['from'] as String?;
              final metadataJson = data['metadata'] as Map<String, dynamic>?;

              if (tripId == null || sessionId == null || from == null) {
                continue;
              }

              // Only respond to requests for active trips
              if (_activeTrip == null || _activeTrip!.id != tripId) {
                if (AppConfig.isDebugMode) {
                  debugPrint(
                    '📹 Ignoring camera request - no active trip or trip mismatch',
                  );
                }
                continue;
              }

              // Verify the request is from the parent of this trip
              if (_activeTrip!.parentId != from) {
                if (AppConfig.isDebugMode) {
                  debugPrint('📹 Ignoring camera request - parent ID mismatch');
                }
                continue;
              }

              try {
                if (AppConfig.isDebugMode) {
                  debugPrint(
                    '📹 Received camera request for active trip: $tripId',
                  );
                  debugPrint('📹 Session ID: $sessionId');
                }

                // Check network connectivity before attempting signaling
                if (AppConfig.isDebugMode) {
                  debugPrint('🌐 Checking network connectivity...');
                }
                final hasConnection =
                    await FirestoreRetryHelper.hasConnectivity();
                if (!hasConnection) {
                  if (AppConfig.isDebugMode) {
                    debugPrint(
                      '❌ No network connectivity, ignoring camera request',
                    );
                  }
                  continue;
                }
                if (AppConfig.isDebugMode) {
                  debugPrint('✅ Network connectivity confirmed');
                }

                // Parse metadata
                RtcSessionMetadata? metadata;
                if (metadataJson != null) {
                  metadata = RtcSessionMetadata(
                    tripId: metadataJson['tripId'] as String,
                    driverId: metadataJson['driverId'] as String,
                    parentId: metadataJson['parentId'] as String,
                    sessionId: metadataJson['sessionId'] as String,
                    customData:
                        metadataJson['customData'] as Map<String, dynamic>?,
                  );
                } else {
                  // Create metadata from request data
                  metadata = RtcSessionMetadata(
                    tripId: tripId,
                    driverId: driver.uid,
                    parentId: from,
                    sessionId: sessionId,
                  );
                }

                // Get signaling path before starting broadcast
                final signalingPath = 'rtc_sessions/$sessionId';
                final signalingDoc = _firestore.doc(signalingPath);

                // Set up ICE candidate listener BEFORE starting broadcast
                // This ensures we don't miss any candidates generated during offer creation
                StreamSubscription? iceCandidateSub;
                iceCandidateSub = _rtcService.onIceCandidate.listen((
                  candidate,
                ) async {
                  try {
                    if (AppConfig.isDebugMode) {
                      debugPrint('📹 Sending ICE candidate to parent');
                    }
                    await FirestoreRetryHelper.executeWithRetry(
                      operation: () => signalingDoc.set({
                        'iceCandidate': {
                          'candidate': candidate.candidate,
                          'sdpMid': candidate.sdpMid,
                          'sdpMLineIndex': candidate.sdpMLineIndex,
                        },
                        'type': 'ice-candidate',
                        'from': driver.uid,
                        'to': from,
                        'sessionId': sessionId,
                        'timestamp': DateTime.now().toIso8601String(),
                      }, SetOptions(merge: true)),
                      operationName: 'send-ice-candidate',
                      maxRetries: 2,
                    );
                  } catch (e) {
                    if (AppConfig.isDebugMode) {
                      debugPrint('❌ Error sending ICE candidate: $e');
                    }
                  }
                });

                // Start driver broadcast (this creates the offer)
                final offer = await _rtcService.startDriverBroadcast(metadata);

                if (offer == null) {
                  iceCandidateSub.cancel();
                  if (AppConfig.isDebugMode) {
                    debugPrint('❌ Failed to create offer');
                  }
                  continue;
                }

                // Send offer to parent
                final offerPayload = await _rtcService.buildSignalingPayload(
                  extra: {
                    'type': 'offer',
                    'from': driver.uid,
                    'to': from,
                    'sessionId': sessionId,
                    'timestamp': DateTime.now().toIso8601String(),
                  },
                );

                await FirestoreRetryHelper.executeWithRetry(
                  operation: () =>
                      signalingDoc.set(offerPayload, SetOptions(merge: true)),
                  operationName: 'send-offer',
                  maxRetries: 3,
                );

                if (AppConfig.isDebugMode) {
                  debugPrint('📹 Offer sent to parent: $from');
                }

                // Track if we've already processed the answer (must be outside listener to persist)
                final answerProcessedRef = <String, bool>{};

                // Listen for answer from parent
                signalingDoc.snapshots().listen((snapshot) async {
                  if (!snapshot.exists) {
                    if (AppConfig.isDebugMode) {
                      debugPrint(
                        '📹 Driver: Signaling snapshot does not exist',
                      );
                    }
                    return;
                  }

                  final answerData = snapshot.data();
                  if (answerData == null) {
                    if (AppConfig.isDebugMode) {
                      debugPrint('📹 Driver: Signaling snapshot data is null');
                    }
                    return;
                  }

                  final type = answerData['type'] as String?;
                  final answerFrom = answerData['from'] as String?;
                  final answerTo = answerData['to'] as String?;
                  final messageSessionId = answerData['sessionId'] as String?;

                  if (AppConfig.isDebugMode) {
                    debugPrint(
                      '📹 Driver: Received signaling message: type=$type, from=$answerFrom, to=$answerTo, sessionId=$messageSessionId, expectedSessionId=$sessionId, driverId=$driver.uid',
                    );
                  }

                  // CRITICAL FIX: Check sessionId first to prevent cross-session message processing
                  if (messageSessionId != null &&
                      messageSessionId != sessionId) {
                    if (AppConfig.isDebugMode) {
                      debugPrint(
                        '📹 Driver: Ignoring message from different session: $messageSessionId != $sessionId',
                      );
                    }
                    return;
                  }

                  // CRITICAL FIX: Check 'to' field to ensure message is intended for this driver
                  // Messages intended for driver should have to == driver.uid
                  if (answerTo != null && answerTo != driver.uid) {
                    if (AppConfig.isDebugMode) {
                      debugPrint(
                        '📹 Driver: Ignoring message not intended for this driver: to=$answerTo != driver.uid=$driver.uid',
                      );
                    }
                    return;
                  }

                  // Ignore messages from ourselves (driver)
                  if (answerFrom == driver.uid) {
                    if (AppConfig.isDebugMode) {
                      debugPrint(
                        '📹 Driver: Ignoring own message (from driver)',
                      );
                    }
                    return;
                  }

                  // Only process messages from the requesting parent
                  if (answerFrom != null && answerFrom != from) {
                    if (AppConfig.isDebugMode) {
                      debugPrint(
                        '📹 Driver: Ignoring message from different parent: $answerFrom != $from',
                      );
                    }
                    return;
                  }

                  try {
                    // Check for answer/offer FIRST (by checking for SDP)
                    // This is important because ICE candidates might overwrite the 'type' field
                    if (answerData['sdp'] != null) {
                      final sdpType =
                          answerData['sdpType'] as String? ??
                          answerData['type'] as String? ??
                          'answer';

                      // Only process answers (we already sent the offer)
                      if (sdpType == 'answer' || type == 'answer') {
                        if (answerProcessedRef[sessionId] == true) {
                          if (AppConfig.isDebugMode) {
                            debugPrint(
                              '📹 Driver: Answer already processed, ignoring duplicate',
                            );
                          }
                          return;
                        }

                        if (AppConfig.isDebugMode) {
                          debugPrint('📹 Received answer from parent');
                          debugPrint(
                            '📹 Answer SDP length: ${answerData['sdp'].toString().length}',
                          );
                        }

                        answerProcessedRef[sessionId] =
                            true; // Mark as processed

                        final answer = rtc.RTCSessionDescription(
                          answerData['sdp'] as String,
                          'answer',
                        );

                        await _rtcService.completeDriverBroadcast(answer);

                        if (AppConfig.isDebugMode) {
                          debugPrint('📹 Connection established with parent');
                        }
                        return; // Don't process ICE candidates in the same snapshot
                      }
                    }

                    // Check for ICE candidates
                    if (type == 'ice-candidate' &&
                        answerData['iceCandidate'] != null) {
                      if (AppConfig.isDebugMode) {
                        debugPrint(
                          '📹 Driver: Received ICE candidate from parent (from=$answerFrom, to=$answerTo)',
                        );
                      }

                      final candidateData =
                          answerData['iceCandidate'] as Map<String, dynamic>;
                      final candidate = rtc.RTCIceCandidate(
                        candidateData['candidate'] as String,
                        candidateData['sdpMid'] as String?,
                        candidateData['sdpMLineIndex'] as int?,
                      );
                      await _rtcService.addRemoteIceCandidate(candidate);
                    } else {
                      if (AppConfig.isDebugMode) {
                        debugPrint(
                          '📹 Driver: Unknown or incomplete signaling message: type=$type, hasSdp=${answerData['sdp'] != null}, hasIceCandidate=${answerData['iceCandidate'] != null}',
                        );
                      }
                    }
                  } catch (e, stackTrace) {
                    if (AppConfig.isDebugMode) {
                      debugPrint('❌ Error processing parent signaling: $e');
                      debugPrint('❌ Stack trace: $stackTrace');
                    }
                  }
                });
              } catch (e, stackTrace) {
                if (AppConfig.isDebugMode) {
                  debugPrint('❌ Error handling camera request: $e');
                  debugPrint('❌ Stack trace: $stackTrace');
                }
              }
            }
          },
          onError: (error) {
            if (AppConfig.isDebugMode) {
              debugPrint('❌ Camera requests stream error: $error');
            }
          },
        );
  }

  void _updateScreenStatus() {
    final current = uiState.value;
    final hasError = (current.errorMessage ?? '').isNotEmpty;
    final status = current.isLoadingLocation || current.isLoadingTrips
        ? DriverHomeScreenStatus.loading
        : hasError
        ? DriverHomeScreenStatus.error
        : DriverHomeScreenStatus.ready;
    uiState.value = current.copyWith(status: status);
  }

  void _updateDriverLocation(LatLng position) {
    final markers = uiState.value.mapMarkers.toSet()
      ..removeWhere((marker) => marker.markerId.value == 'driver');
    markers.add(
      Marker(
        markerId: const MarkerId('driver'),
        position: position,
        icon: MarkerUtils.getDriverMarker(),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );
    uiState.value = uiState.value.copyWith(
      driverLocation: position,
      mapMarkers: markers,
    );
  }

  Future<void> changeTab(DriverHomeTripTab tab) async {
    uiState.value = uiState.value.copyWith(activeTab: tab);
    TripModel? candidate;
    switch (tab) {
      case DriverHomeTripTab.scheduled:
        candidate = uiState.value.scheduledTrips.firstOrNull;
        break;
      case DriverHomeTripTab.instant:
        candidate = uiState.value.instantTrips.firstOrNull;
        break;
      case DriverHomeTripTab.inProgress:
        candidate = uiState.value.inProgressTrips.firstOrNull ?? _activeTrip;
        break;
    }
    if (candidate != null) {
      await selectTrip(candidate);
    } else {
      _highlightedTrip = null;
      _refreshTripVisuals(null);
    }
  }

  Future<void> selectTrip(TripModel trip) async {
    _highlightedTrip = trip;
    uiState.value = uiState.value.copyWith(
      highlightedTrip: trip,
      tripPanelCollapsed: false,
    );
    await _ensureTripArtifacts(trip);
    _refreshTripVisuals(trip);
  }

  Future<void> focusOnDriver() async {
    final controller = mapController.value;
    final position = uiState.value.driverLocation;
    if (controller == null || position == null) return;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 15, tilt: 18),
      ),
    );
  }

  Future<void> focusOnTrip(TripModel trip, {bool collapsePanel = false}) async {
    if (focusingTripId.value == trip.id) return;
    focusingTripId.value = trip.id;
    try {
      await selectTrip(trip);
      _animateCameraToTrip(trip);
      if (collapsePanel) {
        setTripPanelCollapsed(true);
      }
    } finally {
      focusingTripId.value = null;
    }
  }

  Future<void> toggleAvailability() async {
    if (isTogglingAvailability.value) return;
    final user = _auth.currentUser;
    if (user == null) return;

    final newStatus = !uiState.value.isOnline;
    isTogglingAvailability.value = true;
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': newStatus,
        'lastOnlineStatusChange': DateTime.now().toIso8601String(),
      });
      uiState.value = uiState.value.copyWith(isOnline: newStatus);
      CustomToasts(
        message: newStatus
            ? 'driver_online_message'.tr
            : 'driver_offline_message'.tr,
        type: newStatus ? CustomToastType.success : CustomToastType.warning,
      ).show();
    } catch (error) {
      CustomToasts(
        message: 'failed_to_update_status'.tr,
        type: CustomToastType.error,
      ).show();
    } finally {
      isTogglingAvailability.value = false;
    }
  }

  Future<void> acceptInstantRide(TripModel trip) async {
    if (busyTripActions.contains(trip.id)) return;
    busyTripActions.add(trip.id);
    try {
      await _updateTripStatus(
        trip,
        newStatus: TripStatus.accepted,
        subscriptionStatus: trip.subscriptionId == 'instant_ride'
            ? null
            : SubscriptionStatus.driverAssigned,
      );
      CustomToasts(
        message: 'ride_accepted_success'.tr,
        type: CustomToastType.success,
      ).show();
    } catch (error) {
      CustomToasts(
        message: error.toString(),
        type: CustomToastType.error,
      ).show();
    } finally {
      busyTripActions.remove(trip.id);
    }
  }

  Future<void> declineInstantRide(TripModel trip) async {
    if (busyTripActions.contains(trip.id)) return;
    busyTripActions.add(trip.id);
    try {
      await _updateTripStatus(
        trip,
        newStatus: TripStatus.rejected,
        subscriptionStatus: trip.subscriptionId == 'instant_ride'
            ? null
            : SubscriptionStatus.driverRejected,
      );
      CustomToasts(
        message: 'ride_declined_success'.tr,
        type: CustomToastType.warning,
      ).show();
    } catch (error) {
      CustomToasts(
        message: error.toString(),
        type: CustomToastType.error,
      ).show();
    } finally {
      busyTripActions.remove(trip.id);
    }
  }

  Future<void> startTrip(TripModel trip) async {
    if (busyTripActions.contains(trip.id)) return;
    busyTripActions.add(trip.id);

    try {
      if (!uiState.value.isOnline) {
        CustomToasts(
          message: 'driver_must_be_online'.tr,
          type: CustomToastType.warning,
        ).show();
        return;
      }

      await _ensureTripArtifacts(trip);

      // Show selfie verification dialog (always required)
      Get.dialog(
        SelfieVerificationDialog(
          trip: trip,
          onVerified: () => _proceedWithTripStart(trip),
        ),
        barrierDismissible: false,
      );
    } catch (error) {
      CustomToasts(
        message: error.toString(),
        type: CustomToastType.error,
      ).show();
      await _trackingService.stopTracking();
    } finally {
      busyTripActions.remove(trip.id);
    }
  }

  Future<void> _proceedWithTripStart(TripModel trip) async {
    try {
      final routePoints = _routePointsCache[trip.id] ?? [];
      final pois = _tripPoisCache[trip.id] ?? [];

      if (routePoints.isEmpty) {
        throw 'route_not_ready'.tr;
      }

      final shouldSimulateRoute = AppConfig.isDebugMode;
      final pickupPoint = routePoints.first;

      // For real trips (not simulation), check if driver is near pickup location
      if (!shouldSimulateRoute) {
        final driverLocation = uiState.value.driverLocation;
        if (driverLocation != null) {
          final distance = Geolocator.distanceBetween(
            driverLocation.latitude,
            driverLocation.longitude,
            pickupPoint.latitude,
            pickupPoint.longitude,
          );

          // Require driver to be within 100 meters of pickup location
          const maxDistanceMeters = 100.0;
          if (distance > maxDistanceMeters) {
            CustomToasts(
              message: 'driver_too_far_from_pickup'.tr,
              type: CustomToastType.error,
            ).show();
            throw Exception(
              'Driver is ${distance.toStringAsFixed(0)}m away from pickup. Must be within ${maxDistanceMeters}m.',
            );
          }
        }
      }

      if (shouldSimulateRoute) {
        await _trackingService.seedInitialPosition(pickupPoint);
      }

      _updateDriverLocation(pickupPoint);
      _refreshTripVisuals(trip);
      _animateCameraToTrip(trip);

      await _trackingService.startTracking(
        trip: trip,
        routePoints: routePoints,
        pois: pois,
        simulationConfig: shouldSimulateRoute
            ? const TripSimulationConfig(
                scenario: SimulationScenario.normalRoute,
              )
            : null,
      );

      _activeTrip = trip;
      uiState.value = uiState.value.copyWith(
        activeTab: DriverHomeTripTab.inProgress,
      );

      await _updateTripStatus(
        trip,
        newStatus: TripStatus.enRoutePickup,
        subscriptionStatus: trip.subscriptionId == 'instant_ride'
            ? null
            : SubscriptionStatus.active,
      );

      CustomToasts(
        message: 'trip_started_success'.tr,
        type: CustomToastType.success,
      ).show();
      if (shouldSimulateRoute) {
        CustomToasts(
          message: 'trip_simulation_started'.tr,
          type: CustomToastType.warning,
        ).show();
      }
    } catch (error) {
      CustomToasts(
        message: error.toString(),
        type: CustomToastType.error,
      ).show();
      await _trackingService.stopTracking();
      rethrow;
    }
  }

  Future<void> completeActiveTrip([TripModel? tripParam]) async {
    // Use provided trip, fall back to _activeTrip, or try to find from inProgressTrips
    TripModel? trip = tripParam ?? _activeTrip;

    // If still null, try to get from inProgressTrips
    if (trip == null && uiState.value.inProgressTrips.isNotEmpty) {
      trip = uiState.value.inProgressTrips.first;
      if (AppConfig.isDebugMode) {
        debugPrint(
          '⚠️ _activeTrip is null, using first inProgress trip: ${trip.id}',
        );
      }
    }

    if (trip == null) {
      if (AppConfig.isDebugMode) {
        debugPrint('❌ Cannot complete trip: No active trip found');
        debugPrint('   _activeTrip: ${_activeTrip?.id}');
        debugPrint(
          '   inProgressTrips: ${uiState.value.inProgressTrips.length}',
        );
      }
      CustomToasts(
        message: 'no_active_trip'.tr,
        type: CustomToastType.error,
      ).show();
      return;
    }

    if (busyTripActions.contains(trip.id) || isCompletingTrip.value) {
      if (AppConfig.isDebugMode) {
        debugPrint('❌ Cannot complete trip: Trip is already being processed');
      }
      CustomToasts(
        message: 'trip_already_processing'.tr,
        type: CustomToastType.warning,
      ).show();
      return;
    }

    busyTripActions.add(trip.id);
    isCompletingTrip.value = true;

    try {
      if (AppConfig.isDebugMode) {
        debugPrint('✅ Starting trip completion for trip: ${trip.id}');
      }

      // Simulate checkout process
      await _simulateCheckout(trip);

      await _trackingService.stopTracking();
      await _updateTripStatus(
        trip,
        newStatus: TripStatus.completed,
        subscriptionStatus: trip.subscriptionId == 'instant_ride'
            ? null
            : SubscriptionStatus.completed,
      );
      _activeTrip = null;
      CustomToasts(
        message: 'trip_completed_success'.tr,
        type: CustomToastType.success,
      ).show();

      if (AppConfig.isDebugMode) {
        debugPrint('✅ Trip completed successfully');
      }
    } catch (error) {
      if (AppConfig.isDebugMode) {
        debugPrint('❌ Error completing trip: $error');
      }
      CustomToasts(
        message: error.toString(),
        type: CustomToastType.error,
      ).show();
    } finally {
      busyTripActions.remove(trip.id);
      isCompletingTrip.value = false;
    }
  }

  Future<void> _simulateCheckout(TripModel trip) async {
    // Simulate checkout/payment processing
    if (AppConfig.isDebugMode) {
      debugPrint('💳 Simulating checkout for trip ${trip.id}');
    }

    // Show a brief loading delay to simulate payment processing
    await Future.delayed(const Duration(milliseconds: 1500));

    // In a real app, this would process payment, update billing, etc.
    if (AppConfig.isDebugMode) {
      debugPrint('✅ Checkout simulation completed');
    }
  }

  Future<void> startSimulation(
    TripModel trip,
    SimulationScenario scenario,
  ) async {
    if (busyTripActions.contains(trip.id)) return;
    busyTripActions.add(trip.id);

    try {
      if (!uiState.value.isOnline) {
        CustomToasts(
          message: 'driver_must_be_online'.tr,
          type: CustomToastType.warning,
        ).show();
        return;
      }

      await _ensureTripArtifacts(trip);

      // Show selfie verification dialog before simulation (always required)
      Get.dialog(
        SelfieVerificationDialog(
          trip: trip,
          onVerified: () => _proceedWithSimulationStart(trip, scenario),
        ),
        barrierDismissible: false,
      );
    } catch (error) {
      CustomToasts(
        message: error.toString(),
        type: CustomToastType.error,
      ).show();
    } finally {
      busyTripActions.remove(trip.id);
    }
  }

  Future<void> _proceedWithSimulationStart(
    TripModel trip,
    SimulationScenario scenario,
  ) async {
    try {
      final routePoints = _routePointsCache[trip.id] ?? [];
      final pois = _tripPoisCache[trip.id] ?? [];

      // Seed initial position for simulation
      if (routePoints.isNotEmpty) {
        await _trackingService.seedInitialPosition(routePoints.first);
        _updateDriverLocation(routePoints.first);
      }

      await _trackingService.startTracking(
        trip: trip,
        routePoints: routePoints,
        pois: pois,
        simulationConfig: TripSimulationConfig(scenario: scenario),
      );

      _activeTrip = trip;
      _refreshTripVisuals(trip);
      _animateCameraToTrip(trip);

      uiState.value = uiState.value.copyWith(
        activeTab: DriverHomeTripTab.inProgress,
      );

      // Update trip status to enRoutePickup and send notification to parent
      await _updateTripStatus(
        trip,
        newStatus: TripStatus.enRoutePickup,
        subscriptionStatus: trip.subscriptionId == 'instant_ride'
            ? null
            : SubscriptionStatus.active,
      );

      // Send specific simulation notification to parent
      try {
        final notificationService = Get.find<NotificationService>();
        String simulationMessage;

        switch (scenario) {
          case SimulationScenario.normalRoute:
            simulationMessage = 'simulation_normal_started'.tr;
            break;
          case SimulationScenario.offRoute:
            simulationMessage = 'simulation_off_route_started'.tr;
            break;
          case SimulationScenario.heavyTraffic:
            simulationMessage = 'simulation_heavy_traffic_started'.tr;
            break;
        }

        await notificationService.sendNotificationToUser(
          userId: trip.parentId,
          title: 'trip_update'.tr,
          body: simulationMessage,
          type: NotificationService.tripReminderType,
          data: {
            'tripId': trip.id,
            'subscriptionId': trip.subscriptionId,
            'status': TripStatus.enRoutePickup.name,
            'simulation': 'true',
            'scenario': scenario.name,
          },
        );
        print('✅ Simulation notification sent to parent: $simulationMessage');
      } catch (e) {
        print('❌ Error sending simulation notification to parent: $e');
      }

      CustomToasts(
        message: 'trip_simulation_started'.tr,
        type: CustomToastType.success,
      ).show();
    } catch (error) {
      CustomToasts(
        message: error.toString(),
        type: CustomToastType.error,
      ).show();
      await _trackingService.stopTracking();
      rethrow;
    }
  }

  Future<void> stopSimulation() async {
    await _trackingService.stopTracking();
    uiState.value = uiState.value.copyWith(isSimulating: false);
  }

  void openSafetyActions() {
    final trip = _activeTrip ?? _highlightedTrip;
    if (trip == null) return;
    Get.dialog(SafetyEventDialog(trip: trip), barrierDismissible: true);
  }

  void toggleTripPanelCollapsed() {
    final current = uiState.value.isTripPanelCollapsed;
    setTripPanelCollapsed(!current);
  }

  void setTripPanelCollapsed(bool collapsed) {
    uiState.value = uiState.value.copyWith(tripPanelCollapsed: collapsed);
  }

  void onMapCreated(GoogleMapController controller) {
    mapController.value = controller;
    uiState.value = uiState.value.copyWith(mapReady: true);
    _refreshTripVisuals(_highlightedTrip ?? _activeTrip);
  }

  Future<void> retry() async {
    await _initLocation();
    isRefreshing.value = true;
    await Future.delayed(const Duration(milliseconds: 400));
    isRefreshing.value = false;
  }

  bool _isInProgressStatus(TripStatus status) {
    // Only trips that are actively being tracked are "in progress"
    return status == TripStatus.enRoutePickup ||
        status == TripStatus.enRouteDropoff;
  }

  bool _isAwaitingStatus(TripStatus status) {
    // Include both pending and accepted trips in scheduled/awaiting
    // Accepted trips should show in scheduled tab with start/simulate options
    return status == TripStatus.awaitingDriverResponse ||
        status == TripStatus.accepted;
  }

  Future<void> _updateTripStatus(
    TripModel trip, {
    required TripStatus newStatus,
    SubscriptionStatus? subscriptionStatus,
  }) async {
    await _firestore.collection('trips').doc(trip.id).update({
      'status': newStatus.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    if (subscriptionStatus != null && trip.subscriptionId != 'instant_ride') {
      await _firestore
          .collection('subscriptions')
          .doc(trip.subscriptionId)
          .update({
            'status': subscriptionStatus.name,
            'updatedAt': DateTime.now().toIso8601String(),
          });
    }

    // Send notification to parent for trip status changes
    if (newStatus == TripStatus.accepted ||
        newStatus == TripStatus.rejected ||
        newStatus == TripStatus.enRoutePickup ||
        newStatus == TripStatus.enRouteDropoff ||
        newStatus == TripStatus.completed) {
      try {
        final notificationService = Get.find<NotificationService>();
        String notificationMessage;
        String notificationType;

        switch (newStatus) {
          case TripStatus.accepted:
            notificationMessage = 'driver_accepted_trip'.tr;
            notificationType = NotificationService.driverAssignedType;
            break;
          case TripStatus.rejected:
            notificationMessage = 'driver_rejected_trip'.tr;
            notificationType = NotificationService.driverAssignedType;
            break;
          case TripStatus.enRoutePickup:
            notificationMessage = 'driver_on_route_pickup'.tr;
            notificationType = NotificationService.tripReminderType;
            break;
          case TripStatus.enRouteDropoff:
            notificationMessage = 'kids_picked_up'.tr;
            notificationType = NotificationService.tripReminderType;
            break;
          case TripStatus.completed:
            notificationMessage = 'trip_completed'.tr;
            notificationType = NotificationService.tripCompletedType;
            break;
          default:
            return; // Don't send notification for other statuses
        }

        await notificationService.sendNotificationToUser(
          userId: trip.parentId,
          title: 'trip_update'.tr,
          body: notificationMessage,
          type: notificationType,
          data: {
            'tripId': trip.id,
            'subscriptionId': trip.subscriptionId,
            'status': newStatus.name,
          },
        );
        print('✅ Notification sent to parent: $notificationMessage');
      } catch (e) {
        print('❌ Error sending notification to parent: $e');
        // Don't fail the trip status update if notification fails
      }
    }
  }

  void _refreshTripVisuals(TripModel? trip) {
    final driver = uiState.value.driverLocation;
    final markers = <Marker>{};

    if (driver != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: driver,
          icon: MarkerUtils.getDriverMarker(),
          infoWindow: const InfoWindow(title: 'You'),
        ),
      );
    }

    Set<Polyline> polylines = {};
    List<RoutePoi> pois = const [];

    if (trip != null) {
      final cachedMarkers = _tripMarkersCache[trip.id];
      if (cachedMarkers != null) {
        markers.addAll(cachedMarkers);
      }
      polylines = _tripPolylinesCache[trip.id] ?? {};
      pois = _tripPoisCache[trip.id] ?? const [];
    }

    uiState.value = uiState.value.copyWith(
      mapMarkers: markers,
      polylines: polylines,
      pois: pois,
    );
  }

  Future<void> _ensureTripArtifacts(TripModel trip) async {
    if (_routePointsCache.containsKey(trip.id)) {
      if (AppConfig.isDebugMode) {
        debugPrint('✅ Using cached route for trip ${trip.id}');
      }
      return;
    }

    try {
      final artifacts = await _buildTripArtifacts(trip);
      _routePointsCache[trip.id] = artifacts.points;
      _tripMarkersCache[trip.id] = artifacts.markers;
      _tripPolylinesCache[trip.id] = artifacts.polylines;
      _tripPoisCache[trip.id] = artifacts.pois;
      if (AppConfig.isDebugMode) {
        debugPrint('✅ Trip artifacts cached for ${trip.id}');
      }
    } catch (error, stackTrace) {
      debugPrint('⚠️ Failed to build trip artifacts for ${trip.id}: $error');
      debugPrint('$stackTrace');

      // Show user-friendly error if not already shown
      final errorMsg = error.toString().toLowerCase();
      if (!errorMsg.contains('route_empty') &&
          !errorMsg.contains('invalid') &&
          !errorMsg.contains('api key')) {
        CustomToasts(
          message: 'route_fetch_failed'.tr,
          type: CustomToastType.error,
        ).show();
      }

      // Ensure fallback route is available
      final fallbackPoints = _fallbackRoutePoints(trip);
      if (fallbackPoints.isNotEmpty) {
        _routePointsCache[trip.id] = fallbackPoints;
        _tripMarkersCache[trip.id] = {
          Marker(
            markerId: MarkerId('${trip.id}_pickup'),
            position: LatLng(
              trip.pickupLocation.latitude,
              trip.pickupLocation.longitude,
            ),
            icon: MarkerUtils.getPickupMarker(),
          ),
          Marker(
            markerId: MarkerId('${trip.id}_dropoff'),
            position: LatLng(
              trip.dropoffLocation.latitude,
              trip.dropoffLocation.longitude,
            ),
            icon: MarkerUtils.getDropoffMarker(),
          ),
        };
        _tripPolylinesCache[trip.id] = {
          Polyline(
            polylineId: PolylineId('${trip.id}_route'),
            points: fallbackPoints,
            width: 6,
            color: Colors.blueAccent,
          ),
        };
      }
    }
  }

  Future<_TripArtifacts> _buildTripArtifacts(TripModel trip) async {
    List<LatLng> points = const [];
    RoutePath? routePath;
    bool skipPois = false;

    // Validate trip location data
    final pickupLat = trip.pickupLocation.latitude;
    final pickupLng = trip.pickupLocation.longitude;
    final dropoffLat = trip.dropoffLocation.latitude;
    final dropoffLng = trip.dropoffLocation.longitude;

    if (AppConfig.isDebugMode) {
      debugPrint('🗺️ Building route for trip ${trip.id}');
      debugPrint(
        '📍 Pickup: ${trip.pickupLocation.name} ($pickupLat, $pickupLng)',
      );
      debugPrint(
        '📍 Dropoff: ${trip.dropoffLocation.name} ($dropoffLat, $dropoffLng)',
      );
    }

    // Check if coordinates are valid (not 0,0 and within valid ranges)
    final isValidPickup =
        pickupLat.abs() > 0.001 &&
        pickupLng.abs() > 0.001 &&
        pickupLat >= -90 &&
        pickupLat <= 90 &&
        pickupLng >= -180 &&
        pickupLng <= 180;
    final isValidDropoff =
        dropoffLat.abs() > 0.001 &&
        dropoffLng.abs() > 0.001 &&
        dropoffLat >= -90 &&
        dropoffLat <= 90 &&
        dropoffLng >= -180 &&
        dropoffLng <= 180;

    if (!isValidPickup || !isValidDropoff) {
      if (AppConfig.isDebugMode) {
        debugPrint('❌ Invalid trip coordinates:');
        debugPrint('   Pickup valid: $isValidPickup ($pickupLat, $pickupLng)');
        debugPrint(
          '   Dropoff valid: $isValidDropoff ($dropoffLat, $dropoffLng)',
        );
      }
      CustomToasts(
        message: 'route_invalid_coordinates'.tr,
        type: CustomToastType.error,
      ).show();
      points = _fallbackRoutePoints(trip);
    } else if (trip.encodedPolyline != null &&
        trip.encodedPolyline!.isNotEmpty) {
      if (AppConfig.isDebugMode) {
        debugPrint('✅ Using cached encoded polyline');
      }
      points = PolylineUtils.decodePolyline(trip.encodedPolyline!);
    } else {
      if (AppConfig.isDebugMode) {
        debugPrint('🔄 Fetching route from Directions API...');
        debugPrint('   API Key valid: ${AppConfig.isApiKeyValid}');
      }

      if (!AppConfig.isApiKeyValid) {
        CustomToasts(
          message: 'route_api_key_invalid'.tr,
          type: CustomToastType.error,
        ).show();
        points = _fallbackRoutePoints(trip);
      } else {
        final routeResult = await _getRoutePathUseCase(
          GetRoutePathParams(
            origin: domain_geo.GeoPoint(
              latitude: pickupLat,
              longitude: pickupLng,
            ),
            destination: domain_geo.GeoPoint(
              latitude: dropoffLat,
              longitude: dropoffLng,
            ),
          ),
        );

        if (routeResult is ResultSuccess<RoutePath>) {
          if (AppConfig.isDebugMode) {
            debugPrint(
              '✅ Route fetched successfully: ${points.length} waypoints',
            );
          }
          routePath = routeResult.data;
          points = routePath.waypoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
        } else if (routeResult is ResultFailure<RoutePath>) {
          final failure = routeResult.failure;
          final code = (failure.code ?? '').toUpperCase();
          final message = failure.message;
          final normalizedMessage = message.toLowerCase();
          final unauthorized =
              code == 'REQUEST_DENIED' ||
              normalizedMessage.contains('not authorized') ||
              normalizedMessage.contains('this api key');

          if (AppConfig.isDebugMode) {
            debugPrint('❌ Route fetch failed:');
            debugPrint('   Code: $code');
            debugPrint('   Message: $message');
            debugPrint('   Unauthorized: $unauthorized');
          }

          CustomToasts(
            message: unauthorized
                ? 'directions_not_authorized'.tr
                : 'route_fetch_failed'.tr,
            type: CustomToastType.error,
          ).show();

          skipPois = unauthorized;
          points = _fallbackRoutePoints(trip);
          routePath = RoutePath(
            encodedPolyline: '',
            waypoints: points
                .map(
                  (point) => domain_geo.GeoPoint(
                    latitude: point.latitude,
                    longitude: point.longitude,
                  ),
                )
                .toList(),
          );
        } else {
          if (AppConfig.isDebugMode) {
            debugPrint('⚠️ Unknown route result type');
          }
          points = _fallbackRoutePoints(trip);
        }
      }
    }

    if (points.isEmpty) {
      points = _fallbackRoutePoints(trip);
    }

    if (points.isEmpty) {
      CustomToasts(
        message: 'route_empty'.tr,
        type: CustomToastType.warning,
      ).show();
      throw Exception('route_empty'.tr);
    }

    final polyline = Polyline(
      polylineId: PolylineId('${trip.id}_route'),
      points: points,
      width: 6,
      color: Colors.blueAccent,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );

    final markers = <Marker>{
      Marker(
        markerId: MarkerId('${trip.id}_pickup'),
        position: LatLng(
          trip.pickupLocation.latitude,
          trip.pickupLocation.longitude,
        ),
        icon: MarkerUtils.getPickupMarker(),
        infoWindow: InfoWindow(
          title: trip.pickupLocation.name,
          snippet: 'pickup_point'.tr,
        ),
      ),
      Marker(
        markerId: MarkerId('${trip.id}_dropoff'),
        position: LatLng(
          trip.dropoffLocation.latitude,
          trip.dropoffLocation.longitude,
        ),
        icon: MarkerUtils.getDropoffMarker(),
        infoWindow: InfoWindow(
          title: trip.dropoffLocation.name,
          snippet: 'dropoff_point'.tr,
        ),
      ),
    };

    RoutePath? finalRoutePath = routePath;
    if (finalRoutePath == null) {
      finalRoutePath = RoutePath(
        encodedPolyline: '',
        waypoints: points
            .map(
              (point) => domain_geo.GeoPoint(
                latitude: point.latitude,
                longitude: point.longitude,
              ),
            )
            .toList(),
      );
    }

    List<RoutePoi> pois = const [];
    if (!skipPois) {
      final poiResult = await _getRoutePoisUseCase(
        GetRoutePoisParams(
          route: finalRoutePath,
          placeTypes: const ['school', 'gas_station', 'hospital'],
          maxResults: 12,
        ),
      );

      if (poiResult is ResultSuccess<List<RoutePoiEntity>>) {
        pois = poiResult.data.map(RoutePoi.fromEntity).toList();
      }
    }

    return _TripArtifacts(
      points: points,
      markers: markers,
      polylines: {polyline},
      pois: pois,
    );
  }

  List<LatLng> _fallbackRoutePoints(TripModel trip) {
    return [
      LatLng(trip.pickupLocation.latitude, trip.pickupLocation.longitude),
      LatLng(trip.dropoffLocation.latitude, trip.dropoffLocation.longitude),
    ];
  }

  TripModel? _determineHighlightedTrip({
    required List<TripModel> scheduled,
    required List<TripModel> instant,
    required List<TripModel> inProgress,
  }) {
    final allTrips = [...inProgress, ...instant, ...scheduled];

    if (_activeTrip != null) {
      final activeMatch = allTrips.firstWhereOrNull(
        (trip) => trip.id == _activeTrip!.id,
      );
      if (activeMatch != null) {
        return activeMatch;
      }
    }

    if (_highlightedTrip != null) {
      final existing = allTrips.firstWhereOrNull(
        (trip) => trip.id == _highlightedTrip!.id,
      );
      if (existing != null) {
        return existing;
      }
    }

    return inProgress.firstOrNull ??
        instant.firstOrNull ??
        scheduled.firstOrNull;
  }

  DriverHomeTripTab _determineActiveTab(TripModel? trip) {
    if (trip == null) {
      return DriverHomeTripTab.scheduled;
    }
    if (uiState.value.inProgressTrips.any((t) => t.id == trip.id)) {
      return DriverHomeTripTab.inProgress;
    }
    if (uiState.value.instantTrips.any((t) => t.id == trip.id)) {
      return DriverHomeTripTab.instant;
    }
    return DriverHomeTripTab.scheduled;
  }

  void _animateCameraToTrip(TripModel? trip) {
    if (trip == null) return;
    final controller = mapController.value;
    if (controller == null) return;

    final bounds = _boundsForTrip(trip);
    if (bounds != null) {
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 72.0));
    } else {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(trip.pickupLocation.latitude, trip.pickupLocation.longitude),
          14,
        ),
      );
    }
  }

  LatLngBounds? _boundsForTrip(TripModel trip) {
    final points = _routePointsCache[trip.id];
    if (points == null || points.isEmpty) return null;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _updateInstantRideNotifications(List<TripModel> instant) {
    final ids = instant.map((trip) => trip.id).toSet();
    final newlyAdded = ids.difference(_knownInstantTripIds);
    if (newlyAdded.isNotEmpty) {
      CustomToasts(
        message: 'new_instant_ride_request'.tr,
        type: CustomToastType.warning,
      ).show();
    }
    _knownInstantTripIds
      ..clear()
      ..addAll(ids);
  }

  Position _fallbackPosition() {
    return Position(
      latitude: 24.7136,
      longitude: 46.6753,
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

class _TripArtifacts {
  const _TripArtifacts({
    required this.points,
    required this.markers,
    required this.polylines,
    required this.pois,
  });

  final List<LatLng> points;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final List<RoutePoi> pois;
}
