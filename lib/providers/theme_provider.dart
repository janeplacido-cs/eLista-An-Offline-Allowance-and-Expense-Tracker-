import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _darkModeKey = 'dark_mode_enabled';

  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> loadTheme() async {
    final preferences = await SharedPreferences.getInstance();
    _isDarkMode = preferences.getBool(_darkModeKey) ?? false;
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(_darkModeKey, enabled);
    if (!saved) {
      throw StateError('Unable to save the theme preference.');
    }

    _isDarkMode = enabled;
    notifyListeners();
  }
}
