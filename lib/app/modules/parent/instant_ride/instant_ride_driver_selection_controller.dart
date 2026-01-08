import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../data/models/subscription_model.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../core/services/notification_service.dart';
import '../../../custom_widgets/custom_toast.dart';

class InstantRideDriverSelectionController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService =
      Get.find<NotificationService>();

  final RxList<DriverModel> availableDrivers = <DriverModel>[].obs;
  final RxString selectedDriverId = ''.obs;
  final RxBool isLoading = true.obs;
  final RxBool isProcessing = false.obs;

  Map<String, dynamic>? rideData;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      rideData = args;
    }
    loadAvailableDrivers();
  }

  Future<void> loadAvailableDrivers() async {
    isLoading.value = true;
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .where('isOnline', isEqualTo: true) // Only online drivers
          .get();

      availableDrivers.value = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            return DriverModel(
              id: doc.id,
              fullName: data['fullName'] ?? 'Unknown Driver',
              age: data['age'] ?? 25,
              profileImageUrl: data['profileImageUrl'],
              rating: (data['rating'] ?? 4.5).toDouble(),
              totalTrips: data['totalTrips'] ?? 0,
              phoneNumber: data['phoneNumber'] ?? '',
              licenseNumber: data['licenseNumber'] ?? '',
              isAvailable: data['isAvailable'] ?? true,
              createdAt: data['createdAt'] != null
                  ? (data['createdAt'] is Timestamp
                      ? (data['createdAt'] as Timestamp).toDate()
                      : DateTime.tryParse(data['createdAt']) ?? DateTime.now())
                  : DateTime.now(),
              updatedAt: data['updatedAt'] != null
                  ? (data['updatedAt'] is Timestamp
                      ? (data['updatedAt'] as Timestamp).toDate()
                      : DateTime.tryParse(data['updatedAt']) ?? DateTime.now())
                  : DateTime.now(),
            );
          })
          .where((driver) => driver.isAvailable)
          .toList();

      availableDrivers.sort((a, b) => b.rating.compareTo(a.rating));
    } catch (e) {
      CustomToasts(
        message: 'failed_to_load_drivers'.tr.replaceAll('{error}', e.toString()),
        type: CustomToastType.error,
      ).show();
    } finally {
      isLoading.value = false;
    }
  }

  void selectDriver(String driverId) {
    selectedDriverId.value = driverId;
  }

  Future<void> createInstantRide() async {
    if (selectedDriverId.value.isEmpty) {
      CustomToasts(
        message: 'please_select_driver'.tr,
        type: CustomToastType.warning,
      ).show();
      return;
    }

    if (rideData == null) {
      CustomToasts(
        message: 'invalid_ride_data'.tr,
        type: CustomToastType.error,
      ).show();
      return;
    }

    isProcessing.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        CustomToasts(
          message: 'user_not_authenticated'.tr,
          type: CustomToastType.error,
        ).show();
        return;
      }

      final tripId = _firestore.collection('trips').doc().id;

      final trip = TripModel(
        id: tripId,
        subscriptionId: 'instant_ride', // Mark as instant ride
        driverId: selectedDriverId.value,
        parentId: rideData!['parentId'] as String,
        kidIds: List<String>.from(rideData!['selectedChildrenIds'] as List),
        pickupLocation: LocationData.fromJson(
          Map<String, dynamic>.from(rideData!['pickupLocation'] as Map),
        ),
        dropoffLocation: LocationData.fromJson(
          Map<String, dynamic>.from(rideData!['dropoffLocation'] as Map),
        ),
        pickupTime: CustomTimeOfDay.fromJson(
          Map<String, dynamic>.from(rideData!['pickupTime'] as Map),
        ),
        returnPickupTime: null,
        status: TripStatus.accepted, // Instant rides are auto-accepted
        scheduledDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        encodedPolyline: null,
        distanceMeters: rideData!['distanceMeters'] as int?,
        durationSeconds: null,
      );

      await _firestore.collection('trips').doc(tripId).set(trip.toJson());

      // Send notification to driver
      await _notificationService.sendNotificationToUser(
        userId: selectedDriverId.value,
        title: 'instant_ride_notification_title'.tr,
        body: 'instant_ride_notification_body'.tr,
        type: NotificationService.driverAssignedType,
        data: {
          'tripId': tripId,
          'type': 'instant_ride',
          'pickupLocation': trip.pickupLocation.name,
          'dropoffLocation': trip.dropoffLocation.name,
          'pickupTime': trip.pickupTime.formattedString,
        },
      );

      CustomToasts(
        message: 'instant_ride_created_successfully'.tr,
        type: CustomToastType.success,
      ).show();

      Get.offAllNamed('/parent-main-view');
    } catch (e) {
      CustomToasts(
        message: 'failed_to_create_ride'.tr,
        type: CustomToastType.error,
      ).show();
    } finally {
      isProcessing.value = false;
    }
  }
}

