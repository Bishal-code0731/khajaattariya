import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Centralizes SnackBar styling and the "Exception: " prefix-stripping
/// that used to be copy-pasted at every call site.
class AppSnackbar {
  AppSnackbar._();

  static void success(BuildContext context, String message) =>
      _show(context, message, AppColors.success, Icons.check_circle_rounded);

  static void error(BuildContext context, Object error) =>
      _show(context, _cleanMessage(error), AppColors.error, Icons.error_rounded);

  static void info(BuildContext context, String message) =>
      _show(context, message, AppColors.info, Icons.info_rounded);

  static String _cleanMessage(Object error) =>
      error.toString().replaceAll('Exception: ', '');

  static void _show(BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              Icon(icon, color: AppColors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message, style: const TextStyle(color: AppColors.white)),
              ),
            ],
          ),
        ),
      );
  }
}
