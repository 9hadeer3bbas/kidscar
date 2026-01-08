import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../custom_widgets/custom_toast.dart';

class FileAttachDriverController extends GetxController {
  final Rx<File?> selectedFile = Rx<File?>(null);

  final ImagePicker _picker = ImagePicker();

  Future<void> pickFile({ImageSource source = ImageSource.gallery}) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      selectedFile.value = File(pickedFile.path);
    }
  }

  void removeFile() {
    selectedFile.value = null;
  }

  void submitFile() {
    if (selectedFile.value != null) {
      // TODO: Implement file upload or next step
      CustomToasts(
        message: 'file_submitted_successfully'.tr,
        type: CustomToastType.success,
      ).show();
    } else {
      CustomToasts(
        message: 'please_attach_file_first'.tr,
        type: CustomToastType.warning,
      ).show();
    }
  }
}
