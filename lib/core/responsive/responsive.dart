import 'package:flutter/material.dart';

/// Breakpoints and helpers used across the app instead of ad-hoc
/// hardcoded pixel widths/heights per screen. Values follow Material's
/// window-size classes (compact/medium/expanded), which comfortably
/// cover phones, foldables (unfolded ~600-900dp), tablets, and desktop.
class Responsive {
  Responsive._();

  static const double tabletBreakpoint = 600;
  static const double desktopBreakpoint = 1000;

  static bool isPhone(BuildContext context) => _width(context) < tabletBreakpoint;
  static bool isTablet(BuildContext context) =>
      _width(context) >= tabletBreakpoint && _width(context) < desktopBreakpoint;
  static bool isDesktop(BuildContext context) => _width(context) >= desktopBreakpoint;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  static double _width(BuildContext context) => MediaQuery.of(context).size.width;

  /// Picks a value based on the current width bucket. Falls back down
  /// the chain (desktop -> tablet -> phone) so callers only need to
  /// override the sizes that actually differ.
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

  /// How many columns a card grid should use at the current width —
  /// used by any screen that switches from a single-column list (phone)
  /// to a grid (tablet/desktop/landscape) instead of stretching cards
  /// edge-to-edge on wide screens.
  static int gridColumns(BuildContext context) {
    final width = _width(context);
    if (width >= 1400) return 4;
    if (width >= desktopBreakpoint) return 3;
    if (width >= tabletBreakpoint) return 2;
    return 1;
  }

  /// Horizontal screen padding that grows slightly on wider screens so
  /// content doesn't look pinned to the edges of a tablet/desktop window.
  static double screenHorizontalPadding(BuildContext context) =>
      value(context, phone: 16, tablet: 24, desktop: 32);

  /// Caps content width on very wide screens (desktop) so text/cards
  /// don't stretch into unreadably long lines — centers the constrained
  /// content instead.
  static Widget centeredMaxWidth(BuildContext context, Widget child, {double maxWidth = 1100}) {
    if (!isDesktop(context)) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Clamps the system/user font-scale factor so accessibility "large
/// text" settings don't blow up fixed-height cards into overflow, while
/// still allowing real scaling (unlike disabling it outright).
extension ClampedTextScaling on MediaQueryData {
  MediaQueryData withClampedTextScale({double min = 0.85, double max = 1.25}) {
    return copyWith(textScaler: textScaler.clamp(minScaleFactor: min, maxScaleFactor: max));
  }
}
