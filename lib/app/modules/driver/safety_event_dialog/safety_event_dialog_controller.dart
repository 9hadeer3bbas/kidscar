import 'package:get/get.dart';
import '../../../../core/services/safety_event_service.dart';
import '../../../../core/services/trip_tracking_service.dart';
import '../../../../data/models/trip_model.dart';
import '../../../custom_widgets/custom_toast.dart';

class SafetyEventDialogController extends GetxController {
  final SafetyEventService _safetyEventService =
      Get.find<SafetyEventService>();
  final TripTrackingService _trackingService = Get.find<TripTrackingService>();

  final RxBool isProcessing = false.obs;

  Future<void> simulateSafetyEvent(
    SafetyEventType eventType,
    TripModel? trip,
  ) async {
    if (trip == null) {
      CustomToasts(
        message: 'no_active_trip'.tr,
        type: CustomToastType.warning,
      ).show();
      return;
    }

    if (!_trackingService.trackingActive.value) {
      CustomToasts(
        message: 'trip_not_active'.tr,
        type: CustomToastType.warning,
      ).show();
      return;
    }

    try {
      isProcessing.value = true;

      String? message;
      Map<String, double>? location;

      switch (eventType) {
        case SafetyEventType.loudSound:
          message = 'loud_sound_simulation'.tr;
          break;
        case SafetyEventType.offRoad:
          message = 'off_road_simulation'.tr;
          // Get current location for off-road events
          final currentPosition = _trackingService.currentDriverPosition.value;
          if (currentPosition != null) {
            location = {
              'latitude': currentPosition.latitude,
              'longitude': currentPosition.longitude,
            };
          }
          break;
        case SafetyEventType.unexpectedStop:
          message = 'unexpected_stop_simulation'.tr;
          // Get current location for unexpected stop events
          final currentPosition = _trackingService.currentDriverPosition.value;
          if (currentPosition != null) {
            location = {
              'latitude': currentPosition.latitude,
              'longitude': currentPosition.longitude,
            };
          }
          break;
      }

      // Log all event types including off-road
      await _safetyEventService.simulateSafetyEvent(
        tripId: trip.id,
        eventType: eventType,
        message: message,
        location: location,
      );

      CustomToasts(
        message: 'safety_event_sent'.tr,
        type: CustomToastType.success,
      ).show();

      Get.back();
    } catch (e) {
      CustomToasts(
        message: 'failed_to_send_event'.tr,
        type: CustomToastType.error,
      ).show();
    } finally {
      isProcessing.value = false;
    }
  }
}

