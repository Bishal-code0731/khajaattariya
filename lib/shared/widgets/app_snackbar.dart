import 'package:flutter/material.dart';
import '../../core/errors/user_message.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum _ToastKind { success, error, info, warning }

/// Short, friendly feedback after an action.
class AppSnackbar {
  AppSnackbar._();

  static void success(BuildContext context, String message) =>
      _show(context, message, _ToastKind.success);
  static void info(BuildContext context, String message) =>
      _show(context, message, _ToastKind.info);
  static void warning(BuildContext context, String message) =>
      _show(context, message, _ToastKind.warning);
  static void error(BuildContext context, Object? error) =>
      _show(context, userMessage(context, error), _ToastKind.error);

  static void _show(BuildContext context, String message, _ToastKind kind) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final p = context.palette;
    final (Color accent, IconData icon) = switch (kind) {
      _ToastKind.success => (p.success, Icons.check_circle_rounded),
      _ToastKind.error => (p.error, Icons.error_rounded),
      _ToastKind.warning => (p.warning, Icons.warning_amber_rounded),
      _ToastKind.info => (p.info, Icons.info_rounded),
    };
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: p.surface,
          elevation: 0,
          duration: Duration(seconds: kind == _ToastKind.error ? 5 : 3),
          margin: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: BorderSide(color: accent.withValues(alpha: 0.35)),
          ),
          content: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: accent, width: 4)),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(icon, color: accent, size: 22),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(message,
                        style: AppTypography.bodyMedium
                            .copyWith(color: p.textPrimary)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
