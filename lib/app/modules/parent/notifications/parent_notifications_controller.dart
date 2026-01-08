import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum NotificationFilter { all, unread }

class ParentNotificationsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final isLoading = false.obs;
  final notifications = <Map<String, dynamic>>[].obs;
  final unreadCount = 0.obs;
  final selectedFilter = NotificationFilter.all.obs;

  @override
  void onInit() {
    super.onInit();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      isLoading.value = true;
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        isLoading.value = false;
        return;
      }

      // Query by userId only (to avoid composite index requirement)
      // Then sort in memory
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .limit(100)
          .get();

      final loadedNotifications = <Map<String, dynamic>>[];
      int unread = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        loadedNotifications.add({'id': doc.id, ...data});

        if (data['isRead'] == false || data['isRead'] == null) {
          unread++;
        }
      }

      // Sort by createdAt in descending order (newest first)
      loadedNotifications.sort((a, b) {
        final aDate = a['createdAt'] as String?;
        final bDate = b['createdAt'] as String?;

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;

        try {
          final aDateTime = DateTime.parse(aDate);
          final bDateTime = DateTime.parse(bDate);
          return bDateTime.compareTo(aDateTime); // Descending order
        } catch (e) {
          return 0;
        }
      });

      notifications.value = loadedNotifications;
      unreadCount.value = unread;
    } catch (e) {
      print('Error loading notifications: $e');
      Get.snackbar(
        'error'.tr,
        'failed_to_load_notifications'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': DateTime.now().toIso8601String(),
      });

      // Update local state
      final index = notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        notifications[index]['isRead'] = true;
        notifications.refresh();

        // Update unread count
        unreadCount.value = notifications
            .where((n) => n['isRead'] != true)
            .length;
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final unreadNotifications = notifications
          .where((n) => n['isRead'] != true)
          .map((n) => n['id'] as String)
          .toList();

      if (unreadNotifications.isEmpty) return;

      final batch = _firestore.batch();
      for (final id in unreadNotifications) {
        batch.update(_firestore.collection('notifications').doc(id), {
          'isRead': true,
          'readAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();

      // Update local state
      for (final notification in notifications) {
        notification['isRead'] = true;
      }
      notifications.refresh();
      unreadCount.value = 0;
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();

      // Update local state
      notifications.removeWhere((n) => n['id'] == notificationId);
      notifications.refresh();

      // Update unread count
      unreadCount.value = notifications
          .where((n) => n['isRead'] != true)
          .length;
    } catch (e) {
      print('Error deleting notification: $e');
      Get.snackbar(
        'error'.tr,
        'failed_to_delete_notification'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void refreshNotifications() {
    _loadNotifications();
  }

  void changeFilter(NotificationFilter filter) {
    selectedFilter.value = filter;
  }

  List<Map<String, dynamic>> get filteredNotifications {
    final currentNotifications = notifications.toList();
    if (selectedFilter.value == NotificationFilter.all) {
      return currentNotifications;
    }
    return currentNotifications.where((n) => n['isRead'] != true).toList();
  }

  String _getNotificationIcon(String? type) {
    switch (type) {
      case 'driver_assigned':
        return '🚗';
      case 'trip_completed':
        return '✅';
      case 'trip_reminder':
        return '⏰';
      case 'emergency':
        return '🚨';
      case 'subscription_update':
        return '📝';
      default:
        return '🔔';
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'driver_assigned':
        return Colors.green;
      case 'trip_completed':
        return Colors.blue;
      case 'trip_reminder':
        return Colors.orange;
      case 'emergency':
        return Colors.red;
      case 'subscription_update':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String getNotificationIcon(String? type) => _getNotificationIcon(type);
  Color getNotificationColor(String? type) => _getNotificationColor(type);

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'just_now'.tr;
          }
          return '${difference.inMinutes} ${'minutes_ago'.tr}';
        }
        return '${difference.inHours} ${'hours_ago'.tr}';
      } else if (difference.inDays == 1) {
        return 'yesterday'.tr;
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ${'days_ago'.tr}';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }

  String formatDate(String? dateString) => _formatDate(dateString);
}
