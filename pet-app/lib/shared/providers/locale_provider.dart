import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('locale') ?? 'en';
    state = Locale(code);
  }

  Future<void> setLocale(String code) async {
    state = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', code);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

const supportedLocales = [
  Locale('en', 'US'),
  Locale('es', 'ES'),
  Locale('fr', 'FR'),
  Locale('de', 'DE'),
  Locale('pt', 'BR'),
  Locale('zh', 'CN'),
  Locale('ar', 'SA'),
];

const localeNames = {
  'en': 'English',
  'es': 'Español',
  'fr': 'Français',
  'de': 'Deutsch',
  'pt': 'Português',
  'zh': '中文',
  'ar': 'العربية',
};
