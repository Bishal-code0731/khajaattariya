import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  // ── Display ───────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontSize: 36, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, letterSpacing: -1.0, height: 1.1,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.5, height: 1.2,
  );

  // ── Headings ──────────────────────────────────────────
  static const TextStyle headingLarge = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.3, height: 1.3,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.3,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.4,
  );

  // ── Body ──────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textHint, height: 1.5,
  );

  // Dark-mode counterparts for the two body styles that are used
  // inline across list/card content without a per-call-site color
  // override. Screens that already branch on `Theme.of(context).
  // brightness` (see app_text_field.dart) should prefer these over
  // manually copying AppColors.white/darkTextSecondary in per dark
  // mode, keeping that branching logic in one place.
  static const TextStyle bodyMediumDark = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.darkTextSecondary, height: 1.5,
  );

  static const TextStyle bodySmallDark = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.darkTextHint, height: 1.5,
  );

  // ── Labels ────────────────────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, letterSpacing: 0.2,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, letterSpacing: 0.1,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary, letterSpacing: 0.2,
  );

  // ── Price ─────────────────────────────────────────────
  static const TextStyle priceLarge = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, letterSpacing: -0.3,
  );

  static const TextStyle priceMedium = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.2,
  );

  static const TextStyle priceSmall = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}
