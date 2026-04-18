import 'package:flutter/material.dart';

class SettingsController extends ChangeNotifier {
  bool _isDarkMode = false;
  String _language = "EN";

  bool get isDarkMode => _isDarkMode;
  String get language => _language;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }

  void reset() {
    _isDarkMode = false;
    _language = "EN";
    notifyListeners();
  }
}