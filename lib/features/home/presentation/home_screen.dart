import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/s.dart';
import '../../../core/router/navigation_extensions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/glass_bottom_nav.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/application/auth_provider.dart';
import '../../cart/application/cart_notifier.dart';
import '../../cart/presentation/widgets/view_cart_bar.dart';
import '../application/restaurant_filter.dart';
import '../application/restaurant_provider.dart';
import '../domain/models/category_model.dart';
import '../domain/models/food_item_model.dart';
import 'offers_screen.dart';
import 'widgets/category_rail.dart';
import 'widgets/favourite_button.dart';
import 'widgets/home_header.dart';
import 'widgets/offers_carousel.dart';
import 'widgets/popular_dishes_rail.dart';
import 'widgets/restaurant_card.dart';
import 'widgets/restaurant_filter_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();
  CategoryModel? _category;
  RestaurantFilter _filter = const RestaurantFilter();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_maybeLoadMore);
    _scrollController.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      ref.read(restaurantsProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(bannersProvider);
    if (_category != null) {
      ref.invalidate(foodsByCategoryProvider(_category!.id));
    }
    try {
      await Future.wait([
        ref.read(restaurantsProvider.notifier).refresh(),
        ref.read(popularItemsProvider.notifier).refresh(),
        ref.read(categoriesProvider.notifier).refresh(),
      ]);
    } catch (_) {
      // Each list keeps showing what it had; the offline banner explains.
    }
  }

  void _openRestaurant(String id) =>
      context.pushOnce('${RouteNames.restaurant}/$id');

  void _onBannerTap(Map<String, dynamic> banner) {
    final restaurantId = banner['restaurant_id'] as String?;
    if (restaurantId != null && restaurantId.isNotEmpty) {
      _openRestaurant(restaurantId);
    } else {
      AppSnackbar.info(context, context.s.customer.offerComingSoon);
    }
  }

  void _addDish(FoodItemModel item) {
    if (!item.restaurantOpen) {
      AppSnackbar.warning(context, context.s.customer.restaurantClosedCantAdd);
      return;
    }
    ref.read(cartNotifierProvider.notifier).addItem(item);
  }

  void _onNavTap(int index) {
    switch (index) {
      case 1:
        context.go(RouteNames.offers);
      case 2:
        context.pushOnce(RouteNames.orders);
      case 3:
        context.pushOnce(RouteNames.profile);
    }
  }

  void _clearAllFilters() => setState(() {
        _filter = const RestaurantFilter();
        _category = null;
      });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      backgroundColor: p.background,
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                child: LayoutBuilder(
                  builder: (context, constraints) => RefreshIndicator(
                    onRefresh: _refresh,
                    color: p.brand,
                    edgeOffset: 120,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        HomeHeader(user: user),
                        ..._categorySlivers(),
                        ..._offerSlivers(),
                        ..._dishSlivers(),
                        ..._restaurantSlivers(constraints.maxWidth, user?.id),
                        const SliverToBoxAdapter(
                            child: SizedBox(height: AppSpacing.xl)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ViewCartBar(safeArea: false),
          GlassBottomNav(
            currentIndex: 0,
            onTap: _onNavTap,
            items: customerNavItems(context),
          ),
        ],
      ),
    );
  }

  // Categories
  List<Widget> _categorySlivers() {
    final async = ref.watch(categoriesProvider);
    final s = context.s.customer;
    final categories = async.valueOrNull;
    if (async.isLoading && categories == null) {
      return const [
        SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        SliverToBoxAdapter(child: CategoryRailSkeleton()),
      ];
    }
    if (categories == null || categories.isEmpty) return const [];
    return [
      SliverToBoxAdapter(
        child: SectionHeader(
          title: s.categoriesTitle,
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
              AppSpacing.lg, AppSpacing.screenHorizontal, AppSpacing.sm),
        ),
      ),
      SliverToBoxAdapter(
        child: CategoryRail(
          categories: categories,
          selectedId: _category?.id,
          onSelected: (c) => setState(() => _category = c),
        ),
      ),
    ];
  }

  // Offers
  List<Widget> _offerSlivers() {
    final async = ref.watch(bannersProvider);
    final s = context.s.customer;
    final banners = async.valueOrNull;
    if (async.isLoading && banners == null) {
      return const [
        SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        SliverToBoxAdapter(child: OffersCarouselSkeleton()),
      ];
    }
    if (banners == null || banners.isEmpty) return const [];
    return [
      SliverToBoxAdapter(child: SectionHeader(title: s.offersTitle)),
      SliverToBoxAdapter(
          child: OffersCarousel(banners: banners, onTap: _onBannerTap)),
    ];
  }

  // Popular / category dishes
  AsyncValue<List<FoodItemModel>> _watchDishes() => _category == null
      ? ref.watch(popularItemsProvider)
      : ref.watch(foodsByCategoryProvider(_category!.id));

  List<Widget> _dishSlivers() {
    final s = context.s.customer;
    final async = _watchDishes();
    final items = async.valueOrNull;
    final category = _category;
    final header = SliverToBoxAdapter(
      child: SectionHeader(
        title: category == null
            ? s.popularTitle
            : s.categoryDishesTitle(category.name),
        subtitle: category == null ? s.popularSubtitle : null,
      ),
    );
    if (async.isLoading && items == null) {
      return [header, const SliverToBoxAdapter(child: PopularDishesSkeleton())];
    }
    if (items == null || items.isEmpty) {
      if (category == null) return const [];
      return [
        header,
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal),
            child: Text(s.noDishesInCategory(category.name),
                style: context.text.secondary),
          ),
        ),
      ];
    }
    return [
      header,
      SliverToBoxAdapter(
        child: PopularDishesRail(
          items: items,
          onAdd: _addDish,
          onOpenRestaurant: (item) => _openRestaurant(item.restaurantId),
        ),
      ),
    ];
  }

  // Restaurants
  List<Widget> _restaurantSlivers(double width, String? userId) {
    final p = context.palette;
    final s = context.s.customer;
    final async = ref.watch(restaurantsProvider);
    final notifier = ref.read(restaurantsProvider.notifier);
    final all = async.valueOrNull;

    // With a category picked, only restaurants that serve it.
    Set<String>? onlyIds;
    var categoryPending = false;
    if (_category != null) {
      final dishes = _watchDishes();
      onlyIds = dishes.valueOrNull?.map((d) => d.restaurantId).toSet();
      categoryPending = onlyIds == null && dishes.isLoading;
    }
    final visible = all == null ? null : _filter.apply(all, onlyIds: onlyIds);

    final columns = width >= 1000 ? 3 : (width >= 600 ? 2 : 1);
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;

    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: SectionHeader(
          title: _category == null
              ? s.restaurantsTitle
              : s.restaurantsServing(_category!.name),
          subtitle: visible == null ? null : s.restaurantsCount(visible.length),
        ),
      ),
      SliverPersistentHeader(
        pinned: true,
        delegate: RestaurantFilterBarDelegate(
          extent: 40 + 16 * scale + AppSpacing.sm,
          background: p.background,
          border: p.border,
          child: RestaurantFilterBar(
              filter: _filter, onChanged: (f) => setState(() => _filter = f)),
        ),
      ),
    ];

    if ((async.isLoading && all == null) || categoryPending) {
      slivers.add(_rows(columns,
          List.generate(columns * 2, (_) => const RestaurantCardSkeleton())));
      return slivers;
    }
    if (all == null) {
      slivers.add(SliverToBoxAdapter(
        child: AppErrorState(
            error: async.error, onRetry: () => notifier.refresh()),
      ));
      return slivers;
    }
    if (all.isEmpty) {
      slivers.add(SliverToBoxAdapter(
        child: AppEmptyState(
          icon: Icons.storefront_outlined,
          title: s.noRestaurantsTitle,
          subtitle: s.noRestaurantsBody,
        ),
      ));
      return slivers;
    }
    if (visible!.isEmpty) {
      slivers.add(SliverToBoxAdapter(
        child: AppEmptyState(
          icon: Icons.filter_alt_off_outlined,
          title: s.noMatchesTitle,
          subtitle: s.noMatchesBody,
          action: AppButton(
            label: s.clearFilters,
            variant: AppButtonVariant.outline,
            expand: false,
            onPressed: _clearAllFilters,
          ),
        ),
      ));
      if (notifier.hasMore) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMore());
      }
      return slivers;
    }

    final favIds = watchFavouriteIds(ref, userId);
    slivers.add(_rows(columns, [
      for (final r in visible)
        RestaurantCard(
          key: ValueKey(r.id),
          restaurant: r,
          userId: userId,
          isFavourite: favIds.contains(r.id),
          onTap: () => _openRestaurant(r.id),
        ),
    ]));

    if (notifier.hasMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMore());
      slivers.add(_rows(columns,
          List.generate(columns, (_) => const RestaurantCardSkeleton())));
    } else {
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          child: Text(s.endOfList,
              textAlign: TextAlign.center, style: context.text.hint),
        ),
      ));
    }
    return slivers;
  }

  /// Lays cards out in rows of [columns] (cards keep their natural height).
  Widget _rows(int columns, List<Widget> cards) {
    final rowCount = (cards.length / columns).ceil();
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
          AppSpacing.sm, AppSpacing.screenHorizontal, 0),
      sliver: SliverList.separated(
        itemCount: rowCount,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
        itemBuilder: (context, row) {
          if (columns == 1) return cards[row];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: row * columns + c < cards.length
                      ? cards[row * columns + c]
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
