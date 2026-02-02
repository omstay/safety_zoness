import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!['en', 'ta'].contains(locale.languageCode)) return;
    _locale = locale;
    notifyListeners(); // 🔥 This triggers MaterialApp to rebuild with new locale
  }
}
