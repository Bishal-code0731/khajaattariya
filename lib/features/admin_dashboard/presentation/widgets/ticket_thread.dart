import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/router/navigation_extensions.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../../../support/application/support_provider.dart';
import '../../../support/domain/models/ticket_model.dart';
import '../../application/admin_actions.dart';
import '../../../../core/l10n/strings/admin_strings.dart';
import 'admin_busy.dart';
import 'admin_tag.dart';

/// Label, icon and tone for a ticket status (never colour alone).
(String, IconData, AdminTone) ticketStatusStyle(
        AdminStrings s, TicketStatus status) =>
    switch (status) {
      TicketStatus.open => (
          s.ticketOpen,
          Icons.mark_email_unread_rounded,
          AdminTone.warning
        ),
      TicketStatus.inProgress => (
          s.ticketInProgress,
          Icons.pending_rounded,
          AdminTone.info
        ),
      TicketStatus.resolved => (
          s.ticketResolved,
          Icons.check_circle_rounded,
          AdminTone.success
        ),
      TicketStatus.closed => (
          s.ticketClosed,
          Icons.lock_rounded,
          AdminTone.neutral
        ),
    };

class TicketThread extends ConsumerStatefulWidget {
  const TicketThread({super.key, required this.ticket});
  final TicketModel ticket;

  @override
  ConsumerState<TicketThread> createState() => _TicketThreadState();
}

class _TicketThreadState extends ConsumerState<TicketThread> with AdminBusy {
  final _formKey = GlobalKey<FormState>();
  final _reply = TextEditingController();
  bool _internal = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (isBusy || !(_formKey.currentState?.validate() ?? false)) return;
    final s = context.s.admin;
    final ok = await runAction(
      'send',
      () => ref.read(adminActionsProvider).replyToTicket(
          widget.ticket, _reply.text.trim(),
          internal: _internal),
      success: s.replySent,
    );
    if (ok && mounted) {
      _reply.clear();
      _formKey.currentState?.reset();
    }
  }

  Future<void> _setStatus(TicketStatus status, String key) => runAction(
        key,
        () => ref
            .read(adminActionsProvider)
            .setTicketStatus(widget.ticket.id, status),
        success: context.s.admin.ticketUpdated,
      );

  @override
  Widget build(BuildContext context) {
    final s = context.s.admin;
    final t = widget.ticket;
    final done =
        t.status == TicketStatus.resolved || t.status == TicketStatus.closed;
    final (label, icon, tone) = ticketStatusStyle(s, t.status);
    final replies = ref.watch(ticketRepliesProvider(t.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.subject,
                  style: context.text.h3,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: AppSpacing.xs),
              Text(
                  '${s.from(t.customerName ?? s.unknown)} · ${AppFormat.dateTime(context, t.createdAt)}',
                  style: context.text.caption),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AdminTag(label: label, icon: icon, tone: tone),
                  if (t.orderId != null)
                    AppButton(
                      label:
                          '${s.linkedOrder} ${AppFormat.orderCode(t.orderId!)}',
                      leadingIcon: Icons.receipt_long_outlined,
                      variant: AppButtonVariant.text,
                      size: AppButtonSize.small,
                      expand: false,
                      onPressed: () => context
                          .pushOnce('${RouteNames.orderDetail}/${t.orderId}'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: done
                    ? [
                        AppButton(
                          label: s.reopenTicket,
                          leadingIcon: Icons.undo_rounded,
                          variant: AppButtonVariant.outline,
                          size: AppButtonSize.small,
                          expand: false,
                          isLoading: busy == 'reopen',
                          onPressed: isBusy
                              ? null
                              : () =>
                                  _setStatus(TicketStatus.inProgress, 'reopen'),
                        ),
                      ]
                    : [
                        AppButton(
                          label: s.markResolved,
                          leadingIcon: Icons.check_rounded,
                          variant: AppButtonVariant.tonal,
                          size: AppButtonSize.small,
                          expand: false,
                          isLoading: busy == 'resolve',
                          onPressed: isBusy
                              ? null
                              : () =>
                                  _setStatus(TicketStatus.resolved, 'resolve'),
                        ),
                        AppButton(
                          label: s.closeTicket,
                          leadingIcon: Icons.lock_outline_rounded,
                          variant: AppButtonVariant.outline,
                          size: AppButtonSize.small,
                          expand: false,
                          isLoading: busy == 'close',
                          onPressed: isBusy
                              ? null
                              : () => _setStatus(TicketStatus.closed, 'close'),
                        ),
                      ],
              ),
            ],
          ),
        ),
        Divider(height: 1, color: context.palette.border),

        // Conversation
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(ticketRepliesProvider(t.id).future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _Bubble(
                  author: t.customerName ?? s.unknown,
                  message: t.message,
                  time: t.createdAt,
                  fromAdmin: false,
                ),
                if (replies.hasValue)
                  for (final r in replies.value!)
                    _Bubble(
                      author: r.actorName ?? s.unknown,
                      message: r.message,
                      time: r.createdAt,
                      fromAdmin: r.actorId != t.customerId,
                      internal: r.isInternal,
                    )
                else if (replies.hasError)
                  AppErrorState(
                      error: replies.error,
                      onRetry: () =>
                          ref.invalidate(ticketRepliesProvider(t.id)))
                else
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.md),
                    child: AppShimmer(height: 56),
                  ),
                if (replies.valueOrNull?.isEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(s.noReplies,
                        style: context.text.hint, textAlign: TextAlign.center),
                  ),
              ],
            ),
          ),
        ),

        // Composer
        Container(
          decoration: BoxDecoration(
            color: context.palette.surface,
            border: Border(top: BorderSide(color: context.palette.border)),
          ),
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: s.replyLabel,
                  hint: s.replyHint,
                  controller: _reply,
                  maxLines: 4,
                  minLines: 1,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  validator: context.validators.text(s.replyLabel, max: 2000),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        toggled: _internal,
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          onTap: () => setState(() => _internal = !_internal),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Row(children: [
                              Checkbox(
                                  value: _internal,
                                  onChanged: (v) =>
                                      setState(() => _internal = v ?? false)),
                              Expanded(
                                child: Text(s.internalNote,
                                    style: context.text.caption,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      label: s.send,
                      trailingIcon: Icons.send_rounded,
                      size: AppButtonSize.medium,
                      expand: false,
                      isLoading: busy == 'send',
                      onPressed: isBusy ? null : _send,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.author,
    required this.message,
    required this.time,
    required this.fromAdmin,
    this.internal = false,
  });

  final String author;
  final String message;
  final DateTime time;
  final bool fromAdmin;
  final bool internal;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bg =
        internal ? p.warningSoft : (fromAdmin ? p.brandSoft : p.surfaceAlt);
    return Align(
      alignment: fromAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppSpacing.radiusMd),
              topRight: const Radius.circular(AppSpacing.radiusMd),
              bottomLeft: Radius.circular(
                  fromAdmin ? AppSpacing.radiusMd : AppSpacing.xxs),
              bottomRight: Radius.circular(
                  fromAdmin ? AppSpacing.xxs : AppSpacing.radiusMd),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(author,
                        style: context.text.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (internal) ...[
                    const SizedBox(width: AppSpacing.sm),
                    AdminTag(
                        label: context.s.admin.internalTag,
                        icon: Icons.visibility_off_rounded,
                        tone: AdminTone.warning),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              SelectableText(message, style: context.text.body),
              const SizedBox(height: AppSpacing.xs),
              Text(AppFormat.dateTime(context, time), style: context.text.hint),
            ],
          ),
        ),
      ),
    );
  }
}
