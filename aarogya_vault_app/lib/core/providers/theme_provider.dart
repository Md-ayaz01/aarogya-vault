import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/local_db.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  void _loadTheme() {
    final isDark = LocalDB.get('pref_dark_mode', defaultValue: null);
    if (isDark == null) {
      state = ThemeMode.system;
    } else {
      state = isDark == true ? ThemeMode.dark : ThemeMode.light;
    }
  }

  void toggleTheme(bool isDark) {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    LocalDB.save('pref_dark_mode', isDark);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
