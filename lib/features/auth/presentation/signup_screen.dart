import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/enums/user_role.dart';
import '../../../core/router/navigation_extensions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../application/auth_provider.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Returns emoji + subtitle based on selected role
  ({String emoji, String subtitle}) get _roleHeader {
    switch (_selectedRole) {
      case UserRole.restaurant:
        return (
        emoji: '🍽️',
        subtitle: 'Partner with Khaja Attariya and grow your restaurant business',
        );
      case UserRole.rider:
        return (
        emoji: '🛵',
        subtitle: 'Deliver food across Attariya and earn on your schedule',
        );
      case UserRole.customer:
      case UserRole.admin:
        return (
        emoji: '🎉',
        subtitle: 'Join Khaja Attariya and order your favourite food',
        );
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _selectedRole.name,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackbar.error(context, e);
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Navigation on success is handled entirely by the router's redirect
    // (it watches authStateProvider via refreshListenable) — calling
    // context.go here too would race with it and double-navigate.
    final authState = ref.read(authNotifierProvider);
    authState.whenOrNull(
      error: (e, _) => AppSnackbar.error(context, e),
    );
  }

  @override
  Widget build(BuildContext context) {
    final header = _roleHeader;
    // authNotifierProvider is autoDispose; watching it here keeps it alive
    // for as long as this screen is mounted, so the async signUp() call
    // can still write its result to `state` after the network round trip
    // completes (see login_screen.dart for the same fix).
    ref.watch(authNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),

                IconButton(
                  onPressed: () => context.safeBack(RouteNames.login),
                  icon: const Icon(Icons.arrow_back_rounded),
                  padding: EdgeInsets.zero,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Emoji + title animate with role selection
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Column(
                    key: ValueKey(_selectedRole),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Account ${header.emoji}',
                        style: AppTypography.displayMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        header.subtitle,
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                AppTextField(
                  label: 'Full Name',
                  hint: 'Ram Bahadur',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) => Validators.name(v, field: 'Full name'),
                ),

                const SizedBox(height: AppSpacing.md),

                AppTextField(
                  label: 'Email',
                  hint: 'you@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: Validators.email,
                ),

                const SizedBox(height: AppSpacing.md),

                AppTextField(
                  label: 'Phone Number',
                  hint: '98XXXXXXXX',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: Validators.phone,
                ),

                const SizedBox(height: AppSpacing.md),

                AppTextField(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _passwordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: Validators.password,
                ),

                const SizedBox(height: AppSpacing.md),

                AppTextField(
                  label: 'Confirm Password',
                  hint: '••••••••',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (v) => Validators.confirmPassword(v, _passwordController.text),
                ),

                const SizedBox(height: AppSpacing.lg),

                Text('I want to join as', style: AppTypography.headingSmall),
                const SizedBox(height: AppSpacing.sm),
                _RoleSelector(
                  selected: _selectedRole,
                  onChanged: (role) => setState(() => _selectedRole = role),
                ),

                const SizedBox(height: AppSpacing.xl),

                AppButton(
                  label: 'Create Account',
                  isLoading: _isLoading,
                  onPressed: _signUp,
                ),

                const SizedBox(height: AppSpacing.lg),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ',
                        style: AppTypography.bodyMedium),
                    TextButton(
                      onPressed: () => context.go(RouteNames.login),
                      child: const Text('Login'),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleOption {
  final UserRole role;
  final IconData icon;
  final String desc;

  const _RoleOption({required this.role, required this.icon, required this.desc});
}

class _RoleSelector extends StatelessWidget {
  final UserRole selected;
  final ValueChanged<UserRole> onChanged;

  const _RoleSelector({required this.selected, required this.onChanged});

  static const List<_RoleOption> _roles = [
    _RoleOption(role: UserRole.customer, icon: Icons.person_rounded, desc: 'Order food'),
    _RoleOption(role: UserRole.restaurant, icon: Icons.store_rounded, desc: 'Sell food'),
    _RoleOption(role: UserRole.rider, icon: Icons.delivery_dining_rounded, desc: 'Deliver food'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _roles.map((option) {
        final isSelected = selected == option.role;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(option.role),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    option.icon,
                    color: isSelected ? AppColors.white : AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.role.label,
                    style: AppTypography.labelSmall.copyWith(
                      color: isSelected ? AppColors.white : AppColors.primary,
                    ),
                  ),
                  Text(
                    option.desc,
                    style: AppTypography.bodySmall.copyWith(
                      color: isSelected
                          ? AppColors.white.withValues(alpha: 0.8)
                          : AppColors.textHint,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}