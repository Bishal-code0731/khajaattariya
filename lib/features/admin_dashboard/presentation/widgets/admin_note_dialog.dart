import 'package:flutter/material.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

/// Asks for a rejection reason (5–300 characters).
Future<String?> showAdminNoteDialog(
  BuildContext context, {
  required String title,
  String? confirmLabel,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _NoteDialog(title: title, confirmLabel: confirmLabel),
  );
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.title, this.confirmLabel});
  final String title;
  final String? confirmLabel;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s.admin;
    final c = context.s.common;
    final p = context.palette;
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxFormWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: p.errorSoft,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                  child: Icon(Icons.block_rounded, color: p.error),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(widget.title, style: context.text.h2),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: s.notePrompt,
                  hint: s.noteHint,
                  helper: s.noteHelper,
                  controller: _controller,
                  autofocus: true,
                  maxLines: 3,
                  maxLength: 300,
                  textCapitalization: TextCapitalization.sentences,
                  validator:
                      context.validators.text(s.notePrompt, min: 5, max: 300),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: c.cancel,
                        variant: AppButtonVariant.outline,
                        size: AppButtonSize.medium,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton(
                        label: widget.confirmLabel ?? s.reject,
                        variant: AppButtonVariant.danger,
                        size: AppButtonSize.medium,
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
