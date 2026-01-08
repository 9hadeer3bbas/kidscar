import '../../core/result.dart';
import '../../entities/route_path.dart';
import '../../repositories/location_repository.dart';
import '../../value_objects/geo_point.dart';

class GetRoutePathParams {
  const GetRoutePathParams({required this.origin, required this.destination});

  final GeoPoint origin;
  final GeoPoint destination;
}

class GetRoutePathUseCase {
  GetRoutePathUseCase(this._repository);

  final LocationRepository _repository;

  Future<Result<RoutePath>> call(GetRoutePathParams params) {
    return _repository.fetchRoutePath(
      origin: params.origin,
      destination: params.destination,
    );
  }
}

