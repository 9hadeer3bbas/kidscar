import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kidscar/data/repos/driver_auth_repo.dart';
import 'package:kidscar/core/routes/get_routes.dart';
import 'package:kidscar/app/custom_widgets/custom_toast.dart';
// import 'dart:io';

import 'dart:io';

class DriverSignUpController extends GetxController {
  final DriverAuthRepository _driverAuthRepository = DriverAuthRepository();

  final RxString selectedCity = ''.obs;
  final Rx<File?> drivingLicense = Rx<File?>(null);
  final Rx<File?> vehicleRegistration = Rx<File?>(null);
  final Rx<File?> driverPhoto = Rx<File?>(null);
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final firstNameFocusNode = FocusNode();
  final lastNameFocusNode = FocusNode();
  final phoneFocusNode = FocusNode();
  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();
  final confirmPasswordFocusNode = FocusNode();

  final firstNameError = ''.obs;
  final lastNameError = ''.obs;
  final phoneError = ''.obs;
  final emailError = ''.obs;
  final passwordError = ''.obs;
  final confirmPasswordError = ''.obs;

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final agreeToPolicy = false.obs;

  final showPassword = false.obs;
  final showConfirmPassword = false.obs;

  void togglePasswordVisibility() {
    showPassword.value = !showPassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    showConfirmPassword.value = !showConfirmPassword.value;
  }

  void togglePolicy(bool? value) {
    agreeToPolicy.value = value ?? false;
  }

  bool validateInputs() {
    firstNameError.value = '';
    lastNameError.value = '';
    phoneError.value = '';
    emailError.value = '';
    passwordError.value = '';
    confirmPasswordError.value = '';
    bool isValid = true;
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    final passwordRegex = RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#\$&*~_\-]).{6,}$',
    );
    // First name validation
    if (firstName.isEmpty) {
      firstNameError.value = 'first_name_required'.tr;
      isValid = false;
    }
    // Last name validation
    if (lastName.isEmpty) {
      lastNameError.value = 'last_name_required'.tr;
      isValid = false;
    }
    // Email validation
    if (email.isEmpty) {
      emailError.value = 'email_required'.tr;
      isValid = false;
    } else if (!GetUtils.isEmail(email)) {
      emailError.value = 'error_invalid_email'.tr;
      isValid = false;
    }
    // Phone validation
    if (phone.isEmpty) {
      phoneError.value = 'phone_required'.tr;
      isValid = false;
    } else if (!GetUtils.isPhoneNumber(phone)) {
      phoneError.value = 'error_invalid_phone'.tr;
      isValid = false;
    }
    // Password validation
    if (password.isEmpty) {
      passwordError.value = 'password_required'.tr;
      isValid = false;
    } else if (!passwordRegex.hasMatch(password)) {
      passwordError.value = 'error_password_strength'.tr;
      isValid = false;
    }
    // Confirm password validation
    if (confirmPassword.isEmpty) {
      confirmPasswordError.value = 'confirm_password_required'.tr;
      isValid = false;
    } else if (confirmPassword != password) {
      confirmPasswordError.value = 'error_password_match'.tr;
      isValid = false;
    }
    // City required
    if (selectedCity.value.isEmpty) {
      CustomToasts(
        message: 'select_city_required'.tr,
        type: CustomToastType.warning,
      ).show();
      isValid = false;
    }
    // Files required
    if (driverPhoto.value == null) {
      CustomToasts(
        message: 'driver_photo_required'.tr,
        type: CustomToastType.warning,
      ).show();
      isValid = false;
    }
    if (drivingLicense.value == null) {
      CustomToasts(
        message: 'driving_license_required'.tr,
        type: CustomToastType.warning,
      ).show();
      isValid = false;
    }
    if (vehicleRegistration.value == null) {
      CustomToasts(
        message: 'vehicle_registration_required'.tr,
        type: CustomToastType.warning,
      ).show();
      isValid = false;
    }

    // Policy agreement validation
    if (!agreeToPolicy.value) {
      CustomToasts(
        message: 'privacy_policy_agreement'.tr,
        type: CustomToastType.warning,
      ).show();
      isValid = false;
    }

    return isValid;
  }

  Future<void> registerDriver() async {
    if (!validateInputs()) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _driverAuthRepository.registerDriverWithFiles(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        password: passwordController.text,
        city: selectedCity.value,
        driverPhoto: driverPhoto.value!,
        drivingLicense: drivingLicense.value!,
        vehicleRegistration: vehicleRegistration.value!,
      );

      // After successful registration, show verification message and navigate to sign-in
      CustomToasts(
        message:
            'Registration successful! Verification email sent to ${emailController.text.trim()}. Please check your email (including spam folder) and verify your account before signing in.',
        type: CustomToastType.success,
        duration: const Duration(seconds: 8),
      ).show();

      // Navigate to sign-in page after a short delay to show the toast
      await Future.delayed(const Duration(seconds: 2));
      // Clear all previous routes and navigate to sign-in
      Get.offAllNamed(AppRoutes.signIn);
    } catch (e) {
      errorMessage.value = e.toString();
      debugPrint(errorMessage.value);
      CustomToasts(
        message: errorMessage.value,
        type: CustomToastType.error,
      ).show();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    firstNameFocusNode.dispose();
    lastNameFocusNode.dispose();
    phoneFocusNode.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    super.onClose();
  }
}
