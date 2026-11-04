import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../payments/domain/models/coupon_model.dart';

class OfferCouponTile extends StatelessWidget {
  const OfferCouponTile({super.key, required this.coupon});

  final CouponModel coupon;

  String _headline(BuildContext context) {
    final s = context.s.customer;
    if (coupon.discountType == 'percent') {
      final pct = coupon.discountValue % 1 == 0
          ? coupon.discountValue.toStringAsFixed(0)
          : coupon.discountValue.toStringAsFixed(1);
      final base = s.percentOff(pct);
      return coupon.maxDiscount == null
          ? base
          : '$base · ${s.upTo(AppFormat.money(context, coupon.maxDiscount!))}';
    }
    return s.flatOff(AppFormat.money(context, coupon.discountValue));
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: coupon.code));
    if (context.mounted) {
      AppSnackbar.success(context, context.s.customer.codeCopied(coupon.code));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.customer;
    final conditions = [
      coupon.minOrderAmount > 0
          ? s.minOrder(AppFormat.money(context, coupon.minOrderAmount))
          : s.noMinOrder,
      if (coupon.validUntil != null)
        s.validUntil(AppFormat.date(context, coupon.validUntil!)),
    ].join(' · ');

    return AppCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 56,
              color: p.accentSoft,
              alignment: Alignment.center,
              child: Icon(Icons.local_offer_rounded, color: p.accent, size: 26),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_headline(context),
                        style: AppTypography.headingSmall
                            .copyWith(color: p.textPrimary)),
                    if ((coupon.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(coupon.description!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium
                              .copyWith(color: p.textSecondary)),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(conditions,
                        style: AppTypography.bodySmall
                            .copyWith(color: p.textHint)),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md, vertical: 6),
                            decoration: BoxDecoration(
                              color: p.surfaceAlt,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                              border: Border.all(color: p.border),
                            ),
                            child: SelectableText(
                              coupon.code,
                              maxLines: 1,
                              style: AppTypography.labelLarge.copyWith(
                                  color: p.textPrimary, letterSpacing: 1.2),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        TextButton.icon(
                          onPressed: () => _copy(context),
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: Text(s.copyCode),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
