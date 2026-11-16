import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum AppButtonVariant {
  /// Brand-filled — the one main action in an area.
  primary,

  /// Soft brand tint — secondary actions.
  tonal,

  /// Bordered — neutral alternatives ("Cancel", "Edit").
  outline,

  /// Text only — low emphasis.
  text,

  /// Red — destructive actions ("Delete", "Reject").
  danger,
}

enum AppButtonSize { small, medium, large }

/// The button used everywhere.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.leadingIcon,
    this.trailingIcon,
    this.expand = true,
    // Legacy parameters (old screens).
    bool isOutlined = false,
    this.color,
    this.textColor,
  }) : _legacyOutlined = isOutlined;

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  /// Fill the available width (default).
  final bool expand;
  final Color? color;
  final Color? textColor;
  final bool _legacyOutlined;

  AppButtonVariant get _variant =>
      _legacyOutlined ? AppButtonVariant.outline : variant;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null && !isLoading;

    final (Color bg, Color fg, BorderSide? side) = switch (_variant) {
      AppButtonVariant.primary => (
          color ?? p.brand,
          textColor ?? p.onBrand,
          null
        ),
      AppButtonVariant.tonal => (p.brandSoft, textColor ?? p.onBrandSoft, null),
      AppButtonVariant.outline => (
          Colors.transparent,
          textColor ?? color ?? p.textPrimary,
          BorderSide(color: color ?? p.border, width: 1.2)
        ),
      AppButtonVariant.text => (
          Colors.transparent,
          textColor ?? color ?? p.brand,
          null
        ),
      AppButtonVariant.danger => (
          p.error,
          context.isDark ? Colors.black : Colors.white,
          null
        ),
    };

    final height = switch (size) {
      AppButtonSize.small => 38.0,
      AppButtonSize.medium => 46.0,
      AppButtonSize.large => 52.0,
    };
    final textStyle = size == AppButtonSize.small
        ? AppTypography.labelMedium
        : AppTypography.labelLarge;
    final hPad = size == AppButtonSize.small ? AppSpacing.md : AppSpacing.xl;

    final child = AnimatedSwitcher(
      duration: AppMotion.fast,
      child: isLoading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon,
                      size: size == AppButtonSize.small ? 18 : 20),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(trailingIcon,
                      size: size == AppButtonSize.small ? 18 : 20),
                ],
              ],
            ),
    );

    final button = TextButton(
      onPressed: enabled ? onPressed : null,
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(height, height)),
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: hPad)),
        textStyle: WidgetStatePropertyAll(textStyle),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        ),
        side: WidgetStatePropertyAll(side),
        backgroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled) && !isLoading) {
            return bg == Colors.transparent ? Colors.transparent : p.surfaceAlt;
          }
          return bg;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled) && !isLoading) return p.textHint;
          return fg;
        }),
        overlayColor: WidgetStatePropertyAll(fg.withValues(alpha: 0.08)),
      ),
      child: child,
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: isLoading ? '$label…' : null,
      child: SizedBox(
        width: expand ? double.infinity : null,
        height: height,
        child: button,
      ),
    );
  }
}
