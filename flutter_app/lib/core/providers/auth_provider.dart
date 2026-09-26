import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _userName;
  String? _userEmail;

  AuthProvider(this._prefs) {
    _isAuthenticated = _prefs.getBool('isAuthenticated') ?? false;
    _userName = _prefs.getString('userName');
    _userEmail = _prefs.getString('userEmail');
  }

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get userName => _userName;
  String? get userEmail => _userEmail;

  /// Display name for the profile header — derived from the email when
  /// the user never set a name.
  String get displayName {
    if (_userName != null && _userName!.isNotEmpty) return _userName!;
    if (_userEmail != null && _userEmail!.isNotEmpty) {
      final local = _userEmail!.split('@').first;
      if (local.isNotEmpty) {
        return local[0].toUpperCase() + local.substring(1);
      }
    }
    return 'Guest User';
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 1));
    // Demo authentication (the backend has no auth endpoints yet):
    // any valid email + 6-char password signs the user in locally.
    if (email.isNotEmpty && password.length >= 6) {
      _isAuthenticated = true;
      _userEmail = email.trim();
      await _prefs.setBool('isAuthenticated', true);
      await _prefs.setString('userEmail', _userEmail!);
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
      _userEmail = email.trim();
      await _prefs.setBool('isAuthenticated', true);
      await _prefs.setString('userEmail', _userEmail!);
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
