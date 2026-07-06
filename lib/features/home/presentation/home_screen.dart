import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/navigation_extensions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/cart/application/cart_notifier.dart';
import '../../../shared/widgets/app_side_menu.dart';
import '../../../shared/widgets/glass_bottom_nav.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../application/restaurant_provider.dart';
import '../domain/models/category_model.dart';
import '../domain/models/food_item_model.dart';
import 'widgets/category_section.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/home_search_bar.dart';
import 'widgets/nearby_restaurants_section.dart';
import 'widgets/popular_foods_section.dart';
import 'widgets/promo_banner_slider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentNavIndex = 0;
  bool _menuOpen = false;
  CategoryModel? _selectedCategory;

  late AnimationController _menuController;
  late Animation<Offset> _menuSlideAnimation;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _menuSlideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutCubic,
    ));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _menuController.dispose();
    super.dispose();
  }

  // Triggers the next page of restaurants once the user is close to the
  // bottom of the list, instead of fetching every restaurant up front.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      ref.read(restaurantsProvider.notifier).loadMore();
    }
  }

  void _openMenu() {
    setState(() => _menuOpen = true);
    _menuController.forward();
  }

  void _closeMenu() {
    _menuController.reverse().then((_) {
      if (mounted) setState(() => _menuOpen = false);
    });
  }

  void _onAddToCart(FoodItemModel item) {
    ref.read(cartNotifierProvider.notifier).addItem(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _onBannerTap(Map<String, dynamic> banner) {
    final restaurantId = banner['restaurant_id'] as String?;
    if (restaurantId != null && restaurantId.isNotEmpty) {
      context.pushOnce('${RouteNames.restaurant}/$restaurantId');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('More offers coming soon'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(restaurantsProvider);
    final selectedCategory = _selectedCategory;
    // When a category is selected, the "Popular Items" section switches
    // to that category's foods instead; "All" (null) shows the usual
    // cross-restaurant popular list.
    final popularAsync = selectedCategory == null
        ? ref.watch(popularItemsProvider)
        : ref.watch(foodsByCategoryProvider(selectedCategory.id));
    // .select: this widget only needs the item count, not the whole cart
    // (items/restaurant/etc) — avoids rebuilding the app bar + full
    // scroll view on every quantity change inside the cart screen.
    final cartCount =
        ref.watch(cartNotifierProvider.select((c) => c.totalItems));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    HomeAppBar(
                      cartItemCount: cartCount,
                      onNotificationTap: () =>
                          context.push(RouteNames.notifications),
                      onCartTap: () => context.push(RouteNames.cart),
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.sm),
                          HomeSearchBar(
                              onTap: () => context.push(RouteNames.search)),
                          const SizedBox(height: AppSpacing.md),
                          ref.watch(bannersProvider).when(
                                loading: () => const SizedBox(height: 160),
                                error: (_, __) => const SizedBox.shrink(),
                                data: (banners) => banners.isEmpty
                                    ? const SizedBox.shrink()
                                    : PromoBannerSlider(
                                        banners: banners,
                                        onBannerTap: _onBannerTap,
                                      ),
                              ),
                          const SizedBox(height: AppSpacing.lg),
                          CategorySection(
                            onCategorySelected: (cat) =>
                                setState(() => _selectedCategory = cat),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Restaurants — only this section shows a
                          // loading state; the rest of the screen (search
                          // bar, banners, categories) stays interactive
                          // and doesn't wait on it.
                          restaurantsAsync.when(
                            loading: () => const _HorizontalCardShimmer(),
                            error: (e, _) => Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Center(
                                child: Text('Could not load restaurants',
                                    style: TextStyle(
                                        color: AppColors.textSecondary)),
                              ),
                            ),
                            data: (restaurants) => NearbyRestaurantsSection(
                              restaurants: restaurants,
                              onRestaurantTap: (r) => context
                                  .pushOnce('${RouteNames.restaurant}/${r.id}'),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Popular items / category-filtered items
                          popularAsync.when(
                            loading: () => const SizedBox(
                              height: 280,
                              child: AppShimmerCardList(count: 3, itemHeight: 64),
                            ),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (items) => items.isEmpty && selectedCategory != null
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.screenHorizontal),
                                    child: Text(
                                      'No ${selectedCategory.name} items available right now',
                                      style: AppTypography.bodyMedium,
                                    ),
                                  )
                                : PopularFoodsSection(
                                    title: selectedCategory == null
                                        ? 'Popular Items'
                                        : selectedCategory.name,
                                    items: items,
                                    onAddToCart: _onAddToCart,
                                  ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_menuOpen)
                  SlideTransition(
                    position: _menuSlideAnimation,
                    child: AppSideMenu(onClose: _closeMenu),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          // Only "Home" (0) is actually a persistent tab on this screen;
          // Search/Cart/Menu are separate destinations, so they push a
          // new route instead of silently changing the highlighted icon
          // and doing nothing (the bug this replaces).
          switch (index) {
            case 0:
              break; // already home
            case 1:
              context.pushOnce(RouteNames.search);
              break;
            case 2:
              context.pushOnce(RouteNames.cart);
              break;
            case 3:
              _openMenu();
              break;
          }
        },
      ),
    );
  }
}

/// Horizontal shimmer strip shaped like [NearbyRestaurantsSection]'s
/// cards, shown only while [restaurantsProvider] has no cached/fresh
/// data yet.
class _HorizontalCardShimmer extends StatelessWidget {
  const _HorizontalCardShimmer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, __) => AppShimmer(
          width: 210,
          height: 230,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
    );
  }
}
