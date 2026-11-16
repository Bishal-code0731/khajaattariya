import 'package:flutter/foundation.dart';

/// Minimal structured logger.
class AppLogger {
  AppLogger._();

  static void nav(String message) => _emit('NAV', message);

  static void info(String tag, String message) => _emit(tag, message);

  static void warning(String tag, String message) =>
      _emit(tag, message, isWarning: true);

  static void error(String tag, Object error, [StackTrace? stackTrace]) {
    _emit(tag, error.toString(), isWarning: true);
    if (stackTrace != null && kDebugMode) {
      debugPrint(stackTrace.toString());
    }
  }

  static void _emit(String tag, String message, {bool isWarning = false}) {
    if (!kDebugMode) return;
    final prefix = isWarning ? '⚠️' : 'ℹ️';
    debugPrint('$prefix [$tag] ${DateTime.now().toIso8601String()} — $message');
  }
}
