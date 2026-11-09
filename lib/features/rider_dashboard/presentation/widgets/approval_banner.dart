import 'package:flutter/material.dart';

import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../rider/domain/models/rider_model.dart';
import 'rider_chip.dart';

/// Where the rider stands with the team: not registered, waiting, changes needed, or approved.
enum RiderApprovalState { notRegistered, pending, rejected, approved }

RiderApprovalState approvalStateOf(RiderModel? rider) {
  if (rider == null) return RiderApprovalState.notRegistered;
  if (rider.isApproved) return RiderApprovalState.approved;
  final note = rider.approvalNote?.trim() ?? '';
  return note.isEmpty
      ? RiderApprovalState.pending
      : RiderApprovalState.rejected;
}

class ApprovalBanner extends StatelessWidget {
  const ApprovalBanner(
      {super.key,
      required this.rider,
      this.onAction,
      this.actionLabel,
      this.showApproved = false});

  final RiderModel? rider;
  final VoidCallback? onAction;
  final String? actionLabel;
  final bool showApproved;

  @override
  Widget build(BuildContext context) {
    final r = context.s.rider;
    final state = approvalStateOf(rider);
    if (state == RiderApprovalState.approved && !showApproved) {
      return const SizedBox.shrink();
    }

    final (tone, icon, title, body) = switch (state) {
      RiderApprovalState.notRegistered => (
          RiderTone.info,
          Icons.two_wheeler_rounded,
          r.notRegisteredTitle,
          r.notRegisteredBody
        ),
      RiderApprovalState.pending => (
          RiderTone.warning,
          Icons.hourglass_top_rounded,
          r.approvalPendingTitle,
          r.approvalPendingBody
        ),
      RiderApprovalState.rejected => (
          RiderTone.error,
          Icons.error_outline_rounded,
          r.approvalRejectedTitle,
          r.approvalRejectedBody
        ),
      RiderApprovalState.approved => (
          RiderTone.success,
          Icons.verified_rounded,
          r.approvedTitle,
          r.approvedBody
        ),
    };
    final c = riderToneColors(context, tone);
    final p = context.palette;
    final note = rider?.approvalNote?.trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: c.fg, size: 24),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTypography.headingSmall
                            .copyWith(color: p.textPrimary)),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(body,
                        style: AppTypography.bodyMedium
                            .copyWith(color: p.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          if (state == RiderApprovalState.rejected && note.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.adminNote,
                      style: AppTypography.labelSmall
                          .copyWith(color: p.textSecondary)),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(note,
                      style: AppTypography.bodyMedium
                          .copyWith(color: p.textPrimary)),
                ],
              ),
            ),
          ],
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: AppButtonVariant.outline,
              size: AppButtonSize.medium,
              expand: false,
              trailingIcon: Icons.arrow_forward_rounded,
            ),
          ],
        ],
      ),
    );
  }
}
