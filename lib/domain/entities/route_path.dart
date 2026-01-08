import '../value_objects/geo_bounds.dart';
import '../value_objects/geo_point.dart';

class RoutePath {
  const RoutePath({
    required this.encodedPolyline,
    required this.waypoints,
    this.distanceMeters,
    this.durationSeconds,
    this.bounds,
  });

  final String encodedPolyline;
  final int? distanceMeters;
  final int? durationSeconds;
  final List<GeoPoint> waypoints;
  final GeoBounds? bounds;
}

