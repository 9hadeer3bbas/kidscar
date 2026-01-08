import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kidscar/app/custom_widgets/custom_toast.dart';

class ChangePasswordController extends GetxController {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final oldPasswordFocusNode = FocusNode();
  final newPasswordFocusNode = FocusNode();
  final confirmPasswordFocusNode = FocusNode();

  final isSubmitting = false.obs;
  final showOldPassword = false.obs;
  final showNewPassword = false.obs;
  final showConfirmPassword = false.obs;

  final oldPasswordError = ''.obs;
  final newPasswordError = ''.obs;
  final confirmPasswordError = ''.obs;

  @override
  void onClose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    oldPasswordFocusNode.dispose();
    newPasswordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    super.onClose();
  }

  void toggleOldPasswordVisibility() {
    showOldPassword.toggle();
  }

  void toggleNewPasswordVisibility() {
    showNewPassword.toggle();
  }

  void toggleConfirmPasswordVisibility() {
    showConfirmPassword.toggle();
  }

  bool _validateInputs() {
    oldPasswordError.value = '';
    newPasswordError.value = '';
    confirmPasswordError.value = '';

    final oldPassword = oldPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    var isValid = true;

    if (oldPassword.isEmpty) {
      oldPasswordError.value = 'enter_current_password'.tr;
      isValid = false;
    }

    if (newPassword.isEmpty) {
      newPasswordError.value = 'enter_new_password'.tr;
      isValid = false;
    } else if (newPassword.length < 6) {
      newPasswordError.value = 'password_min_length'.tr;
      isValid = false;
    }

    if (confirmPassword.isEmpty) {
      confirmPasswordError.value = 'confirm_new_password'.tr;
      isValid = false;
    } else if (newPassword != confirmPassword) {
      confirmPasswordError.value = 'passwords_do_not_match'.tr;
      isValid = false;
    }

    if (isValid && oldPassword == newPassword) {
      newPasswordError.value = 'password_same_as_old'.tr;
      isValid = false;
    }

    return isValid;
  }

  Future<void> changePassword() async {
    if (!_validateInputs()) return;

    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;

    if (user == null || email == null) {
      CustomToasts(
        message: 'password_change_user_missing'.tr,
        type: CustomToastType.error,
      ).show();
      return;
    }

    final oldPassword = oldPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();

    try {
      isSubmitting.value = true;

      final credential = EmailAuthProvider.credential(
        email: email,
        password: oldPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      CustomToasts(
        message: 'password_updated_success'.tr,
        type: CustomToastType.success,
      ).show();

      oldPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      Get.back();
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code.toLowerCase()) {
        case 'wrong-password':
        case 'invalid-credential':
          message = 'password_change_wrong_old'.tr;
          oldPasswordError.value = 'password_change_wrong_old'.tr;
          break;
        case 'weak-password':
          message = 'password_min_length'.tr;
          newPasswordError.value = 'password_min_length'.tr;
          break;
        case 'requires-recent-login':
          message = 'password_change_requires_recent_login'.tr;
          break;
        default:
          message = 'password_change_failed'.tr;
      }

      CustomToasts(
        message: message,
        type: CustomToastType.error,
      ).show();
    } catch (e) {
      CustomToasts(
        message: 'password_change_failed'.tr,
        type: CustomToastType.error,
      ).show();
    } finally {
      isSubmitting.value = false;
    }
  }
}

