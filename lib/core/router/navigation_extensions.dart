import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_logger.dart';
import 'route_names.dart';

const _navDebounce = Duration(milliseconds: 600);
DateTime? _lastPushAt;
String? _lastPushRoute;

extension SafeNavigation on BuildContext {
  void safeBack([String fallback = RouteNames.home]) {
    if (!mounted) return;
    if (canPop()) {
      pop();
    } else {
      AppLogger.nav('safeBack: nothing to pop, falling back to $fallback');
      go(fallback);
    }
  }

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
