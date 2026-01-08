class AppConfig {
  static const String googlePlacesApiKey =
      "AIzaSyCJtj12oPlvsp8Qo0ECr57H0fLNi4bGBYc";

  // Environment-based configuration
  static const bool isDebugMode = true;

  // AI Face Recognition API Configuration
  static const String aiFaceRecognitionApiEndpoint =
      'http://93.127.213.45:8000/verify-face/';
  static const double faceVerificationThreshold = 0.35; // API threshold
  static const double similarityThreshold =
      0.55; // Minimum similarity (0-1 scale) - driver must match 55% or above

  // API Key validation
  static bool get isApiKeyValid {
    const invalidKeys = {
      '',
      'YOUR_API_KEY_HERE',
      'AIzaSyDXk7TTOQmcC_sMTPCQVaqfASwd-jJd1WY', // Old placeholder
    };

    return !invalidKeys.contains(googlePlacesApiKey) &&
        googlePlacesApiKey.startsWith('AIza') &&
        googlePlacesApiKey.length > 30;
  }

  /// Check if AI face recognition API is configured
  static bool get isAiFaceRecognitionConfigured {
    return aiFaceRecognitionApiEndpoint.isNotEmpty;
  }
}
