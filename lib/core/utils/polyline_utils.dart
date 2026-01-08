import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class PolylineUtils {
  static const double _earthRadiusMeters = 6371000; // Average radius of Earth

  static List<LatLng> decodePolyline(String encoded) {
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

  static double distanceBetween(LatLng a, LatLng b) {
    final double lat1 = _degreesToRadians(a.latitude);
    final double lat2 = _degreesToRadians(b.latitude);
    final double deltaLat = _degreesToRadians(b.latitude - a.latitude);
    final double deltaLng = _degreesToRadians(b.longitude - a.longitude);

    final double hav =
        sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLng / 2) * sin(deltaLng / 2);
    final double c = 2 * atan2(sqrt(hav), sqrt(1 - hav));

    return _earthRadiusMeters * c;
  }

  static double distanceToPolyline(LatLng point, List<LatLng> polyline) {
    if (polyline.length < 2) {
      return double.infinity;
    }

    double minDistance = double.infinity;
    for (var i = 0; i < polyline.length - 1; i++) {
      final segmentDistance = _distancePointToSegment(
        point,
        polyline[i],
        polyline[i + 1],
      );
      if (segmentDistance < minDistance) {
        minDistance = segmentDistance;
      }
    }

    return minDistance;
  }

  static double _distancePointToSegment(LatLng p, LatLng start, LatLng end) {
    if (start.latitude == end.latitude && start.longitude == end.longitude) {
      return distanceBetween(p, start);
    }

    final double lat1 = _degreesToRadians(start.latitude);
    final double lng1 = _degreesToRadians(start.longitude);
    final double lat2 = _degreesToRadians(end.latitude);
    final double lng2 = _degreesToRadians(end.longitude);
    final double lat3 = _degreesToRadians(p.latitude);
    final double lng3 = _degreesToRadians(p.longitude);

    final double x1 = cos(lat1) * cos(lng1);
    final double y1 = cos(lat1) * sin(lng1);
    final double z1 = sin(lat1);

    final double x2 = cos(lat2) * cos(lng2);
    final double y2 = cos(lat2) * sin(lng2);
    final double z2 = sin(lat2);

    final double x3 = cos(lat3) * cos(lng3);
    final double y3 = cos(lat3) * sin(lng3);
    final double z3 = sin(lat3);

    final double dx = x2 - x1;
    final double dy = y2 - y1;
    final double dz = z2 - z1;
    final double lengthSquared = dx * dx + dy * dy + dz * dz;

    double t =
        ((x3 - x1) * dx + (y3 - y1) * dy + (z3 - z1) * dz) / lengthSquared;
    t = t.clamp(0.0, 1.0);

    final double xClosest = x1 + t * dx;
    final double yClosest = y1 + t * dy;
    final double zClosest = z1 + t * dz;

    final double latClosest = atan2(
      zClosest,
      sqrt(xClosest * xClosest + yClosest * yClosest),
    );
    final double lngClosest = atan2(yClosest, xClosest);

    return distanceBetween(
      p,
      LatLng(_radiansToDegrees(latClosest), _radiansToDegrees(lngClosest)),
    );
  }

  static double _degreesToRadians(double degrees) => degrees * pi / 180;

  static double _radiansToDegrees(double radians) => radians * 180 / pi;
}
