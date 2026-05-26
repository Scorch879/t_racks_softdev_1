import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeController extends ChangeNotifier {
  AppThemeController._();

  static final AppThemeController instance = AppThemeController._();
  static const _darkModeKey = 'is_dark_mode';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setDarkMode(bool isDarkMode) async {
    final nextMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    if (_themeMode == nextMode) return;

    _themeMode = nextMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, isDarkMode);
  }
}

ThemeData buildLightTheme() {
  const seedColor = Color(0xFF167C94);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
    ),
  );
}

ThemeData buildDarkTheme() {
  const seedColor = Color(0xFF93C0D3);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF071E29),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0C3343),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}
