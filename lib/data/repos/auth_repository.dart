import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:kidscar/data/models/user_model.dart';
import 'package:kidscar/core/services/cache_service.dart';
import 'package:kidscar/core/services/fcm_service.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  late final CacheService _cacheService;

  AuthRepository() {
    _initializeCacheService();
  }

  Future<void> _initializeCacheService() async {
    _cacheService = await CacheService.getInstance();
  }

  /// Universal login method for both parents and drivers
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = userCredential.user?.uid ?? '';
    if (uid.isEmpty) throw Exception('Login failed.');

    // Get user data from Firestore
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      await _auth.signOut();
      throw Exception('User account not found.');
    }

    final userData = doc.data()!;
    final userRole = userData['role'] as String?;

    if (userRole != 'parent' && userRole != 'driver') {
      await _auth.signOut();
      throw Exception('Invalid user role.');
    }

    await userCredential.user?.reload();
    if (!(userCredential.user?.emailVerified ?? false)) {
      await _auth.signOut();
      throw Exception('Please verify your email before logging in.');
    }

    // Cache user data after successful login
    try {
      final user = UserModel.fromJson(userData);
      await _cacheService.saveUserData(user);

      // Save auth token if available
      final token = await userCredential.user?.getIdToken();
      if (token != null) {
        await _cacheService.saveAuthToken(token);
      }
    } catch (e) {
      // Log error but don't fail login
      print('Failed to cache user data: $e');
    }

    return uid;
  }

  /// Register parent user
  Future<String> registerParent({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    // Create auth user
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = userCredential.user?.uid ?? '';
    if (uid.isEmpty) throw Exception('Registration failed.');

    // Get FCM token
    String? fcmToken;
    try {
      fcmToken = await FCMService.initializeFCM();
      print('FCM Token obtained for parent: $fcmToken');
    } catch (e) {
      print('Failed to get FCM token for parent: $e');
      // Continue registration even if FCM token fails
    }

    // Create user document
    final user = UserModel(
      uid: uid,
      fullName: '$firstName $lastName',
      email: email,
      phoneNumber: phoneNumber,
      role: 'parent',
      fcmToken: fcmToken,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(uid).set(user.toJson());

    // Send verification email
    final currentUser = _auth.currentUser;
    if (currentUser != null && !currentUser.emailVerified) {
      await currentUser.sendEmailVerification();
    }
    return uid;
  }

  /// Register driver user with files
  Future<String> registerDriver({
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

    // Create user document
    final user = UserModel(
      uid: uid,
      fullName: '$firstName $lastName',
      email: email,
      phoneNumber: phoneNumber,
      role: 'driver',
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
    if (currentUser != null && !currentUser.emailVerified) {
      await currentUser.sendEmailVerification();
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
      return await _cacheService.getUserData();
    } catch (e) {
      print('Failed to get cached user data: $e');
      return null;
    }
  }

  /// Check if user is logged in (from cache)
  Future<bool> isLoggedIn() async {
    try {
      return await _cacheService.isLoggedIn();
    } catch (e) {
      return false;
    }
  }

  /// Get cached auth token
  Future<String?> getCachedAuthToken() async {
    try {
      return await _cacheService.getAuthToken();
    } catch (e) {
      return null;
    }
  }

  /// Logout and clear cache
  Future<void> logout() async {
    try {
      await _auth.signOut();
      await _cacheService.clearCache();
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
      await _cacheService.refreshUserData(user);

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
      for (final entry in updates.entries) {
        await _cacheService.updateUserField(entry.key, entry.value);
      }
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Get user document from Firestore
  Future<DocumentSnapshot?> getUserDocument(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc : null;
    } catch (e) {
      print('Failed to get user document: $e');
      return null;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }
}
