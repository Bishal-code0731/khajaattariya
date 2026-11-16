import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// − 2 + control for cart / menu items.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.addLabel,
    this.max = 50,
    this.compact = false,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final String? addLabel;
  final int max;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final h = compact ? 32.0 : 38.0;
    final localizations = MaterialLocalizations.of(context);

    if (quantity == 0 && addLabel != null) {
      return SizedBox(
        height: h,
        child: OutlinedButton(
          onPressed: onIncrement,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(compact ? 64 : 84, h),
            backgroundColor: p.surface,
            foregroundColor: p.brand,
            side: BorderSide(color: p.brand, width: 1.2),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
            textStyle: AppTypography.labelMedium,
          ),
          child: Text(addLabel!.toUpperCase()),
        ),
      );
    }

    Widget btn(IconData icon, VoidCallback? onTap, String tooltip) => SizedBox(
          width: h,
          height: h,
          child: IconButton(
            tooltip: tooltip,
            padding: EdgeInsets.zero,
            iconSize: 18,
            color: p.onBrand,
            disabledColor: p.onBrand.withValues(alpha: 0.4),
            onPressed: onTap,
            icon: Icon(icon),
          ),
        );

    return Container(
      height: h,
      decoration: BoxDecoration(
          color: p.brand,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(
              quantity <= 1
                  ? Icons.delete_outline_rounded
                  : Icons.remove_rounded,
              onDecrement,
              localizations.deleteButtonTooltip),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 22),
            child: Text('$quantity',
                textAlign: TextAlign.center,
                style: AppTypography.labelLarge.copyWith(color: p.onBrand)),
          ),
          btn(Icons.add_rounded, quantity >= max ? null : onIncrement, '+1'),
        ],
      ),
    );
  }
}
