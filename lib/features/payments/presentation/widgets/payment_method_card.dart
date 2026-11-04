import 'package:flutter/material.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_typography.dart';

/// The ways a customer can pay in the app (Stripe was removed).
enum PaymentMethod { cash, khalti, esewa }

class PaymentMethodCard extends StatelessWidget {
  const PaymentMethodCard({
    super.key,
    required this.method,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.text;
    final o = context.s.orders;

    final (String title, String subtitle, IconData icon, Color mark) =
        switch (method) {
      PaymentMethod.cash => (
          o.methodCash,
          o.cashSubtitle,
          Icons.payments_rounded,
          p.brand,
        ),
      PaymentMethod.khalti => (
          o.methodKhalti,
          o.khaltiSubtitle,
          Icons.account_balance_wallet_rounded,
          AppColors.khaltiPurple,
        ),
      PaymentMethod.esewa => (
          o.methodEsewa,
          o.esewaSubtitle,
          Icons.account_balance_wallet_rounded,
          AppColors.esewaGreen,
        ),
    };
    final markForeground =
        method == PaymentMethod.cash ? p.onBrand : AppColors.white;
    final radius = BorderRadius.circular(AppSpacing.radiusLg);

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      button: true,
      label: enabled ? '$title. $subtitle' : '$title. ${o.comingSoon}',
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          decoration: BoxDecoration(
            color: selected ? p.brandSoft : p.surface,
            borderRadius: radius,
            border: Border.all(
              color: selected ? p.brand : p.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? onTap : null,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: mark,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(icon, color: markForeground, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(title,
                                    style: text.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              if (!enabled) ...[
                                const SizedBox(width: AppSpacing.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xxs),
                                  decoration: BoxDecoration(
                                    color: p.surfaceAlt,
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusXs),
                                  ),
                                  child: Text(o.comingSoon,
                                      style: AppTypography.labelSmall
                                          .copyWith(color: p.textSecondary)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(subtitle, style: text.caption),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _RadioDot(selected: selected),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedContainer(
      duration: AppMotion.fast,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? p.brand : p.border,
          width: selected ? 6.5 : 1.5,
        ),
        color: p.surface,
      ),
    );
  }
}
