import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/s.dart';
import '../../../core/router/navigation_extensions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../auth/application/auth_provider.dart';
import '../../profile/presentation/widgets/account_bottom_bar.dart';
import '../application/support_provider.dart';
import '../domain/models/ticket_model.dart';
import 'widgets/new_ticket_sheet.dart';
import 'widgets/ticket_status_chip.dart';

/// The user's support requests and a way to open a new one.
class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.s.account;
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return Scaffold(
          appBar: AppTopBar(title: a.supportTitle),
          body: const AppShimmerCardList(itemHeight: 56));
    }
    final async = ref.watch(ownTicketsProvider(user.id));
    final hasTickets = (async.valueOrNull ?? const []).isNotEmpty;

    return Scaffold(
      appBar: AppTopBar(title: a.supportTitle, subtitle: a.supportSubtitle),
      body: async.when(
        skipLoadingOnReload: true,
        loading: () => const AppShimmerCardList(count: 4, itemHeight: 56),
        error: (e, _) => AppErrorState(
            error: e,
            onRetry: () => ref.invalidate(ownTicketsProvider(user.id))),
        data: (tickets) {
          if (tickets.isEmpty) {
            return AppEmptyState(
              icon: Icons.support_agent_rounded,
              title: a.noTicketsTitle,
              subtitle: a.noTicketsBody,
              action: AppButton(
                label: a.newRequest,
                leadingIcon: Icons.edit_note_rounded,
                expand: false,
                onPressed: () => showNewTicketSheet(context, user.id),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(ownTicketsProvider(user.id).future),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.lg,
                    AppSpacing.screenHorizontal,
                    AppSpacing.xxl,
                  ),
                  itemCount: tickets.length + 1,
                  separatorBuilder: (_, i) =>
                      SizedBox(height: i == 0 ? AppSpacing.sm : AppSpacing.md),
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return Text(a.yourRequests.toUpperCase(),
                          style: context.text.overline
                              .copyWith(letterSpacing: 0.8));
                    }
                    final t = tickets[i - 1];
                    return _TicketCard(
                      ticket: t,
                      onTap: () =>
                          context.pushOnce('${RouteNames.support}/${t.id}'),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: hasTickets
          ? AccountBottomBar(
              child: AppButton(
                label: a.newRequest,
                leadingIcon: Icons.edit_note_rounded,
                onPressed: () => showNewTicketSheet(context, user.id),
              ),
            )
          : null,
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.onTap});

  final TicketModel ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final a = context.s.account;
    final finished = ticketIsFinished(ticket.status);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.subject,
                  style: finished
                      ? context.text.label.copyWith(color: p.textSecondary)
                      : context.text.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(ticket.message,
                    style: context.text.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TicketStatusChip(status: ticket.status),
                    Text(
                        a.updated(
                            AppFormat.timeAgo(context, ticket.lastActivity)),
                        style: context.text.hint),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.textHint),
        ],
      ),
    );
  }
}
