import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/support_provider.dart';

Future<void> showNewTicketSheet(BuildContext context, String userId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => NewTicketSheet(userId: userId),
    );

/// "New request" form: subject (3–200) and message (10–5000).
class NewTicketSheet extends ConsumerStatefulWidget {
  const NewTicketSheet({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<NewTicketSheet> createState() => _NewTicketSheetState();
}

class _NewTicketSheetState extends ConsumerState<NewTicketSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    final ok = await ref.read(supportActionsProvider.notifier).createTicket(
          customerId: widget.userId,
          subject: _subject.text.trim(),
          message: _message.text.trim(),
        );
    if (!mounted) return;
    if (ok) {
      ref.invalidate(ownTicketsProvider(widget.userId));
      final msg = context.s.account.requestSent;
      Navigator.of(context).pop();
      AppSnackbar.success(context, msg);
    } else {
      setState(() => _sending = false);
      AppSnackbar.error(context, ref.read(supportActionsProvider).error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = context.s.account;
    final v = context.validators;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(a.newRequest, style: context.text.h2),
              const SizedBox(height: AppSpacing.xs),
              Text(a.supportSubtitle, style: context.text.secondary),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                label: a.subject,
                hint: a.subjectHint,
                controller: _subject,
                prefixIcon: Icons.short_text_rounded,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                maxLength: 200,
                validator: v.text(a.subject, min: 3, max: 200),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: a.message,
                hint: a.messageHint,
                controller: _message,
                minLines: 4,
                maxLines: 8,
                maxLength: 5000,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                validator: v.text(a.message, min: 10, max: 5000),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: a.sendRequest,
                isLoading: _sending,
                onPressed: _submit,
                leadingIcon: Icons.send_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
