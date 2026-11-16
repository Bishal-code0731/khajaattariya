import 'package:flutter/material.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../payments/domain/models/coupon_model.dart';

/// Coupon entry with Apply, or the applied coupon with Remove.
class CouponCard extends StatelessWidget {
  const CouponCard({
    super.key,
    required this.controller,
    required this.applied,
    required this.estimatedDiscount,
    required this.isLoading,
    required this.error,
    required this.onApply,
    required this.onRemove,
  });

  final TextEditingController controller;
  final CouponModel? applied;
  final double estimatedDiscount;
  final bool isLoading;
  final Object? error;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.customer;
    final c = applied;

    if (c != null) {
      return AppCard(
        color: p.successSoft,
        borderColor: p.success.withValues(alpha: 0.4),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.verified_rounded, color: p.success),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.couponApplied(c.code), style: context.text.label),
                  Text(
                      s.couponSaving(
                          AppFormat.money(context, estimatedDiscount.round())),
                      style: context.text.caption),
                ],
              ),
            ),
            TextButton(
                onPressed: onRemove, child: Text(context.s.common.remove)),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AppTextField(
                  label: s.couponLabel,
                  hint: s.couponHint,
                  controller: controller,
                  prefixIcon: Icons.local_offer_outlined,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  maxLength: 30,
                  onSubmitted: (_) => onApply(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: AppButton(
                  label: context.s.common.apply,
                  variant: AppButtonVariant.tonal,
                  size: AppButtonSize.medium,
                  expand: false,
                  isLoading: isLoading,
                  onPressed: onApply,
                ),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline_rounded, size: 16, color: p.error),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(userMessage(context, error),
                      style: context.text.caption.copyWith(color: p.error)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
