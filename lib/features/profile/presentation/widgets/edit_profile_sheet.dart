import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../application/profile_provider.dart';
import '../../../../shared/widgets/busy_overlay.dart';

/// Opens the edit-profile sheet.
Future<void> showEditProfileSheet(BuildContext context, UserModel user) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => EditProfileSheet(user: user),
  );
}

class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({super.key, required this.user});

  final UserModel user;

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.user.fullName);
  late final TextEditingController _phone =
      TextEditingController(text: widget.user.phone ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileUpdateProvider.notifier).updateProfile(
            userId: widget.user.id,
            fullName: _name.text.trim(),
            phone: _phone.text.replaceAll(RegExp(r'[\s-]'), ''),
          );
      ref.invalidate(authStateProvider);
      if (!mounted) return;
      final msg = context.s.account.profileUpdated;
      Navigator.of(context).pop();
      AppSnackbar.success(context, msg);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) =>
      BusyOverlay(busy: _saving, child: _buildBusyContent(context));

  Widget _buildBusyContent(BuildContext context) {
    final a = context.s.account;
    final c = context.s.common;
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
              Text(a.editProfile, style: context.text.h2),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                label: c.fieldFullName,
                controller: _name,
                prefixIcon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: v.name(c.fieldFullName),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: c.fieldPhone,
                hint: '98XXXXXXXX',
                controller: _phone,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.telephoneNumber],
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
                  LengthLimitingTextInputFormatter(16),
                ],
                validator: v.phone,
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: c.fieldEmail,
                initialValue: widget.user.email,
                prefixIcon: Icons.mail_outline_rounded,
                enabled: false,
                helper: a.emailReadOnlyHelper,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                  label: c.saveChanges, isLoading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
