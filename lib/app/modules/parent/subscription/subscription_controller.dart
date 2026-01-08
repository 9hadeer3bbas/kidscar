import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kidscar/data/models/subscription_model.dart';
import 'package:kidscar/data/models/trip_model.dart';
import '../../../../data/models/kid_model.dart';
import '../../../custom_widgets/custom_toast.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../domain/usecases/location/get_route_path_usecase.dart';
import '../../../../domain/value_objects/geo_point.dart' as domain_geo;
import '../../../../domain/core/result.dart';
import '../../../../domain/entities/route_path.dart';

class SubscriptionController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GetRoutePathUseCase _getRoutePathUseCase =
      Get.find<GetRoutePathUseCase>();

  // Pricing constants
  static const double basePrice = 0.0; // Base price in SAR (no base price)
  static const double pricePerKilometer = 15.0; // Price per kilometer in SAR

  // Form controllers
  final TextEditingController durationController = TextEditingController();
  final TextEditingController pickupLocationController =
      TextEditingController();
  final TextEditingController dropoffLocationController =
      TextEditingController();

  // Location data
  final Rx<LocationData?> selectedPickupLocation = Rx<LocationData?>(null);
  final Rx<LocationData?> selectedDropoffLocation = Rx<LocationData?>(null);

  // Observable variables
  final Rx<TripType> selectedTripType = TripType.roundTrip.obs;
  final RxList<DayOfWeek> selectedServiceDays = <DayOfWeek>[].obs;
  final RxInt numberOfChildren = 1.obs;
  final RxList<String> selectedChildrenIds = <String>[].obs;
  final Rx<CustomTimeOfDay?> selectedPickupTime = Rx<CustomTimeOfDay?>(null);
  final Rx<CustomTimeOfDay?> selectedReturnPickupTime = Rx<CustomTimeOfDay?>(
    null,
  );
  final RxDouble pricePerTrip = basePrice.obs;
  final RxDouble estimatedTotalPrice = 0.0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingChildren = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isCalculatingRoute = false.obs;
  final Rx<int?> routeDistanceMeters = Rx<int?>(null);

  // Available children and drivers
  final RxList<KidModel> availableChildren = <KidModel>[].obs;
  final RxList<DriverModel> availableDrivers = <DriverModel>[].obs;

  // Validation
  final RxString durationError = ''.obs;
  final RxString pickupLocationError = ''.obs;
  final RxString dropoffLocationError = ''.obs;
  final RxString serviceDaysError = ''.obs;
  final RxString pickupTimeError = ''.obs;
  final RxString returnPickupTimeError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    _setupPriceCalculation();
  }

  @override
  void onClose() {
    durationController.dispose();
    pickupLocationController.dispose();
    dropoffLocationController.dispose();
    super.onClose();
  }

  Future<void> _loadUserData() async {
    isLoading.value = true;
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _loadChildren(user.uid);
        await _loadAvailableDrivers();
      }
    } catch (e) {
      print('Error loading user data: $e');
      CustomToasts(
        message: 'failed_to_load_user_data'.tr,
        type: CustomToastType.error,
      ).show();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadChildren(String parentId) async {
    isLoadingChildren.value = true;
    try {
      final querySnapshot = await _firestore
          .collection('kids')
          .where('parentId', isEqualTo: parentId)
          .get();

      availableChildren.value = querySnapshot.docs
          .map((doc) => KidModel.fromFirestore(doc))
          .toList();

      // Auto-select first child if available
      if (availableChildren.isNotEmpty) {
        selectedChildrenIds.value = [availableChildren.first.id];
      }
    } catch (e) {
      print('Error loading children: $e');
      CustomToasts(
        message: 'failed_to_load_children'.tr,
        type: CustomToastType.error,
      ).show();
    } finally {
      isLoadingChildren.value = false;
    }
  }

  Future<void> _loadAvailableDrivers() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .where('isOnline', isEqualTo: true) // Only online drivers
          .get();

      availableDrivers.value = querySnapshot.docs
          .map((doc) => DriverModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error loading drivers: $e');
    }
  }

  void _setupPriceCalculation() {
    // Listen to changes and recalculate price
    ever(selectedServiceDays, (_) => _calculatePrice());
    ever(
      selectedChildrenIds,
      (_) => _calculatePrice(),
    ); // Listen to actual selected children
    ever(selectedTripType, (_) => _calculatePrice());
    ever(pricePerTrip, (_) => _calculatePrice());
    ever(routeDistanceMeters, (_) => _calculatePrice());

    // Listen to duration controller changes
    durationController.addListener(_calculatePrice);

    // Listen to location changes to calculate route distance
    ever(selectedPickupLocation, (_) => _calculateRouteDistance());
    ever(selectedDropoffLocation, (_) => _calculateRouteDistance());
  }

  void _calculatePrice() {
    final duration = int.tryParse(durationController.text) ?? 0;
    final serviceDaysCount = selectedServiceDays.length;
    final childrenCount =
        selectedChildrenIds.length; // Use actual selected children count
    final tripMultiplier = selectedTripType.value == TripType.roundTrip ? 2 : 1;

    estimatedTotalPrice.value =
        duration *
        serviceDaysCount *
        childrenCount *
        pricePerTrip.value *
        tripMultiplier;

    // Debug print for price calculation
    print('=== Price Calculation ===');
    print('Duration: $duration weeks');
    print('Service days: $serviceDaysCount');
    print('Children: $childrenCount');
    print('Price per trip: ${pricePerTrip.value}');
    print(
      'Route distance: ${routeDistanceMeters.value != null ? "${(routeDistanceMeters.value! / 1000).toStringAsFixed(2)} km" : "Not calculated"}',
    );
    print('Trip multiplier: $tripMultiplier');
    print('Estimated total: ${estimatedTotalPrice.value}');
    print('========================');
  }

  Future<void> _calculateRouteDistance() async {
    // Only calculate if both locations are set
    if (selectedPickupLocation.value == null ||
        selectedDropoffLocation.value == null) {
      routeDistanceMeters.value = null;
      // Reset to base price if locations are not set
      pricePerTrip.value = basePrice;
      return;
    }

    // Prevent multiple simultaneous calculations
    if (isCalculatingRoute.value) return;

    isCalculatingRoute.value = true;

    try {
      final routeResult = await _getRoutePathUseCase(
        GetRoutePathParams(
          origin: domain_geo.GeoPoint(
            latitude: selectedPickupLocation.value!.latitude,
            longitude: selectedPickupLocation.value!.longitude,
          ),
          destination: domain_geo.GeoPoint(
            latitude: selectedDropoffLocation.value!.latitude,
            longitude: selectedDropoffLocation.value!.longitude,
          ),
        ),
      );

      if (routeResult is ResultSuccess<RoutePath>) {
        final route = routeResult.data;
        if (route.distanceMeters != null) {
          routeDistanceMeters.value = route.distanceMeters;
          // Calculate price based on distance
          _updatePriceBasedOnDistance(route.distanceMeters!);
        } else {
          routeDistanceMeters.value = null;
          pricePerTrip.value = basePrice;
        }
      } else if (routeResult is ResultFailure<RoutePath>) {
        print(
          'Failed to calculate route distance: ${routeResult.failure.message}',
        );
        routeDistanceMeters.value = null;
        pricePerTrip.value = basePrice;
      }
    } catch (e) {
      print('Error calculating route distance: $e');
      routeDistanceMeters.value = null;
      pricePerTrip.value = basePrice;
    } finally {
      isCalculatingRoute.value = false;
    }
  }

  void _updatePriceBasedOnDistance(int distanceMeters) {
    // Convert meters to kilometers
    final distanceKm = distanceMeters / 1000.0;

    // Calculate price: base price + (distance in km * price per km)
    final calculatedPrice = basePrice + (distanceKm * pricePerKilometer);

    // Round to 2 decimal places
    pricePerTrip.value = double.parse(calculatedPrice.toStringAsFixed(2));

    print('💰 Distance-based pricing:');
    print('   Distance: ${distanceKm.toStringAsFixed(2)} km');
    print('   Base price: $basePrice SAR');
    print(
      '   Distance cost: ${(distanceKm * pricePerKilometer).toStringAsFixed(2)} SAR',
    );
    print('   Total price per trip: ${pricePerTrip.value} SAR');
  }

  // Helper methods for summary display
  String get routeDistanceDisplay {
    if (routeDistanceMeters.value == null) {
      return 'calculating'.tr;
    }
    final distanceKm = routeDistanceMeters.value! / 1000.0;
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get pickupLocationDisplay {
    if (selectedPickupLocation.value == null) return '-';
    final name = selectedPickupLocation.value!.name;
    // Show first 30 characters if too long
    return name.length > 30 ? '${name.substring(0, 30)}...' : name;
  }

  String get dropoffLocationDisplay {
    if (selectedDropoffLocation.value == null) return '-';
    final name = selectedDropoffLocation.value!.name;
    // Show first 30 characters if too long
    return name.length > 30 ? '${name.substring(0, 30)}...' : name;
  }

  // Trip type selection
  void selectTripType(TripType tripType) {
    selectedTripType.value = tripType;
    if (tripType == TripType.oneWay) {
      selectedReturnPickupTime.value = null;
    }
  }

  // Service days selection
  void toggleServiceDay(DayOfWeek day) {
    if (selectedServiceDays.contains(day)) {
      selectedServiceDays.remove(day);
    } else {
      selectedServiceDays.add(day);
    }
    serviceDaysError.value = '';
  }

  void selectAllServiceDays() {
    selectedServiceDays.value = DayOfWeek.values.toList();
    serviceDaysError.value = '';
  }

  void clearAllServiceDays() {
    selectedServiceDays.clear();
    serviceDaysError.value = '';
  }

  // Children selection
  void incrementChildren() {
    if (numberOfChildren.value < 5) {
      // Max 5 children
      numberOfChildren.value++;
    }
  }

  void decrementChildren() {
    if (numberOfChildren.value > 1) {
      numberOfChildren.value--;
    }
  }

  void toggleChildSelection(String childId) {
    if (selectedChildrenIds.contains(childId)) {
      selectedChildrenIds.remove(childId);
    } else {
      selectedChildrenIds.add(childId);
    }
  }

  // Time selection
  Future<void> selectPickupTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedPickupTime.value != null
          ? TimeOfDay(
              hour: selectedPickupTime.value!.hour,
              minute: selectedPickupTime.value!.minute,
            )
          : const TimeOfDay(hour: 7, minute: 0),
    );

    if (picked != null) {
      selectedPickupTime.value = CustomTimeOfDay(
        hour: picked.hour,
        minute: picked.minute,
      );
      pickupTimeError.value = '';
    }
  }

  Future<void> selectReturnPickupTime(BuildContext context) async {
    if (selectedTripType.value == TripType.oneWay) return;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedReturnPickupTime.value != null
          ? TimeOfDay(
              hour: selectedReturnPickupTime.value!.hour,
              minute: selectedReturnPickupTime.value!.minute,
            )
          : const TimeOfDay(hour: 10, minute: 0),
    );

    if (picked != null) {
      selectedReturnPickupTime.value = CustomTimeOfDay(
        hour: picked.hour,
        minute: picked.minute,
      );
      returnPickupTimeError.value = '';
    }
  }

  // Validation
  bool _validateForm() {
    bool isValid = true;

    // Duration validation
    final duration = int.tryParse(durationController.text);
    if (duration == null || duration < 1 || duration > 52) {
      durationError.value = 'please_enter_valid_duration'.tr;
      isValid = false;
    } else {
      durationError.value = '';
    }

    // Service days validation
    if (selectedServiceDays.isEmpty) {
      serviceDaysError.value = 'please_select_service_days'.tr;
      isValid = false;
    } else {
      serviceDaysError.value = '';
    }

    // Pickup time validation
    if (selectedPickupTime.value == null) {
      pickupTimeError.value = 'please_select_pickup_time'.tr;
      isValid = false;
    } else {
      pickupTimeError.value = '';
    }

    // Return pickup time validation (for round trip)
    if (selectedTripType.value == TripType.roundTrip &&
        selectedReturnPickupTime.value == null) {
      returnPickupTimeError.value = 'please_select_return_pickup_time'.tr;
      isValid = false;
    } else {
      returnPickupTimeError.value = '';
    }

    // Location validation
    if (selectedPickupLocation.value == null) {
      pickupLocationError.value = 'please_enter_pickup_location'.tr;
      isValid = false;
    } else {
      pickupLocationError.value = '';
    }

    if (selectedDropoffLocation.value == null) {
      dropoffLocationError.value = 'please_enter_dropoff_location'.tr;
      isValid = false;
    } else {
      dropoffLocationError.value = '';
    }

    // Children validation
    if (selectedChildrenIds.isEmpty) {
      CustomToasts(
        message: 'please_select_at_least_one_child'.tr,
        type: CustomToastType.warning,
      ).show();
      isValid = false;
    }

    return isValid;
  }

  // Submit subscription - now navigates to driver selection first
  Future<void> submitSubscription() async {
    if (!_validateForm()) {
      CustomToasts(
        message: 'please_fill_all_required_fields'.tr,
        type: CustomToastType.warning,
      ).show();
      return;
    }

    // Navigate to driver selection with subscription data
    Get.toNamed('/driver-selection', arguments: _getSubscriptionData());
  }

  // Get subscription data for driver selection
  Map<String, dynamic> _getSubscriptionData() {
    return {
      'parentId': _auth.currentUser?.uid,
      'durationWeeks': int.parse(durationController.text),
      'tripType': selectedTripType.value.name,
      'serviceDays': selectedServiceDays.map((e) => e.name).toList(),
      'numberOfChildren': selectedChildrenIds.length,
      'selectedChildrenIds': selectedChildrenIds.toList(),
      'pickupLocation': selectedPickupLocation.value!.toJson(),
      'dropoffLocation': selectedDropoffLocation.value!.toJson(),
      'pickupTime': selectedPickupTime.value!.toJson(),
      'returnPickupTime': selectedReturnPickupTime.value?.toJson(),
      'pricePerTrip': pricePerTrip.value,
      'estimatedTotalPrice': estimatedTotalPrice.value,
    };
  }

  // Create subscription with driver ID (called from driver selection)
  Future<void> createSubscriptionWithDriver(String driverId) async {
    isSubmitting.value = true;
    try {
      final user = _auth.currentUser;
      if (user == null) {
        CustomToasts(
          message: 'user_not_authenticated'.tr,
          type: CustomToastType.error,
        ).show();
        return;
      }

      final tripId = _firestore.collection('trips').doc().id;
      final subscriptionId = _firestore.collection('subscriptions').doc().id;

      final subscription = SubscriptionModel(
        id: subscriptionId,
        parentId: user.uid,
        driverId: driverId,
        durationWeeks: int.parse(durationController.text),
        tripType: selectedTripType.value,
        serviceDays: selectedServiceDays.toList(),
        numberOfChildren: selectedChildrenIds.length,
        selectedChildrenIds: selectedChildrenIds.toList(),
        pickupLocation: selectedPickupLocation.value!,
        dropoffLocation: selectedDropoffLocation.value!,
        pickupTime: selectedPickupTime.value!,
        returnPickupTime: selectedReturnPickupTime.value,
        pricePerTrip: pricePerTrip.value,
        estimatedTotalPrice: estimatedTotalPrice.value,
        status: SubscriptionStatus.awaitingDriver,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tripId: tripId,
      );

      final trip = TripModel(
        id: tripId,
        subscriptionId: subscriptionId,
        driverId: driverId,
        parentId: user.uid,
        kidIds: selectedChildrenIds.toList(),
        pickupLocation: selectedPickupLocation.value!,
        dropoffLocation: selectedDropoffLocation.value!,
        pickupTime: selectedPickupTime.value!,
        returnPickupTime: selectedReturnPickupTime.value,
        status: TripStatus.awaitingDriverResponse,
        scheduledDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        encodedPolyline: null,
        distanceMeters: null,
        durationSeconds: null,
      );

      await _firestore.runTransaction((transaction) async {
        transaction.set(
          _firestore.collection('subscriptions').doc(subscriptionId),
          subscription.toJson(),
        );
        transaction.set(
          _firestore.collection('trips').doc(tripId),
          trip.toJson(),
        );
      });

      // Send notification to driver
      try {
        final notificationService = Get.find<NotificationService>();
        await notificationService.sendNotificationToUser(
          userId: driverId,
          title: 'New Subscription Assignment',
          body:
              'You have been assigned a new subscription. Check details in your dashboard.',
          type: NotificationService.newSubscriptionType,
          data: {
            'subscriptionId': subscriptionId,
            'tripId': tripId,
            'parentId': user.uid,
            'pickupLocation': subscription.pickupLocation.name,
            'dropoffLocation': subscription.dropoffLocation.name,
            'pickupTime': subscription.pickupTime.formattedString,
            'duration': '${subscription.durationWeeks} weeks',
            'price': '${subscription.estimatedTotalPrice.toInt()} SAR',
          },
        );
        print('Driver notification sent successfully');
      } catch (e) {
        print('Error sending driver notification: $e');
        // Don't fail the subscription creation if notification fails
      }

      CustomToasts(
        message: 'subscription_created_successfully'.tr,
        type: CustomToastType.success,
      ).show();

      Get.offAllNamed('/parent-main-view');
    } catch (e) {
      print('Error creating subscription: $e');
      CustomToasts(
        message: 'failed_to_create_subscription'.tr,
        type: CustomToastType.error,
      ).show();
    } finally {
      isSubmitting.value = false;
    }
  }

  // Location handling
  void setPickupLocation(LocationData location) {
    print('📍 CONTROLLER: Setting pickup location');
    print('   Name: ${location.name}');
    print('   Latitude: ${location.latitude}');
    print('   Longitude: ${location.longitude}');
    print('   Address: ${location.address}');

    selectedPickupLocation.value = location;
    pickupLocationController.text = location.name;
    pickupLocationError.value = '';

    print('✅ CONTROLLER: Pickup location set successfully');
    print(
      '   Stored value: ${selectedPickupLocation.value?.latitude}, ${selectedPickupLocation.value?.longitude}',
    );

    // Route distance will be calculated automatically via ever() listener
  }

  void setDropoffLocation(LocationData location) {
    print('📍 CONTROLLER: Setting dropoff location');
    print('   Name: ${location.name}');
    print('   Latitude: ${location.latitude}');
    print('   Longitude: ${location.longitude}');
    print('   Address: ${location.address}');

    selectedDropoffLocation.value = location;
    dropoffLocationController.text = location.name;
    dropoffLocationError.value = '';

    print('✅ CONTROLLER: Dropoff location set successfully');
    print(
      '   Stored value: ${selectedDropoffLocation.value?.latitude}, ${selectedDropoffLocation.value?.longitude}',
    );

    // Route distance will be calculated automatically via ever() listener
  }

  // Helper methods
  String getDayName(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.saturday:
        return 'saturday'.tr;
      case DayOfWeek.sunday:
        return 'sunday'.tr;
      case DayOfWeek.monday:
        return 'monday'.tr;
      case DayOfWeek.tuesday:
        return 'tuesday'.tr;
      case DayOfWeek.wednesday:
        return 'wednesday'.tr;
      case DayOfWeek.thursday:
        return 'thursday'.tr;
      case DayOfWeek.friday:
        return 'friday'.tr;
    }
  }

  String getTripTypeText(TripType tripType) {
    switch (tripType) {
      case TripType.oneWay:
        return 'one_way'.tr;
      case TripType.roundTrip:
        return 'round_trip'.tr;
    }
  }

  bool get canProceed {
    final durationValid = durationController.text.isNotEmpty;
    final serviceDaysValid = selectedServiceDays.isNotEmpty;
    final pickupTimeValid = selectedPickupTime.value != null;
    final pickupLocationValid = selectedPickupLocation.value != null;
    final dropoffLocationValid = selectedDropoffLocation.value != null;
    final childrenValid = selectedChildrenIds.isNotEmpty;
    final returnTimeValid =
        selectedTripType.value == TripType.oneWay ||
        selectedReturnPickupTime.value != null;

    // Debug logging
    print('=== Continue Button Validation ===');
    print('Duration valid: $durationValid (${durationController.text})');
    print(
      'Service days valid: $serviceDaysValid (${selectedServiceDays.length} days)',
    );
    print('Pickup time valid: $pickupTimeValid (${selectedPickupTime.value})');
    print(
      'Pickup location valid: $pickupLocationValid (${selectedPickupLocation.value?.name})',
    );
    print(
      'Dropoff location valid: $dropoffLocationValid (${selectedDropoffLocation.value?.name})',
    );
    print(
      'Children valid: $childrenValid (${selectedChildrenIds.length} children)',
    );
    print(
      'Return time valid: $returnTimeValid (${selectedReturnPickupTime.value})',
    );
    print('Trip type: ${selectedTripType.value}');
    print(
      'Can proceed: ${durationValid && serviceDaysValid && pickupTimeValid && pickupLocationValid && dropoffLocationValid && childrenValid && returnTimeValid}',
    );
    print('================================');

    return durationValid &&
        serviceDaysValid &&
        pickupTimeValid &&
        pickupLocationValid &&
        dropoffLocationValid &&
        childrenValid &&
        returnTimeValid;
  }
}
