import 'package:flutter/material.dart';
import '../../core/errors/user_message.dart';
import '../../core/l10n/s.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'app_button.dart';

/// Load failed.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.message,
    this.error,
    this.onRetry,
    this.icon = Icons.cloud_off_rounded,
  });

  final String? message;
  final Object? error;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = context.s.common;
    final text =
        message ?? (error != null ? userMessage(context, error) : c.errGeneric);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration:
                    BoxDecoration(color: p.errorSoft, shape: BoxShape.circle),
                child: Icon(icon, size: 34, color: p.error),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(c.errorTitle,
                  style: AppTypography.headingMedium
                      .copyWith(color: p.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              Text(text,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium
                      .copyWith(color: p.textSecondary)),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: c.retry,
                  onPressed: onRetry,
                  variant: AppButtonVariant.outline,
                  leadingIcon: Icons.refresh_rounded,
                  expand: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
