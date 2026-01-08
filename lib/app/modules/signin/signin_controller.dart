import 'package:get/get.dart';
import '../../../data/repos/auth_repository.dart';
import '../../../app/custom_widgets/custom_toast.dart';
import '../../../core/controllers/language_controller.dart';
import '../../../core/services/auth_flow_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignInController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();
  final LanguageController _languageController = Get.find<LanguageController>();

  late TextEditingController emailController;
  late TextEditingController passwordController;

  late FocusNode emailFocusNode;
  late FocusNode passwordFocusNode;

  var isLoading = false.obs;
  var isSendingReset = false.obs;
  var errorMessage = ''.obs;
  var emailError = ''.obs;
  var passwordError = ''.obs;
  // controls password visibility in the UI
  var showPassword = false.obs;

  @override
  void onInit() {
    super.onInit();
    print('=== SIGNIN CONTROLLER INIT ===');
    // Initialize controllers
    emailController = TextEditingController();
    passwordController = TextEditingController();
    // Initialize focus nodes
    emailFocusNode = FocusNode();
    passwordFocusNode = FocusNode();
    print('Controllers initialized');
    // Note: Login status check is now handled by AuthFlowService in SplashScreen
  }

  // Method to ensure controllers are properly initialized
  void ensureControllersInitialized() {
    print('=== ENSURE CONTROLLERS INITIALIZED ===');
    // Check if controllers are disposed and reinitialize if needed
    try {
      // Try to access the text property to check if controller is disposed
      final _ = emailController.text;
      final _ = passwordController.text;
      // Check if focus nodes are disposed by trying to use them
      try {
        if (!emailFocusNode.canRequestFocus) {
          emailFocusNode = FocusNode();
        }
      } catch (e) {
        emailFocusNode = FocusNode();
      }
      try {
        if (!passwordFocusNode.canRequestFocus) {
          passwordFocusNode = FocusNode();
        }
      } catch (e) {
        passwordFocusNode = FocusNode();
      }
      print('Controllers are properly initialized');
    } catch (e) {
      print('ERROR: Controllers were disposed, reinitializing...');
      print('Error: $e');
      // If controllers are disposed, reinitialize them
      emailController = TextEditingController();
      passwordController = TextEditingController();
      emailFocusNode = FocusNode();
      passwordFocusNode = FocusNode();
      print('Controllers reinitialized');
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    // Dispose focus nodes safely
    try {
      if (emailFocusNode.canRequestFocus || emailFocusNode.hasFocus) {
        emailFocusNode.unfocus();
      }
      emailFocusNode.dispose();
    } catch (e) {
      // Focus node already disposed, ignore
    }
    try {
      if (passwordFocusNode.canRequestFocus || passwordFocusNode.hasFocus) {
        passwordFocusNode.unfocus();
      }
      passwordFocusNode.dispose();
    } catch (e) {
      // Focus node already disposed, ignore
    }
    super.onClose();
  }

  void togglePasswordVisibility() {
    showPassword.value = !showPassword.value;
  }

  bool validateInputs() {
    emailError.value = '';
    passwordError.value = '';
    bool isValid = true;
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      emailError.value = 'Please enter a valid email.';
      isValid = false;
    }
    if (password.isEmpty || password.length < 6) {
      passwordError.value = 'Password must be at least 6 characters.';
      isValid = false;
    }
    return isValid;
  }

  Future<void> signIn() async {
    if (!validateInputs()) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      print('=== SIGN IN DEBUG ===');
      print('Email: ${emailController.text.trim()}');
      print('Password length: ${passwordController.text.length}');

      // Use universal auth repository for login (handles both parents and drivers)
      await _authRepository.loginUser(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      print('Login successful');

      // Refresh AuthFlowService to update current user
      final authService = Get.find<AuthFlowService>();
      await authService.refreshAuthStatus();

      // Navigate based on authentication status
      if (authService.isAuthenticated) {
        await authService.navigateToInitialScreen();
      } else {
        errorMessage.value = 'Authentication failed.';
        print('ERROR: Authentication failed after login');
      }
    } catch (e) {
      print('=== SIGN IN ERROR ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: ${e.toString()}');
      print('Error details: $e');

      String localizedErrorMessage;

      if (e is FirebaseAuthException) {
        print('Firebase Auth Error Code: ${e.code}');
        print('Firebase Auth Error Message: ${e.message}');

        // Handle specific Firebase Auth error codes
        switch (e.code.toLowerCase()) {
          case 'wrong-password':
            localizedErrorMessage = 'error_wrong_password'.tr;
            print('Translated error_wrong_password: $localizedErrorMessage');
            break;
          case 'user-not-found':
            localizedErrorMessage = 'error_user_not_found'.tr;
            print('Translated error_user_not_found: $localizedErrorMessage');
            break;
          case 'invalid-credential':
          case 'invalid-email':
            localizedErrorMessage = 'error_invalid_credentials'.tr;
            print(
              'Translated error_invalid_credentials: $localizedErrorMessage',
            );
            break;
          case 'too-many-requests':
            localizedErrorMessage = 'error_too_many_requests'.tr;
            print('Translated error_too_many_requests: $localizedErrorMessage');
            break;
          case 'user-disabled':
            localizedErrorMessage = 'error_user_disabled'.tr;
            print('Translated error_user_disabled: $localizedErrorMessage');
            break;
          default:
            localizedErrorMessage = e.message ?? 'error_invalid_credentials'.tr;
            print('Default error message: $localizedErrorMessage');
        }
        print('Current locale: ${Get.locale?.languageCode}');
        print('Final error message to show: $localizedErrorMessage');
      } else {
        // For non-Firebase exceptions, use a generic error message
        localizedErrorMessage = e.toString();
        print('Non-Firebase error: $localizedErrorMessage');
      }

      errorMessage.value = localizedErrorMessage;

      // Show custom toast with localized error message
      CustomToasts(
        message: localizedErrorMessage,
        type: CustomToastType.error,
      ).show();
    } finally {
      isLoading.value = false;
      print('=== SIGN IN COMPLETED ===');
    }
  }
  // ...existing code...

  Future<void> resetPassword() async {
    try {
      // Ensure controllers are initialized before accessing them
      ensureControllersInitialized();

      final email = emailController.text.trim();

      if (email.isEmpty) {
        emailError.value = 'enter_registered_email'.tr;
        CustomToasts(
          message: 'enter_registered_email'.tr,
          type: CustomToastType.warning,
        ).show();
        // Request focus on email field if focus node is available
        if (emailFocusNode.canRequestFocus) {
          emailFocusNode.requestFocus();
        }
        return;
      }

      if (!GetUtils.isEmail(email)) {
        emailError.value = 'enter_valid_email'.tr;
        CustomToasts(
          message: 'enter_valid_email'.tr,
          type: CustomToastType.warning,
        ).show();
        // Request focus on email field if focus node is available
        if (emailFocusNode.canRequestFocus) {
          emailFocusNode.requestFocus();
        }
        return;
      }

      isSendingReset.value = true;
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      // Clear any previous errors
      emailError.value = '';
      CustomToasts(
        message: 'password_reset_email_sent'.trParams({'email': email}),
        type: CustomToastType.success,
        duration: const Duration(seconds: 5),
      ).show();
    } on FirebaseAuthException catch (e) {
      final code = e.code.toLowerCase();
      String localizedMessage;
      switch (code) {
        case 'user-not-found':
          localizedMessage = 'password_reset_user_not_found'.tr;
          break;
        case 'invalid-email':
          localizedMessage = 'enter_valid_email'.tr;
          break;
        default:
          localizedMessage = 'password_reset_failed'.tr;
      }
      emailError.value = localizedMessage;
      CustomToasts(
        message: localizedMessage,
        type: CustomToastType.error,
      ).show();
    } catch (e) {
      CustomToasts(
        message: 'password_reset_failed'.tr,
        type: CustomToastType.error,
      ).show();
    } finally {
      isSendingReset.value = false;
    }
  }

  /// Toggle language
  void toggleLanguage() {
    _languageController.toggleLanguage();
  }

  /// Resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      print('=== RESEND VERIFICATION EMAIL DEBUG ===');
      isLoading.value = true;

      // Check if user exists and is not verified
      final email = emailController.text.trim();
      print('Email: $email');

      if (email.isEmpty) {
        print('ERROR: Email is empty');
        CustomToasts(
          message: 'Please enter your email address',
          type: CustomToastType.warning,
        ).show();
        return;
      }

      // Check if password is provided
      final password = passwordController.text.trim();
      print('Password length: ${password.length}');

      if (password.isEmpty) {
        print('ERROR: Password is empty');
        CustomToasts(
          message: 'Please enter your password to resend verification email',
          type: CustomToastType.warning,
        ).show();
        return;
      }

      try {
        print(
          'Attempting to sign in user (bypassing email verification check)...',
        );
        // Sign in directly using FirebaseAuth to bypass email verification check
        // This is needed because we need to send verification email for unverified users
        final userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        print('Sign in successful for resend verification');

        // Get the current user and resend verification
        final currentUser = userCredential.user;
        print('Current user: ${currentUser?.email}');
        print('Email verified: ${currentUser?.emailVerified}');

        if (currentUser != null) {
          // Reload user to get latest state
          print('Reloading user...');
          await currentUser.reload();
          print('User reloaded. Email verified: ${currentUser.emailVerified}');

          if (!currentUser.emailVerified) {
            print('Sending verification email...');
            // Configure action code settings for better email handling
            final actionCodeSettings = ActionCodeSettings(
              url: 'https://kidscar-454dd.firebaseapp.com/__/auth/action',
              handleCodeInApp: false,
              androidPackageName: 'com.codge.kidscar',
              iOSBundleId: 'com.codge.kidscar',
            );
            await currentUser.sendEmailVerification(actionCodeSettings);
            print('Verification email sent successfully');

            CustomToasts(
              message:
                  'Verification email resent to $email. Please check your email (including spam folder).',
              type: CustomToastType.success,
              duration: const Duration(seconds: 6),
            ).show();
          } else {
            print('Email is already verified');
            CustomToasts(
              message: 'Email is already verified. You can sign in now.',
              type: CustomToastType.warning,
            ).show();
          }
        } else {
          print('ERROR: Current user is null');
          CustomToasts(
            message: 'No user found with this email',
            type: CustomToastType.error,
          ).show();
        }

        // Sign out after sending verification
        print('Signing out after verification...');
        await FirebaseAuth.instance.signOut();
        print('Sign out successful');
      } on FirebaseAuthException catch (e) {
        print('=== RESEND VERIFICATION ERROR ===');
        print('Error type: ${e.runtimeType}');
        print('Error message: ${e.toString()}');
        print('Error details: $e');
        print('Firebase Auth Error Code: ${e.code}');
        print('Firebase Auth Error Message: ${e.message}');

        // Handle specific Firebase Auth errors
        String errorMessage;
        switch (e.code.toLowerCase()) {
          case 'user-not-found':
            errorMessage = 'No user found with this email address.';
            break;
          case 'wrong-password':
          case 'invalid-credential':
            errorMessage =
                'Invalid email or password. Please check your credentials.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address format.';
            break;
          case 'user-disabled':
            errorMessage = 'This account has been disabled.';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many requests. Please try again later.';
            break;
          default:
            errorMessage =
                'Failed to resend verification email: ${e.message ?? e.code}';
        }

        CustomToasts(message: errorMessage, type: CustomToastType.error).show();
      } catch (e) {
        print('=== RESEND VERIFICATION ERROR ===');
        print('Error type: ${e.runtimeType}');
        print('Error message: ${e.toString()}');
        print('Error details: $e');

        CustomToasts(
          message: 'Failed to resend verification email: ${e.toString()}',
          type: CustomToastType.error,
        ).show();
      }
    } catch (e) {
      print('=== RESEND VERIFICATION OUTER ERROR ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: ${e.toString()}');
      print('Error details: $e');

      CustomToasts(
        message: 'Failed to resend verification email: ${e.toString()}',
        type: CustomToastType.error,
      ).show();
    } finally {
      isLoading.value = false;
      print('=== RESEND VERIFICATION COMPLETED ===');
    }
  }
}
