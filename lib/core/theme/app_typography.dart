import 'package:flutter/material.dart';
import 'app_colors.dart';

// Every text style in Khaja Attariya comes from here.
// Never set fontSize, fontWeight, or color directly on a Text widget.
// Always use AppTypography.something — it keeps text consistent everywhere.

class AppTypography {

  // ── Display ───────────────────────────────────────────
  // Very large text. Used on:
  // → Splash screen app name
  // → Onboarding hero text
  // → Empty state large numbers
  static const TextStyle displayLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -1.0,
    height: 1.1,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  // ── Headings ──────────────────────────────────────────
  // Screen titles and section headers.
  // headingLarge  → screen title (e.g. "Nearby Restaurants")
  // headingMedium → section title (e.g. "Popular Items")
  // headingSmall  → card title, list item title
  static const TextStyle headingLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // ── Body ──────────────────────────────────────────────
  // Regular content text.
  // bodyLarge  → important descriptions, restaurant bio
  // bodyMedium → standard body text, menu item description
  // bodySmall  → secondary info, timestamps, meta data
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    height: 1.4,
  );

  // ── Labels ────────────────────────────────────────────
  // Short text on interactive elements.
  // labelLarge  → primary button text
  // labelMedium → secondary button, tab labels
  // labelSmall  → chips, badges, tags, status pills
  static const TextStyle labelLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    letterSpacing: 0.2,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
  );

  // ── Price ─────────────────────────────────────────────
  // Special styles for showing prices — used everywhere
  // on menu items, cart totals, order summaries.
  static const TextStyle priceLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 1.2,
  );

  static const TextStyle priceMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static const TextStyle priceSmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
}