import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:kidscar/data/repos/auth_repository.dart';
import 'package:kidscar/app/custom_widgets/custom_toast.dart';
import 'package:kidscar/core/routes/get_routes.dart';

class SignupParentController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;

  late FocusNode nameFocusNode;
  late FocusNode emailFocusNode;
  late FocusNode phoneFocusNode;
  late FocusNode passwordFocusNode;
  late FocusNode confirmPasswordFocusNode;

  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var successMessage = ''.obs;
  final agreeToPolicy = false.obs;

  var nameError = ''.obs;
  var emailError = ''.obs;
  var phoneError = ''.obs;
  var passwordError = ''.obs;
  var confirmPasswordError = ''.obs;

  var showPassword = false.obs;
  var showConfirmPassword = false.obs;

  @override
  void onInit() {
    super.onInit();
    print('=== PARENT SIGNUP CONTROLLER INIT ===');
    // Initialize controllers
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();

    // Initialize focus nodes
    nameFocusNode = FocusNode();
    emailFocusNode = FocusNode();
    phoneFocusNode = FocusNode();
    passwordFocusNode = FocusNode();
    confirmPasswordFocusNode = FocusNode();

    print('Parent signup controllers initialized');
  }

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
    nameError.value = '';
    emailError.value = '';
    phoneError.value = '';
    passwordError.value = '';
    confirmPasswordError.value = '';
    bool isValid = true;
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    final passwordRegex = RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#\$&*~_\-]).{6,}$',
    );

    print('=== PARENT SIGNUP VALIDATION ===');
    print('Name: $name');
    print('Email: $email');
    print('Phone: $phone');
    print('Password length: ${password.length}');
    print('Agree to policy: ${agreeToPolicy.value}');

    // Name validation
    if (name.isEmpty) {
      nameError.value = 'Full name is required';
      isValid = false;
    } else if (name.split(' ').length < 2) {
      nameError.value = 'Please enter your first and last name';
      isValid = false;
    }

    // Email validation
    if (email.isEmpty) {
      emailError.value = 'Email is required';
      isValid = false;
    } else if (!GetUtils.isEmail(email)) {
      emailError.value = 'Please enter a valid email address';
      isValid = false;
    }

    // Phone validation
    if (phone.isEmpty) {
      phoneError.value = 'Phone number is required';
      isValid = false;
    } else if (!GetUtils.isPhoneNumber(phone)) {
      phoneError.value = 'Please enter a valid phone number';
      isValid = false;
    }

    // Password validation
    if (password.isEmpty) {
      passwordError.value = 'Password is required';
      isValid = false;
    } else if (!passwordRegex.hasMatch(password)) {
      passwordError.value =
          'Password must contain at least 6 characters with letters, numbers, and special characters';
      isValid = false;
    }

    // Confirm password validation
    if (confirmPassword.isEmpty) {
      confirmPasswordError.value = 'Please confirm your password';
      isValid = false;
    } else if (confirmPassword != password) {
      confirmPasswordError.value = 'Passwords do not match';
      isValid = false;
    }

    // Policy agreement validation
    if (!agreeToPolicy.value) {
      CustomToasts(
        message: 'Please agree to the terms and conditions',
        type: CustomToastType.warning,
      ).show();
      isValid = false;
    }

    print('Validation result: $isValid');
    return isValid;
  }

  void signUp() {
    register();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameFocusNode.dispose();
    emailFocusNode.dispose();
    phoneFocusNode.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    super.onClose();
  }

  Future<void> register() async {
    if (!validateInputs()) return;

    isLoading.value = true;
    errorMessage.value = '';
    successMessage.value = '';

    try {
      print('=== PARENT REGISTRATION START ===');

      // Split name into first and last name
      final nameParts = nameController.text.trim().split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      print('First name: $firstName');
      print('Last name: $lastName');
      print('Email: ${emailController.text.trim()}');
      print('Phone: ${phoneController.text.trim()}');

      // Register parent using AuthRepository
      final uid = await _authRepository.registerParent(
        firstName: firstName,
        lastName: lastName,
        email: emailController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        password: passwordController.text.trim(),
      );

      print('Parent registration successful with UID: $uid');

      // Show success message
      CustomToasts(
        message:
            'Registration successful! Verification email sent to ${emailController.text.trim()}. Please check your email (including spam folder) and verify your account before signing in.',
        type: CustomToastType.success,
        duration: const Duration(seconds: 8),
      ).show();

      // Navigate to signin after a delay
      await Future.delayed(const Duration(seconds: 2));
      Get.offAllNamed(AppRoutes.signIn);
    } catch (e) {
      print('=== PARENT REGISTRATION ERROR ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: ${e.toString()}');
      print('Error details: $e');

      errorMessage.value = e.toString();

      // Show error toast
      CustomToasts(
        message: 'Registration failed: ${e.toString()}',
        type: CustomToastType.error,
      ).show();
    } finally {
      isLoading.value = false;
      print('=== PARENT REGISTRATION COMPLETED ===');
    }
  }
}
