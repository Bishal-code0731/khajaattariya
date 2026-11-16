import 'package:flutter/material.dart';

/// Spacing (4-pt grid), radii and layout constants.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  static const double screenHorizontal = 16;
  static const double maxContentWidth = 1200; // dashboards on web
  static const double maxFormWidth = 480; // auth / forms on wide screens
  static const double minTouchTarget = 48;

  static const double radiusXs = 6;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  // Fixed media sizes
  static const double menuItemImageSize = 96;
  static const double restaurantCardImageAspect = 16 / 9;
  static const double categoryIconSize = 64;
  static const double restaurantCardHeight = 200; // legacy
}

/// Soft, low shadows (light mode only — dark mode separates with borders).
class AppShadows {
  AppShadows._();

  static List<BoxShadow> card(Color shadow) => [
        BoxShadow(color: shadow, blurRadius: 16, offset: const Offset(0, 4)),
      ];

  static List<BoxShadow> raised(Color shadow) => [
        BoxShadow(color: shadow, blurRadius: 24, offset: const Offset(0, 8)),
      ];
}

/// Durations for restrained motion.
class AppMotion {
  AppMotion._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Curve curve = Curves.easeOutCubic;
}
