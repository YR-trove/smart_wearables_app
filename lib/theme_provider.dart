import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // Default to System theme and Blue accent
  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor = const Color(0xFF3B82F6); 

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;

  // Map ThemeMode to your UI Segmented Control index (0=Light, 1=Dark, 2=Auto)
  int get themeIndex {
    if (_themeMode == ThemeMode.light) return 0;
    if (_themeMode == ThemeMode.dark) return 1;
    return 2;
  }

  void setThemeMode(int index) {
    if (index == 0) {
      _themeMode = ThemeMode.light;
    } else if (index == 1) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  void setAccentColor(Color color) {
    _accentColor = color;
    notifyListeners();
  }
}