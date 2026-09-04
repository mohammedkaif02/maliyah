import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maliyah/data/services/storage_service.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final StorageService _storage;
  ThemeCubit(this._storage) : super(ThemeMode.light) {
    _loadTheme();
  }

  bool get isDark => state == ThemeMode.dark;
  void _loadTheme() {
    final saved = _storage.loadThemeMode();
    if (saved == 'dark') emit(ThemeMode.dark);
  }

  void toggle() {
    final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
    emit(newMode);
    _storage.saveThemeMode(newMode == ThemeMode.dark ? 'dark' : 'light');
  }
}
