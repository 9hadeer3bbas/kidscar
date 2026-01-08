import '../../core/result.dart';
import '../../entities/route_path.dart';
import '../../entities/route_poi_entity.dart';
import '../../repositories/location_repository.dart';

class GetRoutePoisParams {
  const GetRoutePoisParams({
    required this.route,
    required this.placeTypes,
    this.maxResults = 10,
  });

  final RoutePath route;
  final List<String> placeTypes;
  final int maxResults;
}

class GetRoutePoisUseCase {
  GetRoutePoisUseCase(this._repository);

  final LocationRepository _repository;

  Future<Result<List<RoutePoiEntity>>> call(GetRoutePoisParams params) {
    return _repository.fetchPoisAlongRoute(
      route: params.route,
      placeTypes: params.placeTypes,
      maxResults: params.maxResults,
    );
  }
}

