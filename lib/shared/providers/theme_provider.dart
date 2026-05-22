import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

enum AppThemeMode { light, dark, system }

@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  @override
  AppThemeMode build() => AppThemeMode.system; // system as default

  void setTheme(AppThemeMode mode) {
    state = mode;
  }

  ThemeMode get flutterThemeMode {
    if (state == AppThemeMode.light) return ThemeMode.light;
    if (state == AppThemeMode.dark) return ThemeMode.dark;
    return ThemeMode.system;
  }
}