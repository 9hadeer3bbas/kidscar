import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:kidscar/app/custom_widgets/custom_button.dart';
import 'package:kidscar/app/modules/driver/file_attach_driver/file_attach_driver_controller.dart';
import 'package:kidscar/app/custom_widgets/wave_header.dart';
import 'package:kidscar/core/managers/assets_manager.dart';
import 'package:kidscar/core/managers/color_manager.dart';

class FileAttachDriverView extends GetView<FileAttachDriverController> {
  final String title;
  final List<String> instructions;
  final bool isPhoto;

  const FileAttachDriverView({
    super.key,
    this.title = 'Attach Driver File',
    this.instructions = const [
      'The image must be clear and readable.',
      'Accepted formats: JPG, PNG.',
      'Maximum size: 5MB.',
      'Make sure all corners are visible.',
    ],
    this.isPhoto = false,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure the controller is injected
    final controller = Get.put(FileAttachDriverController());
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WaveHeader(
            title: title,
            onBackTap: () => Get.back(),
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...instructions.map(
                    (e) => Column(
                      children: [
                        Text(
                          e.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 14.0.sp,
                          ),
                        ),
                        SizedBox(height: 10.0.h),
                      ],
                    ),
                  ),
                  isPhoto
                      ? Text(
                          'as_shown'.tr,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w400,
                            color: ColorManager.primaryColor,
                          ),
                        )
                      : SizedBox.shrink(),
                  isPhoto
                      ? Align(
                          alignment: Alignment.center,
                          child: Image.asset(
                            AssetsManager.imagePlaceholder,
                            height: 245.h,
                            width: 245.w,
                            fit: BoxFit.contain,
                          ),
                        )
                      : SizedBox(height: 245.h, width: 245.w),
                  Obx(() {
                    if (controller.selectedFile.value == null) {
                      return Center(
                        child: CustomButton(
                          height: 30.0.h,
                          width: 155.0.w,
                          text: 'take_a_photo'.tr,
                          onPressed: () => controller.pickFile(),
                        ),
                      );
                    } else {
                      return Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.insert_drive_file,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  controller.selectedFile.value!.path
                                      .split('/')
                                      .last,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: controller.removeFile,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              onPressed: () {
                                if (controller.selectedFile.value != null) {
                                  Get.back(
                                    result: controller.selectedFile.value,
                                  );
                                }
                              },
                              child: Text('submit'.tr),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '${'selected_file'.tr}: ${controller.selectedFile.value!.path.split('/').last}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      );
                    }
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
