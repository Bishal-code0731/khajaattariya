import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/s.dart';
import '../../../core/router/navigation_extensions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/glass_bottom_nav.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../auth/application/auth_provider.dart';
import '../../cart/presentation/widgets/view_cart_bar.dart';
import '../application/offers_provider.dart';
import '../application/restaurant_provider.dart';
import 'widgets/offer_coupon_tile.dart';
import 'widgets/offers_carousel.dart';
import 'widgets/restaurant_card.dart';

class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RouteNames.home);
      case 2:
        context.pushOnce(RouteNames.orders);
      case 3:
        context.pushOnce(RouteNames.profile);
    }
  }

  void _openBanner(BuildContext context, Map<String, dynamic> banner) {
    final id = banner['restaurant_id'] as String?;
    if (id != null && id.isNotEmpty) {
      context.pushOnce('${RouteNames.restaurant}/$id');
    }
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(availableCouponsProvider);
    ref.invalidate(bannersProvider);
    await ref.read(restaurantsProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s.customer;
    final p = context.palette;
    final user = ref.watch(authStateProvider).valueOrNull;
    final banners = ref.watch(bannersProvider).valueOrNull ?? const [];
    final coupons = ref.watch(availableCouponsProvider);
    final restaurants = ref.watch(restaurantsProvider);
    final deals = (restaurants.valueOrNull ?? const [])
        .where((r) => (r.offer ?? '').trim().isNotEmpty)
        .toList();

    Widget constrained(Widget child) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: child,
          ),
        );

    Widget couponsSection() {
      if (user == null) {
        return AppCard(
          child: Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: p.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.loginForCouponsTitle,
                        style: AppTypography.headingSmall
                            .copyWith(color: p.textPrimary)),
                    Text(s.loginForCouponsBody,
                        style: AppTypography.bodySmall
                            .copyWith(color: p.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                label: context.s.common.login,
                size: AppButtonSize.small,
                variant: AppButtonVariant.tonal,
                expand: false,
                onPressed: () => context.push(RouteNames.login),
              ),
            ],
          ),
        );
      }
      return coupons.when(
        loading: () => const Column(children: [
          AppShimmer(height: 120),
          SizedBox(height: AppSpacing.md),
          AppShimmer(height: 120),
        ]),
        error: (e, _) => AppErrorState(
            error: e, onRetry: () => ref.invalidate(availableCouponsProvider)),
        data: (list) => list.isEmpty
            ? Text(s.noCoupons,
                style:
                    AppTypography.bodyMedium.copyWith(color: p.textSecondary))
            : Column(children: [
                for (final c in list) ...[
                  OfferCouponTile(coupon: c),
                  const SizedBox(height: AppSpacing.md),
                ],
              ]),
      );
    }

    return Scaffold(
      appBar: AppTopBar(
          title: s.offersPageTitle,
          subtitle: s.offersSubtitle,
          showBack: false),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: [
            if (banners.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              OffersCarousel(
                  banners: banners, onTap: (b) => _openBanner(context, b)),
            ],
            constrained(SectionHeader(
                title: s.couponsSection, subtitle: s.couponsHint)),
            constrained(Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal),
              child: couponsSection(),
            )),
            constrained(SectionHeader(
                title: s.restaurantDealsSection,
                subtitle: s.restaurantDealsHint)),
            constrained(Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal),
              child: restaurants.isLoading && deals.isEmpty
                  ? const RestaurantCardSkeleton()
                  : deals.isEmpty
                      ? Text(s.noRestaurantDeals,
                          style: AppTypography.bodyMedium
                              .copyWith(color: p.textSecondary))
                      : Column(children: [
                          for (final r in deals) ...[
                            RestaurantCard(
                              restaurant: r,
                              onTap: () => context
                                  .pushOnce('${RouteNames.restaurant}/${r.id}'),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ]),
            )),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ViewCartBar(safeArea: false),
          GlassBottomNav(
            currentIndex: 1,
            onTap: (i) => _onNavTap(context, i),
            items: customerNavItems(context),
          ),
        ],
      ),
    );
  }
}

/// The customer bottom-nav items, shared by Home and Offers.
List<GlassNavItem> customerNavItems(BuildContext context) {
  final s = context.s.customer;
  return [
    GlassNavItem(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: s.navHome),
    GlassNavItem(
        icon: Icons.local_offer_outlined,
        selectedIcon: Icons.local_offer_rounded,
        label: s.navOffers),
    GlassNavItem(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long_rounded,
        label: s.navOrders),
    GlassNavItem(
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: s.navAccount),
  ];
}
