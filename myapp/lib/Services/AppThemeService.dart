import 'package:flutter/material.dart';

class AppThemeService {
  AppThemeService._();

  static final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(false);

  static void setDarkMode(bool value) {
    if (isDarkMode.value != value) {
      isDarkMode.value = value;
    }
  }
}
