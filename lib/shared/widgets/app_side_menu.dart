import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../features/auth/application/auth_provider.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../providers/theme_provider.dart';

class AppSideMenu extends ConsumerWidget {
  final VoidCallback onClose;

  const AppSideMenu({
    super.key,
    required this.onClose,
  });

  void _navigate(BuildContext context, String path) {
    onClose();
    Future.delayed(
      const Duration(milliseconds: 300),
          () {
        if (context.mounted) context.go(path);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authStateProvider).valueOrNull;

    return GestureDetector(
      onTap: onClose,
      child: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: AppColors.overlay30),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {},
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  bottomLeft: Radius.circular(28),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.78,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.white.withOpacity(0.85),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        bottomLeft: Radius.circular(28),
                      ),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.12)
                            : Colors.white.withOpacity(0.6),
                        width: 1,
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          user != null
                              ? _buildLoggedInHeader(context, ref, user)
                              : _buildGuestHeader(context),
                          const Divider(height: 1),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSection([
                                    _MenuItem(
                                      icon: Icons.home_rounded,
                                      label: 'Home',
                                      onTap: onClose,
                                    ),
                                    if (user != null) ...[
                                      _MenuItem(
                                        icon: Icons.receipt_long_outlined,
                                        label: 'My Orders',
                                        onTap: () => _navigate(
                                            context, RouteNames.orders),
                                      ),
                                      _MenuItem(
                                        icon: Icons.person_outline_rounded,
                                        label: 'My Profile',
                                        onTap: () => _navigate(
                                            context, RouteNames.profile),
                                      ),
                                    ],
                                    _MenuItem(
                                      icon: Icons.location_on_outlined,
                                      label: 'My Addresses',
                                      onTap: () {},
                                    ),
                                    _MenuItem(
                                      icon: Icons.favorite_outline_rounded,
                                      label: 'Saved Items',
                                      onTap: () {},
                                    ),
                                  ]),
                                  const Divider(height: 1),
                                  const SizedBox(height: AppSpacing.sm),
                                  _buildThemeSelector(context, ref, themeMode),
                                  const Divider(height: 1),
                                  _buildSection([
                                    _MenuItem(
                                      icon: Icons.language_rounded,
                                      label: 'Language',
                                      onTap: () {},
                                    ),
                                    _MenuItem(
                                      icon: Icons.star_outline_rounded,
                                      label: 'Rate the App',
                                      onTap: () {},
                                    ),
                                    _MenuItem(
                                      icon: Icons.help_outline_rounded,
                                      label: 'Help & Support',
                                      onTap: () {},
                                    ),
                                    _MenuItem(
                                      icon: Icons.info_outline_rounded,
                                      label: 'About',
                                      onTap: () {},
                                    ),
                                  ]),
                                  if (user != null) ...[
                                    const Divider(height: 1),
                                    _buildSection([
                                      _MenuItem(
                                        icon: Icons.logout_rounded,
                                        label: 'Logout',
                                        color: AppColors.error,
                                        onTap: () async {
                                          onClose();
                                          await ref
                                              .read(
                                              authNotifierProvider.notifier)
                                              .signOut();
                                        },
                                      ),
                                    ]),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          _buildVersion(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogo(),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome to Khaja!',
                    style: AppTypography.headingSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Login or sign up to order food and track deliveries.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => _navigate(context, RouteNames.login),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                    ),
                    child: const Text('Login / Sign Up'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedInHeader(
      BuildContext context, WidgetRef ref, UserModel user) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogo(),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                backgroundImage: user.avatarUrl != null
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? Text(
                  user.fullName.isNotEmpty
                      ? user.fullName[0].toUpperCase()
                      : '?',
                  style: AppTypography.headingSmall
                      .copyWith(color: AppColors.primary),
                )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: AppTypography.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: AppTypography.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        user.role.toUpperCase(),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.restaurant_rounded,
              color: AppColors.white, size: 22),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Text('Khaja Attariya', style: AppTypography.headingSmall),
      ],
    );
  }

  Widget _buildSection(List<_MenuItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: items.map((item) => _buildTile(item)).toList(),
      ),
    );
  }

  Widget _buildTile(_MenuItem item) {
    final color = item.color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(item.icon, color: color, size: 22),
      title: Text(item.label,
          style: AppTypography.bodyLarge.copyWith(color: color)),
      trailing: item.color == null
          ? const Icon(Icons.chevron_right_rounded,
          color: AppColors.textHint, size: 20)
          : null,
      onTap: item.onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
    );
  }

  Widget _buildThemeSelector(
      BuildContext context, WidgetRef ref, AppThemeMode currentMode) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.palette_outlined,
                  size: 22, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              const Text('App Theme', style: AppTypography.bodyLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _ThemeOption(
                label: 'Light',
                icon: Icons.light_mode_rounded,
                isSelected: currentMode == AppThemeMode.light,
                onTap: () => ref
                    .read(themeNotifierProvider.notifier)
                    .setTheme(AppThemeMode.light),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ThemeOption(
                label: 'Dark',
                icon: Icons.dark_mode_rounded,
                isSelected: currentMode == AppThemeMode.dark,
                onTap: () => ref
                    .read(themeNotifierProvider.notifier)
                    .setTheme(AppThemeMode.dark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVersion() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text('Khaja Attariya v1.0.0', style: AppTypography.bodySmall),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.primary.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20,
                  color: isSelected ? AppColors.white : AppColors.primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? AppColors.white : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}