import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_language.dart';
import '../../../core/l10n/s.dart';
import '../../../core/router/navigation_extensions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../auth/application/auth_provider.dart';
import '../../auth/domain/models/user_model.dart';
import '../../notifications/application/notification_provider.dart';
import '../application/profile_provider.dart';
import 'widgets/account_menu.dart';
import 'widgets/edit_profile_sheet.dart';
import 'widgets/profile_header.dart';
import 'widgets/settings_sheets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploadingPhoto = false;
  bool _signingOut = false;

  Future<void> _changePhoto(UserModel user) async {
    if (_uploadingPhoto) return;
    setState(() => _uploadingPhoto = true);
    try {
      final url = await ref
          .read(profileUpdateProvider.notifier)
          .pickAndUploadAvatar(user.id);
      if (url != null) {
        ref.invalidate(authStateProvider);
        if (mounted) {
          AppSnackbar.success(context, context.s.account.photoUpdated);
        }
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _logout() async {
    if (_signingOut) return;
    final a = context.s.account;
    final ok = await AppDialog.confirm(
      context,
      title: a.logoutTitle,
      message: a.logoutMessage,
      confirmLabel: context.s.common.logout,
      destructive: true,
      icon: Icons.logout_rounded,
    );
    if (!ok || !mounted) return;
    setState(() => _signingOut = true);
    await ref.read(authNotifierProvider.notifier).signOut();
    if (!mounted) return;
    final result = ref.read(authNotifierProvider);
    if (result.hasError) {
      setState(() => _signingOut = false);
      AppSnackbar.error(context, result.error);
      return;
    }
    context.go(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);
    return Scaffold(
      appBar: AppTopBar(title: context.s.account.accountTitle),
      body: userAsync.when(
        loading: () => const AppShimmerCardList(count: 3, itemHeight: 72),
        error: (e, _) => AppErrorState(
            error: e, onRetry: () => ref.invalidate(authStateProvider)),
        data: (user) {
          if (user == null) {
            return const AppShimmerCardList(count: 3, itemHeight: 72);
          }
          return _buildHub(context, user);
        },
      ),
    );
  }

  Widget _buildHub(BuildContext context, UserModel user) {
    final a = context.s.account;
    final c = context.s.common;
    final p = context.palette;
    final role = user.userRole;
    final language = ref.watch(languageNotifierProvider);
    final themeMode = ref.watch(themeNotifierProvider);
    final unread = ref.watch(unreadCountProvider(user.id)).valueOrNull ?? 0;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
            AppSpacing.screenHorizontal,
            AppSpacing.xxxl,
          ),
          children: [
            AppCard(
              child: ProfileHeader(
                user: user,
                isUploadingPhoto: _uploadingPhoto,
                onChangePhoto: () => _changePhoto(user),
                onEdit: () => showEditProfileSheet(context, user),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (!user.isCustomer) ...[
              AccountMenuGroup(
                title: a.sectionWork,
                children: [
                  AccountMenuTile(
                    icon: Icons.space_dashboard_outlined,
                    title: a.backToDashboard,
                    subtitle: a.backToDashboardSub,
                    onTap: () => context.go(role.homeRoute),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            if (user.isCustomer) ...[
              AccountMenuGroup(
                title: a.sectionOrders,
                children: [
                  AccountMenuTile(
                    icon: Icons.receipt_long_outlined,
                    title: a.myOrders,
                    subtitle: a.myOrdersSub,
                    onTap: () => context.pushOnce(RouteNames.orders),
                  ),
                  AccountMenuTile(
                    icon: Icons.location_on_outlined,
                    title: a.savedAddresses,
                    subtitle: a.savedAddressesSub,
                    onTap: () => context.pushOnce(RouteNames.addressBook),
                  ),
                  AccountMenuTile(
                    icon: Icons.favorite_border_rounded,
                    title: a.savedRestaurants,
                    subtitle: a.savedRestaurantsSub,
                    onTap: () => context.pushOnce(RouteNames.favorites),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            AccountMenuGroup(
              title: a.sectionActivity,
              children: [
                AccountMenuTile(
                  icon: Icons.notifications_none_rounded,
                  title: a.notifications,
                  subtitle: a.notificationsSub,
                  badgeCount: unread,
                  onTap: () => context.pushOnce(RouteNames.notifications),
                ),
                AccountMenuTile(
                  icon: Icons.support_agent_rounded,
                  title: a.helpSupport,
                  subtitle: a.helpSupportSub,
                  onTap: () => context.pushOnce(RouteNames.support),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AccountMenuGroup(
              title: a.sectionSettings,
              children: [
                AccountMenuTile(
                  icon: Icons.translate_rounded,
                  title: c.language,
                  value: language.nativeName,
                  onTap: () => showLanguageSheet(context),
                ),
                AccountMenuTile(
                  icon: Icons.contrast_rounded,
                  title: c.theme,
                  value: themeModeLabel(context, themeMode),
                  onTap: () => showAppearanceSheet(context),
                ),
                AccountMenuTile(
                  icon: Icons.info_outline_rounded,
                  title: a.about,
                  value: appVersion,
                  onTap: () => showAboutSheet(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: c.logout,
              onPressed: _logout,
              isLoading: _signingOut,
              variant: AppButtonVariant.outline,
              color: p.error,
              leadingIcon: Icons.logout_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
