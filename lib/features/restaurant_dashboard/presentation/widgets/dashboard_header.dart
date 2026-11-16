import 'package:flutter/material.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/navigation_extensions.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/language_toggle.dart';
import '../../domain/models/owner_restaurant.dart';
import 'open_status_switch.dart';

/// Restaurant identity, the open/closed switch, quick links and the language switch.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader(
      {super.key,
      required this.restaurant,
      required this.ownerId,
      required this.wide});

  final OwnerRestaurant restaurant;
  final String ownerId;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final identity = _Identity(restaurant: restaurant);
    final links = _QuickLinks(restaurant: restaurant);
    final openSwitch = OpenStatusSwitch(
        restaurant: restaurant, ownerId: ownerId, expand: !wide);

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        bottom: false,
        left: !wide,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            wide ? AppSpacing.xl : AppSpacing.screenHorizontal,
            AppSpacing.md,
            wide ? AppSpacing.xl : AppSpacing.screenHorizontal,
            AppSpacing.md,
          ),
          child: wide
              ? Row(
                  children: [
                    Expanded(child: identity),
                    const SizedBox(width: AppSpacing.lg),
                    links,
                    const SizedBox(width: AppSpacing.lg),
                    openSwitch,
                    const SizedBox(width: AppSpacing.md),
                    const LanguageToggle(),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: identity),
                        const SizedBox(width: AppSpacing.sm),
                        const LanguageToggle(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    openSwitch,
                    const SizedBox(height: AppSpacing.sm),
                    SingleChildScrollView(
                        scrollDirection: Axis.horizontal, child: links),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.restaurant});

  final OwnerRestaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: p.border),
          ),
          child: AppNetworkImage(
            url: restaurant.imageUrl,
            width: 48,
            height: 48,
            fallbackIcon: Icons.storefront_rounded,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(restaurant.name,
                    style: context.text.h2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              if (restaurant.cuisineType.isNotEmpty)
                Text(restaurant.cuisineType,
                    style: context.text.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickLinks extends StatelessWidget {
  const _QuickLinks({required this.restaurant});

  final OwnerRestaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final s = context.s.restaurant;
    Widget link(String label, IconData icon, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: AppButton(
            label: label,
            leadingIcon: icon,
            variant: AppButtonVariant.outline,
            size: AppButtonSize.medium,
            expand: false,
            onPressed: onTap,
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        link(
            s.quickMenu,
            Icons.restaurant_menu_rounded,
            () => context.pushOnce(
                '${RouteNames.menuManagement}/${restaurant.id}',
                extra: restaurant.name)),
        link(
            s.quickHours,
            Icons.schedule_rounded,
            () => context
                .pushOnce('${RouteNames.restaurantHours}/${restaurant.id}')),
        link(s.quickAccount, Icons.person_outline_rounded,
            () => context.pushOnce(RouteNames.profile)),
      ],
    );
  }
}
