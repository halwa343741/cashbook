import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleCubit extends Cubit<Locale> {
  static const String _prefLocaleKey = 'app_language_code';

  LocaleCubit() : super(const Locale('id')) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefLocaleKey) ?? 'id';
    emit(Locale(code));
  }

  Future<void> setLocale(String languageCode) async {
    if (state.languageCode == languageCode) return;
    emit(Locale(languageCode));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLocaleKey, languageCode);
  }
}
