import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../application/support_provider.dart';
import '../domain/models/ticket_model.dart';

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Help & Support')),
        body: const AppEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Please log in',
          subtitle: 'Log in to contact support or view your tickets.',
        ),
      );
    }

    final ticketsAsync = ref.watch(ownTicketsProvider(user.id));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Help & Support'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewTicketSheet(context, ref, user.id),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Ticket', style: TextStyle(color: Colors.white)),
      ),
      body: ticketsAsync.when(
        loading: () => const AppLoader.fullscreen(),
        error: (_, __) => AppErrorState(
          message: 'Could not load your tickets',
          onRetry: () => ref.invalidate(ownTicketsProvider(user.id)),
        ),
        data: (tickets) {
          if (tickets.isEmpty) {
            return const AppEmptyState(
              icon: Icons.support_agent_rounded,
              title: 'No support tickets yet',
              subtitle: 'Having an issue with an order or your account? Tap "New Ticket" below.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            itemCount: tickets.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) {
              final t = tickets[i];
              return GlassCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                borderRadius: AppSpacing.radiusLg,
                onTap: () => context.push('${RouteNames.support}/${t.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(t.subject,
                              style: AppTypography.labelLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        _StatusChip(status: t.status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(t.message,
                        style: AppTypography.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showNewTicketSheet(BuildContext context, WidgetRef ref, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewTicketSheet(userId: userId),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final TicketStatus status;
  const _StatusChip({required this.status});

  Color get _color {
    switch (status) {
      case TicketStatus.open:
        return AppColors.warning;
      case TicketStatus.inProgress:
        return AppColors.info;
      case TicketStatus.resolved:
      case TicketStatus.closed:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(status.label, style: AppTypography.labelSmall.copyWith(color: _color)),
    );
  }
}

class _NewTicketSheet extends ConsumerStatefulWidget {
  final String userId;
  const _NewTicketSheet({required this.userId});

  @override
  ConsumerState<_NewTicketSheet> createState() => _NewTicketSheetState();
}

class _NewTicketSheetState extends ConsumerState<_NewTicketSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final ok = await ref.read(supportActionsProvider.notifier).createTicket(
          customerId: widget.userId,
          subject: _subjectController.text.trim(),
          message: _messageController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (ok) {
      ref.invalidate(ownTicketsProvider(widget.userId));
      Navigator.of(context).pop();
      AppSnackbar.success(context, 'Ticket submitted. We\'ll get back to you soon.');
    } else {
      AppSnackbar.error(context, 'Could not submit ticket. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Support Ticket', style: AppTypography.headingMedium),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Subject',
                hint: 'What do you need help with?',
                controller: _subjectController,
                validator: (v) => v == null || v.isEmpty ? 'Subject is required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Message',
                hint: 'Describe the issue in detail',
                controller: _messageController,
                maxLines: 4,
                validator: (v) => v == null || v.isEmpty ? 'Message is required' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: 'Submit', isLoading: _isSubmitting, onPressed: _submit),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
