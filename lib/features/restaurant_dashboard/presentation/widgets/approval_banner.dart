import 'package:flutter/material.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/owner_restaurant.dart';

class ApprovalBanner extends StatelessWidget {
  const ApprovalBanner({super.key, required this.restaurant});

  final OwnerRestaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final approval = restaurant.approval;
    if (approval == RestaurantApproval.approved) return const SizedBox.shrink();
    final p = context.palette;
    final s = context.s.restaurant;
    final rejected = approval == RestaurantApproval.rejected;
    final fg = rejected ? p.error : p.warning;
    final note = restaurant.approvalNote?.trim() ?? '';

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: rejected ? p.errorSoft : p.warningSoft,
          border: Border(bottom: BorderSide(color: fg.withValues(alpha: 0.3))),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
                rejected
                    ? Icons.error_outline_rounded
                    : Icons.hourglass_top_rounded,
                size: 22,
                color: fg),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rejected ? s.rejectedTitle : s.pendingTitle,
                      style: context.text.label),
                  const SizedBox(height: 2),
                  Text(rejected ? s.rejectedBody : s.pendingBody,
                      style: context.text.caption),
                  if (rejected && note.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(s.rejectedNote(note), style: context.text.body),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
