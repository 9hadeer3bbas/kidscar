import '../value_objects/geo_point.dart';

class PlaceDetails {
  const PlaceDetails({
    required this.placeId,
    required this.name,
    required this.address,
    required this.location,
  });

  final String placeId;
  final String name;
  final String address;
  final GeoPoint location;
}

