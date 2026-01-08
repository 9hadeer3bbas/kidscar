import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kidscar/data/models/route_poi.dart';
import 'package:kidscar/data/models/trip_model.dart';

enum DriverHomeScreenStatus { loading, ready, error }

enum DriverHomeTripTab { scheduled, instant, inProgress }

class DriverHomeViewState {
  const DriverHomeViewState({
    required this.status,
    required this.isLoadingLocation,
    required this.isLoadingTrips,
    required this.isOnline,
    required this.isTracking,
    required this.isSimulating,
    required this.activeTab,
    required this.scheduledTrips,
    required this.instantTrips,
    required this.inProgressTrips,
    required this.highlightedTrip,
    required this.mapMarkers,
    required this.polylines,
    required this.pois,
    required this.cameraTarget,
    required this.driverLocation,
    required this.roadName,
    required this.errorMessage,
    required this.showSimulationFab,
    required this.simulationStep,
    required this.simulationTotal,
    required this.simulationSpeedKmh,
    required this.mapReady,
    required this.isTripPanelCollapsed,
  });

  final DriverHomeScreenStatus status;
  final bool isLoadingLocation;
  final bool isLoadingTrips;
  final bool isOnline;
  final bool isTracking;
  final bool isSimulating;
  final DriverHomeTripTab activeTab;
  final List<TripModel> scheduledTrips;
  final List<TripModel> instantTrips;
  final List<TripModel> inProgressTrips;
  final TripModel? highlightedTrip;
  final Set<Marker> mapMarkers;
  final Set<Polyline> polylines;
  final List<RoutePoi> pois;
  final LatLng cameraTarget;
  final LatLng? driverLocation;
  final String roadName;
  final String? errorMessage;
  final bool showSimulationFab;
  final int simulationStep;
  final int simulationTotal;
  final double simulationSpeedKmh;
  final bool mapReady;
  final bool isTripPanelCollapsed;

  bool get hasTrips =>
      scheduledTrips.isNotEmpty ||
      instantTrips.isNotEmpty ||
      inProgressTrips.isNotEmpty;
  bool get showLoadingOverlay => isLoadingLocation || isLoadingTrips;

  DriverHomeViewState copyWith({
    DriverHomeScreenStatus? status,
    bool? isLoadingLocation,
    bool? isLoadingTrips,
    bool? isOnline,
    bool? isTracking,
    bool? isSimulating,
    DriverHomeTripTab? activeTab,
    List<TripModel>? scheduledTrips,
    List<TripModel>? instantTrips,
    List<TripModel>? inProgressTrips,
    TripModel? highlightedTrip,
    Set<Marker>? mapMarkers,
    Set<Polyline>? polylines,
    List<RoutePoi>? pois,
    LatLng? cameraTarget,
    LatLng? driverLocation,
    String? roadName,
    String? errorMessage,
    bool? showSimulationFab,
    int? simulationStep,
    int? simulationTotal,
    double? simulationSpeedKmh,
    bool? mapReady,
    bool? tripPanelCollapsed,
    bool resetHighlightedTrip = false,
    bool resetError = false,
  }) {
    return DriverHomeViewState(
      status: status ?? this.status,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      isLoadingTrips: isLoadingTrips ?? this.isLoadingTrips,
      isOnline: isOnline ?? this.isOnline,
      isTracking: isTracking ?? this.isTracking,
      isSimulating: isSimulating ?? this.isSimulating,
      activeTab: activeTab ?? this.activeTab,
      scheduledTrips: scheduledTrips ?? this.scheduledTrips,
      instantTrips: instantTrips ?? this.instantTrips,
      inProgressTrips: inProgressTrips ?? this.inProgressTrips,
      highlightedTrip: resetHighlightedTrip ? null : highlightedTrip ?? this.highlightedTrip,
      mapMarkers: mapMarkers ?? this.mapMarkers,
      polylines: polylines ?? this.polylines,
      pois: pois ?? this.pois,
      cameraTarget: cameraTarget ?? this.cameraTarget,
      driverLocation: driverLocation ?? this.driverLocation,
      roadName: roadName ?? this.roadName,
      errorMessage: resetError ? null : errorMessage ?? this.errorMessage,
      showSimulationFab: showSimulationFab ?? this.showSimulationFab,
      simulationStep: simulationStep ?? this.simulationStep,
      simulationTotal: simulationTotal ?? this.simulationTotal,
      simulationSpeedKmh: simulationSpeedKmh ?? this.simulationSpeedKmh,
      mapReady: mapReady ?? this.mapReady,
      isTripPanelCollapsed: tripPanelCollapsed ?? this.isTripPanelCollapsed,
    );
  }

  factory DriverHomeViewState.initial() {
    const fallback = LatLng(24.7136, 46.6753); // Riyadh
    return DriverHomeViewState(
      status: DriverHomeScreenStatus.loading,
      isLoadingLocation: true,
      isLoadingTrips: true,
      isOnline: false,
      isTracking: false,
      isSimulating: false,
      activeTab: DriverHomeTripTab.scheduled,
      scheduledTrips: const [],
      instantTrips: const [],
      inProgressTrips: const [],
      highlightedTrip: null,
      mapMarkers: <Marker>{},
      polylines: <Polyline>{},
      pois: const [],
      cameraTarget: fallback,
      driverLocation: fallback,
      roadName: '',
      errorMessage: null,
      showSimulationFab: false,
      simulationStep: 0,
      simulationTotal: 0,
      simulationSpeedKmh: 0,
      mapReady: false,
      isTripPanelCollapsed: false,
    );
  }
}

