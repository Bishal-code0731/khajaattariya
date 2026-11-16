import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/s.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../application/auth_provider.dart';
import '../domain/auth_exceptions.dart';
import 'widgets/auth_footer_link.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_scaffold.dart';
import '../../../shared/widgets/busy_overlay.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    await ref.read(authNotifierProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    final user = authState.valueOrNull;
    final error = authState.error;
    if (error is EmailNotVerifiedException) {
      setState(() => _isLoading = false);
      AppSnackbar.info(context, context.s.auth.verifyBeforeLogin);
      context.go(RouteNames.verifyEmail, extra: {'email': error.email});
      return;
    }
    if (authState.hasError || user == null) {
      setState(() => _isLoading = false);
      AppSnackbar.error(
        context,
        error is AccountDisabledException
            ? context.s.common.errAccountDisabled
            : (error ?? context.s.common.errGeneric),
      );
      return;
    }

    context.go(user.userRole.homeRoute);
  }

  @override
  Widget build(BuildContext context) =>
      BusyOverlay(busy: _isLoading, child: _buildBusyContent(context));

  Widget _buildBusyContent(BuildContext context) {
    ref.watch(authNotifierProvider);
    final s = context.s;
    final v = context.validators;

    return AuthScaffold(
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeader(
                  title: s.auth.loginTitle, subtitle: s.auth.loginSubtitle),
              AppTextField(
                label: s.common.fieldEmail,
                hint: s.auth.emailHint,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.mail_outline_rounded,
                autofillHints: const [
                  AutofillHints.email,
                  AutofillHints.username
                ],
                validator: v.email,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: s.common.fieldPassword,
                hint: s.auth.loginPasswordHint,
                controller: _passwordController,
                isPassword: true,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.lock_outline_rounded,
                autofillHints: const [AutofillHints.password],
                showToggleTooltip: s.auth.showPassword,
                hideToggleTooltip: s.auth.hidePassword,
                validator: v.loginPassword,
                onSubmitted: (_) => _login(),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => context.push(RouteNames.forgotPassword),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  child:
                      Text(s.auth.forgotPasswordLink, style: context.text.link),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: s.auth.loginButton,
                isLoading: _isLoading,
                onPressed: _login,
              ),
              const SizedBox(height: AppSpacing.xl),
              AuthFooterLink(
                prompt: s.auth.noAccount,
                action: s.auth.createAccountLink,
                onTap: () => context.go(RouteNames.signup),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
