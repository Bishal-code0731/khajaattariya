import 'package:flutter/material.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/ticket_model.dart';

String ticketStatusLabel(BuildContext context, TicketStatus status) {
  final a = context.s.account;
  return switch (status) {
    TicketStatus.open => a.statusOpen,
    TicketStatus.inProgress => a.statusInProgress,
    TicketStatus.resolved => a.statusResolved,
    TicketStatus.closed => a.statusClosed,
  };
}

/// Resolved / closed tickets are read-only for the customer.
bool ticketIsFinished(TicketStatus s) =>
    s == TicketStatus.resolved || s == TicketStatus.closed;

/// Status as icon + text on a soft tint (never colour alone).
class TicketStatusChip extends StatelessWidget {
  const TicketStatusChip({super.key, required this.status});

  final TicketStatus status;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color fg, Color bg, IconData icon) = switch (status) {
      TicketStatus.open => (
          p.warning,
          p.warningSoft,
          Icons.mark_email_unread_outlined
        ),
      TicketStatus.inProgress => (p.info, p.infoSoft, Icons.autorenew_rounded),
      TicketStatus.resolved => (
          p.success,
          p.successSoft,
          Icons.check_circle_outline_rounded
        ),
      TicketStatus.closed => (
          p.textSecondary,
          p.surfaceAlt,
          Icons.lock_outline_rounded
        ),
    };
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(AppSpacing.radiusXs)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: AppSpacing.xs),
          Text(ticketStatusLabel(context, status),
              style: context.text.overline.copyWith(color: fg)),
        ],
      ),
    );
  }
}
