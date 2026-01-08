import 'dart:developer';

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request notification permission from the user.

  static Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      log("Error in Request notification permission: ${e.toString()}");
      return false;
    }
  }

  /// Request both foreground and background location permissions.
  static Future<bool> requestLocationPermissions() async {
    try {
      final status = await Permission.location.request();
      final backgroundStatus = await Permission.locationAlways.request();
      return status.isGranted && backgroundStatus.isGranted;
    } catch (e) {
      log(
        "Request both foreground and background location permissions: ${e.toString()}",
      );

      return false;
    }
  }

  /// Request camera permission.
  static Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      log("Error in Request camera permission: ${e.toString()}");
      return false;
    }
  }

  /// Request microphone permission.
  static Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (e) {
      log("Error in Request microphone permission: ${e.toString()}");
      return false;
    }
  }

  /// Request Bluetooth permissions (classic and connect).
  static Future<bool> requestBluetoothPermissions() async {
    try {
      final bluetooth = await Permission.bluetooth.request();
      final bluetoothConnect = await Permission.bluetoothConnect.request();
      return bluetooth.isGranted && bluetoothConnect.isGranted;
    } catch (e) {
            log("Error in Request Bluetooth permissions: ${e.toString()}");
      return false;
    }
  }

  /// Request all required permissions for the app.
  static Future<bool> requestAllPermissions() async {
    final notification = await requestNotificationPermission();
    final location = await requestLocationPermissions();
    final camera = await requestCameraPermission();
    final microphone = await requestMicrophonePermission();
    final bluetooth = await requestBluetoothPermissions();
    return notification && location && camera && microphone && bluetooth;
  }

  /// Check if all required permissions are granted.
  static Future<bool> areAllPermissionsGranted() async {
    final notification = await Permission.notification.isGranted;
    final location = await Permission.location.isGranted;
    final locationAlways = await Permission.locationAlways.isGranted;
    final camera = await Permission.camera.isGranted;
    final microphone = await Permission.microphone.isGranted;
    final bluetooth = await Permission.bluetooth.isGranted;
    final bluetoothConnect = await Permission.bluetoothConnect.isGranted;
    return notification &&
        location &&
        locationAlways &&
        camera &&
        microphone &&
        bluetooth &&
        bluetoothConnect;
  }

  /// Open the app settings page for the user to manually grant permissions.
  static Future<void> openAppSettingsPage() async {
    await openAppSettings();
  }
}
