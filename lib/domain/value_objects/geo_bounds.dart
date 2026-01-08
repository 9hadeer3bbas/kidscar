import 'geo_point.dart';

class GeoBounds {
  const GeoBounds({required this.southWest, required this.northEast});

  final GeoPoint southWest;
  final GeoPoint northEast;

  Map<String, dynamic> toMap() => {
        'southWest': southWest.toMap(),
        'northEast': northEast.toMap(),
      };

  factory GeoBounds.fromMap(Map<String, dynamic> map) {
    return GeoBounds(
      southWest: GeoPoint.fromMap(map['southWest'] as Map<String, dynamic>),
      northEast: GeoPoint.fromMap(map['northEast'] as Map<String, dynamic>),
    );
  }
}

