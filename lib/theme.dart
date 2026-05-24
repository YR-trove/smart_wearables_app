import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0A0E1A);
  static const card = Color(0xFF111827);
  static const cardBorder = Color(0xFF1E2A3A);
  static const cyan = Color(0xFF00C8FF);
  static const cyanDim = Color(0xFF0EA5E9);
  static const orange = Color(0xFFFF9500);
  static const yellow = Color(0xFFFFCC00);
  static const purple = Color(0xFF8B5CF6);
  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFEF4444);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8B9CC8);
  static const textMuted = Color(0xFF4B5563);
  static const divider = Color(0xFF1E2A3A);
}

ThemeData buildAppTheme() {
  return ThemeData.dark().copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.cyan,
      surface: AppColors.card,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0D1220),
      selectedItemColor: AppColors.cyan,
      unselectedItemColor: Color(0xFF4B5563),
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 10),
      elevation: 0,
    ),
  );
}
