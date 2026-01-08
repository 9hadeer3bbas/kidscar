import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kidscar/app/custom_widgets/custom_toast.dart';
import 'package:kidscar/app/modules/parent/parent_main/parent_main_controller.dart';
import 'package:kidscar/data/models/user_model.dart';
import 'package:kidscar/data/repos/auth_repository.dart';

class ParentEditProfileController extends GetxController {
  ParentEditProfileController();

  final AuthRepository _authRepository = AuthRepository();
  final ParentMainController _parentMainController =
      Get.find<ParentMainController>();

  late final TextEditingController fullNameController;
  late final TextEditingController phoneController;

  final FocusNode fullNameFocusNode = FocusNode();
  final FocusNode phoneFocusNode = FocusNode();

  final isSaving = false.obs;
  final fullNameError = ''.obs;
  final phoneError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final user = _parentMainController.currentUser.value;
    fullNameController = TextEditingController(text: user?.fullName ?? '');
    phoneController = TextEditingController(text: user?.phoneNumber ?? '');
  }

  @override
  void onClose() {
    fullNameController.dispose();
    phoneController.dispose();
    fullNameFocusNode.dispose();
    phoneFocusNode.dispose();
    super.onClose();
  }

  bool _validateInputs() {
    fullNameError.value = '';
    phoneError.value = '';

    final fullName = fullNameController.text.trim();
    final phone = phoneController.text.trim();
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

    return isValid;
  }

  Future<void> saveProfile() async {
    if (!_validateInputs()) return;

    try {
      isSaving.value = true;

      await _authRepository.updateUserProfile({
        'fullName': fullNameController.text.trim(),
        'phoneNumber': phoneController.text.trim(),
      });

      final UserModel updatedUser = await _authRepository.refreshUserData();
      _parentMainController.setCurrentUser(updatedUser);

      CustomToasts(
        message: 'profile_updated_success'.tr,
        type: CustomToastType.success,
      ).show();

      Get.back();
    } catch (e) {
      CustomToasts(
        message: 'profile_update_failed'.tr,
        type: CustomToastType.error,
      ).show();
    } finally {
      isSaving.value = false;
    }
  }
}

