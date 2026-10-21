import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  static const double tabletBreakpoint = 600;
  static const double desktopBreakpoint = 1000;

  static bool isPhone(BuildContext context) =>
      _width(context) < tabletBreakpoint;
  static bool isTablet(BuildContext context) =>
      _width(context) >= tabletBreakpoint &&
      _width(context) < desktopBreakpoint;
  static bool isDesktop(BuildContext context) =>
      _width(context) >= desktopBreakpoint;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  static double _width(BuildContext context) =>
      MediaQuery.of(context).size.width;

  /// Picks a value based on the current width bucket.
  static T value<T>(
    BuildContext context, {
    required T phone,
    T? tablet,
    T? desktop,
  }) {
    final width = _width(context);
    if (width >= desktopBreakpoint) return desktop ?? tablet ?? phone;
    if (width >= tabletBreakpoint) return tablet ?? phone;
    return phone;
  }

  static int gridColumns(BuildContext context) {
    final width = _width(context);
    if (width >= 1400) return 4;
    if (width >= desktopBreakpoint) return 3;
    if (width >= tabletBreakpoint) return 2;
    return 1;
  }

  static double screenHorizontalPadding(BuildContext context) =>
      value(context, phone: 16, tablet: 24, desktop: 32);

  static Widget centeredMaxWidth(BuildContext context, Widget child,
      {double maxWidth = 1100}) {
    if (!isDesktop(context)) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

extension ClampedTextScaling on MediaQueryData {
  MediaQueryData withClampedTextScale({double min = 0.85, double max = 1.25}) {
    return copyWith(
        textScaler: textScaler.clamp(minScaleFactor: min, maxScaleFactor: max));
  }
}
