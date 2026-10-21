import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_palette.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _build(AppPalette.light, Brightness.light);
  static ThemeData get darkTheme => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.brand,
      onPrimary: p.onBrand,
      primaryContainer: p.brandSoft,
      onPrimaryContainer: p.onBrandSoft,
      secondary: p.accent,
      onSecondary: p.onAccent,
      secondaryContainer: p.accentSoft,
      onSecondaryContainer:
          isDark ? AppColors.marigold : AppColors.marigoldDeep,
      tertiary: p.info,
      onTertiary: AppColors.white,
      error: p.error,
      onError: isDark ? AppColors.black : AppColors.white,
      errorContainer: p.errorSoft,
      onErrorContainer: p.error,
      surface: p.surface,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      surfaceContainerLowest: p.surface,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surfaceAlt,
      surfaceContainerHigh: p.surfaceAlt,
      surfaceContainerHighest: p.surfaceAlt,
      outline: p.border,
      outlineVariant: p.border,
      shadow: AppColors.black,
      scrim: AppColors.scrim,
      inverseSurface:
          isDark ? AppColors.lightSurface : AppColors.lightTextPrimary,
      onInverseSurface:
          isDark ? AppColors.lightTextPrimary : AppColors.lightSurface,
      inversePrimary: isDark ? AppColors.pine : AppColors.pineBright,
    );

    final textTheme = AppTypography.textTheme(p.textPrimary, p.textSecondary);
    final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd));
    OutlineInputBorder inputBorder(Color c, [double w = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTypography.fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      extensions: [p],
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      dividerColor: p.border,
      iconTheme: IconThemeData(color: p.textPrimary, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: p.border,
        centerTitle: false,
        titleSpacing: AppSpacing.lg,
        titleTextStyle:
            AppTypography.headingMedium.copyWith(color: p.textPrimary),
        iconTheme: IconThemeData(color: p.textPrimary),
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: p.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.brand,
          foregroundColor: p.onBrand,
          disabledBackgroundColor: p.surfaceAlt,
          disabledForegroundColor: p.textHint,
          elevation: 0,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          shape: shape,
          textStyle: AppTypography.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.brand,
          foregroundColor: p.onBrand,
          disabledBackgroundColor: p.surfaceAlt,
          disabledForegroundColor: p.textHint,
          minimumSize: const Size(64, 52),
          shape: shape,
          textStyle: AppTypography.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          minimumSize: const Size(64, 52),
          side: BorderSide(color: p.border, width: 1.2),
          shape: shape,
          textStyle: AppTypography.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.brand,
          minimumSize: const Size(48, 44),
          textStyle: AppTypography.labelMedium,
          shape: shape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: p.textPrimary,
          minimumSize: const Size(44, 44),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        hintStyle: AppTypography.bodyMedium.copyWith(color: p.textHint),
        labelStyle: AppTypography.bodyMedium.copyWith(color: p.textSecondary),
        floatingLabelStyle: AppTypography.labelMedium.copyWith(color: p.brand),
        helperStyle: AppTypography.bodySmall.copyWith(color: p.textSecondary),
        errorStyle: AppTypography.bodySmall.copyWith(color: p.error),
        prefixIconColor: p.textSecondary,
        suffixIconColor: p.textSecondary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 15),
        border: inputBorder(p.border),
        enabledBorder: inputBorder(p.border),
        disabledBorder: inputBorder(p.border.withValues(alpha: 0.5)),
        focusedBorder: inputBorder(p.brand, 1.6),
        errorBorder: inputBorder(p.error),
        focusedErrorBorder: inputBorder(p.error, 1.6),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.brandSoft,
        disabledColor: p.surfaceAlt,
        side: BorderSide(color: p.border),
        labelStyle: AppTypography.labelMedium.copyWith(color: p.textPrimary),
        secondaryLabelStyle:
            AppTypography.labelMedium.copyWith(color: p.onBrandSoft),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull)),
        checkmarkColor: p.onBrandSoft,
        showCheckmark: false,
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        textColor: p.textPrimary,
        titleTextStyle: AppTypography.labelLarge.copyWith(color: p.textPrimary),
        subtitleTextStyle:
            AppTypography.bodySmall.copyWith(color: p.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        minVerticalPadding: AppSpacing.sm,
        shape: shape,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.brandSoft,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected)
                  ? p.onBrandSoft
                  : p.textSecondary,
              size: 24,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith(
            (s) => AppTypography.labelSmall.copyWith(
                  color: s.contains(WidgetState.selected)
                      ? p.textPrimary
                      : p.textSecondary,
                )),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.brandSoft,
        selectedIconTheme: IconThemeData(color: p.onBrandSoft),
        unselectedIconTheme: IconThemeData(color: p.textSecondary),
        selectedLabelTextStyle:
            AppTypography.labelSmall.copyWith(color: p.textPrimary),
        unselectedLabelTextStyle:
            AppTypography.labelSmall.copyWith(color: p.textSecondary),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.textPrimary,
        unselectedLabelColor: p.textSecondary,
        labelStyle: AppTypography.labelMedium,
        unselectedLabelStyle: AppTypography.labelMedium,
        indicatorColor: p.brand,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: p.border,
        overlayColor:
            WidgetStatePropertyAll(p.brandSoft.withValues(alpha: 0.4)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        titleTextStyle:
            AppTypography.headingMedium.copyWith(color: p.textPrimary),
        contentTextStyle:
            AppTypography.bodyMedium.copyWith(color: p.textSecondary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.surface,
        showDragHandle: true,
        dragHandleColor: p.border,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? AppColors.darkSurfaceAlt : AppColors.lightTextPrimary,
        contentTextStyle:
            AppTypography.bodyMedium.copyWith(color: AppColors.white),
        actionTextColor: AppColors.marigold,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.brand,
        linearTrackColor: p.surfaceAlt,
        circularTrackColor: Colors.transparent,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? p.brand : Colors.transparent),
        checkColor: WidgetStatePropertyAll(p.onBrand),
        side: BorderSide(color: p.textHint, width: 1.5),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.brand : p.textHint),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.onBrand : p.textHint),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.brand : p.surfaceAlt),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.transparent : p.border),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? p.brandSoft : p.surface),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? p.onBrandSoft : p.textPrimary),
          side: WidgetStatePropertyAll(BorderSide(color: p.border)),
          textStyle: const WidgetStatePropertyAll(AppTypography.labelMedium),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.brand,
        foregroundColor: p.onBrand,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightTextPrimary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        textStyle: AppTypography.bodySmall.copyWith(color: AppColors.white),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: p.border),
        ),
        textStyle: AppTypography.bodyMedium.copyWith(color: p.textPrimary),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: p.brand,
        headerForegroundColor: p.onBrand,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: p.surface,
        dialHandColor: p.brand,
        hourMinuteColor: p.surfaceAlt,
      ),
      badgeTheme:
          BadgeThemeData(backgroundColor: p.accent, textColor: p.onAccent),
    );
  }
}
