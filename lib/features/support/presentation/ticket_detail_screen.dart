import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../application/support_provider.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _replyController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _send(String userId) async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    final ok = await ref.read(supportActionsProvider.notifier).reply(
          ticketId: widget.ticketId,
          actorId: userId,
          message: text,
        );
    if (!mounted) return;
    setState(() => _isSending = false);
    if (ok) {
      _replyController.clear();
      ref.invalidate(ticketRepliesProvider(widget.ticketId));
    } else {
      AppSnackbar.error(context, 'Could not send your reply. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final repliesAsync = ref.watch(ticketRepliesProvider(widget.ticketId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ticket'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          Expanded(
            child: repliesAsync.when(
              loading: () => const AppLoader.fullscreen(),
              error: (_, __) => AppErrorState(
                message: 'Could not load this conversation',
                onRetry: () => ref.invalidate(ticketRepliesProvider(widget.ticketId)),
              ),
              data: (replies) {
                if (replies.isEmpty) {
                  return Center(
                    child: Text('No replies yet. Our team will respond soon.',
                        style: AppTypography.bodyMedium),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                  itemCount: replies.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) {
                    final r = replies[i];
                    final isMe = r.actorId == user?.id;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                        child: GlassCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          borderRadius: AppSpacing.radiusLg,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isMe ? 'You' : (r.actorName ?? 'Support'),
                                  style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
                              const SizedBox(height: 2),
                              Text(r.message, style: AppTypography.bodyMedium),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (user != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        decoration: const InputDecoration(hintText: 'Type a reply...'),
                        minLines: 1,
                        maxLines: 4,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filled(
                      onPressed: _isSending ? null : () => _send(user.id),
                      icon: _isSending
                          ? const AppLoader.button(color: Colors.white)
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
