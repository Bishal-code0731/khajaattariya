import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_logger.dart';
import 'route_names.dart';

/// Debounce window used by [SafeNavigation.pushOnce] to collapse rapid
/// duplicate taps (double-tap on a card, impatient repeated taps on a
/// slow-loading button) into a single navigation.
const _navDebounce = Duration(milliseconds: 600);
DateTime? _lastPushAt;
String? _lastPushRoute;

extension SafeNavigation on BuildContext {
  /// Pops the current route if there's something to pop back to;
  /// otherwise falls back to [fallback] (defaults to Home). Use this
  /// instead of `context.pop()`/`context.go(RouteNames.home)` for any
  /// "back" affordance, since a screen reached via `go()` (stack
  /// replaced) has nothing to pop and a bare `pop()` would either do
  /// nothing or let the system close the app.
  void safeBack([String fallback = RouteNames.home]) {
    if (!mounted) return;
    if (canPop()) {
      pop();
    } else {
      AppLogger.nav('safeBack: nothing to pop, falling back to $fallback');
      go(fallback);
    }
  }

  /// Same as `push`, but ignores a second call for the same route fired
  /// within [_navDebounce] of the first — guards against double
  /// navigation from double-taps on cards/buttons that don't otherwise
  /// disable themselves while the transition is in flight.
  void pushOnce(String route, {Object? extra}) {
    final now = DateTime.now();
    if (_lastPushRoute == route &&
        _lastPushAt != null &&
        now.difference(_lastPushAt!) < _navDebounce) {
      AppLogger.nav('pushOnce: ignored duplicate push to $route');
      return;
    }
    _lastPushAt = now;
    _lastPushRoute = route;
    push(route, extra: extra);
  }
}