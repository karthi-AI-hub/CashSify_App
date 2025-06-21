import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'app_theme.dart';

final themeProviderProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

class ThemeState {
  final ThemeMode themeMode;
  final bool isDarkMode;

  ThemeState({
    required this.themeMode,
    required this.isDarkMode,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    bool? isDarkMode,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  static const _themeKey = 'theme_mode';
  late SharedPreferences _prefs;

  ThemeNotifier() : super(ThemeState(
    
    themeMode: ThemeMode.light,
    isDarkMode: false,
  )) {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await _prefs.setString(_themeKey, ThemeMode.light.toString());
    state = state.copyWith(
      themeMode: ThemeMode.light,
      isDarkMode: false,
    );
  }

  ThemeMode get themeMode => ThemeMode.light;
  bool get isDarkMode => false;

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeKey, ThemeMode.light.toString());
    state = state.copyWith(
      themeMode: ThemeMode.light,
      isDarkMode: false,
    );
  }

  void toggleTheme() {
    setThemeMode(ThemeMode.light);
  }

  ThemeData get theme => AppTheme.lightTheme;
} 