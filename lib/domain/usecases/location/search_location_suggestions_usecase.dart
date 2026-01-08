import '../../core/result.dart';
import '../../entities/location_suggestion.dart';
import '../../repositories/location_repository.dart';

class SearchLocationSuggestionsParams {
  const SearchLocationSuggestionsParams({
    required this.query,
    this.countryCode = 'SA',
  });

  final String query;
  final String countryCode;
}

class SearchLocationSuggestionsUseCase {
  SearchLocationSuggestionsUseCase(this._repository);

  final LocationRepository _repository;

  Future<Result<List<LocationSuggestion>>> call(
    SearchLocationSuggestionsParams params,
  ) {
    return _repository.searchLocationSuggestions(
      query: params.query,
      countryCode: params.countryCode,
    );
  }
}

