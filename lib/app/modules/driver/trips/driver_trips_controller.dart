import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../data/models/subscription_model.dart';
import '../../../custom_widgets/custom_toast.dart';
import '../../../../core/services/notification_service.dart';

enum DriverTripsTab { pending, upcoming, past }

class DriverTripsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = Get.find<NotificationService>();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<DriverTripsTab> selectedTab = DriverTripsTab.pending.obs;
  final RxList<TripModel> pendingTrips = <TripModel>[].obs;
  final RxList<TripModel> upcomingTrips = <TripModel>[].obs;
  final RxList<TripModel> pastTrips = <TripModel>[].obs;
  final RxSet<String> processingTripIds = <String>{}.obs;

  StreamSubscription<QuerySnapshot>? _tripsSubscription;

  @override
  void onInit() {
    super.onInit();
    _listenToTrips();
  }

  @override
  void onClose() {
    _tripsSubscription?.cancel();
    super.onClose();
  }

  void _listenToTrips() {
    final driver = _auth.currentUser;
    if (driver == null) {
      errorMessage.value = 'user_not_authenticated'.tr;
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    _tripsSubscription = _firestore
        .collection('trips')
        .where('driverId', isEqualTo: driver.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final pending = <TripModel>[];
            final upcoming = <TripModel>[];
            final past = <TripModel>[];

            for (final doc in snapshot.docs) {
              final trip = TripModel.fromFirestore(doc);
              switch (trip.status) {
                case TripStatus.awaitingDriverResponse:
                  pending.add(trip);
                  break;
                case TripStatus.accepted:
                case TripStatus.enRoutePickup:
                case TripStatus.enRouteDropoff:
                  upcoming.add(trip);
                  break;
                case TripStatus.rejected:
                case TripStatus.completed:
                case TripStatus.cancelled:
                  past.add(trip);
                  break;
              }
            }

            pendingTrips.assignAll(pending);
            upcomingTrips.assignAll(upcoming);
            pastTrips.assignAll(past);
            isLoading.value = false;
          },
          onError: (error) {
            errorMessage.value = 'failed_to_load_trips'.trArgs([error.toString()]);
            isLoading.value = false;
          },
        );
  }

  Future<void> fetchTrips() async {
    // Real-time updates are handled by _listenToTrips
    // This method is kept for compatibility
    _listenToTrips();
  }

  Future<void> acceptTrip(TripModel trip) async {
    if (processingTripIds.contains(trip.id)) return;
    processingTripIds.add(trip.id);

    try {
      await _updateTripStatus(
        trip,
        TripStatus.accepted,
        SubscriptionStatus.driverAssigned,
        notificationMessage: 'driver_accepted_trip'.tr,
      );
      CustomToasts(
        message: 'trip_accepted_success'.tr,
        type: CustomToastType.success,
      ).show();
    } catch (e) {
      CustomToasts(
        message: 'failed_to_accept_trip'.tr,
        type: CustomToastType.error,
      ).show();
    } finally {
      processingTripIds.remove(trip.id);
    }
  }

  Future<void> declineTrip(TripModel trip) async {
    if (processingTripIds.contains(trip.id)) return;
    processingTripIds.add(trip.id);

    try {
      await _updateTripStatus(
        trip,
        TripStatus.rejected,
        SubscriptionStatus.driverRejected,
        notificationMessage: 'driver_rejected_trip'.tr,
      );
      CustomToasts(
        message: 'trip_declined_success'.tr,
        type: CustomToastType.success,
      ).show();
    } catch (e) {
      CustomToasts(
        message: 'failed_to_decline_trip'.tr,
        type: CustomToastType.error,
      ).show();
    } finally {
      processingTripIds.remove(trip.id);
    }
  }

  Future<void> _updateTripStatus(
    TripModel trip,
    TripStatus tripStatus,
    SubscriptionStatus subscriptionStatus, {
    required String notificationMessage,
  }) async {
    final tripDoc = _firestore.collection('trips').doc(trip.id);
    final subscriptionDoc = _firestore.collection('subscriptions').doc(trip.subscriptionId);

    await _firestore.runTransaction((transaction) async {
      transaction.update(tripDoc, {
        'status': tripStatus.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      transaction.update(subscriptionDoc, {
        'status': subscriptionStatus.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });

    await _notificationService.sendNotificationToUser(
      userId: trip.parentId,
      title: 'trip_update'.tr,
      body: notificationMessage,
      type: NotificationService.driverAssignedType,
      data: {
        'tripId': trip.id,
        'subscriptionId': trip.subscriptionId,
        'status': tripStatus.name,
      },
    );
  }

  Future<void> deleteTrip(TripModel trip) async {
    if (processingTripIds.contains(trip.id)) return;
    processingTripIds.add(trip.id);

    try {
      // Check if trip has pending or active tasks
      final hasPendingTasks = _hasPendingOrActiveTasks(trip);
      
      if (hasPendingTasks) {
        CustomToasts(
          message: 'cannot_delete_trip_with_pending_tasks'.tr,
          type: CustomToastType.warning,
          duration: const Duration(seconds: 4),
        ).show();
        return;
      }

      // Delete trip from Firestore
      await _firestore.collection('trips').doc(trip.id).delete();

      // Also delete related safety events if any
      final safetyEventsSnapshot = await _firestore
          .collection('trips')
          .doc(trip.id)
          .collection('safety_events')
          .get();
      
      final batch = _firestore.batch();
      for (final doc in safetyEventsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      CustomToasts(
        message: 'trip_deleted_successfully'.tr,
        type: CustomToastType.success,
      ).show();
    } catch (e) {
      CustomToasts(
        message: 'failed_to_delete_trip'.tr,
        type: CustomToastType.error,
      ).show();
    } finally {
      processingTripIds.remove(trip.id);
    }
  }

  bool _hasPendingOrActiveTasks(TripModel trip) {
    // Check if trip has any pending or active status that prevents deletion
    switch (trip.status) {
      case TripStatus.awaitingDriverResponse:
      case TripStatus.accepted:
      case TripStatus.enRoutePickup:
      case TripStatus.enRouteDropoff:
        return true;
      case TripStatus.rejected:
      case TripStatus.completed:
      case TripStatus.cancelled:
        return false;
    }
  }

  void changeTab(DriverTripsTab tab) {
    selectedTab.value = tab;
  }

  static TripStatus steppedStatus(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.awaitingDriver:
        return TripStatus.awaitingDriverResponse;
      case SubscriptionStatus.driverAssigned:
        return TripStatus.accepted;
      case SubscriptionStatus.driverRejected:
        return TripStatus.rejected;
      case SubscriptionStatus.active:
        return TripStatus.enRoutePickup;
      case SubscriptionStatus.completed:
        return TripStatus.completed;
      case SubscriptionStatus.cancelled:
        return TripStatus.cancelled;
      case SubscriptionStatus.draft:
        return TripStatus.awaitingDriverResponse;
    }
  }
}
