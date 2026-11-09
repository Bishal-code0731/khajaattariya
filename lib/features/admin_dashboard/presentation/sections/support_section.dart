import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../support/application/support_provider.dart';
import '../../../support/domain/models/ticket_model.dart';
import '../widgets/admin_filter_bar.dart';
import '../widgets/admin_list.dart';
import '../widgets/admin_tag.dart';
import '../widgets/ticket_thread.dart';

enum _TicketFilter { open, inProgress, done, all }

/// Support inbox.
class SupportSection extends ConsumerStatefulWidget {
  const SupportSection({super.key});

  @override
  ConsumerState<SupportSection> createState() => _SupportSectionState();
}

class _SupportSectionState extends ConsumerState<SupportSection> {
  _TicketFilter _filter = _TicketFilter.open;
  String? _selectedId;

  bool _matches(TicketModel t) => _inFilter(t, _filter);

  static bool _inFilter(TicketModel t, _TicketFilter f) => switch (f) {
        _TicketFilter.open => t.status == TicketStatus.open,
        _TicketFilter.inProgress => t.status == TicketStatus.inProgress,
        _TicketFilter.done =>
          t.status == TicketStatus.resolved || t.status == TicketStatus.closed,
        _TicketFilter.all => true,
      };

  void _open(TicketModel t, bool split) {
    if (split) {
      setState(() => _selectedId = t.id);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => _TicketPage(ticketId: t.id, initial: t)));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s.admin;
    final async = ref.watch(allTicketsProvider);
    final all = async.valueOrNull ?? const <TicketModel>[];
    int count(_TicketFilter f) => all.where((t) => _inFilter(t, f)).length;

    return LayoutBuilder(builder: (context, c) {
      final split = c.maxWidth >= 860;
      final list = AdminAsyncList<TicketModel>(
        value: async.whenData((l) => l.where(_matches).toList()),
        onRefresh: () => ref.refresh(allTicketsProvider.future),
        header: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: AdminFilterBar<_TicketFilter>(
            selected: _filter,
            onSelected: (f) => setState(() => _filter = f),
            options: [
              AdminFilterOption(_TicketFilter.open, s.ticketOpen,
                  count: count(_TicketFilter.open)),
              AdminFilterOption(_TicketFilter.inProgress, s.ticketInProgress,
                  count: count(_TicketFilter.inProgress)),
              AdminFilterOption(_TicketFilter.done, s.ticketResolved,
                  count: count(_TicketFilter.done)),
              AdminFilterOption(_TicketFilter.all, s.all, count: all.length),
            ],
          ),
        ),
        empty: AppEmptyState(
          icon: Icons.mark_email_read_outlined,
          title: s.ticketsEmpty,
          subtitle: s.ticketsEmptyHint,
          compact: true,
        ),
        itemBuilder: (context, t) => _TicketRow(
            ticket: t,
            selected: split && t.id == _selectedId,
            onTap: () => _open(t, split)),
      );
      if (!split) return list;

      final selected = all.where((t) => t.id == _selectedId).firstOrNull;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 380, child: list),
          VerticalDivider(width: 1, color: context.palette.border),
          Expanded(
            child: selected == null
                ? AppEmptyState(
                    icon: Icons.forum_outlined,
                    title: s.selectTicket,
                    compact: true)
                : TicketThread(key: ValueKey(selected.id), ticket: selected),
          ),
        ],
      );
    });
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow(
      {required this.ticket, required this.selected, required this.onTap});
  final TicketModel ticket;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.s.admin;
    final t = ticket;
    final (label, icon, tone) = ticketStatusStyle(s, t.status);
    return AdminRow(
      onTap: onTap,
      borderColor: selected ? context.palette.brand : null,
      color:
          selected ? context.palette.brandSoft.withValues(alpha: 0.35) : null,
      title: t.subject,
      trailing: Text(AppFormat.timeAgo(context, t.createdAt),
          style: context.text.hint),
      lines: [s.from(t.customerName ?? s.unknown), t.message],
      tags: [
        AdminTag(label: label, icon: icon, tone: tone),
        if (t.priority == 'urgent')
          AdminTag(
              label: s.priorityUrgent,
              icon: Icons.priority_high_rounded,
              tone: AdminTone.error)
        else if (t.priority == 'high')
          AdminTag(
              label: s.priorityHigh,
              icon: Icons.arrow_upward_rounded,
              tone: AdminTone.warning),
      ],
    );
  }
}

/// Phone: one ticket's conversation on its own page.
class _TicketPage extends ConsumerWidget {
  const _TicketPage({required this.ticketId, required this.initial});
  final String ticketId;
  final TicketModel initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(allTicketsProvider).valueOrNull;
    final ticket =
        tickets?.where((t) => t.id == ticketId).firstOrNull ?? initial;
    return Scaffold(
      appBar: AppTopBar(
        title: context.s.admin.conversation,
        subtitle: ticket.subject,
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(top: false, child: TicketThread(ticket: ticket)),
    );
  }
}
