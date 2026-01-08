import 'dart:io';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../../custom_widgets/custom_toast.dart';
import 'driver_profile_controller.dart';

class DriverVehicleDocumentsController extends GetxController {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  final isLoading = false.obs;
  final driverPhotoUrl = Rxn<String>();
  final drivingLicenseUrl = Rxn<String>();
  final vehicleRegistrationUrl = Rxn<String>();
  
  // Password verification
  final isVerifyingPassword = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDocuments();
  }

  Future<void> loadDocuments() async {
    try {
      isLoading.value = true;
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) return;

      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        driverPhotoUrl.value = data['driverPhotoUrl'];
        drivingLicenseUrl.value = data['drivingLicenseUrl'];
        vehicleRegistrationUrl.value = data['vehicleRegistrationUrl'];
      }
    } catch (e) {
      print('Error loading documents: $e');
      CustomToasts(
        message: 'failed_to_load_documents'.tr,
        type: CustomToastType.error,
      ).show();
    } finally {
      isLoading.value = false;
    }
  }

  /// Check if document exists and needs password verification
  bool documentExists(String documentType) {
    switch (documentType) {
      case 'driverPhoto':
        return driverPhotoUrl.value != null && driverPhotoUrl.value!.isNotEmpty;
      case 'drivingLicense':
        return drivingLicenseUrl.value != null && drivingLicenseUrl.value!.isNotEmpty;
      case 'vehicleRegistration':
        return vehicleRegistrationUrl.value != null && vehicleRegistrationUrl.value!.isNotEmpty;
      default:
        return false;
    }
  }

  /// Verify password using Firebase reauthentication
  Future<bool> verifyPassword(String password) async {
    try {
      isVerifyingPassword.value = true;
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        throw Exception('No authenticated user');
      }

      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: password,
      );

      await currentUser.reauthenticateWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      print('Password verification error: $e');
      if (e.code == 'wrong-password') {
        CustomToasts(
          message: 'incorrect_password'.tr,
          type: CustomToastType.error,
        ).show();
      } else if (e.code == 'invalid-credential') {
        CustomToasts(
          message: 'invalid_credentials'.tr,
          type: CustomToastType.error,
        ).show();
      } else {
        CustomToasts(
          message: 'password_verification_failed'.tr,
          type: CustomToastType.error,
        ).show();
      }
      return false;
    } catch (e) {
      print('Password verification error: $e');
      CustomToasts(
        message: 'password_verification_failed'.tr,
        type: CustomToastType.error,
      ).show();
      return false;
    } finally {
      isVerifyingPassword.value = false;
    }
  }

  Future<void> pickDocument(String documentType) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _uploadDocument(File(pickedFile.path), documentType);
      }
    } catch (e) {
      print('Error picking document: $e');
      CustomToasts(
        message: 'failed_to_pick_document'.tr,
        type: CustomToastType.error,
      ).show();
    }
  }

  Future<void> _uploadDocument(File file, String documentType) async {
    try {
      isLoading.value = true;
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      String path;
      String fieldName;

      switch (documentType) {
        case 'driverPhoto':
          path = 'drivers/${currentUser.uid}/driver_photo.jpg';
          fieldName = 'driverPhotoUrl';
          break;
        case 'drivingLicense':
          path = 'drivers/${currentUser.uid}/driving_license.jpg';
          fieldName = 'drivingLicenseUrl';
          break;
        case 'vehicleRegistration':
          path = 'drivers/${currentUser.uid}/vehicle_registration.jpg';
          fieldName = 'vehicleRegistrationUrl';
          break;
        default:
          throw Exception('Invalid document type');
      }

      // Upload to Firebase Storage
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(file);
      if (uploadTask.state != TaskState.success) {
        throw Exception('Failed to upload file');
      }

      final downloadUrl = await ref.getDownloadURL();

      // Update Firestore
      await _firestore.collection('users').doc(currentUser.uid).update({
        fieldName: downloadUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update local state
      switch (documentType) {
        case 'driverPhoto':
          driverPhotoUrl.value = downloadUrl;
          break;
        case 'drivingLicense':
          drivingLicenseUrl.value = downloadUrl;
          break;
        case 'vehicleRegistration':
          vehicleRegistrationUrl.value = downloadUrl;
          break;
      }

      // Refresh profile controller if it exists
      if (Get.isRegistered<DriverProfileController>()) {
        final profileController = Get.find<DriverProfileController>();
        await profileController.refreshProfile();
      }

      CustomToasts(
        message: 'document_uploaded_successfully'.tr,
        type: CustomToastType.success,
      ).show();
    } catch (e) {
      print('Error uploading document: $e');
      CustomToasts(
        message: 'failed_to_upload_document'.tr,
        type: CustomToastType.error,
      ).show();
    } finally {
      isLoading.value = false;
    }
  }

  // This method is handled in the view
  void viewDocument(String imageUrl, String title) {
    // Navigation to view document is handled in the view
  }
}

