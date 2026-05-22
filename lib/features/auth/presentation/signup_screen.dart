import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
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
  String _selectedRole = 'customer';

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
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authNotifierProvider.notifier).signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _selectedRole,
    );

    if (!mounted) return;

    final state = ref.read(authNotifierProvider);
    state.when(
      data: (user) {
        if (user != null) context.go(RouteNames.home);
      },
      loading: () {},
      error: (e, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

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
                  onPressed: () => context.go(RouteNames.login),
                  icon: const Icon(Icons.arrow_back_rounded),
                  padding: EdgeInsets.zero,
                ),

                const SizedBox(height: AppSpacing.lg),

                const Text('Create Account 🎉', style: AppTypography.displayMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Join Khaja Attariya and order your favourite food',
                  style: AppTypography.bodyMedium,
                ),

                const SizedBox(height: AppSpacing.xl),

                AppTextField(
                  label: 'Full Name',
                  hint: 'Ram Bahadur',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) =>
                  v == null || v.isEmpty ? 'Full name is required' : null,
                ),

                const SizedBox(height: AppSpacing.md),

                AppTextField(
                  label: 'Email',
                  hint: 'you@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                AppTextField(
                  label: 'Phone Number',
                  hint: '98XXXXXXXX',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (v) =>
                  v == null || v.isEmpty ? 'Phone number is required' : null,
                ),

                const SizedBox(height: AppSpacing.md),

                AppTextField(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _passwordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                AppTextField(
                  label: 'Confirm Password',
                  hint: '••••••••',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm password';
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // Role selection
                Text('I want to join as', style: AppTypography.headingSmall),
                const SizedBox(height: AppSpacing.sm),
                _RoleSelector(
                  selected: _selectedRole,
                  onChanged: (role) => setState(() => _selectedRole = role),
                ),

                const SizedBox(height: AppSpacing.xl),

                AppButton(
                  label: 'Create Account',
                  isLoading: isLoading,
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

class _RoleSelector extends StatelessWidget {
  final String selected;
  final Function(String) onChanged;

  const _RoleSelector({required this.selected, required this.onChanged});

  static const List<Map<String, dynamic>> _roles = [
    {
      'value': 'customer',
      'label': 'Customer',
      'icon': Icons.person_rounded,
      'desc': 'Order food',
    },
    {
      'value': 'restaurant',
      'label': 'Restaurant',
      'icon': Icons.store_rounded,
      'desc': 'Sell food',
    },
    {
      'value': 'rider',
      'label': 'Rider',
      'icon': Icons.delivery_dining_rounded,
      'desc': 'Deliver food',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _roles.map((role) {
        final isSelected = selected == role['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(role['value'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    role['icon'] as IconData,
                    color: isSelected ? AppColors.white : AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role['label'] as String,
                    style: AppTypography.labelSmall.copyWith(
                      color: isSelected ? AppColors.white : AppColors.primary,
                    ),
                  ),
                  Text(
                    role['desc'] as String,
                    style: AppTypography.bodySmall.copyWith(
                      color: isSelected
                          ? AppColors.white.withOpacity(0.8)
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