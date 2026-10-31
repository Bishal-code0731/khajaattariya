import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/s.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../application/auth_provider.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/otp_code_field.dart';
import '../../../shared/widgets/busy_overlay.dart';

/// "Enter the 6-digit code we emailed you" — after signup, or after a login with an unverified email.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  static const _codeLength = 6;
  static const _resendCooldown = 60;

  final _code = TextEditingController();
  Timer? _timer;
  int _secondsLeft = _resendCooldown;
  bool _verifying = false;
  bool _resending = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  Future<void> _verify() async {
    if (_verifying) return;
    final code = _code.text;
    if (code.length != _codeLength) {
      setState(() => _hasError = true);
      AppSnackbar.warning(context, context.s.auth.enterFullCode);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _verifying = true;
      _hasError = false;
    });
    try {
      final user = await ref
          .read(authNotifierProvider.notifier)
          .verifyEmailOtp(email: widget.email, code: code);
      if (!mounted) return;
      AppSnackbar.success(context, context.s.auth.emailVerified);
      context.go(user.userRole.homeRoute);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _hasError = true;
      });
      _code.clear();
      AppSnackbar.error(context, e);
    }
  }

  Future<void> _resend() async {
    if (_resending || _secondsLeft > 0) return;
    setState(() => _resending = true);
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .resendEmailOtp(widget.email);
      if (!mounted) return;
      _code.clear();
      setState(() => _hasError = false);
      _startCooldown();
      AppSnackbar.success(context, context.s.auth.codeResent);
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      BusyOverlay(busy: _verifying, child: _buildBusyContent(context));

  Widget _buildBusyContent(BuildContext context) {
    // Keeps the auto-dispose auth notifier alive while this screen is open.
    ref.watch(authNotifierProvider);
    final s = context.s.auth;
    final p = context.palette;

    return AuthScaffold(
      onBack: () => context.go(RouteNames.signup),
      showBack: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
              title: s.verifyTitle, subtitle: s.verifySubtitle(widget.email)),
          const SizedBox(height: AppSpacing.xl),
          OtpCodeField(
            controller: _code,
            semanticLabel: s.codeFieldLabel,
            length: _codeLength,
            hasError: _hasError,
            enabled: !_verifying,
            onCompleted: (_) => _verify(),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
              label: s.verifyButton, isLoading: _verifying, onPressed: _verify),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(s.didntGetCode,
                  style: AppTypography.bodyMedium
                      .copyWith(color: p.textSecondary)),
              _secondsLeft > 0
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: AppSpacing.md),
                      child: Text(
                        s.resendIn(_secondsLeft),
                        style: AppTypography.labelMedium
                            .copyWith(color: p.textHint),
                      ),
                    )
                  : TextButton(
                      onPressed: _resending ? null : _resend,
                      child: Text(s.resendCode),
                    ),
            ],
          ),
          Center(
            child: TextButton(
              onPressed: () => context.go(RouteNames.signup),
              child: Text(s.wrongEmail),
            ),
          ),
        ],
      ),
    );
  }
}
