import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_language.g.dart';

enum AppLanguage {
  en('EN', 'English'),
  ne('ने', 'नेपाली');

  const AppLanguage(this.shortLabel, this.nativeName);
  final String shortLabel;
  final String nativeName;

  Locale get locale => Locale(name);
}

/// The app language (D-12).
@Riverpod(keepAlive: true)
class LanguageNotifier extends _$LanguageNotifier {
  static const _prefsKey = 'app_language';

  @override
  AppLanguage build() {
    _restore();
    return AppLanguage.en;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == AppLanguage.ne.name) state = AppLanguage.ne;
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language.name);
  }

  Future<void> toggle() =>
      setLanguage(state == AppLanguage.en ? AppLanguage.ne : AppLanguage.en);
}
