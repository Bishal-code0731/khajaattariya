import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/router/navigation_extensions.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/language_toggle.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../notifications/application/notification_provider.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.user});

  final UserModel? user;

  String _greeting(BuildContext context) {
    final s = context.s.customer;
    final h = DateTime.now().hour;
    final g = h < 12
        ? s.greetingMorning
        : (h < 17 ? s.greetingAfternoon : s.greetingEvening);
    final first = user?.fullName.trim().split(RegExp(r'\s+')).first ?? '';
    return first.isEmpty ? g : s.greetingWithName(g, first);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.customer;
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;

    return SliverAppBar(
      floating: true,
      snap: true,
      automaticallyImplyLeading: false,
      backgroundColor: p.background,
      surfaceTintColor: p.background,
      scrolledUnderElevation: 0,
      toolbarHeight: 56 + 16 * scale,
      titleSpacing: AppSpacing.screenHorizontal,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 16, color: p.brand),
              const SizedBox(width: AppSpacing.xxs),
              Flexible(
                child: Text(
                  s.deliveringIn,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(color: p.brand),
                ),
              ),
            ],
          ),
          Text(
            _greeting(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.h2,
          ),
        ],
      ),
      actions: [
        const Center(child: LanguageToggle()),
        const SizedBox(width: AppSpacing.xs),
        if (user != null)
          _NotificationBell(userId: user!.id)
        else
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: Center(
              child: AppButton(
                label: context.s.common.login,
                size: AppButtonSize.small,
                variant: AppButtonVariant.tonal,
                expand: false,
                onPressed: () => context.pushOnce(RouteNames.login),
              ),
            ),
          ),
        const SizedBox(width: AppSpacing.sm),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(40 + 24 * scale),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
              AppSpacing.xs, AppSpacing.screenHorizontal, AppSpacing.sm),
          child: AppSearchField(
            hint: s.searchHint,
            readOnly: true,
            onTap: () => context.pushOnce(RouteNames.search),
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s.customer;
    final unread = ref.watch(unreadCountProvider(userId)).valueOrNull ?? 0;
    return IconButton(
      tooltip: unread > 0 ? s.notificationsUnread(unread) : s.notifications,
      onPressed: () => context.pushOnce(RouteNames.notifications),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: const Icon(Icons.notifications_none_rounded),
      ),
    );
  }
}
