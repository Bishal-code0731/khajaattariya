import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../features/orders/domain/models/order_model.dart';

/// Canonical order-status pill. Replaces the two independent
/// `_StatusBadge` classes that used to live in orders_screen.dart and
/// restaurant_dashboard_screen.dart.
class AppStatusBadge extends StatelessWidget {
  final OrderStatus status;

  const AppStatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case OrderStatus.pending:    return AppColors.accent;
      case OrderStatus.confirmed:  return AppColors.primary;
      case OrderStatus.preparing:  return AppColors.primary;
      case OrderStatus.ready:      return AppColors.success;
      case OrderStatus.pickedUp:   return AppColors.success;
      case OrderStatus.delivered:  return AppColors.success;
      case OrderStatus.cancelled:  return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.label,
        style: AppTypography.labelSmall.copyWith(color: _color),
      ),
    );
  }
}
