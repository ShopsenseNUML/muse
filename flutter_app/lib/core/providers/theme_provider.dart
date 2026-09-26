import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  ThemeMode _themeMode;

  ThemeProvider(this._prefs) : _themeMode = ThemeMode.light {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  void _loadTheme() {
    final isDark = _prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    notifyListeners();
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;
}
