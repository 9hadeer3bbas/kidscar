import 'package:flutter/material.dart';
import 'color_manager.dart';
import 'font_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

ThemeData themeManager(Locale locale) {
  return ThemeData(
    fontFamily: FontManager.getFontFamily(locale),
    primaryColor: ColorManager.primaryColor,
    scaffoldBackgroundColor: ColorManager.scaffoldBackground,
    cardColor: ColorManager.card,
    dividerColor: ColorManager.divider,
    colorScheme: ColorScheme(
      primary: ColorManager.primaryColor,
      primaryContainer: ColorManager.primaryLight,
      secondary: ColorManager.secondaryColor,
      secondaryContainer: ColorManager.secondaryLight,
      surface: ColorManager.card,
      error: ColorManager.error,
      onPrimary: ColorManager.white,
      onSecondary: ColorManager.black,
      onSurface: ColorManager.textPrimary,
      onError: ColorManager.white,
      brightness: Brightness.light,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 32.sp,
        fontWeight: FontManager.bold,
        color: ColorManager.textPrimary,
        fontFamily: FontManager.getFontFamily(locale),
      ),
      displayMedium: TextStyle(
        fontSize: 28.sp,
        fontWeight: FontManager.semiBold,
        color: ColorManager.textPrimary,
        fontFamily: FontManager.getFontFamily(locale),
      ),
      displaySmall: TextStyle(
        fontSize: 24.sp,
        fontWeight: FontManager.semiBold,
        color: ColorManager.textPrimary,
        fontFamily: FontManager.getFontFamily(locale),
      ),
      headlineLarge: TextStyle(
        fontSize: 22.sp,
        fontWeight: FontManager.bold,
        color: ColorManager.textPrimary,
        fontFamily: FontManager.getFontFamily(locale),
      ),
      headlineMedium: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontManager.semiBold,
        color: ColorManager.textPrimary,
        fontFamily: FontManager.getFontFamily(locale),
      ),
      headlineSmall: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontManager.semiBold,
        color: ColorManager.textPrimary,
        fontFamily: FontManager.getFontFamily(locale),
      ),
      titleLarge: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontManager.bold,
        color: ColorManager.textPrimary,
        fontFamily: FontManager.getFontFamily(locale),
      ),
      titleMedium: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontManager.medium,
        color: ColorManager.textPrimary,
        fontFamily: FontManager.getFontFamily(locale),
      ),
      titleSmall: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontManager.medium,
        color: ColorManager.textSecondary,
        fontFamily: FontManager.getFontFamily(locale),
      ),
      bodyLarge: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontManager.regular,
        color: ColorManager.textPrimary,
        fontFamily: FontManager.getFontFamily(locale),
      ),
      bodyMedium: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontManager.regular,
        color: ColorManager.textPrimary,
        fontFamily: FontManager.getFontFamily(locale),
      ),
      bodySmall: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontManager.light,
        color: ColorManager.textSecondary,
        fontFamily: FontManager.getFontFamily(locale),
      ),
      labelLarge: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontManager.medium,
        color: ColorManager.textPrimary,
        fontFamily: FontManager.getFontFamily(locale),
      ),
      labelMedium: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontManager.medium,
        color: ColorManager.textSecondary,
        fontFamily: FontManager.getFontFamily(locale),
      ),
      labelSmall: TextStyle(
        fontSize: 10.sp,
        fontWeight: FontManager.medium,
        color: ColorManager.textDisabled,
        fontFamily: FontManager.getFontFamily(locale),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: ColorManager.primaryColor,
      elevation: 0,
      iconTheme: IconThemeData(color: ColorManager.white),
      titleTextStyle: TextStyle(
        fontFamily: FontManager.getFontFamily(locale),
        fontWeight: FontManager.bold,
        fontSize: 20.sp,
        color: ColorManager.white,
      ),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: ColorManager.primaryColor,
      textTheme: ButtonTextTheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorManager.primaryColor,
        foregroundColor: ColorManager.white,
        textStyle: TextStyle(
          fontFamily: FontManager.getFontFamily(locale),
          fontWeight: FontManager.bold,
          fontSize: 16.sp,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColorManager.backgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: ColorManager.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: ColorManager.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: ColorManager.primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: ColorManager.error),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      hintStyle: TextStyle(
        color: ColorManager.textDisabled,
        fontFamily: FontManager.getFontFamily(locale),
        fontWeight: FontManager.regular,
        fontSize: 14.sp,
      ),
      labelStyle: TextStyle(
        color: ColorManager.textSecondary,
        fontFamily: FontManager.getFontFamily(locale),
        fontWeight: FontManager.medium,
        fontSize: 14.sp,
      ),
      errorStyle: TextStyle(
        color: ColorManager.error,
        fontFamily: FontManager.getFontFamily(locale),
        fontWeight: FontManager.regular,
        fontSize: 12.sp,
      ),
    ),
    iconTheme: IconThemeData(color: ColorManager.primaryColor),
    dividerTheme: DividerThemeData(color: ColorManager.divider, thickness: 1),
  );
}
