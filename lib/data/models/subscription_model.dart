import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TripType { oneWay, roundTrip }

enum DayOfWeek {
  saturday,
  sunday,
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
}

class LocationData {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? placeId;

  LocationData({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.placeId,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      placeId: json['placeId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'placeId': placeId,
    };
  }
}

class SubscriptionModel {
  final String id;
  final String parentId;
  final String? driverId;
  final int durationWeeks;
  final TripType tripType;
  final List<DayOfWeek> serviceDays;
  final int numberOfChildren;
  final List<String> selectedChildrenIds;
  final LocationData pickupLocation;
  final LocationData dropoffLocation;
  final CustomTimeOfDay pickupTime;
  final CustomTimeOfDay? returnPickupTime;
  final double pricePerTrip;
  final double estimatedTotalPrice;
  final SubscriptionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? tripId;

  SubscriptionModel({
    required this.id,
    required this.parentId,
    this.driverId,
    required this.durationWeeks,
    required this.tripType,
    required this.serviceDays,
    required this.numberOfChildren,
    required this.selectedChildrenIds,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupTime,
    this.returnPickupTime,
    required this.pricePerTrip,
    required this.estimatedTotalPrice,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.startDate,
    this.endDate,
    this.tripId,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] ?? '',
      parentId: json['parentId'] ?? '',
      driverId: json['driverId'],
      durationWeeks: json['durationWeeks'] ?? 0,
      tripType: TripType.values.firstWhere(
        (e) => e.name == json['tripType'],
        orElse: () => TripType.roundTrip,
      ),
      serviceDays:
          (json['serviceDays'] as List<dynamic>?)
              ?.map(
                (day) => DayOfWeek.values.firstWhere(
                  (e) => e.name == day,
                  orElse: () => DayOfWeek.monday,
                ),
              )
              .toList() ??
          [],
      numberOfChildren: json['numberOfChildren'] ?? 0,
      selectedChildrenIds: List<String>.from(json['selectedChildrenIds'] ?? []),
      pickupLocation: LocationData.fromJson(json['pickupLocation'] ?? {}),
      dropoffLocation: LocationData.fromJson(json['dropoffLocation'] ?? {}),
      pickupTime: CustomTimeOfDay.fromJson(json['pickupTime'] ?? {}),
      returnPickupTime: json['returnPickupTime'] != null
          ? CustomTimeOfDay.fromJson(json['returnPickupTime'])
          : null,
      pricePerTrip: (json['pricePerTrip'] ?? 0.0).toDouble(),
      estimatedTotalPrice: (json['estimatedTotalPrice'] ?? 0.0).toDouble(),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SubscriptionStatus.draft,
      ),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'])
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'])
          : null,
      tripId: json['tripId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'driverId': driverId,
      'durationWeeks': durationWeeks,
      'tripType': tripType.name,
      'serviceDays': serviceDays.map((day) => day.name).toList(),
      'numberOfChildren': numberOfChildren,
      'selectedChildrenIds': selectedChildrenIds,
      'pickupLocation': pickupLocation.toJson(),
      'dropoffLocation': dropoffLocation.toJson(),
      'pickupTime': pickupTime.toJson(),
      'returnPickupTime': returnPickupTime?.toJson(),
      'pricePerTrip': pricePerTrip,
      'estimatedTotalPrice': estimatedTotalPrice,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'tripId': tripId,
    };
  }

  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionModel.fromJson(data);
  }

  SubscriptionModel copyWith({
    String? id,
    String? parentId,
    String? driverId,
    int? durationWeeks,
    TripType? tripType,
    List<DayOfWeek>? serviceDays,
    int? numberOfChildren,
    List<String>? selectedChildrenIds,
    LocationData? pickupLocation,
    LocationData? dropoffLocation,
    CustomTimeOfDay? pickupTime,
    CustomTimeOfDay? returnPickupTime,
    double? pricePerTrip,
    double? estimatedTotalPrice,
    SubscriptionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startDate,
    DateTime? endDate,
    String? tripId,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      driverId: driverId ?? this.driverId,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      tripType: tripType ?? this.tripType,
      serviceDays: serviceDays ?? this.serviceDays,
      numberOfChildren: numberOfChildren ?? this.numberOfChildren,
      selectedChildrenIds: selectedChildrenIds ?? this.selectedChildrenIds,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      pickupTime: pickupTime ?? this.pickupTime,
      returnPickupTime: returnPickupTime ?? this.returnPickupTime,
      pricePerTrip: pricePerTrip ?? this.pricePerTrip,
      estimatedTotalPrice: estimatedTotalPrice ?? this.estimatedTotalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      tripId: tripId ?? this.tripId,
    );
  }
}

enum SubscriptionStatus {
  draft,
  awaitingDriver,
  driverAssigned,
  driverRejected,
  active,
  completed,
  cancelled,
}

class CustomTimeOfDay {
  final int hour;
  final int minute;

  const CustomTimeOfDay({required this.hour, required this.minute});

  factory CustomTimeOfDay.fromJson(Map<String, dynamic> json) {
    return CustomTimeOfDay(
      hour: json['hour'] ?? 0,
      minute: json['minute'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'hour': hour, 'minute': minute};
  }

  String format(BuildContext context) {
    return MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay(hour: hour, minute: minute));
  }

  String get formattedString {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }
}

class ChildModel {
  final String id;
  final String parentId;
  final String name;
  final int age;
  final String? profileImageUrl;
  final String schoolName;
  final String grade;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChildModel({
    required this.id,
    required this.parentId,
    required this.name,
    required this.age,
    this.profileImageUrl,
    required this.schoolName,
    required this.grade,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: json['id'] ?? '',
      parentId: json['parentId'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      profileImageUrl: json['profileImageUrl'],
      schoolName: json['schoolName'] ?? '',
      grade: json['grade'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'name': name,
      'age': age,
      'profileImageUrl': profileImageUrl,
      'schoolName': schoolName,
      'grade': grade,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ChildModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChildModel.fromJson(data);
  }
}

class DriverModel {
  final String id;
  final String fullName;
  final int age;
  final String? profileImageUrl;
  final double rating;
  final int totalTrips;
  final String phoneNumber;
  final String licenseNumber;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  DriverModel({
    required this.id,
    required this.fullName,
    required this.age,
    this.profileImageUrl,
    required this.rating,
    required this.totalTrips,
    required this.phoneNumber,
    required this.licenseNumber,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      age: json['age'] ?? 0,
      profileImageUrl: json['profileImageUrl'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalTrips: json['totalTrips'] ?? 0,
      phoneNumber: json['phoneNumber'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      isAvailable: json['isAvailable'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'age': age,
      'profileImageUrl': profileImageUrl,
      'rating': rating,
      'totalTrips': totalTrips,
      'phoneNumber': phoneNumber,
      'licenseNumber': licenseNumber,
      'isAvailable': isAvailable,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DriverModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DriverModel.fromJson(data);
  }
}
