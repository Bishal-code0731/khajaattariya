import 'package:flutter/material.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/rating_badge.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../../../cart/domain/delivery_fee_estimate.dart';
import '../../domain/models/restaurant_model.dart';
import 'favourite_button.dart';

String restaurantInfoLine(BuildContext context, RestaurantModel r) {
  final s = context.s.customer;
  const fee = kEstimatedDeliveryFeePerOrder;
  final feeText = fee == 0
      ? s.freeDelivery
      : s.deliveryFeeLine(AppFormat.money(context, fee));
  return '${s.deliveryMinutes(r.deliveryTimeMin)} · $feeText';
}

class RestaurantCard extends StatelessWidget {
  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.onTap,
    this.userId,
    this.isFavourite = false,
  });

  final RestaurantModel restaurant;
  final VoidCallback onTap;

  /// Logged-in user — the favourite heart is shown only when set.
  final String? userId;
  final bool isFavourite;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.customer;
    final r = restaurant;
    final radius = BorderRadius.circular(AppSpacing.radiusLg);

    return Semantics(
      button: true,
      label:
          '${r.name}. ${r.cuisineType}. ${restaurantInfoLine(context, r)}${r.isOpen ? '' : '. ${s.closedNow}'}',
      child: Material(
        color: p.surface,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
                borderRadius: radius, border: Border.all(color: p.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: AppSpacing.restaurantCardImageAspect,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ExcludeSemantics(
                        child: ColorFiltered(
                          colorFilter: r.isOpen
                              ? const ColorFilter.mode(
                                  AppColors.transparent, BlendMode.dst)
                              : const ColorFilter.matrix(_greyscale),
                          child: AppNetworkImage(
                              url: r.imageUrl,
                              fallbackIcon: Icons.storefront_rounded),
                        ),
                      ),
                      if (!r.isOpen)
                        Positioned(
                          left: AppSpacing.md,
                          top: AppSpacing.md,
                          child: _PhotoTag(
                            icon: Icons.schedule_rounded,
                            label: s.closedNow,
                            bg: AppColors.black.withValues(alpha: 0.7),
                            fg: AppColors.white,
                          ),
                        ),
                      if (r.hasOffer)
                        Positioned(
                          left: AppSpacing.md,
                          bottom: AppSpacing.md,
                          right: 64,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _PhotoTag(
                              icon: Icons.local_offer_rounded,
                              label: r.offer!.trim(),
                              bg: AppColors.marigold,
                              fg: p.onAccent,
                            ),
                          ),
                        ),
                      if (userId != null)
                        Positioned(
                          right: AppSpacing.xs,
                          top: AppSpacing.xs,
                          child: FavouriteButton(
                            userId: userId!,
                            restaurantId: r.id,
                            isFavourite: isFavourite,
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                      AppSpacing.md, AppSpacing.md, AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(r.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.h3),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          RatingBadge(
                              rating: r.rating,
                              count: r.reviewCount,
                              newLabel: s.newRestaurant),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        r.cuisineType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.caption,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(Icons.delivery_dining_rounded,
                              size: 16, color: p.brand),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              restaurantInfoLine(context, r),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelSmall
                                  .copyWith(color: p.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const List<double> _greyscale = [
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0,
];

class _PhotoTag extends StatelessWidget {
  const _PhotoTag(
      {required this.icon,
      required this.label,
      required this.bg,
      required this.fg});

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(AppSpacing.radiusXs)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall.copyWith(color: fg)),
          ),
        ],
      ),
    );
  }
}

/// Skeleton matching [RestaurantCard].
class RestaurantCardSkeleton extends StatelessWidget {
  const RestaurantCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: AppSpacing.restaurantCardImageAspect,
          child: AppShimmer(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        ),
        const SizedBox(height: AppSpacing.md),
        const AppShimmer(height: 16, width: 180),
        const SizedBox(height: AppSpacing.sm),
        const AppShimmer(height: 12, width: 120),
        const SizedBox(height: AppSpacing.sm),
        const AppShimmer(height: 12, width: 150),
      ],
    );
  }
}
