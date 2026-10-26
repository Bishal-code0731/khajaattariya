import 'package:flutter/material.dart';
import '../../core/l10n/s.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'app_button.dart';

/// Confirmation dialogs ("Clear cart?", "Delete item?", "Log out?").
class AppDialog {
  AppDialog._();

  /// Returns true when the user confirms.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    String? message,
    String? confirmLabel,
    String? cancelLabel,
    bool destructive = false,
    IconData? icon,
  }) async {
    final c = context.s.common;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final p = ctx.palette;
        return Dialog(
          insetPadding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: destructive ? p.errorSoft : p.brandSoft,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(icon,
                          color: destructive ? p.error : p.onBrandSoft),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  Text(title,
                      style: AppTypography.headingMedium
                          .copyWith(color: p.textPrimary)),
                  if (message != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(message,
                        style: AppTypography.bodyMedium
                            .copyWith(color: p.textSecondary)),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: cancelLabel ?? c.cancel,
                          variant: AppButtonVariant.outline,
                          size: AppButtonSize.medium,
                          onPressed: () => Navigator.of(ctx).pop(false),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppButton(
                          label: confirmLabel ?? c.confirm,
                          variant: destructive
                              ? AppButtonVariant.danger
                              : AppButtonVariant.primary,
                          size: AppButtonSize.medium,
                          onPressed: () => Navigator.of(ctx).pop(true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return result ?? false;
  }
}
