import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/s.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../application/auth_provider.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_scaffold.dart';
import '../../../shared/widgets/busy_overlay.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final user = await ref
          .read(authNotifierProvider.notifier)
          .updatePassword(_passwordController.text);
      if (!mounted) return;
      AppSnackbar.success(context, context.s.auth.passwordUpdated);
      // Spinner stays on until this screen is replaced.
      context.go(user?.userRole.homeRoute ?? RouteNames.login);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackbar.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) =>
      BusyOverlay(busy: _isLoading, child: _buildBusyContent(context));

  Widget _buildBusyContent(BuildContext context) {
    // Keeps the autoDispose notifier alive while updatePassword() runs.
    ref.watch(authNotifierProvider);
    final s = context.s;
    final v = context.validators;

    return AuthScaffold(
      showBack: true,
      onBack: () => context.go(RouteNames.login),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeader(
                  title: s.auth.resetTitle, subtitle: s.auth.resetSubtitle),
              AppTextField(
                label: s.auth.newPasswordLabel,
                hint: s.auth.passwordHint,
                helper: s.auth.passwordHelper,
                controller: _passwordController,
                isPassword: true,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.lock_outline_rounded,
                autofillHints: const [AutofillHints.newPassword],
                showToggleTooltip: s.auth.showPassword,
                hideToggleTooltip: s.auth.hidePassword,
                validator: v.password,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: s.auth.confirmNewPasswordLabel,
                hint: s.auth.confirmPasswordHint,
                controller: _confirmController,
                isPassword: true,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.lock_outline_rounded,
                autofillHints: const [AutofillHints.newPassword],
                showToggleTooltip: s.auth.showPassword,
                hideToggleTooltip: s.auth.hidePassword,
                validator: v.confirmPassword(() => _passwordController.text),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: s.auth.updatePasswordButton,
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
