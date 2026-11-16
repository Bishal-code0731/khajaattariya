import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';

/// Shown while the customer is paying in Khalti's external checkout.
class KhaltiWaitingCard extends StatelessWidget {
  const KhaltiWaitingCard({
    super.key,
    required this.isChecking,
    required this.onCheck,
    required this.onReopen,
    required this.onDebugPidx,
  });

  final bool isChecking;
  final VoidCallback? onCheck;
  final VoidCallback? onReopen;
  final VoidCallback onDebugPidx;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.text;
    final o = context.s.orders;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: AppColors.khaltiPurple.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(strokeWidth: 2.4, color: p.brand),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(o.khaltiWaitingTitle, style: text.h3),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(o.khaltiWaitingBody, style: text.secondary),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: o.reopenKhalti,
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.medium,
                  onPressed: isChecking ? null : onReopen,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: o.checkPayment,
                  variant: AppButtonVariant.tonal,
                  size: AppButtonSize.medium,
                  isLoading: isChecking,
                  onPressed: isChecking ? null : onCheck,
                ),
              ),
            ],
          ),
          if (kDebugMode) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: o.debugEnterPidx,
              variant: AppButtonVariant.text,
              size: AppButtonSize.small,
              onPressed: isChecking ? null : onDebugPidx,
            ),
          ],
        ],
      ),
    );
  }
}
