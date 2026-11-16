import 'package:flutter/material.dart';

/// Type scale (Mukta — Latin + Devanagari).
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Mukta';

  // Display / headings
  static const TextStyle displayLarge = TextStyle(
      fontFamily: fontFamily,
      fontSize: 34,
      fontWeight: FontWeight.w800,
      height: 1.15,
      letterSpacing: -0.6);
  static const TextStyle displayMedium = TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w800,
      height: 1.2,
      letterSpacing: -0.4);
  static const TextStyle headingLarge = TextStyle(
      fontFamily: fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 1.3,
      letterSpacing: -0.2);
  static const TextStyle headingMedium = TextStyle(
      fontFamily: fontFamily,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      height: 1.3);
  static const TextStyle headingSmall = TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.35);

  // Body
  static const TextStyle bodyLarge = TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5);
  static const TextStyle bodyMedium = TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5);
  static const TextStyle bodySmall = TextStyle(
      fontFamily: fontFamily,
      fontSize: 12.5,
      fontWeight: FontWeight.w400,
      height: 1.45);

  // Labels (buttons, tabs, chips, form labels)
  static const TextStyle labelLarge = TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.3);
  static const TextStyle labelMedium = TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.3);
  static const TextStyle labelSmall = TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: 0.2);

  // Money
  static const TextStyle priceLarge = TextStyle(
      fontFamily: fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w800,
      height: 1.2,
      fontFeatures: [FontFeature.tabularFigures()]);
  static const TextStyle priceMedium = TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      height: 1.25,
      fontFeatures: [FontFeature.tabularFigures()]);
  static const TextStyle priceSmall = TextStyle(
      fontFamily: fontFamily,
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      height: 1.25,
      fontFeatures: [FontFeature.tabularFigures()]);

  static const TextStyle bodyMediumDark = bodyMedium;
  static const TextStyle bodySmallDark = bodySmall;

  /// Material TextTheme built from this scale (used by AppTheme).
  static TextTheme textTheme(Color primary, Color secondary) => TextTheme(
        displayLarge: displayLarge.copyWith(color: primary),
        displayMedium: displayMedium.copyWith(color: primary),
        displaySmall: headingLarge.copyWith(color: primary),
        headlineLarge: displayMedium.copyWith(color: primary),
        headlineMedium: headingLarge.copyWith(color: primary),
        headlineSmall: headingMedium.copyWith(color: primary),
        titleLarge: headingMedium.copyWith(color: primary),
        titleMedium: headingSmall.copyWith(color: primary),
        titleSmall: labelMedium.copyWith(color: primary),
        bodyLarge: bodyLarge.copyWith(color: primary),
        bodyMedium: bodyMedium.copyWith(color: primary),
        bodySmall: bodySmall.copyWith(color: secondary),
        labelLarge: labelLarge.copyWith(color: primary),
        labelMedium: labelMedium.copyWith(color: primary),
        labelSmall: labelSmall.copyWith(color: secondary),
      );
}
