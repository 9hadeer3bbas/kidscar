import 'package:flutter/material.dart';

class ColorManager {
  // Gradients
  static const List<Color> signUpGradient = [
    Color(0xFFACE6FF),
    Color(0xFF67C4EB),
    Color(0xFF1C70A6),
  ];
  // Primary and Secondary
  static const Color primaryColor = Color(0xFF67C4EB); // Primary brand color
  static const Color primaryLight = Color(0xFF6EC6FF);
  static const Color primaryDark = Color(0xFF0069C0);
  static const Color secondaryColor = Color(
    0xFFFFC107,
  ); // Secondary brand color
  static const Color secondaryLight = Color(0xFFFFF350);
  static const Color secondaryDark = Color(0xFFC79100);

  // Backgrounds
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color scaffoldBackground = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);

  // Accents & States
  static const Color accent = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color success = Color(0xFF43A047);
  static const Color info = Color(0xFF29B6F6);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color divider = Color(0xFFBDBDBD);

  static const Color colorToast = Color(0xFFFFFFFF);
}
