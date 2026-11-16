import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Theme-aware colours.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brand,
    required this.onBrand,
    required this.brandSoft,
    required this.onBrandSoft,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.error,
    required this.errorSoft,
    required this.info,
    required this.infoSoft,
    required this.shadow,
  });

  final Color brand;
  final Color onBrand;
  final Color brandSoft;
  final Color onBrandSoft;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color error;
  final Color errorSoft;
  final Color info;
  final Color infoSoft;
  final Color shadow;

  static const light = AppPalette(
    brand: AppColors.pine,
    onBrand: AppColors.white,
    brandSoft: Color(0xFFE2F2EB),
    onBrandSoft: AppColors.pineDeep,
    accent: AppColors.marigold,
    onAccent: Color(0xFF2B1A00),
    accentSoft: Color(0xFFFEF0D6),
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceAlt: AppColors.lightSurfaceAlt,
    border: AppColors.lightBorder,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textHint: AppColors.lightTextHint,
    success: AppColors.success,
    successSoft: Color(0xFFDCFCE7),
    warning: AppColors.warning,
    warningSoft: Color(0xFFFEF3C7),
    error: AppColors.error,
    errorSoft: Color(0xFFFEE2E2),
    info: AppColors.info,
    infoSoft: Color(0xFFDBEAFE),
    shadow: Color(0x14101814),
  );

  static const dark = AppPalette(
    brand: AppColors.pineBright,
    onBrand: Color(0xFF04150E),
    brandSoft: Color(0xFF16332A),
    onBrandSoft: Color(0xFFA6EFD0),
    accent: AppColors.marigold,
    onAccent: Color(0xFF2B1A00),
    accentSoft: Color(0xFF3A2B12),
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceAlt: AppColors.darkSurfaceAlt,
    border: AppColors.darkBorder,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textHint: AppColors.darkTextHint,
    success: AppColors.successOnDark,
    successSoft: Color(0xFF12301F),
    warning: AppColors.warningOnDark,
    warningSoft: Color(0xFF3A2C0B),
    error: AppColors.errorOnDark,
    errorSoft: Color(0xFF3B1616),
    info: AppColors.infoOnDark,
    infoSoft: Color(0xFF14243F),
    shadow: Color(0x00000000),
  );

  @override
  AppPalette copyWith({Color? brand, Color? surface, Color? background}) =>
      AppPalette(
        brand: brand ?? this.brand,
        onBrand: onBrand,
        brandSoft: brandSoft,
        onBrandSoft: onBrandSoft,
        accent: accent,
        onAccent: onAccent,
        accentSoft: accentSoft,
        background: background ?? this.background,
        surface: surface ?? this.surface,
        surfaceAlt: surfaceAlt,
        border: border,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        textHint: textHint,
        success: success,
        successSoft: successSoft,
        warning: warning,
        warningSoft: warningSoft,
        error: error,
        errorSoft: errorSoft,
        info: info,
        infoSoft: infoSoft,
        shadow: shadow,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      brand: l(brand, other.brand),
      onBrand: l(onBrand, other.onBrand),
      brandSoft: l(brandSoft, other.brandSoft),
      onBrandSoft: l(onBrandSoft, other.onBrandSoft),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      accentSoft: l(accentSoft, other.accentSoft),
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      border: l(border, other.border),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textHint: l(textHint, other.textHint),
      success: l(success, other.success),
      successSoft: l(successSoft, other.successSoft),
      warning: l(warning, other.warning),
      warningSoft: l(warningSoft, other.warningSoft),
      error: l(error, other.error),
      errorSoft: l(errorSoft, other.errorSoft),
      info: l(info, other.info),
      infoSoft: l(infoSoft, other.infoSoft),
      shadow: l(shadow, other.shadow),
    );
  }
}

extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
