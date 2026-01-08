import '../value_objects/geo_point.dart';

class RoutePoiEntity {
  const RoutePoiEntity({
    required this.placeId,
    required this.name,
    required this.location,
    this.address,
    this.primaryType,
    this.rating,
    this.userRatingsTotal,
  });

  final String placeId;
  final String name;
  final GeoPoint location;
  final String? address;
  final String? primaryType;
  final double? rating;
  final int? userRatingsTotal;
}

