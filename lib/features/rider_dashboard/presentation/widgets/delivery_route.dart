import 'package:flutter/material.dart';

import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Two-step progress for an active job: Picked up → Delivered.
class DeliveryStepProgress extends StatelessWidget {
  const DeliveryStepProgress({super.key, required this.delivered});

  final bool delivered;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.s.rider;
    Widget dot({required bool done, required int n}) => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: done ? p.brand : p.surface,
            shape: BoxShape.circle,
            border: Border.all(color: done ? p.brand : p.border, width: 2),
          ),
          child: Center(
            child: done
                ? Icon(Icons.check_rounded, size: 16, color: p.onBrand)
                : Text('$n',
                    style: AppTypography.labelSmall
                        .copyWith(color: p.textSecondary)),
          ),
        );
    Widget label(String text, {required bool strong}) => Text(text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.labelMedium
            .copyWith(color: strong ? p.textPrimary : p.textSecondary));

    return Semantics(
      label:
          delivered ? '${r.stepPickedUp}, ${r.stepDelivered}' : r.stepPickedUp,
      excludeSemantics: true,
      child: Column(
        children: [
          Row(
            children: [
              dot(done: true, n: 1),
              Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: delivered ? p.brand : p.border,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),
              dot(done: delivered, n: 2),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(child: label(r.stepPickedUp, strong: true)),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: label(r.stepDelivered, strong: delivered),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DeliveryStop extends StatelessWidget {
  const DeliveryStop({
    super.key,
    required this.icon,
    required this.label,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  /// The stop the rider is heading to now.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: highlight ? p.brandSoft : p.surfaceAlt,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(icon,
              size: 22, color: highlight ? p.onBrandSoft : p.textSecondary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  style: AppTypography.labelSmall
                      .copyWith(color: p.textSecondary, letterSpacing: 0.6)),
              const SizedBox(height: AppSpacing.xxs),
              Text(title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: (highlight
                          ? AppTypography.bodyLarge
                          : AppTypography.bodyMedium)
                      .copyWith(
                          color: p.textPrimary, fontWeight: FontWeight.w600)),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall
                        .copyWith(color: p.textSecondary)),
            ],
          ),
        ),
        ...actions,
      ],
    );
  }
}

/// Compact pickup → drop-off lines for an order card.
class RouteSummary extends StatelessWidget {
  const RouteSummary({super.key, required this.pickup, required this.dropOff});

  final String pickup;
  final String dropOff;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.s.rider;
    Widget line(IconData icon, String label, String text, Color color) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: '$label  ',
                      style: AppTypography.labelSmall
                          .copyWith(color: p.textSecondary)),
                  TextSpan(
                      text: text,
                      style: AppTypography.bodyMedium
                          .copyWith(color: p.textPrimary)),
                ]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        line(Icons.storefront_rounded, r.pickupFrom, pickup, p.textSecondary),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Container(width: 2, height: 12, color: p.border),
        ),
        line(Icons.location_on_rounded, r.dropAt, dropOff, p.brand),
      ],
    );
  }
}
