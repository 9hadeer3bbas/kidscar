import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../config/app_config.dart';
import 'notification_service.dart';

enum SafetyEventType {
  loudSound, // Loud sound detected
  offRoad, // Car went off the road
  unexpectedStop, // Car stopped unexpectedly
}

class SafetyEvent {
  SafetyEvent({
    required this.type,
    required this.tripId,
    required this.driverId,
    required this.parentId,
    this.message,
    this.location,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final SafetyEventType type;
  final String tripId;
  final String driverId;
  final String parentId;
  final String? message;
  final Map<String, double>? location; // {latitude, longitude}
  final DateTime timestamp;

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'tripId': tripId,
      'driverId': driverId,
      'parentId': parentId,
      'message': message,
      'location': location,
      'timestamp': timestamp.toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Service for logging and managing safety events during trips
class SafetyEventService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService =
      Get.find<NotificationService>();

  /// Log a safety event and notify the parent
  Future<void> logSafetyEvent(SafetyEvent event) async {
    try {
      // Log to Firestore
      await _firestore
          .collection('trips')
          .doc(event.tripId)
          .collection('safety_events')
          .add(event.toJson());

      // Also log to a separate safety events collection for analytics
      await _firestore.collection('safety_events').add(event.toJson());

      // Send notification to parent
      await _sendParentNotification(event);

      if (AppConfig.isDebugMode) {
        debugPrint('✅ Safety event logged: ${event.type.name}');
        debugPrint('   Trip: ${event.tripId}');
        debugPrint('   Message: ${event.message ?? 'No message'}');
      }
    } catch (e) {
      if (AppConfig.isDebugMode) {
        debugPrint('❌ Failed to log safety event: $e');
      }
      rethrow;
    }
  }

  /// Send notification to parent about safety event
  /// This sends an instant notification with high priority and sound
  Future<void> _sendParentNotification(SafetyEvent event) async {
    try {
      String title;
      String body;

      switch (event.type) {
        case SafetyEventType.loudSound:
          title = 'loud_sound_detected'.tr;
          body = 'loud_sound_detected_message'.tr;
          break;
        case SafetyEventType.offRoad:
          title = 'off_road_detected'.tr;
          body = 'off_road_detected_message'.tr;
          break;
        case SafetyEventType.unexpectedStop:
          title = 'unexpected_stop_detected'.tr;
          body = 'unexpected_stop_detected_message'.tr;
          break;
      }

      // Send notification via notification service (stores in Firestore and triggers FCM)
      await _notificationService.sendNotificationToUser(
        userId: event.parentId,
        title: title,
        body: body,
        type: 'safety_event',
        data: {
          'tripId': event.tripId,
          'eventType': event.type.name,
          'timestamp': event.timestamp.toIso8601String(),
          'location': event.location,
          'priority': 'high',
          'sound': 'default',
        },
      );

      // Also send a high-priority local notification for immediate alert
      await _notificationService.showSafetyEventNotification(
        title: title,
        body: body,
        eventType: event.type.name,
        tripId: event.tripId,
      );

      if (AppConfig.isDebugMode) {
        debugPrint('✅ Safety notification sent to parent: ${event.parentId}');
        debugPrint('   Event: ${event.type.name}');
        debugPrint('   Trip: ${event.tripId}');
      }
    } catch (e) {
      if (AppConfig.isDebugMode) {
        debugPrint('❌ Failed to send safety notification: $e');
      }
      // Don't throw - notification failure shouldn't block event logging
    }
  }

  /// Simulate a safety event (for testing/debugging)
  Future<void> simulateSafetyEvent({
    required String tripId,
    required SafetyEventType eventType,
    String? message,
    Map<String, double>? location,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Get trip details to find parent ID
    final tripDoc = await _firestore.collection('trips').doc(tripId).get();
    if (!tripDoc.exists) {
      throw Exception('Trip not found');
    }

    final tripData = tripDoc.data()!;
    final parentId = tripData['parentId'] as String;

    final event = SafetyEvent(
      type: eventType,
      tripId: tripId,
      driverId: user.uid,
      parentId: parentId,
      message: message ?? _getDefaultMessage(eventType),
      location: location,
    );

    await logSafetyEvent(event);
  }

  String _getDefaultMessage(SafetyEventType type) {
    switch (type) {
      case SafetyEventType.loudSound:
        return 'loud_sound_detected_description'.tr;
      case SafetyEventType.offRoad:
        return 'off_road_detected_description'.tr;
      case SafetyEventType.unexpectedStop:
        return 'unexpected_stop_detected_description'.tr;
    }
  }
}

