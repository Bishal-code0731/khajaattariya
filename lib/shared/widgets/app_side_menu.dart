import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
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
import 'app_snackbar.dart';

class AppSideMenu extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const AppSideMenu({
    super.key,
    required this.onClose,
  });

  @override
  ConsumerState<AppSideMenu> createState() => _AppSideMenuState();
}

class _AppSideMenuState extends ConsumerState<AppSideMenu> {
  // Guards against double navigation if a menu item is tapped more than
  // once before the close animation + delayed push below fires.
  bool _isNavigating = false;

  void _navigate(BuildContext context, String path) {
    if (_isNavigating) return;
    _isNavigating = true;
    widget.onClose();
    Future.delayed(
      const Duration(milliseconds: 300),
          () {
        _isNavigating = false;
        if (context.mounted) context.push(path);
      },
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    widget.onClose();
    AppSnackbar.info(context, '$feature is coming soon');
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authStateProvider).valueOrNull;

    return GestureDetector(
      onTap: widget.onClose,
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
                    // Capped so the drawer doesn't become an absurdly
                    // wide panel on tablets/desktop — 78% of a phone
                    // screen reads fine, 78% of a 1400px window doesn't.
                    width: (MediaQuery.of(context).size.width * 0.78).clamp(0.0, 360.0),
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.85),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        bottomLeft: Radius.circular(28),
                      ),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.6),
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
                                      onTap: widget.onClose,
                                    ),
                                    if (user != null) ...[
                                      _MenuItem(
                                        icon: Icons.receipt_long_outlined,
                                        label: 'My Orders',
                                        onTap: () => _navigate(
                                            context, RouteNames.orders),
                                      ),
                                      _MenuItem(
                                        icon: Icons.notifications_outlined,
                                        label: 'Notifications',
                                        onTap: () => _navigate(
                                            context, RouteNames.notifications),
                                      ),
                                      _MenuItem(
                                        icon: Icons.person_outline_rounded,
                                        label: 'My Profile',
                                        onTap: () => _navigate(
                                            context, RouteNames.profile),
                                      ),
                                      _MenuItem(
                                        icon: Icons.location_on_outlined,
                                        label: 'My Addresses',
                                        onTap: () => _navigate(
                                            context, RouteNames.addressBook),
                                      ),
                                      _MenuItem(
                                        icon: Icons.favorite_outline_rounded,
                                        label: 'Saved Restaurants',
                                        onTap: () => _navigate(
                                            context, RouteNames.favorites),
                                      ),
                                    ],
                                  ]),
                                  const Divider(height: 1),
                                  const SizedBox(height: AppSpacing.sm),
                                  _buildThemeSelector(
                                      context, ref, themeMode),
                                  const Divider(height: 1),
                                  _buildSection([
                                    _MenuItem(
                                      icon: Icons.language_rounded,
                                      label: 'Language',
                                      onTap: () => _comingSoon(context, 'Language'),
                                    ),
                                    _MenuItem(
                                      icon: Icons.star_outline_rounded,
                                      label: 'Rate the App',
                                      onTap: () => _comingSoon(context, 'Rate the App'),
                                    ),
                                    _MenuItem(
                                      icon: Icons.help_outline_rounded,
                                      label: 'Help & Support',
                                      onTap: () => _navigate(context, RouteNames.support),
                                    ),
                                    _MenuItem(
                                      icon: Icons.info_outline_rounded,
                                      label: 'About',
                                      onTap: () => _comingSoon(context, 'About'),
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
                                          widget.onClose();
                                          await ref
                                              .read(authNotifierProvider
                                              .notifier)
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
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
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
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                backgroundImage: user.avatarUrl != null
                    ? CachedNetworkImageProvider(user.avatarUrl!)
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
                        color: user.userRole.color.withValues(alpha: 0.1),
                        borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        user.userRole.label.toUpperCase(),
                        style: AppTypography.labelSmall.copyWith(
                          color: user.userRole.color,
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
                : AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.2),
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