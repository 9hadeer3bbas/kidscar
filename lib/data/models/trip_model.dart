import 'package:cloud_firestore/cloud_firestore.dart';
import 'subscription_model.dart';

enum TripStatus {
  awaitingDriverResponse,
  accepted,
  rejected,
  enRoutePickup,
  enRouteDropoff,
  completed,
  cancelled,
}

class TripModel {
  const TripModel({
    required this.id,
    required this.subscriptionId,
    required this.driverId,
    required this.parentId,
    required this.kidIds,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupTime,
    this.returnPickupTime,
    required this.status,
    required this.scheduledDate,
    required this.createdAt,
    required this.updatedAt,
    this.encodedPolyline,
    this.distanceMeters,
    this.durationSeconds,
    this.parentNotes,
    this.driverNotes,
  });

  final String id;
  final String subscriptionId;
  final String driverId;
  final String parentId;
  final List<String> kidIds;
  final LocationData pickupLocation;
  final LocationData dropoffLocation;
  final CustomTimeOfDay pickupTime;
  final CustomTimeOfDay? returnPickupTime;
  final TripStatus status;
  final DateTime scheduledDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? encodedPolyline;
  final int? distanceMeters;
  final int? durationSeconds;
  final String? parentNotes;
  final String? driverNotes;

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] ?? '',
      subscriptionId: json['subscriptionId'] ?? '',
      driverId: json['driverId'] ?? '',
      parentId: json['parentId'] ?? '',
      kidIds: List<String>.from(json['kidIds'] ?? const []),
      pickupLocation: LocationData.fromJson(json['pickupLocation'] ?? {}),
      dropoffLocation: LocationData.fromJson(json['dropoffLocation'] ?? {}),
      pickupTime: CustomTimeOfDay.fromJson(json['pickupTime'] ?? {}),
      returnPickupTime: json['returnPickupTime'] != null
          ? CustomTimeOfDay.fromJson(json['returnPickupTime'])
          : null,
      status: TripStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => TripStatus.awaitingDriverResponse,
      ),
      scheduledDate: _parseDate(json['scheduledDate']) ?? DateTime.now(),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
      encodedPolyline: json['encodedPolyline'],
      distanceMeters: json['distanceMeters'],
      durationSeconds: json['durationSeconds'],
      parentNotes: json['parentNotes'],
      driverNotes: json['driverNotes'],
    );
  }

  factory TripModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TripModel.fromJson(data);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subscriptionId': subscriptionId,
      'driverId': driverId,
      'parentId': parentId,
      'kidIds': kidIds,
      'pickupLocation': pickupLocation.toJson(),
      'dropoffLocation': dropoffLocation.toJson(),
      'pickupTime': pickupTime.toJson(),
      'returnPickupTime': returnPickupTime?.toJson(),
      'status': status.name,
      'scheduledDate': scheduledDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'encodedPolyline': encodedPolyline,
      'distanceMeters': distanceMeters,
      'durationSeconds': durationSeconds,
      'parentNotes': parentNotes,
      'driverNotes': driverNotes,
    };
  }

  TripModel copyWith({
    String? id,
    String? subscriptionId,
    String? driverId,
    String? parentId,
    List<String>? kidIds,
    LocationData? pickupLocation,
    LocationData? dropoffLocation,
    CustomTimeOfDay? pickupTime,
    CustomTimeOfDay? returnPickupTime,
    TripStatus? status,
    DateTime? scheduledDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? encodedPolyline,
    int? distanceMeters,
    int? durationSeconds,
    String? parentNotes,
    String? driverNotes,
  }) {
    return TripModel(
      id: id ?? this.id,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      driverId: driverId ?? this.driverId,
      parentId: parentId ?? this.parentId,
      kidIds: kidIds ?? this.kidIds,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      pickupTime: pickupTime ?? this.pickupTime,
      returnPickupTime: returnPickupTime ?? this.returnPickupTime,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      encodedPolyline: encodedPolyline ?? this.encodedPolyline,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      parentNotes: parentNotes ?? this.parentNotes,
      driverNotes: driverNotes ?? this.driverNotes,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
