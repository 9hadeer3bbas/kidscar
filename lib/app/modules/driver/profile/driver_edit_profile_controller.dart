import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../custom_widgets/custom_toast.dart';
import '../../../../data/repos/driver_auth_repo.dart';
import 'driver_profile_controller.dart';

class DriverEditProfileController extends GetxController {
  final DriverAuthRepository _authRepository = DriverAuthRepository();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final TextEditingController fullNameController;
  late final TextEditingController phoneController;
  late final TextEditingController cityController;

  final FocusNode fullNameFocusNode = FocusNode();
  final FocusNode phoneFocusNode = FocusNode();
  final FocusNode cityFocusNode = FocusNode();

  final isSaving = false.obs;
  final fullNameError = ''.obs;
  final phoneError = ''.obs;
  final cityError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize controllers with empty values first
    fullNameController = TextEditingController();
    phoneController = TextEditingController();
    cityController = TextEditingController();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      // Get user data from Firestore first (most reliable)
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        final doc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          
          // Load from Firestore data
          fullNameController.text = data['fullName'] ?? '';
          phoneController.text = data['phoneNumber'] ?? '';
          cityController.text = data['city'] ?? '';
        }
      }
      
      // Try to get from cache as fallback (in case Firestore fails)
      if (fullNameController.text.isEmpty || phoneController.text.isEmpty) {
        final user = await _authRepository.getCachedUserData();
        if (user != null) {
          if (fullNameController.text.isEmpty) {
            fullNameController.text = user.fullName;
          }
          if (phoneController.text.isEmpty) {
            phoneController.text = user.phoneNumber;
          }
        }
      }
    } catch (e) {
      print('Error loading profile data: $e');
      // Try cache as last resort
      try {
        final user = await _authRepository.getCachedUserData();
        if (user != null) {
          fullNameController.text = user.fullName;
          phoneController.text = user.phoneNumber;
        }
      } catch (cacheError) {
        print('Error loading from cache: $cacheError');
      }
    }
  }

  @override
  void onClose() {
    fullNameController.dispose();
    phoneController.dispose();
    cityController.dispose();
    fullNameFocusNode.dispose();
    phoneFocusNode.dispose();
    cityFocusNode.dispose();
    super.onClose();
  }

  bool _validateInputs() {
    fullNameError.value = '';
    phoneError.value = '';
    cityError.value = '';

    final fullName = fullNameController.text.trim();
    final phone = phoneController.text.trim();
    final city = cityController.text.trim();
    var isValid = true;

    if (fullName.isEmpty) {
      fullNameError.value = 'enter_full_name'.tr;
      isValid = false;
    }

    if (phone.isEmpty) {
      phoneError.value = 'enter_phone_number'.tr;
      isValid = false;
    } else if (phone.length < 8) {
      phoneError.value = 'invalid_phone_number'.tr;
      isValid = false;
    }

    if (city.isEmpty) {
      cityError.value = 'enter_city'.tr;
      isValid = false;
    }

    return isValid;
  }

  Future<void> saveProfile() async {
    if (!_validateInputs()) return;

    try {
      isSaving.value = true;

      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      // Update in Firestore
      await _firestore.collection('users').doc(currentUser.uid).update({
        'fullName': fullNameController.text.trim(),
        'phoneNumber': phoneController.text.trim(),
        'city': cityController.text.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update using repository to update cache
      await _authRepository.updateUserProfile({
        'fullName': fullNameController.text.trim(),
        'phoneNumber': phoneController.text.trim(),
      });

      // Note: City is not in UserModel, so we update it separately in Firestore only

      // Refresh profile in profile controller if it exists
      if (Get.isRegistered<DriverProfileController>()) {
        final profileController = Get.find<DriverProfileController>();
        await profileController.refreshProfile();
      }

      CustomToasts(
        message: 'profile_updated_success'.tr,
        type: CustomToastType.success,
      ).show();

      Get.back();
    } catch (e) {
      print('Error saving profile: $e');
      CustomToasts(
        message: 'profile_update_failed'.tr,
        type: CustomToastType.error,
      ).show();
    } finally {
      isSaving.value = false;
    }
  }
}

