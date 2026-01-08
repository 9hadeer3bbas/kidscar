import 'package:get/get.dart';
import 'package:kidscar/core/routes/get_routes.dart';
import 'package:kidscar/data/models/trip_model.dart';
import '../../../custom_widgets/custom_toast.dart';
import '../parent_activity/parent_activity_controller.dart';

class ParentHomeController extends GetxController {
  // Observable variables
  final isLoading = false.obs;
  final currentLocation = 'Current location'.obs;
  final Rxn<TripModel> currentTrip = Rxn<TripModel>();

  // Sample data for favorites
  final favorites = <Map<String, dynamic>>[
    {
      'title': 'School',
      'date': 'Aug 1',
      'time': '6:30 AM',
      'price': '10 \$',
      'distance': '6.2 km',
      'image': 'assets/images/school_placeholder.png',
    },
    {
      'title': 'Grandma\'s',
      'date': 'Aug 10',
      'time': '8:40 PM',
      'price': '15 \$',
      'distance': '8.5 km',
      'image': 'assets/images/grandma_placeholder.png',
    },
  ].obs;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
    // Initialize ParentActivityController to load trips data
    // This ensures trips are available on home page
    if (!Get.isRegistered<ParentActivityController>()) {
      Get.put(ParentActivityController());
    }
    final activityController = Get.find<ParentActivityController>();
    activityController.refreshTrips();

    // Listen to trips to detect current trip
    ever(
      activityController.trips,
      (_) => _updateCurrentTrip(activityController),
    );
    _updateCurrentTrip(activityController);
  }

  void _updateCurrentTrip(ParentActivityController activityController) {
    final now = DateTime.now();
    final activeTrips = activityController.trips.where((trip) {
      final isActiveStatus =
          trip.status == TripStatus.accepted ||
          trip.status == TripStatus.enRoutePickup ||
          trip.status == TripStatus.enRouteDropoff;
      return isActiveStatus;
    }).toList();

    if (activeTrips.isNotEmpty) {
      // Get the most recent active trip
      activeTrips.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      currentTrip.value = activeTrips.first;
    } else {
      currentTrip.value = null;
    }
  }

  void viewCurrentTrip() {
    final trip = currentTrip.value;
    if (trip != null) {
      Get.toNamed(AppRoutes.parentTripDetail, arguments: trip);
    }
  }

  void _initializeData() {
    // Initialize any required data
    isLoading.value = false;
  }

  void onSubscriptionTap() {
    // Navigate to subscription page
    Get.toNamed('/subscription');
  }

  void onMyKidsTap() {
    // Navigate to my kids page
    Get.toNamed('/my-kids');
  }

  void onRideTap() {
    // Navigate to instant ride booking page
    Get.toNamed('/instant-ride');
  }

  void onBookAgainTap(int index) {
    // Handle book again action
    final favorite = favorites[index];
    CustomToasts(
      message: 'booking_again'.tr.replaceAll('{title}', favorite['title']),
      type: CustomToastType.success,
    ).show();
  }

  void onNotificationTap() {
    // Handle notification tap
    CustomToasts(
      message: 'notifications_feature_coming_soon'.tr,
      type: CustomToastType.warning,
    ).show();
  }

  void onLocationTap() {
    // Handle location tap
    CustomToasts(
      message: 'location_services_coming_soon'.tr,
      type: CustomToastType.warning,
    ).show();
  }
}
