import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums/user_role.dart';
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
import 'widgets/role_option_card.dart';
import 'widgets/terms_checkbox_field.dart';
import '../../../shared/widgets/busy_overlay.dart';

/// Version of the Terms of Service / Privacy Policy the user accepts here.
const String kTermsVersion = '1';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  UserRole _selectedRole = UserRole.customer;
  bool _isLoading = false;

  /// Set when the account was created but the email must be confirmed before the first login (B-11).

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    await ref.read(authNotifierProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim().replaceAll(RegExp(r'[\s-]'), ''),
          role: _selectedRole.name,
          termsVersion: kTermsVersion,
        );
    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    final user = authState.valueOrNull;
    final error = authState.error;
    if (error is EmailConfirmationRequiredException) {
      setState(() => _isLoading = false);
      context.go(RouteNames.verifyEmail, extra: {'email': error.email});
      return;
    }
    if (authState.hasError || user == null) {
      setState(() => _isLoading = false);
      AppSnackbar.error(context, error ?? context.s.common.errGeneric);
      return;
    }

    context.go(user.userRole.homeRoute);
  }

  @override
  Widget build(BuildContext context) =>
      BusyOverlay(busy: _isLoading, child: _buildBusyContent(context));

  Widget _buildBusyContent(BuildContext context) {
    ref.watch(authNotifierProvider);
    return AuthScaffold(child: _buildForm(context));
  }

  Widget _buildForm(BuildContext context) {
    final s = context.s;
    final v = context.validators;

    final roles = [
      (
        UserRole.customer,
        Icons.shopping_bag_outlined,
        s.auth.roleCustomerTitle,
        s.auth.roleCustomerDesc
      ),
      (
        UserRole.restaurant,
        Icons.storefront_outlined,
        s.auth.roleRestaurantTitle,
        s.auth.roleRestaurantDesc
      ),
      (
        UserRole.rider,
        Icons.two_wheeler_outlined,
        s.auth.roleRiderTitle,
        s.auth.roleRiderDesc
      ),
    ];

    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
                title: s.auth.signupTitle, subtitle: s.auth.signupSubtitle),
            _SectionLabel(s.auth.sectionRole),
            Semantics(
              container: true,
              label: s.auth.sectionRole,
              child: Column(
                children: [
                  for (final (role, icon, title, desc) in roles) ...[
                    RoleOptionCard(
                      icon: icon,
                      title: title,
                      description: desc,
                      selected: _selectedRole == role,
                      onTap: () => setState(() => _selectedRole = role),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel(s.auth.sectionDetails),
            AppTextField(
              label: s.common.fieldFullName,
              hint: s.auth.nameHint,
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.person_outline_rounded,
              autofillHints: const [AutofillHints.name],
              validator: v.name(s.common.fieldFullName),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: s.common.fieldEmail,
              hint: s.auth.emailHint,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.mail_outline_rounded,
              autofillHints: const [AutofillHints.email],
              validator: v.email,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: s.common.fieldPhone,
              hint: s.auth.phoneHint,
              helper: s.auth.phoneHelper,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.phone_outlined,
              autofillHints: const [AutofillHints.telephoneNumber],
              validator: v.phone,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: s.common.fieldPassword,
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
              label: s.auth.confirmPasswordLabel,
              hint: s.auth.confirmPasswordHint,
              controller: _confirmPasswordController,
              isPassword: true,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.lock_outline_rounded,
              autofillHints: const [AutofillHints.newPassword],
              showToggleTooltip: s.auth.showPassword,
              hideToggleTooltip: s.auth.hidePassword,
              validator: v.confirmPassword(() => _passwordController.text),
              onSubmitted: (_) => _signUp(),
            ),
            const SizedBox(height: AppSpacing.md),
            TermsCheckboxField(
              validator: (accepted) =>
                  accepted == true ? null : context.s.auth.termsRequired,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: s.auth.createAccountButton,
              isLoading: _isLoading,
              onPressed: _signUp,
            ),
            const SizedBox(height: AppSpacing.xl),
            AuthFooterLink(
              prompt: s.auth.haveAccount,
              action: s.auth.loginLink,
              onTap: () => context.go(RouteNames.login),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child:
            Semantics(header: true, child: Text(text, style: context.text.h3)),
      );
}
