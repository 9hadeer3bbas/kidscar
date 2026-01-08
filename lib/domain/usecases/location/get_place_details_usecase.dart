import '../../core/result.dart';
import '../../entities/place_details.dart';
import '../../repositories/location_repository.dart';

class GetPlaceDetailsParams {
  const GetPlaceDetailsParams({required this.placeId});

  final String placeId;
}

class GetPlaceDetailsUseCase {
  GetPlaceDetailsUseCase(this._repository);

  final LocationRepository _repository;

  Future<Result<PlaceDetails>> call(GetPlaceDetailsParams params) {
    return _repository.fetchPlaceDetails(params.placeId);
  }
}

