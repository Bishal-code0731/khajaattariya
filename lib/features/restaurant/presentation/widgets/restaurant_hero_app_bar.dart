import 'package:flutter/material.dart';
import '../../../../core/router/navigation_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/language_toggle.dart';
import '../../../home/domain/models/restaurant_model.dart';
import '../../../home/presentation/widgets/favourite_button.dart';

/// Collapsing photo header.
class RestaurantHeroAppBar extends StatelessWidget {
  const RestaurantHeroAppBar({
    super.key,
    required this.restaurant,
    required this.collapsed,
    required this.expandedHeight,
    this.userId,
    this.isFavourite = false,
  });

  final RestaurantModel restaurant;
  final bool collapsed;
  final double expandedHeight;
  final String? userId;
  final bool isFavourite;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final chip = collapsed
        ? null
        : IconButton.styleFrom(
            backgroundColor: AppColors.black.withValues(alpha: 0.42));
    final fg = collapsed ? p.textPrimary : AppColors.white;

    return SliverAppBar(
      pinned: true,
      expandedHeight: expandedHeight,
      automaticallyImplyLeading: false,
      backgroundColor: p.surface,
      surfaceTintColor: p.surface,
      scrolledUnderElevation: 0,
      shape: collapsed ? Border(bottom: BorderSide(color: p.border)) : null,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.xs),
        child: Center(
          child: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            style: chip,
            icon: Icon(Icons.arrow_back_rounded, color: fg),
            onPressed: () => context.safeBack(),
          ),
        ),
      ),
      title: AnimatedOpacity(
        opacity: collapsed ? 1 : 0,
        duration: AppMotion.fast,
        child: Text(restaurant.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.h2),
      ),
      actions: [
        if (userId != null)
          FavouriteButton(
            userId: userId!,
            restaurantId: restaurant.id,
            isFavourite: isFavourite,
            overPhoto: !collapsed,
          ),
        const SizedBox(width: AppSpacing.xs),
        Center(child: LanguageToggle(onDark: !collapsed)),
        const SizedBox(width: AppSpacing.md),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            AppNetworkImage(
              url: restaurant.imageUrl,
              fallbackIcon: Icons.storefront_rounded,
              semanticLabel: restaurant.name,
            ),
            // Top scrim keeps the back / favourite / language controls readable on bright photos.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    AppColors.black.withValues(alpha: 0.5),
                    AppColors.transparent
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
