import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../application/admin_queries.dart';
import '../../domain/admin_models.dart';
import '../widgets/admin_list.dart';

IconData _iconFor(String action) {
  if (action.startsWith('approve') || action.startsWith('confirm')) {
    return Icons.check_circle_outline_rounded;
  }
  if (action.startsWith('reject') ||
      action.startsWith('ban') ||
      action.startsWith('deactivate')) {
    return Icons.block_rounded;
  }
  if (action.contains('setting')) return Icons.tune_rounded;
  if (action.contains('coupon')) return Icons.local_offer_outlined;
  if (action.contains('ticket')) return Icons.support_agent_rounded;
  if (action.contains('feature')) return Icons.star_outline_rounded;
  return Icons.edit_note_rounded;
}

/// Readable history of every admin change.
class AuditSection extends ConsumerWidget {
  const AuditSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s.admin;
    return AdminAsyncList<AdminAuditEntry>(
      value: ref.watch(adminAuditProvider),
      onRefresh: () => ref.refresh(adminAuditProvider.future),
      empty: AppEmptyState(
        icon: Icons.history_rounded,
        title: s.auditEmpty,
        subtitle: s.auditEmptyHint,
        compact: true,
      ),
      itemBuilder: (context, e) {
        final p = context.palette;
        final target = [
          if (e.targetTable != null) s.auditTarget(e.targetTable),
          if (e.targetId != null && e.targetId!.isNotEmpty)
            e.targetTable == 'platform_settings'
                ? e.targetId!
                : (e.targetId!.length >= 8
                    ? AppFormat.orderCode(e.targetId!)
                    : e.targetId!),
        ].join(' ');
        return AdminRow(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: p.surfaceAlt,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            child: Icon(_iconFor(e.action), size: 20, color: p.textSecondary),
          ),
          title: s.auditAction(e.action),
          trailing: Tooltip(
            message: AppFormat.dateTime(context, e.createdAt),
            child: Text(AppFormat.timeAgo(context, e.createdAt),
                style: context.text.hint),
          ),
          lines: [
            [s.by(e.actorName ?? s.system), if (target.isNotEmpty) target]
                .join(' · '),
          ],
        );
      },
    );
  }
}
