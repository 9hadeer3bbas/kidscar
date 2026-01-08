import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../data/models/subscription_model.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../data/models/trip_model.dart';
import '../../../custom_widgets/custom_toast.dart';

class DriverSelectionController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService =
      Get.find<NotificationService>();

  // Observable variables
  final RxList<DriverModel> availableDrivers = <DriverModel>[].obs;
  final RxString selectedDriverId = ''.obs;
  final RxBool isLoading = true.obs;
  final RxBool isProcessing = false.obs;

  // Subscription data from subscription page
  Map<String, dynamic>? subscriptionData;
  String? subscriptionId; // For backward compatibility

  @override
  void onInit() {
    super.onInit();
    // Get subscription data from arguments
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      subscriptionData = args;
    } else if (args is String) {
      // Backward compatibility - if it's a string, it's a subscription ID
      subscriptionId = args;
    }
    loadAvailableDrivers();
  }

  Future<void> loadAvailableDrivers() async {
    isLoading.value = true;
    try {
      print('Loading drivers from users collection...'); // Debug print

      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .where('isOnline', isEqualTo: true)  // Only online drivers
          .get();

      print(
        'Found ${querySnapshot.docs.length} users with driver role',
      ); // Debug print

      // Convert users to DriverModel format
      availableDrivers.value = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            print(
              'Driver data: ${doc.id} - ${data['fullName']} - Available: ${data['isAvailable']}',
            ); // Debug print

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
                        : DateTime.tryParse(data['createdAt']) ??
                              DateTime.now())
                  : DateTime.now(),
              updatedAt: data['updatedAt'] != null
                  ? (data['updatedAt'] is Timestamp
                        ? (data['updatedAt'] as Timestamp).toDate()
                        : DateTime.tryParse(data['updatedAt']) ??
                              DateTime.now())
                  : DateTime.now(),
            );
          })
          .where((driver) => driver.isAvailable)
          .toList();

      print(
        'Filtered to ${availableDrivers.length} available drivers',
      ); // Debug print

      // Sort by rating (highest first)
      availableDrivers.sort((a, b) => b.rating.compareTo(a.rating));

      print(
        'Drivers loaded successfully: ${availableDrivers.map((d) => d.fullName).join(', ')}',
      ); // Debug print
    } catch (e) {
      print('Error loading drivers: $e');
      CustomToasts(
        message: 'failed_to_load_drivers'.tr.replaceAll(
          '{error}',
          e.toString(),
        ),
        type: CustomToastType.error,
      ).show();
    } finally {
      isLoading.value = false;
    }
  }

  void selectDriver(String driverId) {
    print('Selecting driver: $driverId'); // Debug print
    selectedDriverId.value = driverId;
    print(
      'Selected driver ID updated to: ${selectedDriverId.value}',
    ); // Debug print

    // Find the selected driver for additional info
    try {
      final selectedDriver = availableDrivers.firstWhere(
        (driver) => driver.id == driverId,
      );
      print('Selected driver: ${selectedDriver.fullName}'); // Debug print
    } catch (e) {
      print('Driver not found in available drivers list'); // Debug print
    }
  }

  Future<void> proceedToPayment() async {
    if (selectedDriverId.value.isEmpty) {
      CustomToasts(
        message: 'please_select_driver'.tr,
        type: CustomToastType.warning,
      ).show();
      return;
    }

    isProcessing.value = true;
    try {
      if (subscriptionData != null) {
        // New flow: Create subscription with driver ID
        await _createSubscriptionWithDriver();
      } else if (subscriptionId != null) {
        // Old flow: Update existing subscription
        await _updateExistingSubscription();
      } else {
        CustomToasts(
          message: 'invalid_subscription'.tr,
          type: CustomToastType.error,
        ).show();
        return;
      }
    } catch (e) {
      print('Error processing payment: $e');
      CustomToasts(
        message: 'failed_to_process'.tr,
        type: CustomToastType.error,
      ).show();
    } finally {
      isProcessing.value = false;
    }
  }

  // Create new subscription with driver ID
  Future<void> _createSubscriptionWithDriver() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        CustomToasts(
          message: 'user_not_authenticated'.tr,
          type: CustomToastType.error,
        ).show();
        return;
      }

      // Create subscription with driver ID
      final tripId = FirebaseFirestore.instance.collection('trips').doc().id;
      final subscriptionId = FirebaseFirestore.instance
          .collection('subscriptions')
          .doc()
          .id;

      final tripTypeString = subscriptionData!['tripType'] as String;
      final TripType tripType = TripType.values.firstWhere(
        (type) => type.name == tripTypeString,
      );
      final serviceDays = (subscriptionData!['serviceDays'] as List<dynamic>)
          .map((day) => DayOfWeek.values.firstWhere((e) => e.name == day))
          .toList();

      final subscription = SubscriptionModel(
        id: subscriptionId,
        parentId: subscriptionData!['parentId'] as String,
        driverId: selectedDriverId.value,
        durationWeeks: subscriptionData!['durationWeeks'] as int,
        tripType: tripType,
        serviceDays: serviceDays,
        numberOfChildren: subscriptionData!['numberOfChildren'] as int,
        selectedChildrenIds: List<String>.from(
          subscriptionData!['selectedChildrenIds'] as List,
        ),
        pickupLocation: LocationData.fromJson(
          Map<String, dynamic>.from(subscriptionData!['pickupLocation'] as Map),
        ),
        dropoffLocation: LocationData.fromJson(
          Map<String, dynamic>.from(
            subscriptionData!['dropoffLocation'] as Map,
          ),
        ),
        pickupTime: CustomTimeOfDay.fromJson(
          Map<String, dynamic>.from(subscriptionData!['pickupTime'] as Map),
        ),
        returnPickupTime: subscriptionData!['returnPickupTime'] != null
            ? CustomTimeOfDay.fromJson(
                Map<String, dynamic>.from(
                  subscriptionData!['returnPickupTime'] as Map,
                ),
              )
            : null,
        pricePerTrip: subscriptionData!['pricePerTrip'] as double,
        estimatedTotalPrice: subscriptionData!['estimatedTotalPrice'] as double,
        status: SubscriptionStatus.awaitingDriver,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tripId: tripId,
      );

      final trip = TripModel(
        id: tripId,
        subscriptionId: subscriptionId,
        driverId: selectedDriverId.value,
        parentId: subscription.parentId,
        kidIds: List<String>.from(
          subscriptionData!['selectedChildrenIds'] as List,
        ),
        pickupLocation: subscription.pickupLocation,
        dropoffLocation: subscription.dropoffLocation,
        pickupTime: subscription.pickupTime,
        returnPickupTime: subscription.returnPickupTime,
        status: TripStatus.awaitingDriverResponse,
        scheduledDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        encodedPolyline: null,
        distanceMeters: null,
        durationSeconds: null,
      );

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.set(
          FirebaseFirestore.instance
              .collection('subscriptions')
              .doc(subscriptionId),
          subscription.toJson(),
        );
        transaction.set(
          FirebaseFirestore.instance.collection('trips').doc(tripId),
          trip.toJson(),
        );
      });

      // Send notification to driver
      await _sendDriverNotification(subscription);

      CustomToasts(
        message: 'driver_assigned_successfully'.tr,
        type: CustomToastType.success,
      ).show();

      // Navigate back to parent home
      Get.offAllNamed('/parent-main-view');
    } catch (e) {
      print('Error creating subscription with driver: $e');
      CustomToasts(
        message: 'failed_to_create_subscription'.tr,
        type: CustomToastType.error,
      ).show();
    }
  }

  // Update existing subscription (backward compatibility)
  Future<void> _updateExistingSubscription() async {
    // Update subscription with selected driver
    await _firestore.collection('subscriptions').doc(subscriptionId).update({
      'driverId': selectedDriverId.value,
      'status': SubscriptionStatus.driverAssigned.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Send notification to driver
    await _sendDriverNotification();

    CustomToasts(
      message: 'driver_assigned_successfully'.tr,
      type: CustomToastType.success,
    ).show();

    // Navigate to payment or back to home
    Get.offAllNamed('/parent-main-view');
  }

  Future<void> _sendDriverNotification([
    SubscriptionModel? subscription,
  ]) async {
    try {
      SubscriptionModel? sub;

      if (subscription != null) {
        // New subscription passed as parameter
        sub = subscription;
      } else if (subscriptionId != null) {
        // Get subscription details from database
        final subscriptionDoc = await _firestore
            .collection('subscriptions')
            .doc(subscriptionId!)
            .get();

        if (subscriptionDoc.exists) {
          sub = SubscriptionModel.fromFirestore(subscriptionDoc);
        }
      }

      if (sub != null) {
        print('=== SENDING DRIVER NOTIFICATION ===');
        print('Driver ID: ${selectedDriverId.value}');
        print('Subscription ID: ${sub.id}');
        print('Trip ID: ${sub.tripId}');
        
        // Send notification to driver
        try {
          await _notificationService.sendNotificationToUser(
            userId: selectedDriverId.value,
            title: 'New Subscription Assignment',
            body:
                'You have been assigned a new subscription. Check details in your dashboard.',
            type: NotificationService.newSubscriptionType,
            data: {
              'subscriptionId': sub.id,
              'tripId': sub.tripId ?? '',
              'parentId': sub.parentId,
              'pickupLocation': sub.pickupLocation.name,
              'dropoffLocation': sub.dropoffLocation.name,
              'pickupTime': sub.pickupTime.formattedString,
              'duration': '${sub.durationWeeks} weeks',
              'price': '${sub.estimatedTotalPrice.toInt()} SAR',
            },
          );

          print('✅ Driver notification sent successfully');
        } catch (notificationError) {
          print('❌ Error sending notification: $notificationError');
          print('Stack trace: ${StackTrace.current}');
          // Don't fail the subscription creation if notification fails
        }
      } else {
        print('⚠️ Subscription is null, cannot send notification');
      }
    } catch (e) {
      print('❌ Error in _sendDriverNotification: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }
}
