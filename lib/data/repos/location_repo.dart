import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/utils/polyline_utils.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/location_suggestion.dart';
import '../../domain/entities/place_details.dart';
import '../../domain/entities/route_path.dart';
import '../../domain/entities/route_poi_entity.dart';
import '../../domain/failures/failure.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/value_objects/geo_bounds.dart';
import '../../domain/value_objects/geo_point.dart';

class LocationRepositoryImpl extends GetxService implements LocationRepository {
  LocationRepositoryImpl({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  static const _autocompleteEndpoint =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const _placeDetailsEndpoint =
      'https://maps.googleapis.com/maps/api/place/details/json';
  static const _directionsEndpoint =
      'https://maps.googleapis.com/maps/api/directions/json';
  static const _placesNearbyEndpoint =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  String get _apiKey => AppConfig.googlePlacesApiKey;

  @override
  Future<Result<List<LocationSuggestion>>> searchLocationSuggestions({
    required String query,
    String countryCode = 'SA',
  }) async {
    if (!AppConfig.isApiKeyValid) {
      return ResultFailure<List<LocationSuggestion>>(
        Failure(message: 'Google Places API key is invalid.', code: 'invalid_api_key'),
      );
    }

    final url = Uri.parse(
      '$_autocompleteEndpoint'
      '?input=${Uri.encodeComponent(query)}'
      '&key=$_apiKey'
      '&language=en'
      '&components=country:$countryCode',
    );

    try {
      final response = await _httpClient.get(url);
      if (response.statusCode != 200) {
        return ResultFailure<List<LocationSuggestion>>(
          Failure(
            message: 'Autocomplete request failed with status ${response.statusCode}.',
            code: 'http_error',
          ),
        );
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      final status = body['status'] as String? ?? 'UNKNOWN_ERROR';

      if (status != 'OK') {
        final errorMessage = body['error_message'] as String?;
        if (AppConfig.isDebugMode) {
          debugPrint('Places API Error: $status - $errorMessage');
        }
        return ResultFailure<List<LocationSuggestion>>(
          Failure(message: errorMessage ?? status, code: status),
        );
      }

      final predictions = body['predictions'] as List<dynamic>? ?? [];
      final suggestions = predictions.map((prediction) {
        final map = prediction as Map<String, dynamic>;
        final formatting = map['structured_formatting'] as Map<String, dynamic>?;

        return LocationSuggestion(
          placeId: map['place_id'] as String? ?? '',
          description: map['description'] as String? ?? '',
          primaryText: formatting?['main_text'] as String?,
          secondaryText: formatting?['secondary_text'] as String?,
        );
      }).toList();

      return ResultSuccess<List<LocationSuggestion>>(suggestions);
    } catch (error, stackTrace) {
      if (AppConfig.isDebugMode) {
        debugPrint('Get Location Suggestions Error: $error');
      }
      return ResultFailure<List<LocationSuggestion>>(
        Failure(
          message: 'Failed to fetch location suggestions.',
          exception: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<PlaceDetails>> fetchPlaceDetails(String placeId) async {
    if (!AppConfig.isApiKeyValid) {
      return ResultFailure<PlaceDetails>(
        Failure(message: 'Google Places API key is invalid.', code: 'invalid_api_key'),
      );
    }

    final url = Uri.parse(
      '$_placeDetailsEndpoint'
      '?place_id=$placeId'
      '&key=$_apiKey'
      '&language=en'
      '&fields=name,formatted_address,geometry',
    );

    try {
      final response = await _httpClient.get(url);
      if (response.statusCode != 200) {
        return ResultFailure<PlaceDetails>(
          Failure(
            message: 'Place details request failed with status ${response.statusCode}.',
            code: 'http_error',
          ),
        );
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      final status = body['status'] as String? ?? 'UNKNOWN_ERROR';

      if (status != 'OK') {
        final errorMessage = body['error_message'] as String?;
        if (AppConfig.isDebugMode) {
          debugPrint('Place Details API Error: $status - $errorMessage');
        }
        return ResultFailure<PlaceDetails>(
          Failure(message: errorMessage ?? status, code: status),
        );
      }

      final result = body['result'] as Map<String, dynamic>? ?? {};
      final geometry = (result['geometry'] ?? {}) as Map<String, dynamic>;
      final location = (geometry['location'] ?? {}) as Map<String, dynamic>;

      final placeDetails = PlaceDetails(
        placeId: placeId,
        name: result['name'] as String? ?? result['formatted_address'] as String? ?? '',
        address: result['formatted_address'] as String? ?? '',
        location: GeoPoint(
          latitude: (location['lat'] ?? 0).toDouble(),
          longitude: (location['lng'] ?? 0).toDouble(),
        ),
      );

      return ResultSuccess<PlaceDetails>(placeDetails);
    } catch (error, stackTrace) {
      if (AppConfig.isDebugMode) {
        debugPrint('Get Place Details Error: $error');
      }
      return ResultFailure<PlaceDetails>(
        Failure(
          message: 'Failed to fetch place details.',
          exception: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<RoutePath>> fetchRoutePath({
    required GeoPoint origin,
    required GeoPoint destination,
  }) async {
    if (!AppConfig.isApiKeyValid) {
      return ResultFailure<RoutePath>(
        Failure(message: 'Google Places API key is invalid.', code: 'invalid_api_key'),
      );
    }

    final url = Uri.parse(
      '$_directionsEndpoint'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&mode=driving'
      '&key=$_apiKey',
    );

    try {
      final response = await _httpClient.get(url);
      if (response.statusCode != 200) {
        return ResultFailure<RoutePath>(
          Failure(
            message: 'Directions request failed with status ${response.statusCode}.',
            code: 'http_error',
          ),
        );
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      final status = body['status'] as String? ?? 'UNKNOWN_ERROR';
      final routes = body['routes'] as List<dynamic>? ?? [];

      if (status != 'OK' || routes.isEmpty) {
        if (AppConfig.isDebugMode) {
          debugPrint('Directions API Error: $status - ${body['error_message']}');
        }
        return ResultFailure<RoutePath>(
          Failure(message: body['error_message'] as String? ?? status, code: status),
        );
      }

      final firstRoute = routes.first as Map<String, dynamic>;
      final overviewPolyline =
          (firstRoute['overview_polyline'] ?? {}) as Map<String, dynamic>;
      final legs = (firstRoute['legs'] as List<dynamic>? ?? []);

      if (!overviewPolyline.containsKey('points') || legs.isEmpty) {
        return ResultFailure<RoutePath>(
          Failure(message: 'No route found for the provided coordinates.', code: 'no_route'),
        );
      }

      final polyline = overviewPolyline['points'] as String;
      final decodedPoints = PolylineUtils.decodePolyline(polyline)
          .map((point) => GeoPoint(latitude: point.latitude, longitude: point.longitude))
          .toList();

      final firstLeg = legs.first as Map<String, dynamic>;
      final distance = ((firstLeg['distance'] ?? {}) as Map<String, dynamic>)['value'];
      final duration = ((firstLeg['duration'] ?? {}) as Map<String, dynamic>)['value'];

      final bounds = _computeBounds(decodedPoints);

      final routePath = RoutePath(
        encodedPolyline: polyline,
        distanceMeters: distance is num ? distance.toInt() : null,
        durationSeconds: duration is num ? duration.toInt() : null,
        waypoints: decodedPoints,
        bounds: bounds,
      );

      return ResultSuccess<RoutePath>(routePath);
    } catch (error, stackTrace) {
      if (AppConfig.isDebugMode) {
        debugPrint('Get Route Error: $error');
      }
      return ResultFailure<RoutePath>(
        Failure(
          message: 'Failed to fetch route data.',
          exception: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<List<RoutePoiEntity>>> fetchPoisAlongRoute({
    required RoutePath route,
    required List<String> placeTypes,
    int maxResults = 10,
  }) async {
    if (!AppConfig.isApiKeyValid) {
      return ResultFailure<List<RoutePoiEntity>>(
        Failure(message: 'Google Places API key is invalid.', code: 'invalid_api_key'),
      );
    }

    final bounds = route.bounds ?? _computeBounds(route.waypoints);
    if (bounds == null) {
      return ResultFailure<List<RoutePoiEntity>>(
        Failure(message: 'Unable to compute route bounds.', code: 'no_bounds'),
      );
    }

    final centerLat = (bounds.southWest.latitude + bounds.northEast.latitude) / 2;
    final centerLng = (bounds.southWest.longitude + bounds.northEast.longitude) / 2;
    final radius = _estimateRadiusMeters(bounds);

    final List<RoutePoiEntity> pois = [];

    try {
      for (final type in placeTypes) {
        final url = Uri.parse(
          '$_placesNearbyEndpoint'
          '?location=$centerLat,$centerLng'
          '&radius=$radius'
          '&type=$type'
          '&key=$_apiKey',
        );

        final response = await _httpClient.get(url);
        if (response.statusCode != 200) {
          continue;
        }

        final body = json.decode(response.body) as Map<String, dynamic>;
        if ((body['status'] ?? '') != 'OK') {
          continue;
        }

        final results = body['results'] as List<dynamic>? ?? [];
        for (final raw in results) {
          final map = raw as Map<String, dynamic>;
          final geometry = (map['geometry'] ?? {}) as Map<String, dynamic>;
          final location = (geometry['location'] ?? {}) as Map<String, dynamic>;

          if (!location.containsKey('lat') || !location.containsKey('lng')) {
            continue;
          }

          final poi = RoutePoiEntity(
            placeId: map['place_id'] as String? ?? '',
            name: map['name'] as String? ?? '',
            location: GeoPoint(
              latitude: (location['lat'] ?? 0.0).toDouble(),
              longitude: (location['lng'] ?? 0.0).toDouble(),
            ),
            address: map['vicinity'] as String? ?? map['formatted_address'] as String?,
            primaryType: type,
            rating: map['rating'] != null ? (map['rating'] as num).toDouble() : null,
            userRatingsTotal: map['user_ratings_total'] as int?,
          );

          pois.add(poi);
          if (pois.length >= maxResults) {
            break;
          }
        }

        if (pois.length >= maxResults) {
          break;
        }
      }

      return ResultSuccess<List<RoutePoiEntity>>(pois);
    } catch (error, stackTrace) {
      if (AppConfig.isDebugMode) {
        debugPrint('Get POIs Error: $error');
      }
      return ResultFailure<List<RoutePoiEntity>>(
        Failure(
          message: 'Failed to fetch points of interest.',
          exception: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  GeoBounds? _computeBounds(List<GeoPoint> points) {
    if (points.isEmpty) return null;

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    return GeoBounds(
      southWest: GeoPoint(latitude: minLat, longitude: minLng),
      northEast: GeoPoint(latitude: maxLat, longitude: maxLng),
    );
  }

  double _estimateRadiusMeters(GeoBounds bounds) {
    final centerLat = (bounds.southWest.latitude + bounds.northEast.latitude) / 2;
    final centerLng = (bounds.southWest.longitude + bounds.northEast.longitude) / 2;

    final center = LatLng(centerLat, centerLng);
    final corner = LatLng(bounds.northEast.latitude, bounds.northEast.longitude);
    final distance = PolylineUtils.distanceBetween(center, corner);

    return distance.clamp(500, 5000);
  }
}

