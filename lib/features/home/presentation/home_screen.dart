import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/dummy_data.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/cart/application/cart_notifier.dart';
import '../../../shared/widgets/app_side_menu.dart';
import '../../../shared/widgets/glass_bottom_nav.dart';
import '../application/restaurant_provider.dart';
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

  late AnimationController _menuController;
  late Animation<Offset> _menuSlideAnimation;

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
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
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
    final added = ref.read(cartNotifierProvider.notifier).addItem(item);
    if (added) {
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
    // Conflict handled inside CartNotifier — home screen just ignores false
    // since user is not in a restaurant context here
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(restaurantsProvider);
    final popularAsync = ref.watch(popularItemsProvider);
    final cartCount = ref.watch(cartNotifierProvider).totalItems;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              HomeAppBar(
                cartItemCount: cartCount,
                onNotificationTap: () {},
                onCartTap: () => context.go(RouteNames.cart),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    HomeSearchBar(onTap: () => context.go(RouteNames.search)),
                    const SizedBox(height: AppSpacing.md),
                    PromoBannerSlider(banners: DummyData.promoBanners),
                    const SizedBox(height: AppSpacing.lg),
                    CategorySection(onCategorySelected: (_) {}),
                    const SizedBox(height: AppSpacing.lg),
                    // Restaurants
                    restaurantsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Center(
                          child: Text('Could not load restaurants',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      ),
                      data: (restaurants) => NearbyRestaurantsSection(
                        restaurants: restaurants,
                        onRestaurantTap: (r) =>
                            context.go('${RouteNames.restaurant}/${r.id}'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Popular items
                    popularAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (items) => PopularFoodsSection(
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
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          if (index == 3) {
            _openMenu();
            return;
          }
          setState(() => _currentNavIndex = index);
        },
      ),
    );
  }
}