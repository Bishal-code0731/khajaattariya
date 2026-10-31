import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/s.dart';
import '../../../core/router/navigation_extensions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../application/auth_provider.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_status_panel.dart';
import '../../../shared/widgets/busy_overlay.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;

  /// The address the link went to; non-null shows the "sent" state.
  String? _sentTo;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<bool> _send(String email) async {
    try {
      await ref.read(authNotifierProvider.notifier).sendPasswordReset(email);
      return true;
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e);
      return false;
    }
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final ok = await _send(email);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (ok) _sentTo = email;
    });
  }

  Future<void> _resend() async {
    final email = _sentTo;
    if (email == null || _isResending) return;
    setState(() => _isResending = true);
    final ok = await _send(email);
    if (!mounted) return;
    setState(() => _isResending = false);
    if (ok) AppSnackbar.success(context, context.s.auth.resendDone);
  }

  @override
  Widget build(BuildContext context) =>
      BusyOverlay(busy: _isLoading, child: _buildBusyContent(context));

  Widget _buildBusyContent(BuildContext context) {
    final s = context.s;
    final sentTo = _sentTo;

    return AuthScaffold(
      showBack: true,
      onBack: () => context.safeBack(RouteNames.login),
      child: sentTo != null
          ? AuthStatusPanel(
              icon: Icons.mark_email_read_outlined,
              title: s.auth.resetSentTitle,
              body: s.auth.resetSentBody(sentTo),
              hint: s.auth.resetSentHint,
              actions: [
                AppButton(
                    label: s.auth.backToLogin,
                    onPressed: () => context.go(RouteNames.login)),
                AppButton(
                  label: s.auth.resendLink,
                  variant: AppButtonVariant.outline,
                  leadingIcon: Icons.refresh_rounded,
                  isLoading: _isResending,
                  onPressed: _resend,
                ),
              ],
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthHeader(
                      title: s.auth.forgotTitle,
                      subtitle: s.auth.forgotSubtitle),
                  AppTextField(
                    label: s.common.fieldEmail,
                    hint: s.auth.emailHint,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.mail_outline_rounded,
                    autofillHints: const [AutofillHints.email],
                    validator: context.validators.email,
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: s.auth.sendResetLink,
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: s.auth.backToLogin,
                    variant: AppButtonVariant.text,
                    onPressed: () => context.go(RouteNames.login),
                  ),
                ],
              ),
            ),
    );
  }
}
