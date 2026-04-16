import 'package:flutter/material.dart';

/// ===============================
/// 🌿 SETTINGS CONTROLLER (PRODUCTION STYLE)
/// ===============================
/// Manages:
/// - Theme (dark/light)
/// - Language (EN / AR)
/// ===============================
class SettingsController extends ChangeNotifier {
  bool _isDarkMode = false;
  String _language = "EN";

  /// GETTERS
  bool get isDarkMode => _isDarkMode;
  String get language => _language;

  /// ===============================
  /// 🌙 TOGGLE THEME
  /// ===============================
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  /// ===============================
  /// 🌍 SET LANGUAGE
  /// ===============================
  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }

  /// ===============================
  /// 🎯 OPTIONAL: RESET SETTINGS
  /// ===============================
  void reset() {
    _isDarkMode = false;
    _language = "EN";
    notifyListeners();
  }
}