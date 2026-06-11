import 'package:flutter/material.dart';

class AppCurrencyService {
  AppCurrencyService._();

  static const usdRate = 18000;
  static final ValueNotifier<String> currency = ValueNotifier<String>("IDR");

  static void setCurrency(String value) {
    final normalized = value.toUpperCase() == "USD" ? "USD" : "IDR";
    if (currency.value != normalized) {
      currency.value = normalized;
    }
  }
}
