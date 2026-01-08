class LocationSuggestion {
  const LocationSuggestion({
    required this.placeId,
    required this.description,
    this.primaryText,
    this.secondaryText,
  });

  final String placeId;
  final String description;
  final String? primaryText;
  final String? secondaryText;

  LocationSuggestion copyWith({
    String? placeId,
    String? description,
    String? primaryText,
    String? secondaryText,
  }) {
    return LocationSuggestion(
      placeId: placeId ?? this.placeId,
      description: description ?? this.description,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
    );
  }
}

