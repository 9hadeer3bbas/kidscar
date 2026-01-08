import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kidscar/core/managers/color_manager.dart';
import 'package:kidscar/core/managers/theme_manager.dart';
import 'package:kidscar/core/routes/get_pages.dart';
import 'package:kidscar/core/controllers/language_controller.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/config/app_binding.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class KidsCarApp extends StatefulWidget {
  const KidsCarApp({super.key});

  @override
  State<KidsCarApp> createState() => _KidsCarAppState();
}

class _KidsCarAppState extends State<KidsCarApp> {
  // Cache the translations future to prevent reloading on hot reload
  late final Future<Map<String, Map<String, String>>> _translationsFuture;

  @override
  void initState() {
    super.initState();
    _translationsFuture = _loadTranslations();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, Map<String, String>>>(
      future: _translationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: ColorManager.primaryColor,
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint('⚠️ Failed to load translations: ${snapshot.error}');
        }

        final translations =
            snapshot.data ??
            const {'en': <String, String>{}, 'ar': <String, String>{}};
        return ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return Obx(() {
              // Get locale from LanguageController - Obx will track currentLanguage.value
              Locale locale;
              // Check if controller is registered before trying to find it
              if (Get.isRegistered<LanguageController>()) {
                final langController = Get.find<LanguageController>();
                // Access .value to ensure Obx tracks this observable
                final langCode = langController.currentLanguage.value;
                locale = langCode == 'ar'
                    ? const Locale('ar')
                    : const Locale('en');

                // Debug: Print current locale and translation keys count
                debugPrint(
                  '🌐 Current locale: ${locale.languageCode} (from controller: $langCode)',
                );
                debugPrint(
                  '🌐 Translations available: en=${translations['en']?.length ?? 0}, ar=${translations['ar']?.length ?? 0}',
                );
              } else {
                // Fallback if controller not registered yet - register it and use its observable
                // Note: This path should rarely execute as controller is registered in AppBinding
                final langController = Get.put(LanguageController());
                // Access .value to ensure Obx tracks this observable
                final langCode = langController.currentLanguage.value;
                locale = langCode == 'ar'
                    ? const Locale('ar')
                    : const Locale('en');
                debugPrint('🌐 Controller registered on-the-fly, using locale: ${locale.languageCode}');
              }

              return GetMaterialApp(
                key: ValueKey(
                  'app_${locale.languageCode}',
                ), // Force rebuild on locale change
                debugShowCheckedModeBanner: false,
                title: 'KidsCar',
                initialRoute: '/splash',
                getPages: AppPages.pages,
                initialBinding: AppBinding(),
                translations: _AppTranslations(translations),
                locale: locale,
                fallbackLocale: const Locale('en'),
                theme: themeManager(locale),
                builder: (context, widget) {
                  ScreenUtil.init(context);
                  return MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(1)),
                    child: Directionality(
                      textDirection: locale.languageCode == 'ar'
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      child: widget!,
                    ),
                  );
                },
              );
            });
          },
        );
      },
    );
  }

  Future<Map<String, Map<String, String>>> _loadTranslations() async {
    try {
      final enString = await rootBundle.loadString('assets/languages/en.json');
      final arString = await rootBundle.loadString('assets/languages/ar.json');
      final enMap = Map<String, String>.from(json.decode(enString));
      final arMap = Map<String, String>.from(json.decode(arString));
      return {'en': enMap, 'ar': arMap};
    } catch (error, stackTrace) {
      debugPrint('⚠️ Translation load error: $error');
      debugPrint('$stackTrace');
      return {'en': <String, String>{}, 'ar': <String, String>{}};
    }
  }
}

class _AppTranslations extends Translations {
  final Map<String, Map<String, String>> translations;
  _AppTranslations(this.translations);

  @override
  Map<String, Map<String, String>> get keys => translations;
}
