import 'package:get/get.dart';
import 'package:kidscar/core/controllers/language_controller.dart';
import 'package:kidscar/core/services/notification_service.dart';
import 'package:kidscar/core/services/trip_tracking_service.dart';
import 'package:kidscar/data/repos/location_repo.dart';
import 'package:kidscar/domain/repositories/location_repository.dart';
import 'package:kidscar/domain/usecases/location/get_place_details_usecase.dart';
import 'package:kidscar/domain/usecases/location/get_route_path_usecase.dart';
import 'package:kidscar/domain/usecases/location/get_route_pois_usecase.dart';
import 'package:kidscar/domain/usecases/location/search_location_suggestions_usecase.dart';
import 'package:kidscar/core/services/selfie_verification_service.dart';
import 'package:kidscar/core/services/safety_event_service.dart';
import 'package:kidscar/core/services/rtc_streaming_service.dart';
import 'package:kidscar/core/services/audio_monitoring_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(LanguageController());
    Get.put<LocationRepositoryImpl>(LocationRepositoryImpl());
    Get.lazyPut<LocationRepository>(() => Get.find<LocationRepositoryImpl>());
    Get.lazyPut<SearchLocationSuggestionsUseCase>(
      () => SearchLocationSuggestionsUseCase(Get.find<LocationRepository>()),
    );
    Get.lazyPut<GetPlaceDetailsUseCase>(
      () => GetPlaceDetailsUseCase(Get.find<LocationRepository>()),
    );
    Get.lazyPut<GetRoutePathUseCase>(
      () => GetRoutePathUseCase(Get.find<LocationRepository>()),
    );
    Get.lazyPut<GetRoutePoisUseCase>(
      () => GetRoutePoisUseCase(Get.find<LocationRepository>()),
    );
    if (!Get.isRegistered<NotificationService>()) {
      Get.put(NotificationService());
    }

    if (!Get.isRegistered<TripTrackingService>()) {
      Get.put(TripTrackingService(), permanent: true);
    }

    if (!Get.isRegistered<SelfieVerificationService>()) {
      Get.put(SelfieVerificationService(), permanent: true);
    }

    if (!Get.isRegistered<SafetyEventService>()) {
      Get.put(SafetyEventService(), permanent: true);
    }

    if (!Get.isRegistered<RtcStreamingService>()) {
      Get.put(RtcStreamingService(), permanent: true);
    }

    if (!Get.isRegistered<AudioMonitoringService>()) {
      Get.put(AudioMonitoringService(), permanent: true);
    }
    // AuthFlowService will be initialized in SplashScreen
  }
}
