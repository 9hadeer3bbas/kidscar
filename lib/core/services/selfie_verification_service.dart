import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';

/// Service for verifying driver identity using selfie comparison
/// Compares a real-time selfie with the driver's stored photo using AI API
class SelfieVerificationService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Cache for original driver photo
  final Map<String, File> _originalPhotoCache = {};

  /// Verify driver identity by comparing selfie with stored photo
  /// Returns similarity score (0-1) if successful
  /// Throws exception if verification fails
  Future<double> verifyDriverSelfie(File selfieFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get driver's stored photo URL from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        throw Exception('Driver profile not found');
      }

      final driverPhotoUrl = userDoc.data()?['driverPhotoUrl'] as String?;
      if (driverPhotoUrl == null || driverPhotoUrl.isEmpty) {
        throw Exception('Driver photo not found in profile');
      }

      // Get or cache the original photo
      File originalPhotoFile = await _getOrCacheOriginalPhoto(
        userId: user.uid,
        photoUrl: driverPhotoUrl,
      );

      // Call AI API to compare photos
      final similarityScore = await _compareFacesWithAI(
        originalFile: originalPhotoFile,
        candidateFile: selfieFile,
      );

      // Log verification attempt
      await _logVerificationAttempt(
        userId: user.uid,
        similarityScore: similarityScore,
        isVerified: similarityScore >= AppConfig.similarityThreshold,
      );

      return similarityScore;
    } catch (e) {
      if (AppConfig.isDebugMode) {
        debugPrint('Selfie verification error: $e');
      }
      rethrow;
    }
  }

  /// Get original photo from cache or download and cache it
  Future<File> _getOrCacheOriginalPhoto({
    required String userId,
    required String photoUrl,
  }) async {
    // Check cache first
    if (_originalPhotoCache.containsKey(userId)) {
      final cachedFile = _originalPhotoCache[userId]!;
      if (await cachedFile.exists()) {
        if (AppConfig.isDebugMode) {
          debugPrint('✅ Using cached original photo for user $userId');
        }
        return cachedFile;
      } else {
        // Cache file doesn't exist, remove from cache
        _originalPhotoCache.remove(userId);
      }
    }

    // Download and cache the photo
    try {
      if (AppConfig.isDebugMode) {
        debugPrint('📥 Downloading original photo from: $photoUrl');
      }

      final response = await http.get(Uri.parse(photoUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download original photo: ${response.statusCode}');
      }

      // Get cache directory
      final cacheDir = await getTemporaryDirectory();
      final cacheFile = File('${cacheDir.path}/driver_photo_$userId.jpg');

      // Save to cache
      await cacheFile.writeAsBytes(response.bodyBytes);
      _originalPhotoCache[userId] = cacheFile;

      if (AppConfig.isDebugMode) {
        debugPrint('✅ Original photo cached: ${cacheFile.path}');
      }

      return cacheFile;
    } catch (e) {
      throw Exception('Failed to cache original photo: $e');
    }
  }

  /// Compare faces using AI API with multipart/form-data
  /// Returns similarity score (0-1)
  Future<double> _compareFacesWithAI({
    required File originalFile,
    required File candidateFile,
  }) async {
    try {
      if (!AppConfig.isAiFaceRecognitionConfigured) {
        if (AppConfig.isDebugMode) {
          debugPrint('🔍 Selfie Verification: Comparing faces (DEBUG MODE - Mock)');
          await Future.delayed(const Duration(seconds: 1));
          return 0.85; // Mock similarity score above threshold
        } else {
          throw Exception(
            'AI face comparison API not configured.',
          );
        }
      }

      if (AppConfig.isDebugMode) {
        debugPrint('🔄 Calling face verification API...');
        debugPrint('   Original: ${originalFile.path}');
        debugPrint('   Candidate: ${candidateFile.path}');
      }

      // Create multipart request with threshold 0.75
      final uri = Uri.parse(
        '${AppConfig.aiFaceRecognitionApiEndpoint}?threshold=0.75',
      );

      final request = http.MultipartRequest('POST', uri);
      request.headers['accept'] = 'application/json';

      // Add original image
      request.files.add(
        await http.MultipartFile.fromPath(
          'original',
          originalFile.path,
          filename: 'original.jpg',
        ),
      );

      // Add candidate image
      request.files.add(
        await http.MultipartFile.fromPath(
          'candidate',
          candidateFile.path,
          filename: 'candidate.jpg',
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final similarity = data['similarity'] as double;
        final verified = data['verified'] as bool;

        if (AppConfig.isDebugMode) {
          debugPrint('✅ Face verification response:');
          debugPrint('   Similarity: $similarity');
          debugPrint('   Verified: $verified');
          debugPrint('   Threshold: ${data['threshold']}');
        }

        // Return similarity score (0-1 scale)
        if (similarity < 0 || similarity > 1) {
          throw Exception('Invalid similarity score returned from API: $similarity');
        }

        return similarity;
      } else {
        final errorBody = response.body;
        if (AppConfig.isDebugMode) {
          debugPrint('❌ API request failed: ${response.statusCode}');
          debugPrint('   Response: $errorBody');
        }
        throw Exception('AI API request failed: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      if (AppConfig.isDebugMode) {
        debugPrint('⚠️ AI API call failed: $e');
        // In debug mode, return mock score if API fails
        if (!e.toString().contains('not configured')) {
          await Future.delayed(const Duration(seconds: 1));
          return 0.85;
        }
      }
      rethrow;
    }
  }

  /// Log verification attempt to Firestore
  Future<void> _logVerificationAttempt({
    required String userId,
    required double similarityScore,
    required bool isVerified,
  }) async {
    try {
      await _firestore.collection('selfie_verifications').add({
        'userId': userId,
        'similarityScore': similarityScore,
        'isVerified': isVerified,
        'threshold': AppConfig.similarityThreshold,
        'apiThreshold': AppConfig.faceVerificationThreshold,
        'timestamp': DateTime.now().toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (AppConfig.isDebugMode) {
        debugPrint('Failed to log verification attempt: $e');
      }
      // Don't throw - logging failure shouldn't block verification
    }
  }

  /// Clear cached original photo for a user
  Future<void> clearCache(String userId) async {
    if (_originalPhotoCache.containsKey(userId)) {
      final cachedFile = _originalPhotoCache[userId]!;
      try {
        if (await cachedFile.exists()) {
          await cachedFile.delete();
        }
      } catch (e) {
        if (AppConfig.isDebugMode) {
          debugPrint('Failed to delete cached photo: $e');
        }
      }
      _originalPhotoCache.remove(userId);
    }
  }

  /// Clear all cached photos
  Future<void> clearAllCache() async {
    for (final entry in _originalPhotoCache.entries) {
      try {
        if (await entry.value.exists()) {
          await entry.value.delete();
        }
      } catch (e) {
        if (AppConfig.isDebugMode) {
          debugPrint('Failed to delete cached photo: $e');
        }
      }
    }
    _originalPhotoCache.clear();
  }
}
