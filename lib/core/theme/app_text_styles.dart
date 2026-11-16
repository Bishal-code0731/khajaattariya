import 'package:flutter/material.dart';
import 'app_palette.dart';
import 'app_typography.dart';

/// Ready-coloured text styles for the current theme: `Text('Hi', style: context.text.secondary)`.
class AppTextStyles {
  const AppTextStyles(this._p);
  final AppPalette _p;

  TextStyle get display =>
      AppTypography.displayMedium.copyWith(color: _p.textPrimary);
  TextStyle get h1 =>
      AppTypography.headingLarge.copyWith(color: _p.textPrimary);
  TextStyle get h2 =>
      AppTypography.headingMedium.copyWith(color: _p.textPrimary);
  TextStyle get h3 =>
      AppTypography.headingSmall.copyWith(color: _p.textPrimary);
  TextStyle get body =>
      AppTypography.bodyMedium.copyWith(color: _p.textPrimary);
  TextStyle get bodyLarge =>
      AppTypography.bodyLarge.copyWith(color: _p.textPrimary);
  TextStyle get secondary =>
      AppTypography.bodyMedium.copyWith(color: _p.textSecondary);
  TextStyle get caption =>
      AppTypography.bodySmall.copyWith(color: _p.textSecondary);
  TextStyle get hint => AppTypography.bodySmall.copyWith(color: _p.textHint);
  TextStyle get label =>
      AppTypography.labelMedium.copyWith(color: _p.textPrimary);
  TextStyle get labelSecondary =>
      AppTypography.labelMedium.copyWith(color: _p.textSecondary);
  TextStyle get overline =>
      AppTypography.labelSmall.copyWith(color: _p.textSecondary);
  TextStyle get price =>
      AppTypography.priceMedium.copyWith(color: _p.textPrimary);
  TextStyle get priceLarge =>
      AppTypography.priceLarge.copyWith(color: _p.textPrimary);
  TextStyle get link => AppTypography.labelMedium.copyWith(color: _p.brand);
}

extension AppTextStylesX on BuildContext {
  AppTextStyles get text => AppTextStyles(palette);
}
