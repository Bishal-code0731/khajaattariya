import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/s.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../auth/application/auth_provider.dart';
import '../application/support_provider.dart';
import '../domain/models/ticket_model.dart';
import 'widgets/message_bubble.dart';
import 'widgets/ticket_status_chip.dart';

/// One support request as a conversation, with a reply box while the request is still open.
class TicketDetailScreen extends ConsumerStatefulWidget {
  const TicketDetailScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _reply = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send(String userId) async {
    final text = _reply.text.trim();
    if (_sending) return;
    if (text.isEmpty) {
      AppSnackbar.info(context, context.s.account.replyRequired);
      return;
    }
    setState(() => _sending = true);
    final ok = await ref.read(supportActionsProvider.notifier).reply(
          ticketId: widget.ticketId,
          actorId: userId,
          message: text,
        );
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      _reply.clear();
      ref.invalidate(ticketRepliesProvider(widget.ticketId));
      ref.invalidate(ownTicketsProvider(userId));
    } else {
      AppSnackbar.error(context, ref.read(supportActionsProvider).error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = context.s.account;
    final user = ref.watch(authStateProvider).valueOrNull;
    final ticket = user == null
        ? null
        : ref
            .watch(ownTicketsProvider(user.id))
            .valueOrNull
            ?.where((t) => t.id == widget.ticketId)
            .firstOrNull;
    final repliesAsync = ref.watch(ticketRepliesProvider(widget.ticketId));
    final finished = ticket != null && ticketIsFinished(ticket.status);

    return Scaffold(
      appBar: AppTopBar(title: ticket?.subject ?? a.ticketTitle),
      body: Column(
        children: [
          if (ticket != null) _TicketHeader(ticket: ticket),
          Expanded(
            child: repliesAsync.when(
              skipLoadingOnReload: true,
              loading: () => const AppShimmerCardList(count: 3, itemHeight: 48),
              error: (e, _) => AppErrorState(
                  error: e,
                  onRetry: () =>
                      ref.invalidate(ticketRepliesProvider(widget.ticketId))),
              data: (replies) {
                final bubbles = <Widget>[
                  if (ticket != null)
                    MessageBubble(
                        message: ticket.message,
                        sender: a.you,
                        sentAt: ticket.createdAt,
                        isMine: true),
                  for (final r in replies.where((r) => !r.isInternal))
                    MessageBubble(
                      message: r.message,
                      sender: r.actorId == user?.id
                          ? a.you
                          : (r.actorName ?? a.supportTeam),
                      sentAt: r.createdAt,
                      isMine: r.actorId == user?.id,
                    ),
                ];
                final awaiting = !finished &&
                    replies.where((r) => r.actorId != user?.id).isEmpty;
                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    // reverse: newest at the bottom and the list opens there.
                    child: ListView(
                      reverse: true,
                      padding:
                          const EdgeInsets.all(AppSpacing.screenHorizontal),
                      children: [
                        if (awaiting)
                          _Note(
                              icon: Icons.schedule_rounded,
                              text: a.waitingForReply),
                        for (final b in bubbles.reversed)
                          Padding(
                              padding:
                                  const EdgeInsets.only(top: AppSpacing.md),
                              child: b),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (finished)
            _ClosedBar(text: a.ticketClosedNote)
          else if (user != null)
            _Composer(
                controller: _reply,
                sending: _sending,
                onSend: () => _send(user.id)),
        ],
      ),
    );
  }
}

class _TicketHeader extends StatelessWidget {
  const _TicketHeader({required this.ticket});

  final TicketModel ticket;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: p.surface,
          border: Border(bottom: BorderSide(color: p.border))),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TicketStatusChip(status: ticket.status),
          Text(
              context.s.account
                  .opened(AppFormat.date(context, ticket.createdAt)),
              style: context.text.caption),
          if (ticket.orderId != null)
            Text(AppFormat.orderCode(ticket.orderId!),
                style: context.text.caption),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: p.textHint),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
              child: Text(text,
                  style: context.text.hint, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _ClosedBar extends StatelessWidget {
  const _ClosedBar({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: p.surfaceAlt,
          border: Border(top: BorderSide(color: p.border))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 18, color: p.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(text, style: context.text.secondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer(
      {required this.controller, required this.sending, required this.onSend});

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final a = context.s.account;
    return Container(
      decoration: BoxDecoration(
          color: p.surface, border: Border(top: BorderSide(color: p.border))),
      child: SafeArea(
        top: false,
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      enabled: !sending,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 5000,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      style: context.text.body,
                      decoration: InputDecoration(
                        hintText: a.replyHint,
                        counterText: '',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton.filled(
                      tooltip: a.send,
                      onPressed: sending ? null : onSend,
                      style: IconButton.styleFrom(
                        backgroundColor: p.brand,
                        foregroundColor: p.onBrand,
                        disabledBackgroundColor: p.brand.withValues(alpha: 0.6),
                      ),
                      icon: sending
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: p.onBrand),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
