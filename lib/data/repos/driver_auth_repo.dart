import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:kidscar/data/models/user_model.dart';
import 'package:kidscar/core/services/cache_service.dart';
import 'package:kidscar/core/services/fcm_service.dart';

class DriverAuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  CacheService? _cacheService;
  Future<CacheService>? _cacheServiceFuture;

  DriverAuthRepository() {
    _initializeCacheService();
  }

  Future<void> _initializeCacheService() async {
    _cacheServiceFuture = CacheService.getInstance();
    _cacheService = await _cacheServiceFuture;
  }

  /// Ensure cache service is initialized before use
  Future<CacheService> _ensureCacheService() async {
    if (_cacheService != null) {
      return _cacheService!;
    }
    if (_cacheServiceFuture != null) {
      _cacheService = await _cacheServiceFuture;
      return _cacheService!;
    }
    _cacheService = await CacheService.getInstance();
    return _cacheService!;
  }

  Future<String> loginDriver({
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = userCredential.user?.uid ?? '';
    if (uid.isEmpty) throw Exception('Login failed.');

    // Ensure role is driver
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || (doc.data()?['role'] != 'driver')) {
      await _auth.signOut();
      throw Exception('Account is not registered as a driver.');
    }

    await userCredential.user?.reload();
    if (!(userCredential.user?.emailVerified ?? false)) {
      await _auth.signOut();
      throw Exception('Please verify your email before logging in.');
    }

    // Cache user data after successful login
    try {
      final cacheService = await _ensureCacheService();
      final userData = doc.data()!;
      final user = UserModel.fromJson(userData);
      await cacheService.saveUserData(user);

      // Save auth token if available
      final token = await userCredential.user?.getIdToken();
      if (token != null) {
        await cacheService.saveAuthToken(token);
      }
    } catch (e) {
      // Log error but don't fail login
      print('Failed to cache user data: $e');
    }

    return uid;
  }

  Future<String> registerDriverWithFiles({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    required String city,
    required File driverPhoto,
    required File drivingLicense,
    required File vehicleRegistration,
  }) async {
    // Create auth user
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = userCredential.user?.uid ?? '';
    if (uid.isEmpty) throw Exception('Registration failed.');

    // Upload images
    final driverPhotoUrl = await _uploadFile(
      file: driverPhoto,
      path: 'drivers/$uid/driver_photo.jpg',
    );
    final drivingLicenseUrl = await _uploadFile(
      file: drivingLicense,
      path: 'drivers/$uid/driving_license.jpg',
    );
    final vehicleRegistrationUrl = await _uploadFile(
      file: vehicleRegistration,
      path: 'drivers/$uid/vehicle_registration.jpg',
    );

    // Get FCM token
    String? fcmToken;
    try {
      fcmToken = await FCMService.initializeFCM();
      print('FCM Token obtained for driver: $fcmToken');
    } catch (e) {
      print('Failed to get FCM token for driver: $e');
      // Continue registration even if FCM token fails
    }

    // Create user document
    final user = UserModel(
      uid: uid,
      fullName: '$firstName $lastName',
      email: email,
      phoneNumber: phoneNumber,
      role: 'driver',
      fcmToken: fcmToken,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final userData = user.toJson()
      ..addAll({
        'city': city,
        'driverPhotoUrl': driverPhotoUrl,
        'drivingLicenseUrl': drivingLicenseUrl,
        'vehicleRegistrationUrl': vehicleRegistrationUrl,
      });

    await _firestore.collection('users').doc(uid).set(userData);

    // Send verification email
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        // Wait a moment to ensure the user is properly created
        await Future.delayed(const Duration(milliseconds: 500));

        // Reload the user to get the latest state
        await currentUser.reload();

        // Check if email is already verified
        if (currentUser.emailVerified) {
          print('Email is already verified for: $email');
        } else {
          // Configure action code settings for better email handling
          final actionCodeSettings = ActionCodeSettings(
            url: 'https://kidscar-454dd.firebaseapp.com/__/auth/action',
            handleCodeInApp: false,
            androidPackageName: 'com.codge.kidscar',
            iOSBundleId: 'com.codge.kidscar',
          );
          
          // Send verification email with custom settings
          await currentUser.sendEmailVerification(actionCodeSettings);
          print('Verification email sent successfully to: $email');

          // Add a small delay to ensure the email is processed
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      } catch (e) {
        print('Failed to send verification email: $e');
        print('Error details: ${e.toString()}');
        // Don't throw an exception here, just log the error
        // The user can still resend verification email later
        print('User can resend verification email from the sign-in screen');
      }
    } else {
      print('Current user is null after registration');
    }
    return uid;
  }

  Future<String> _uploadFile({required File file, required String path}) async {
    final ref = _storage.ref().child(path);
    final uploadTask = await ref.putFile(file);
    if (uploadTask.state != TaskState.success) {
      throw Exception('Failed to upload file: $path');
    }
    return await ref.getDownloadURL();
  }

  /// Get cached user data
  Future<UserModel?> getCachedUserData() async {
    try {
      final cacheService = await _ensureCacheService();
      return await cacheService.getUserData();
    } catch (e) {
      print('Failed to get cached user data: $e');
      return null;
    }
  }

  /// Check if user is logged in (from cache)
  Future<bool> isLoggedIn() async {
    try {
      final cacheService = await _ensureCacheService();
      return await cacheService.isLoggedIn();
    } catch (e) {
      return false;
    }
  }

  /// Get cached auth token
  Future<String?> getCachedAuthToken() async {
    try {
      final cacheService = await _ensureCacheService();
      return await cacheService.getAuthToken();
    } catch (e) {
      return null;
    }
  }

  /// Logout and clear cache
  Future<void> logout() async {
    try {
      await _auth.signOut();
      final cacheService = await _ensureCacheService();
      await cacheService.clearCache();
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }

  /// Refresh user data from server and update cache
  Future<UserModel> refreshUserData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (!doc.exists) {
        throw Exception('User document not found');
      }

      final userData = doc.data()!;
      final user = UserModel.fromJson(userData);

      // Update cache with fresh data
      final cacheService = await _ensureCacheService();
      await cacheService.refreshUserData(user);

      return user;
    } catch (e) {
      throw Exception('Failed to refresh user data: $e');
    }
  }

  /// Update user profile and cache
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      // Update in Firestore
      updates['updatedAt'] = DateTime.now().toIso8601String();
      await _firestore.collection('users').doc(currentUser.uid).update(updates);

      // Update cache
      final cacheService = await _ensureCacheService();
      for (final entry in updates.entries) {
        await cacheService.updateUserField(entry.key, entry.value);
      }
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      // Reload user to get latest state
      await currentUser.reload();

      if (currentUser.emailVerified) {
        throw Exception('Email is already verified');
      }

      // Configure action code settings for better email handling
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://kidscar-454dd.firebaseapp.com/__/auth/action',
        handleCodeInApp: false,
        androidPackageName: 'com.kidscar.kidscar',
        iOSBundleId: 'com.kidscar.kidscar',
      );

      // Send verification email with custom settings
      await currentUser.sendEmailVerification(actionCodeSettings);
      print('Verification email resent successfully to: ${currentUser.email}');

      // Add a small delay to ensure the email is processed
      await Future.delayed(const Duration(milliseconds: 1000));
    } catch (e) {
      print('Failed to resend verification email: $e');
      throw Exception('Failed to resend verification email: $e');
    }
  }

  /// Check if email is verified
  Future<bool> isEmailVerified() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      await currentUser.reload();
      return currentUser.emailVerified;
    } catch (e) {
      print('Failed to check email verification status: $e');
      return false;
    }
  }
}
