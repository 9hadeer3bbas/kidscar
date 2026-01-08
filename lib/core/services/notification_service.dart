import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'fcm_service.dart';
import '../../app/custom_widgets/custom_toast.dart';

class NotificationService extends GetxService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Notification types
  static const String newSubscriptionType = 'new_subscription';
  static const String subscriptionUpdateType = 'subscription_update';
  static const String tripReminderType = 'trip_reminder';
  static const String driverAssignedType = 'driver_assigned';
  static const String tripCompletedType = 'trip_completed';
  static const String emergencyType = 'emergency';

  StreamSubscription<QuerySnapshot>? _notificationsSubscription;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeLocalNotifications();
    await _setupFCMHandlers();
    await _updateFCMTokenInDatabase();
    _listenToNotifications();
  }

  @override
  void onClose() {
    _notificationsSubscription?.cancel();
    super.onClose();
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  /// Setup FCM handlers
  Future<void> _setupFCMHandlers() async {
    // Setup background handler
    FCMService.setupBackgroundHandler();

    // Setup foreground handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle initial message (when app is opened from terminated state)
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Update FCM token in database
  Future<void> _updateFCMTokenInDatabase() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final fcmToken = await FCMService.refreshToken();
      if (fcmToken != null) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'fcmToken': fcmToken,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        print('FCM token updated in database');
      }
    } catch (e) {
      print('Failed to update FCM token: $e');
    }
  }

  /// Listen to notifications collection for real-time updates
  void _listenToNotifications() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      // Listen for auth state changes
      _auth.authStateChanges().listen((user) {
        if (user != null) {
          _startNotificationsListener(user.uid);
        } else {
          _notificationsSubscription?.cancel();
        }
      });
      return;
    }

    _startNotificationsListener(currentUser.uid);
  }

  void _startNotificationsListener(String userId) {
    // Cancel existing subscription
    _notificationsSubscription?.cancel();

    print('🔔 Starting notifications listener for user: $userId');

    // Track which notifications we've already shown to avoid duplicates
    final Set<String> shownNotificationIds = <String>{};
    
    // Track when we started listening to avoid showing old notifications
    final listenerStartTime = DateTime.now();

    _notificationsSubscription = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.docs.isEmpty) return;

        // Get all notifications and sort by createdAt in memory
        final notifications = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'data': data,
            'createdAt': DateTime.tryParse(
                  data['createdAt'] as String? ?? '',
                ) ??
                DateTime.now(),
          };
        }).toList();

        // Sort by createdAt descending
        notifications.sort((a, b) => 
          (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime)
        );

        // Get the latest notification
        if (notifications.isEmpty) return;
        
        final latestNotification = notifications.first;
        final notificationId = latestNotification['id'] as String;
        final notificationData = latestNotification['data'] as Map<String, dynamic>;
        final createdAt = latestNotification['createdAt'] as DateTime;

        // Skip if we've already shown this notification
        if (shownNotificationIds.contains(notificationId)) {
          return;
        }

        // Only show notifications created after we started listening
        // or within the last 5 seconds (to catch notifications created just before we started)
        final now = DateTime.now();
        final timeDiff = now.difference(createdAt);
        
        if (createdAt.isBefore(listenerStartTime.subtract(const Duration(seconds: 5)))) {
          print(
            '⏭️ Skipping old notification (${timeDiff.inSeconds}s ago, created before listener started)',
          );
          // Mark as shown so we don't check it again
          shownNotificationIds.add(notificationId);
          return;
        }

        // Mark as shown
        shownNotificationIds.add(notificationId);

        print('🔔 New notification received via Firestore listener');
        print('   ID: $notificationId');
        print('   Title: ${notificationData['title']}');
        print('   Body: ${notificationData['body']}');
        print('   Type: ${notificationData['type']}');
        print('   Created: ${createdAt.toIso8601String()}');

        // Show local notification
        _showLocalNotificationFromData(
          title: notificationData['title'] as String? ?? 'New Notification',
          body: notificationData['body'] as String? ?? '',
          data: notificationData['data'] as Map<String, dynamic>? ?? {},
          notificationId: notificationId,
        );

        // Show in-app toast notification
        if (Get.context != null) {
          CustomToasts(
            message: notificationData['body'] as String? ?? '',
            type: CustomToastType.success,
            buttonName: 'view'.tr,
            onTap: (_) {
              _navigateFromNotification(
                notificationData['data'] as Map<String, dynamic>? ?? {},
              );
            },
          ).show();
        }
      },
      onError: (error) {
        print('❌ Error listening to notifications: $error');
      },
    );
  }

  /// Show local notification from data (not from FCM message)
  Future<void> _showLocalNotificationFromData({
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required String notificationId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'kids_car_notifications',
      'KidsCar Notifications',
      channelDescription: 'Notifications for KidsCar app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF2196F3),
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notificationId.hashCode,
      title,
      body,
      details,
      payload: jsonEncode(data),
    );

    print('✅ Local notification shown: $title');
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');
    print('Message data: ${message.data}');
    print('Message notification: ${message.notification?.title}');

    // Show local notification for foreground messages
    await _showLocalNotification(message);

    // Show in-app notification if app is active
    if (Get.context != null) {
      _showInAppNotification(message);
    }
  }

  /// Handle notification taps
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    print('Notification tapped: ${message.messageId}');
    print('Message data: ${message.data}');

    // Navigate based on notification type
    await _navigateFromNotification(message.data);
  }

  /// Handle local notification taps
  void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');

    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _navigateFromNotification(data);
      } catch (e) {
        print('Failed to parse notification payload: $e');
      }
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'kids_car_notifications',
      'KidsCar Notifications',
      channelDescription: 'Notifications for KidsCar app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF2196F3), // Primary color
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  /// Show in-app notification
  void _showInAppNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    CustomToasts(
      message: notification.body ?? '',
      type: CustomToastType.success,
      buttonName: 'view'.tr,
      onTap: (_) => _navigateFromNotification(message.data),
    ).show();
  }

  /// Navigate based on notification data
  Future<void> _navigateFromNotification(Map<String, dynamic> data) async {
    final type = data['type'] as String?;
    final subscriptionId = data['subscriptionId'] as String?;

    print(
      'Navigating from notification - Type: $type, SubscriptionId: $subscriptionId',
    );

    switch (type) {
      case newSubscriptionType:
        if (subscriptionId != null) {
          Get.toNamed(
            '/driver-main-view',
            arguments: {'subscriptionId': subscriptionId},
          );
        }
        break;

      case driverAssignedType:
        if (subscriptionId != null) {
          Get.toNamed(
            '/parent-main-view',
            arguments: {'subscriptionId': subscriptionId},
          );
        }
        break;

      case tripReminderType:
        Get.toNamed('/parent-main-view');
        break;

      case tripCompletedType:
        Get.toNamed('/parent-main-view');
        break;

      case emergencyType:
        // Show emergency dialog
        _showEmergencyDialog(data);
        break;

      default:
        // Default navigation
        Get.toNamed('/parent-main-view');
    }
  }

  /// Show emergency dialog
  void _showEmergencyDialog(Map<String, dynamic> data) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('emergency_alert'.tr),
          ],
        ),
        content: Text(data['message'] ?? 'Emergency situation detected'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('ok'.tr)),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Send notification to specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('=== SEND NOTIFICATION TO USER ===');
      print('User ID: $userId');
      print('Title: $title');
      print('Type: $type');
      
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('❌ User not found: $userId');
        return;
      }

      final userData = userDoc.data()!;
      final fcmToken = userData['fcmToken'] as String?;
      final userName = userData['fullName'] ?? userData['name'] ?? 'Unknown';

      print('User found: $userName');
      print('FCM Token: ${fcmToken != null ? "Present" : "Missing"}');

      if (fcmToken == null || fcmToken.isEmpty) {
        print('⚠️ No FCM token for user: $userId');
        print('⚠️ Notification will be stored but push notification cannot be sent');
        // Continue to store notification even without FCM token
      }

      // Create notification data
      final notificationData = {
        'type': type,
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
        ...?data,
      };

      // Store notification in database
      final notificationRef = await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': notificationData,
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      print('✅ Notification stored in database with ID: ${notificationRef.id}');

      // Note: FCM push notifications require a backend server (Cloud Functions)
      // The notification is stored in the database and will appear in the app's notification list
      // To send actual push notifications, you need to implement Cloud Functions
      // that call FCM Admin SDK with the server key
      
      if (fcmToken != null && fcmToken.isNotEmpty) {
        print('📱 FCM token available - push notification should be sent via Cloud Functions');
        print('💡 To enable push notifications, implement a Cloud Function that:');
        print('   1. Listens to notifications collection');
        print('   2. Sends FCM message using Admin SDK');
        print('   3. Uses the FCM token: $fcmToken');
      }

      print('✅ Notification process completed for user $userId');
    } catch (e, stackTrace) {
      print('❌ Failed to send notification: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Send notification to all drivers
  Future<void> sendNotificationToAllDrivers({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final driversQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .get();

      for (final doc in driversQuery.docs) {
        final driverId = doc.id;
        await sendNotificationToUser(
          userId: driverId,
          title: title,
          body: body,
          type: type,
          data: data,
        );
      }
    } catch (e) {
      print('Failed to send notification to all drivers: $e');
    }
  }

  /// Send notification to all parents
  Future<void> sendNotificationToAllParents({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final parentsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'parent')
          .get();

      for (final doc in parentsQuery.docs) {
        final parentId = doc.id;
        await sendNotificationToUser(
          userId: parentId,
          title: title,
          body: body,
          type: type,
          data: data,
        );
      }
    } catch (e) {
      print('Failed to send notification to all parents: $e');
    }
  }

  /// Get user notifications
  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Failed to get user notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Failed to mark notification as read: $e');
    }
  }

  /// Clear all notifications for user
  Future<void> clearAllNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Failed to clear notifications: $e');
    }
  }

  /// Schedule trip reminder (simplified version)
  Future<void> scheduleTripReminder({
    required String subscriptionId,
    required DateTime reminderTime,
    required String title,
    required String body,
  }) async {
    try {
      // For now, we'll just show an immediate notification
      // In a production app, you would use a proper scheduling library
      await _localNotifications.show(
        subscriptionId.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'trip_reminders',
            'Trip Reminders',
            channelDescription: 'Reminders for upcoming trips',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode({
          'type': tripReminderType,
          'subscriptionId': subscriptionId,
        }),
      );
      print('Trip reminder scheduled for subscription: $subscriptionId');
    } catch (e) {
      print('Failed to schedule trip reminder: $e');
    }
  }

  /// Cancel trip reminder
  Future<void> cancelTripReminder(String subscriptionId) async {
    try {
      await _localNotifications.cancel(subscriptionId.hashCode);
    } catch (e) {
      print('Failed to cancel trip reminder: $e');
    }
  }

  /// Show safety event notification with high priority and sound
  /// This provides instant real-time alerts to parents
  Future<void> showSafetyEventNotification({
    required String title,
    required String body,
    required String eventType,
    required String tripId,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'safety_events',
        'Safety Events',
        channelDescription: 'Real-time safety alerts during trips',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(''),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        tripId.hashCode + eventType.hashCode,
        title,
        body,
        notificationDetails,
        payload: jsonEncode({
          'type': 'safety_event',
          'eventType': eventType,
          'tripId': tripId,
        }),
      );
    } catch (e) {
      print('Failed to show safety event notification: $e');
    }
  }
}
