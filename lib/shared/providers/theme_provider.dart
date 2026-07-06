import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

enum AppThemeMode { light, dark, system }

@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  @override
  AppThemeMode build() => AppThemeMode.light; // light as default, not system

  void setTheme(AppThemeMode mode) {
    state = mode;
  }
}

extension AppThemeModeX on AppThemeMode {
  ThemeMode get flutterThemeMode {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}