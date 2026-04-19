import 'package:flutter/material.dart';

class SettingsController extends ChangeNotifier {
  bool _isDarkMode = false;

  // 🌍 Locale instead of String
  Locale _locale = const Locale('en');

  bool get isDarkMode => _isDarkMode;
  Locale get locale => _locale;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // 🌍 Change language properly
  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  void reset() {
    _isDarkMode = false;
    _locale = const Locale('en');
    notifyListeners();
  }
}