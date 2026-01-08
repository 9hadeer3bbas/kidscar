import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../data/models/kid_model.dart';
import '../../../custom_widgets/custom_toast.dart';

class MyKidsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Observable variables
  final RxList<KidModel> kids = <KidModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isAddingKid = false.obs;

  // Form controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController schoolNameController = TextEditingController();
  final TextEditingController gradeController = TextEditingController();
  final TextEditingController emergencyContactController =
      TextEditingController();
  final TextEditingController emergencyPhoneController =
      TextEditingController();
  final TextEditingController medicalNotesController = TextEditingController();

  // Focus nodes
  final FocusNode nameFocusNode = FocusNode();
  final FocusNode ageFocusNode = FocusNode();
  final FocusNode schoolNameFocusNode = FocusNode();
  final FocusNode gradeFocusNode = FocusNode();
  final FocusNode emergencyContactFocusNode = FocusNode();
  final FocusNode emergencyPhoneFocusNode = FocusNode();
  final FocusNode medicalNotesFocusNode = FocusNode();

  // Form state
  final Rx<Gender?> selectedGender = Rx<Gender?>(null);
  final Rx<File?> selectedImage = Rx<File?>(null);
  final RxString imageUrl = ''.obs;

  // Validation errors
  final RxString nameError = ''.obs;
  final RxString ageError = ''.obs;
  final RxString schoolError = ''.obs;
  final RxString gradeError = ''.obs;
  final RxString emergencyContactError = ''.obs;
  final RxString emergencyPhoneError = ''.obs;
  final RxString genderError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadKids();
  }

  @override
  void onClose() {
    nameController.dispose();
    ageController.dispose();
    schoolNameController.dispose();
    gradeController.dispose();
    emergencyContactController.dispose();
    emergencyPhoneController.dispose();
    medicalNotesController.dispose();

    // Dispose focus nodes
    nameFocusNode.dispose();
    ageFocusNode.dispose();
    schoolNameFocusNode.dispose();
    gradeFocusNode.dispose();
    emergencyContactFocusNode.dispose();
    emergencyPhoneFocusNode.dispose();
    medicalNotesFocusNode.dispose();

    super.onClose();
  }

  Future<void> _loadKids() async {
    isLoading.value = true;
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final querySnapshot = await _firestore
            .collection('kids')
            .where('parentId', isEqualTo: user.uid)
            .get();

        kids.value = querySnapshot.docs
            .map((doc) => KidModel.fromFirestore(doc))
            .toList();
      }
    } catch (e) {
      print('Error loading kids: $e');
      CustomToasts(
        message: 'failed_to_load_kids'.tr,
        type: CustomToastType.error,
      ).show();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        selectedImage.value = File(image.path);
      }
    } catch (e) {
      print('Error picking image: $e');
      CustomToasts(
        message: 'failed_to_pick_image'.tr,
        type: CustomToastType.error,
      ).show();
    }
  }

  Future<String?> _uploadImageToStorage(File imageFile, String kidId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Create a unique filename
      final fileName =
          'kid_${kidId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage
          .ref()
          .child('kids_images')
          .child(user.uid)
          .child(fileName);

      // Upload the file
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  bool _validateForm() {
    bool isValid = true;

    // Clear previous errors
    nameError.value = '';
    ageError.value = '';
    schoolError.value = '';
    gradeError.value = '';
    emergencyContactError.value = '';
    emergencyPhoneError.value = '';
    genderError.value = '';

    // Validate name
    final name = nameController.text.trim();
    if (name.isEmpty) {
      nameError.value = 'name_required'.tr;
      isValid = false;
    } else if (name.length < 2) {
      nameError.value = 'name_min_length'.tr;
      isValid = false;
    } else if (name.length > 50) {
      nameError.value = 'name_max_length'.tr;
      isValid = false;
    }

    // Validate age
    final ageText = ageController.text.trim();
    if (ageText.isEmpty) {
      ageError.value = 'age_required'.tr;
      isValid = false;
    } else {
      final age = int.tryParse(ageText);
      if (age == null || age < 1 || age > 18) {
        ageError.value = 'age_invalid'.tr;
        isValid = false;
      }
    }

    // Validate school
    final school = schoolNameController.text.trim();
    if (school.isEmpty) {
      schoolError.value = 'school_required'.tr;
      isValid = false;
    } else if (school.length < 2) {
      schoolError.value = 'school_min_length'.tr;
      isValid = false;
    }

    // Validate grade
    final grade = gradeController.text.trim();
    if (grade.isEmpty) {
      gradeError.value = 'grade_required'.tr;
      isValid = false;
    } else if (grade.length < 1) {
      gradeError.value = 'grade_invalid'.tr;
      isValid = false;
    }

    // Validate emergency contact
    final emergencyContact = emergencyContactController.text.trim();
    if (emergencyContact.isEmpty) {
      emergencyContactError.value = 'emergency_contact_required'.tr;
      isValid = false;
    } else if (emergencyContact.length < 2) {
      emergencyContactError.value = 'emergency_contact_min_length'.tr;
      isValid = false;
    }

    // Validate emergency phone
    final emergencyPhone = emergencyPhoneController.text.trim();
    if (emergencyPhone.isEmpty) {
      emergencyPhoneError.value = 'emergency_phone_required'.tr;
      isValid = false;
    } else if (!_isValidPhoneNumber(emergencyPhone)) {
      emergencyPhoneError.value = 'emergency_phone_invalid'.tr;
      isValid = false;
    }

    // Validate gender
    if (selectedGender.value == null) {
      genderError.value = 'gender_required'.tr;
      isValid = false;
    }

    return isValid;
  }

  bool _isValidPhoneNumber(String phone) {
    // Remove all non-digit characters
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Check if it's a valid length (7-15 digits)
    if (digitsOnly.length < 7 || digitsOnly.length > 15) {
      return false;
    }

    // Additional validation for common phone number patterns
    final phoneRegex = RegExp(r'^[\+]?[0-9\s\-\(\)]{7,15}$');
    return phoneRegex.hasMatch(phone);
  }

  void _clearForm() {
    nameController.clear();
    ageController.clear();
    schoolNameController.clear();
    gradeController.clear();
    emergencyContactController.clear();
    emergencyPhoneController.clear();
    medicalNotesController.clear();
    selectedGender.value = null;
    selectedImage.value = null;
    imageUrl.value = '';

    // Clear errors
    nameError.value = '';
    ageError.value = '';
    schoolError.value = '';
    gradeError.value = '';
    emergencyContactError.value = '';
    emergencyPhoneError.value = '';
    genderError.value = '';
  }

  Future<void> addKid() async {
    if (!_validateForm()) {
      CustomToasts(
        message: 'validation_error'.tr,
        type: CustomToastType.warning,
      ).show();
      return;
    }

    isAddingKid.value = true;
    try {
      final user = _auth.currentUser;
      if (user == null) {
        CustomToasts(
          message: 'user_not_authenticated'.tr,
          type: CustomToastType.error,
        ).show();
        return;
      }

      final kid = KidModel(
        id: _firestore.collection('kids').doc().id,
        parentId: user.uid,
        name: nameController.text.trim(),
        age: int.parse(ageController.text.trim()),
        gender: selectedGender.value!,
        schoolName: schoolNameController.text.trim(),
        grade: gradeController.text.trim(),
        profileImageUrl: null, // Will be set after upload
        emergencyContact: emergencyContactController.text.trim(),
        emergencyPhone: emergencyPhoneController.text.trim(),
        medicalNotes: medicalNotesController.text.trim().isEmpty
            ? null
            : medicalNotesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Upload image if selected
      String? imageUrl;
      if (selectedImage.value != null) {
        imageUrl = await _uploadImageToStorage(selectedImage.value!, kid.id);
        if (imageUrl == null) {
          CustomToasts(
            message: 'failed_to_upload_image'.tr,
            type: CustomToastType.error,
          ).show();
          return;
        }
      }

      // Update kid with image URL
      final kidWithImage = kid.copyWith(profileImageUrl: imageUrl);

      await _firestore
          .collection('kids')
          .doc(kid.id)
          .set(kidWithImage.toJson());

      CustomToasts(
        message: 'kid_added_successfully'.tr,
        type: CustomToastType.success,
      ).show();
      _clearForm();
      _loadKids(); // Refresh the list
      Get.back(); // Navigate back to My Kids page
    } catch (e) {
      print('Error adding kid: $e');
      CustomToasts(
        message: 'failed_to_add_kid'.tr,
        type: CustomToastType.error,
      ).show();
    } finally {
      isAddingKid.value = false;
    }
  }

  Future<void> updateKid(KidModel kid) async {
    if (!_validateForm()) {
      CustomToasts(
        message: 'validation_error'.tr,
        type: CustomToastType.warning,
      ).show();
      return;
    }

    isAddingKid.value = true;
    try {
      // Upload new image if selected
      String? imageUrl = kid.profileImageUrl; // Keep existing image by default
      if (selectedImage.value != null) {
        imageUrl = await _uploadImageToStorage(selectedImage.value!, kid.id);
        if (imageUrl == null) {
          CustomToasts(
            message: 'failed_to_upload_image'.tr,
            type: CustomToastType.error,
          ).show();
          return;
        }
      }

      final updatedKid = kid.copyWith(
        name: nameController.text.trim(),
        age: int.parse(ageController.text.trim()),
        gender: selectedGender.value!,
        schoolName: schoolNameController.text.trim(),
        grade: gradeController.text.trim(),
        profileImageUrl: imageUrl,
        emergencyContact: emergencyContactController.text.trim(),
        emergencyPhone: emergencyPhoneController.text.trim(),
        medicalNotes: medicalNotesController.text.trim().isEmpty
            ? null
            : medicalNotesController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('kids')
          .doc(kid.id)
          .update(updatedKid.toJson());

      CustomToasts(
        message: 'kid_updated_successfully'.tr,
        type: CustomToastType.success,
      ).show();
      _clearForm();
      _loadKids(); // Refresh the list
      Get.back(); // Navigate back to My Kids page
    } catch (e) {
      print('Error updating kid: $e');
      CustomToasts(
        message: 'failed_to_update_kid'.tr,
        type: CustomToastType.error,
      ).show();
    } finally {
      isAddingKid.value = false;
    }
  }

  Future<void> deleteKid(KidModel kid) async {
    try {
      await _firestore.collection('kids').doc(kid.id).delete();
      CustomToasts(
        message: 'kid_deleted_successfully'.tr,
        type: CustomToastType.success,
      ).show();
      _loadKids(); // Refresh the list
    } catch (e) {
      print('Error deleting kid: $e');
      CustomToasts(
        message: 'failed_to_delete_kid'.tr,
        type: CustomToastType.error,
      ).show();
    }
  }

  void _navigateToAddEditKid([KidModel? kid]) {
    if (kid != null) {
      // Pre-fill form for editing
      nameController.text = kid.name;
      ageController.text = kid.age.toString();
      schoolNameController.text = kid.schoolName;
      gradeController.text = kid.grade;
      emergencyContactController.text = kid.emergencyContact;
      emergencyPhoneController.text = kid.emergencyPhone;
      medicalNotesController.text = kid.medicalNotes ?? '';
      selectedGender.value = kid.gender;
      imageUrl.value = kid.profileImageUrl ?? '';
    } else {
      _clearForm();
    }

    Get.toNamed('/add-edit-kid', arguments: kid);
  }

  void showAddKidDialog() {
    _navigateToAddEditKid();
  }

  void showEditKidDialog(KidModel kid) {
    _navigateToAddEditKid(kid);
  }

  void showDeleteKidDialog(KidModel kid) {
    Get.dialog(
      AlertDialog(
        title: Text('delete_kid'.tr),
        content: Text(
          'delete_kid_confirmation'.tr.replaceAll('{name}', kid.name),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () {
              Get.back();
              deleteKid(kid);
            },
            child: Text('delete'.tr, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String getGenderText(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 'male'.tr;
      case Gender.female:
        return 'female'.tr;
    }
  }

  // Focus management methods
  void focusNextField(FocusNode currentFocus) {
    if (currentFocus == nameFocusNode) {
      ageFocusNode.requestFocus();
    } else if (currentFocus == ageFocusNode) {
      schoolNameFocusNode.requestFocus();
    } else if (currentFocus == schoolNameFocusNode) {
      gradeFocusNode.requestFocus();
    } else if (currentFocus == gradeFocusNode) {
      emergencyContactFocusNode.requestFocus();
    } else if (currentFocus == emergencyContactFocusNode) {
      emergencyPhoneFocusNode.requestFocus();
    } else if (currentFocus == emergencyPhoneFocusNode) {
      medicalNotesFocusNode.requestFocus();
    } else if (currentFocus == medicalNotesFocusNode) {
      // Last field - unfocus to dismiss keyboard
      medicalNotesFocusNode.unfocus();
    }
  }

  void focusPreviousField(FocusNode currentFocus) {
    if (currentFocus == ageFocusNode) {
      nameFocusNode.requestFocus();
    } else if (currentFocus == schoolNameFocusNode) {
      ageFocusNode.requestFocus();
    } else if (currentFocus == gradeFocusNode) {
      schoolNameFocusNode.requestFocus();
    } else if (currentFocus == emergencyContactFocusNode) {
      gradeFocusNode.requestFocus();
    } else if (currentFocus == emergencyPhoneFocusNode) {
      emergencyContactFocusNode.requestFocus();
    } else if (currentFocus == medicalNotesFocusNode) {
      emergencyPhoneFocusNode.requestFocus();
    }
  }
}
