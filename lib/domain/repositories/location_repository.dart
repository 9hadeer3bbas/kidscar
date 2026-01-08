import '../core/result.dart';
import '../entities/location_suggestion.dart';
import '../entities/place_details.dart';
import '../entities/route_path.dart';
import '../entities/route_poi_entity.dart';
import '../value_objects/geo_point.dart';

abstract class LocationRepository {
  Future<Result<List<LocationSuggestion>>> searchLocationSuggestions({
    required String query,
    String countryCode = 'SA',
  });

  Future<Result<PlaceDetails>> fetchPlaceDetails(String placeId);

  Future<Result<RoutePath>> fetchRoutePath({
    required GeoPoint origin,
    required GeoPoint destination,
  });

  Future<Result<List<RoutePoiEntity>>> fetchPoisAlongRoute({
    required RoutePath route,
    required List<String> placeTypes,
    int maxResults = 10,
  });
}

