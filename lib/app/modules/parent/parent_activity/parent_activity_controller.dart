import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../core/routes/get_routes.dart';

class ParentActivityController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final isLoading = false.obs;
  final trips = <TripModel>[].obs;
  final upcomingTrips = <TripModel>[].obs;
  final completedTrips = <TripModel>[].obs;
  final totalTripsCount = 0.obs;
  final thisMonthTripsCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadTrips();
  }

  Future<void> loadTrips() async {
    try {
      isLoading.value = true;
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        isLoading.value = false;
        return;
      }

      thisMonthTripsCount.value = 0;
      // Query trips for this parent
      final querySnapshot = await _firestore
          .collection('trips')
          .where('parentId', isEqualTo: currentUser.uid)
          .limit(100)
          .get();

      final loadedTrips = <TripModel>[];
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      for (var doc in querySnapshot.docs) {
        try {
          final trip = TripModel.fromFirestore(doc);
          loadedTrips.add(trip);

          // Count this month's trips
          if (trip.createdAt.isAfter(startOfMonth)) {
            thisMonthTripsCount.value++;
          }
        } catch (e) {
          print('Error parsing trip ${doc.id}: $e');
        }
      }

      // Sort by scheduledDate descending (newest first)
      loadedTrips.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

      trips.value = loadedTrips;
      totalTripsCount.value = loadedTrips.length;

      // Separate upcoming and completed trips
      upcomingTrips.value = loadedTrips
          .where((trip) =>
              trip.status != TripStatus.completed &&
              trip.status != TripStatus.cancelled &&
              trip.scheduledDate.isAfter(now))
          .toList()
        ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate)); // Oldest first for upcoming

      completedTrips.value = (loadedTrips
            .where((trip) => trip.status == TripStatus.completed)
            .toList())
        ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    } catch (e) {
      print('Error loading trips: $e');
      Get.snackbar(
        'error'.tr,
        'failed_to_load_trips'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  String getStatusText(TripStatus status) {
    switch (status) {
      case TripStatus.awaitingDriverResponse:
        return 'awaiting_driver'.tr;
      case TripStatus.accepted:
        return 'accepted'.tr;
      case TripStatus.rejected:
        return 'rejected'.tr;
      case TripStatus.enRoutePickup:
        return 'en_route_pickup'.tr;
      case TripStatus.enRouteDropoff:
        return 'en_route_dropoff'.tr;
      case TripStatus.completed:
        return 'completed'.tr;
      case TripStatus.cancelled:
        return 'cancelled'.tr;
    }
  }

  Color getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.completed:
        return const Color(0xFF43A047); // success green
      case TripStatus.accepted:
      case TripStatus.enRoutePickup:
      case TripStatus.enRouteDropoff:
        return const Color(0xFF2196F3); // info blue
      case TripStatus.awaitingDriverResponse:
        return const Color(0xFFFF9800); // warning orange
      case TripStatus.rejected:
      case TripStatus.cancelled:
        return const Color(0xFFF44336); // error red
    }
  }

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'today'.tr;
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'yesterday'.tr;
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      return 'tomorrow'.tr;
    } else {
      final locale = Get.locale?.languageCode ?? 'en';
      final formatter = DateFormat('MMM d, yyyy', locale);
      return formatter.format(date);
    }
  }

  String formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  void refreshTrips() {
    loadTrips();
  }

  void openTripDetail(TripModel trip) {
    Get.toNamed(AppRoutes.parentTripDetail, arguments: trip);
  }
}
