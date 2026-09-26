import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  AuthProvider(this._prefs) {
    _isAuthenticated = _prefs.getBool('isAuthenticated') ?? false;
  }

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 1));
    // Simulate authentication
    if (email.isNotEmpty && password.length >= 6) {
      _isAuthenticated = true;
      await _prefs.setBool('isAuthenticated', true);
      _setLoading(false);
      return true;
    }
    _setLoading(false);
    return false;
  }

  Future<bool> signup(String email, String password) async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 1));
    if (email.isNotEmpty && password.length >= 6) {
      _isAuthenticated = true;
      await _prefs.setBool('isAuthenticated', true);
      _setLoading(false);
      return true;
    }
    _setLoading(false);
    return false;
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    await _prefs.setBool('isAuthenticated', false);
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
