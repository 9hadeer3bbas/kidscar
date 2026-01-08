import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends GetxController {
  final RxString currentLanguage = 'en'.obs;

  // Available languages
  final List<Map<String, String>> languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
  ];

  static const String _languageKey = 'selected_language';

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);

      if (savedLanguage != null && savedLanguage.isNotEmpty) {
        currentLanguage.value = savedLanguage;
        // Apply the saved language
        if (savedLanguage == 'ar') {
          Get.updateLocale(const Locale('ar'));
        } else {
          Get.updateLocale(const Locale('en'));
        }
      } else {
        // Use device locale or default to English
        final deviceLocale = Get.deviceLocale;
        if (deviceLocale != null && deviceLocale.languageCode == 'ar') {
          currentLanguage.value = 'ar';
          Get.updateLocale(const Locale('ar'));
          await _saveLanguage('ar');
        } else {
          currentLanguage.value = 'en';
          Get.updateLocale(const Locale('en'));
        }
      }
    } catch (e) {
      print('Error loading language: $e');
      currentLanguage.value = 'en';
      Get.updateLocale(const Locale('en'));
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    print(
      '🔄 changeLanguage called with: $languageCode, current: ${currentLanguage.value}',
    );
    if (languageCode != currentLanguage.value) {
      // Update the observable first - this should trigger Obx rebuild
      print('📝 Updating currentLanguage.value to: $languageCode');
      currentLanguage.value = languageCode;

      // Change app locale - this should trigger GetMaterialApp rebuild
      final newLocale = languageCode == 'ar'
          ? const Locale('ar')
          : const Locale('en');
      print('🌐 Calling Get.updateLocale with: ${newLocale.languageCode}');
      Get.updateLocale(newLocale);

      // Force a small delay to ensure locale is updated
      await Future.delayed(const Duration(milliseconds: 50));

      // Save to SharedPreferences
      await _saveLanguage(languageCode);

      print(
        '✅ Language changed to: $languageCode, Get.locale is now: ${Get.locale?.languageCode}',
      );
      print('✅ currentLanguage.value is now: ${currentLanguage.value}');
    } else {
      print('⏭️ Language already set to $languageCode, skipping update');
    }
  }

  Future<void> _saveLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      print('Language saved: $languageCode');
    } catch (e) {
      print('Error saving language: $e');
    }
  }

  String getCurrentLanguageName() {
    final language = languages.firstWhere(
      (lang) => lang['code'] == currentLanguage.value,
      orElse: () => languages.first,
    );
    return language['name'] ?? 'English';
  }

  String getCurrentLanguageFlag() {
    final language = languages.firstWhere(
      (lang) => lang['code'] == currentLanguage.value,
      orElse: () => languages.first,
    );
    return language['flag'] ?? '🇺🇸';
  }

  void toggleLanguage() {
    final currentIndex = languages.indexWhere(
      (lang) => lang['code'] == currentLanguage.value,
    );
    final nextIndex = (currentIndex + 1) % languages.length;
    changeLanguage(languages[nextIndex]['code']!);
  }
}
