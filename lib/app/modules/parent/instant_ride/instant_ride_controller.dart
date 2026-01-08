import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kidscar/data/models/subscription_model.dart';
import '../../../../data/models/kid_model.dart';
import '../../../custom_widgets/custom_toast.dart';
import '../../../../domain/usecases/location/get_route_path_usecase.dart';
import '../../../../domain/value_objects/geo_point.dart' as domain_geo;
import '../../../../domain/core/result.dart';
import '../../../../domain/entities/route_path.dart';

class InstantRideController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GetRoutePathUseCase _getRoutePathUseCase =
      Get.find<GetRoutePathUseCase>();

  // Pricing constants
  static const double basePrice = 0.0; // Base price in SAR (no base price)
  static const double pricePerKilometer = 15.0; // Price per kilometer in SAR

  // Location data
  final Rx<LocationData?> selectedPickupLocation = Rx<LocationData?>(null);
  final Rx<LocationData?> selectedDropoffLocation = Rx<LocationData?>(null);

  // Observable variables
  final RxList<String> selectedChildrenIds = <String>[].obs;
  final Rx<CustomTimeOfDay?> selectedPickupTime = Rx<CustomTimeOfDay?>(null);
  final RxDouble estimatedPrice = 0.0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingChildren = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isCalculatingRoute = false.obs;
  final Rx<int?> routeDistanceMeters = Rx<int?>(null);

  // Available children and drivers
  final RxList<KidModel> availableChildren = <KidModel>[].obs;
  final RxList<DriverModel> availableDrivers = <DriverModel>[].obs;

  // Validation
  final RxString pickupLocationError = ''.obs;
  final RxString dropoffLocationError = ''.obs;
  final RxString pickupTimeError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    _setupPriceCalculation();
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
      debugPrint('Error loading user data: $e');
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
      debugPrint('Error loading children: $e');
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

      availableDrivers.sort((a, b) => b.rating.compareTo(a.rating));
    } catch (e) {
      debugPrint('Error loading drivers: $e');
    }
  }

  void _setupPriceCalculation() {
    ever(selectedChildrenIds, (_) => _calculatePrice());
    ever(routeDistanceMeters, (_) => _calculatePrice());

    // Listen to location changes to calculate route distance
    ever(selectedPickupLocation, (_) => _calculateRouteDistance());
    ever(selectedDropoffLocation, (_) => _calculateRouteDistance());
  }

  void _calculatePrice() {
    final childrenCount = selectedChildrenIds.length;
    double pricePerTrip = basePrice;

    // Calculate price based on distance if available
    if (routeDistanceMeters.value != null) {
      final distanceKm = routeDistanceMeters.value! / 1000.0;
      pricePerTrip = basePrice + (distanceKm * pricePerKilometer);
    }

    // Multiply by number of children
    estimatedPrice.value = pricePerTrip * childrenCount;

    debugPrint('💰 Instant Ride Price Calculation:');
    debugPrint('   Distance: ${routeDistanceMeters.value != null ? "${(routeDistanceMeters.value! / 1000).toStringAsFixed(2)} km" : "Not calculated"}');
    debugPrint('   Price per trip: ${pricePerTrip.toStringAsFixed(2)} SAR');
    debugPrint('   Children: $childrenCount');
    debugPrint('   Total price: ${estimatedPrice.value.toStringAsFixed(2)} SAR');
  }

  Future<void> _calculateRouteDistance() async {
    // Only calculate if both locations are set
    if (selectedPickupLocation.value == null ||
        selectedDropoffLocation.value == null) {
      routeDistanceMeters.value = null;
      estimatedPrice.value = 0.0;
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
        } else {
          routeDistanceMeters.value = null;
        }
      } else if (routeResult is ResultFailure<RoutePath>) {
        debugPrint(
          'Failed to calculate route distance: ${routeResult.failure.message}',
        );
        routeDistanceMeters.value = null;
      }
    } catch (e) {
      debugPrint('Error calculating route distance: $e');
      routeDistanceMeters.value = null;
    } finally {
      isCalculatingRoute.value = false;
    }
  }

  // Helper methods for display
  String get routeDistanceDisplay {
    if (routeDistanceMeters.value == null) {
      return 'calculating'.tr;
    }
    final distanceKm = routeDistanceMeters.value! / 1000.0;
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  void toggleChildSelection(String childId) {
    if (selectedChildrenIds.contains(childId)) {
      selectedChildrenIds.remove(childId);
    } else {
      selectedChildrenIds.add(childId);
    }
  }

  Future<void> selectPickupTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedPickupTime.value != null
          ? TimeOfDay(
              hour: selectedPickupTime.value!.hour,
              minute: selectedPickupTime.value!.minute,
            )
          : TimeOfDay.now(),
    );

    if (picked != null) {
      selectedPickupTime.value = CustomTimeOfDay(
        hour: picked.hour,
        minute: picked.minute,
      );
      pickupTimeError.value = '';
    }
  }

  void setPickupLocation(LocationData location) {
    debugPrint('📍 CONTROLLER: Setting pickup location');
    debugPrint('   Name: ${location.name}');
    debugPrint('   Latitude: ${location.latitude}');
    debugPrint('   Longitude: ${location.longitude}');
    debugPrint('   Address: ${location.address}');
    
    selectedPickupLocation.value = location;
    pickupLocationError.value = '';
    
    debugPrint('✅ CONTROLLER: Pickup location set successfully');
    debugPrint('   Stored value: ${selectedPickupLocation.value?.latitude}, ${selectedPickupLocation.value?.longitude}');
  }

  void setDropoffLocation(LocationData location) {
    debugPrint('📍 CONTROLLER: Setting dropoff location');
    debugPrint('   Name: ${location.name}');
    debugPrint('   Latitude: ${location.latitude}');
    debugPrint('   Longitude: ${location.longitude}');
    debugPrint('   Address: ${location.address}');
    
    selectedDropoffLocation.value = location;
    dropoffLocationError.value = '';
    
    debugPrint('✅ CONTROLLER: Dropoff location set successfully');
    debugPrint('   Stored value: ${selectedDropoffLocation.value?.latitude}, ${selectedDropoffLocation.value?.longitude}');
  }

  bool _validateForm() {
    bool isValid = true;

    if (selectedPickupTime.value == null) {
      pickupTimeError.value = 'please_select_pickup_time'.tr;
      isValid = false;
    } else {
      pickupTimeError.value = '';
    }

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

    if (selectedChildrenIds.isEmpty) {
      CustomToasts(
        message: 'please_select_at_least_one_child'.tr,
        type: CustomToastType.warning,
      ).show();
      isValid = false;
    }

    return isValid;
  }

  Future<void> proceedToDriverSelection() async {
    if (!_validateForm()) {
      CustomToasts(
        message: 'please_fill_all_required_fields'.tr,
        type: CustomToastType.warning,
      ).show();
      return;
    }

    // Navigate to driver selection with ride data
    Get.toNamed('/instant-ride-driver-selection', arguments: _getRideData());
  }

  Map<String, dynamic> _getRideData() {
    return {
      'type': 'instant_ride',
      'parentId': _auth.currentUser?.uid,
      'selectedChildrenIds': selectedChildrenIds.toList(),
      'pickupLocation': selectedPickupLocation.value!.toJson(),
      'dropoffLocation': selectedDropoffLocation.value!.toJson(),
      'pickupTime': selectedPickupTime.value!.toJson(),
      'estimatedPrice': estimatedPrice.value,
      'distanceMeters': routeDistanceMeters.value,
    };
  }

  bool get canProceed {
    final pickupTimeValid = selectedPickupTime.value != null;
    final pickupLocationValid = selectedPickupLocation.value != null;
    final dropoffLocationValid = selectedDropoffLocation.value != null;
    final childrenValid = selectedChildrenIds.isNotEmpty;

    return pickupTimeValid &&
        pickupLocationValid &&
        dropoffLocationValid &&
        childrenValid;
  }
}
