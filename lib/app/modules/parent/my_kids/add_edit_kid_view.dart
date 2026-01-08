import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../custom_widgets/wave_header.dart';
import '../../../custom_widgets/custom_button.dart';
import '../../../custom_widgets/custom_text_field.dart';
import '../../../../core/managers/color_manager.dart';
import '../../../../data/models/kid_model.dart';
import 'my_kids_controller.dart';

class AddEditKidView extends GetView<MyKidsController> {
  final KidModel? kid;

  const AddEditKidView({this.kid, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          WaveHeader(
            title: kid != null ? 'edit_kid'.tr : 'add_kid'.tr,
            onBackTap: () => Get.back(),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 0.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image Section
                  _buildProfileImageSection(),
                  SizedBox(height: 12.h),

                  // Personal Information Section
                  _buildSectionHeader('personal_information'.tr),
                  SizedBox(height: 12.h),

                  // Name
                  _buildTextField(
                    controller: controller.nameController,
                    label: 'full_name'.tr,
                    hint: 'enter_child_full_name'.tr,
                    prefixIcon: Icons.person_outline,
                    focusNode: controller.nameFocusNode,
                    nextFocusNode: controller.ageFocusNode,
                    errorText: controller.nameError.value.isNotEmpty
                        ? controller.nameError.value
                        : null,
                  ),
                  SizedBox(height: 12.h),

                  // Age and Gender Row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildTextField(
                          controller: controller.ageController,
                          label: 'age'.tr,
                          hint: 'enter_age'.tr,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.cake_outlined,
                          focusNode: controller.ageFocusNode,
                          nextFocusNode: controller.schoolNameFocusNode,
                          errorText: controller.ageError.value.isNotEmpty
                              ? controller.ageError.value
                              : null,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(flex: 3, child: _buildGenderDropdown()),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // School Information Section
                  _buildSectionHeader('school_information'.tr),
                  SizedBox(height: 12.h),

                  // School Name
                  _buildTextField(
                    controller: controller.schoolNameController,
                    label: 'school_name'.tr,
                    hint: 'enter_school_name'.tr,
                    prefixIcon: Icons.school_outlined,
                    focusNode: controller.schoolNameFocusNode,
                    nextFocusNode: controller.gradeFocusNode,
                    errorText: controller.schoolError.value.isNotEmpty
                        ? controller.schoolError.value
                        : null,
                  ),
                  SizedBox(height: 12.h),

                  // Grade
                  _buildTextField(
                    controller: controller.gradeController,
                    label: 'grade_class'.tr,
                    hint: 'enter_grade_class'.tr,
                    prefixIcon: Icons.class_outlined,
                    focusNode: controller.gradeFocusNode,
                    nextFocusNode: controller.emergencyContactFocusNode,
                    errorText: controller.gradeError.value.isNotEmpty
                        ? controller.gradeError.value
                        : null,
                  ),
                  SizedBox(height: 12.h),

                  // Emergency Information Section
                  _buildSectionHeader('emergency_information'.tr),
                  SizedBox(height: 12.h),

                  // Emergency Contact
                  _buildTextField(
                    controller: controller.emergencyContactController,
                    label: 'emergency_contact_name'.tr,
                    hint: 'enter_emergency_contact_name'.tr,
                    prefixIcon: Icons.contact_emergency_outlined,
                    focusNode: controller.emergencyContactFocusNode,
                    nextFocusNode: controller.emergencyPhoneFocusNode,
                    errorText: controller.emergencyContactError.value.isNotEmpty
                        ? controller.emergencyContactError.value
                        : null,
                  ),
                  SizedBox(height: 12.h),

                  // Emergency Phone
                  _buildTextField(
                    controller: controller.emergencyPhoneController,
                    label: 'emergency_phone_number'.tr,
                    hint: 'enter_emergency_phone_number'.tr,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                    focusNode: controller.emergencyPhoneFocusNode,
                    nextFocusNode: controller.medicalNotesFocusNode,
                    errorText: controller.emergencyPhoneError.value.isNotEmpty
                        ? controller.emergencyPhoneError.value
                        : null,
                  ),
                  SizedBox(height: 12.h),

                  // Medical Information Section
                  _buildSectionHeader('medical_information'.tr),
                  SizedBox(height: 12.h),

                  // Medical Notes
                  _buildMultiLineTextField(
                    controller: controller.medicalNotesController,
                    label: 'medical_notes_allergies'.tr,
                    hint: 'medical_notes_hint'.tr,
                    maxLines: 4,
                    prefixIcon: Icons.medical_services_outlined,
                    focusNode: controller.medicalNotesFocusNode,
                  ),
                  SizedBox(height: 22.h),

                  // Action Buttons
                  _buildActionButtons(),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          // Profile Image with Floating Camera Button
          SizedBox(
            width: 140.w,
            height: 140.w,
            child: Stack(
              children: [
                // Main Profile Image
                Center(
                  child: Obx(
                    () => GestureDetector(
                      onTap: controller.pickImage,
                      child: Container(
                        width: 120.w,
                        height: 120.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ColorManager.divider.withValues(alpha: 0.1),
                          border: Border.all(
                            color: ColorManager.primaryColor.withValues(
                              alpha: 0.2,
                            ),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: ColorManager.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(child: _buildImageContent()),
                      ),
                    ),
                  ),
                ),
                // Floating Camera Button
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: controller.pickImage,
                    child: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: ColorManager.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 18.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 8.h),

          // Instruction Text
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: ColorManager.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 14.sp,
                  color: ColorManager.primaryColor,
                ),
                SizedBox(width: 6.w),
                Text(
                  'tap_to_add_profile_photo'.tr,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: ColorManager.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    if (controller.selectedImage.value != null) {
      return Image.file(
        controller.selectedImage.value!,
        fit: BoxFit.cover,
        width: 120.w,
        height: 120.w,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      );
    } else if (controller.imageUrl.value.isNotEmpty) {
      return Image.network(
        controller.imageUrl.value,
        fit: BoxFit.cover,
        width: 120.w,
        height: 120.w,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingImage();
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      );
    } else {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 120.w,
      height: 120.w,
      decoration: BoxDecoration(
        color: ColorManager.divider.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.person_outline,
          size: 50.sp,
          color: ColorManager.textSecondary.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildLoadingImage() {
    return Container(
      width: 120.w,
      height: 120.w,
      decoration: BoxDecoration(
        color: ColorManager.divider.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: 24.w,
          height: 24.w,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              ColorManager.primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: ColorManager.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: ColorManager.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16.sp,
            color: ColorManager.primaryColor,
          ),
          SizedBox(width: 12.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: ColorManager.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    String? errorText,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: ColorManager.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        CustomTextField(
          controller: controller,
          hintText: hint,
          keyboardType: keyboardType,
          errorText: errorText,
          focusNode: focusNode,
          onFieldSubmitted: nextFocusNode != null
              ? (value) => nextFocusNode.requestFocus()
              : null,
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  size: 22.sp,
                  color: ColorManager.primaryColor.withOpacity(0.7),
                )
              : null,
        ),
      ],
    );
  }

  Widget _buildMultiLineTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? prefixIcon,
    int maxLines = 3,
    String? errorText,
    FocusNode? focusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: ColorManager.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: Offset(0, 0),
                blurRadius: 12,
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            maxLines: maxLines,
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.sp),
            cursorColor: ColorManager.primaryColor,
            decoration: InputDecoration(
              filled: true,
              fillColor: ColorManager.white,
              hintText: hint,
              hintStyle: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12.sp,
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(
                      prefixIcon,
                      size: 22.sp,
                      color: ColorManager.primaryColor.withOpacity(0.7),
                    )
                  : null,
              prefixIconConstraints: BoxConstraints(
                minWidth: 40.w,
                minHeight: 40.h,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 8.h,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: ColorManager.divider),
                borderRadius: BorderRadius.circular(12.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: ColorManager.primaryColor),
                borderRadius: BorderRadius.circular(12.r),
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: ColorManager.primaryColor),
                borderRadius: BorderRadius.circular(12.r),
              ),
              errorText: errorText,
              errorStyle: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'gender'.tr,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: ColorManager.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Obx(
            () => DropdownButtonFormField<Gender>(
              initialValue: controller.selectedGender.value,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(
                  Icons.person_outline,
                  size: 22.sp,
                  color: ColorManager.primaryColor.withValues(alpha: 0.7),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: ColorManager.divider, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: ColorManager.primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 10.2.h,
                ),
              ),
              borderRadius: BorderRadius.circular(12.r),
              items: Gender.values.map((gender) {
                return DropdownMenuItem(
                  value: gender,
                  child: Row(
                    children: [
                      Icon(
                        gender == Gender.male ? Icons.male : Icons.female,
                        size: 16.sp,
                        color: gender == Gender.male
                            ? Colors.blue
                            : Colors.pink,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        controller.getGenderText(gender),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (Gender? value) {
                if (value != null) {
                  controller.selectedGender.value = value;
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Save Button
          Obx(
            () => CustomButton(
              text: kid != null ? 'update_kid_button'.tr : 'add_kid_button'.tr,
              onPressed: controller.isAddingKid.value
                  ? null
                  : (kid != null
                        ? () => controller.updateKid(kid!)
                        : () => controller.addKid()),
              isLoading: controller.isAddingKid.value,
              height: 40.0.h,
              width: 250.0.w,
              textStyle: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Cancel Button
          SizedBox(
            height: 40.0.h,
            width: 250.0.w,
            child: OutlinedButton(
              onPressed: () => Get.back(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: ColorManager.divider, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                ),
                backgroundColor: Colors.white,
              ),
              child: Text(
                'cancel'.tr,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: ColorManager.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
