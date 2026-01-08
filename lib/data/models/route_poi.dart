import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:kidscar/domain/entities/route_poi_entity.dart';

class RoutePoi {
  RoutePoi({
    required this.placeId,
    required this.name,
    required this.location,
    required this.address,
    required this.primaryType,
    this.rating,
    this.userRatingsTotal,
    this.distanceMeters,
    bool isReached = false,
  }) : reached = isReached.obs;

  factory RoutePoi.fromEntity(
    RoutePoiEntity entity, {
    double? distanceMeters,
    bool isReached = false,
  }) {
    return RoutePoi(
      placeId: entity.placeId,
      name: entity.name,
      location: LatLng(
        entity.location.latitude,
        entity.location.longitude,
      ),
      address: entity.address ?? '',
      primaryType: entity.primaryType ?? '',
      rating: entity.rating,
      userRatingsTotal: entity.userRatingsTotal,
      distanceMeters: distanceMeters,
      isReached: isReached,
    );
  }

  final String placeId;
  final String name;
  final LatLng location;
  final String address;
  final String primaryType;
  final double? rating;
  final int? userRatingsTotal;
  final double? distanceMeters;
  final RxBool reached;

  factory RoutePoi.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? {};

    return RoutePoi(
      placeId: json['placeId'] ?? '',
      name: json['name'] ?? '',
      location: LatLng(
        (location['latitude'] ?? 0.0).toDouble(),
        (location['longitude'] ?? 0.0).toDouble(),
      ),
      address: json['address'] ?? '',
      primaryType: json['primaryType'] ?? '',
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : null,
      userRatingsTotal: json['userRatingsTotal'] as int?,
      distanceMeters: json['distanceMeters'] != null
          ? (json['distanceMeters'] as num).toDouble()
          : null,
      isReached: json['isReached'] == true,
    );
  }

  RoutePoi copyWith({bool? isReached}) {
    final poi = RoutePoi(
      placeId: placeId,
      name: name,
      location: location,
      address: address,
      primaryType: primaryType,
      rating: rating,
      userRatingsTotal: userRatingsTotal,
      distanceMeters: distanceMeters,
      isReached: isReached ?? reached.value,
    );
    return poi;
  }

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'name': name,
      'address': address,
      'primaryType': primaryType,
      'rating': rating,
      'userRatingsTotal': userRatingsTotal,
      'distanceMeters': distanceMeters,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'isReached': reached.value,
    };
  }

  RoutePoi markReached() => copyWith(isReached: true);
}
