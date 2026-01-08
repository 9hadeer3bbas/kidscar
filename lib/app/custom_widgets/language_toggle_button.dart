import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:kidscar/core/managers/color_manager.dart';
import 'package:kidscar/core/controllers/language_controller.dart';

class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    
    return Container(
      height: 40.w,
      width: 40.w,
      decoration: BoxDecoration(
        color: ColorManager.primaryColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(Icons.language, size: 22.w, color: ColorManager.white),
        onPressed: () {
          languageController.toggleLanguage();
        },
        padding: const EdgeInsets.all(8),
        splashRadius: 24,
      ),
    );
  }
}
