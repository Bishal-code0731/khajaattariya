import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/dummy_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_side_menu.dart';
import '../../../shared/widgets/glass_bottom_nav.dart';
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
  int _cartItemCount = 0;
  int _currentNavIndex = 0;
  CategoryModel? _selectedCategory;
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
    setState(() => _cartItemCount++);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              HomeAppBar(
                cartItemCount: _cartItemCount,
                onNotificationTap: () {},
                onCartTap: () {},
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    HomeSearchBar(onTap: () {}),
                    const SizedBox(height: AppSpacing.md),
                    PromoBannerSlider(banners: DummyData.promoBanners),
                    const SizedBox(height: AppSpacing.lg),
                    CategorySection(
                      onCategorySelected: (category) =>
                          setState(() => _selectedCategory = category),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    NearbyRestaurantsSection(
                      restaurants: DummyData.restaurants,
                      onRestaurantTap: (restaurant) {},
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PopularFoodsSection(
                      items: DummyData.popularItems,
                      onAddToCart: _onAddToCart,
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
              child: AppSideMenu(
                onLoginTap: _closeMenu,
                onClose: _closeMenu,
              ),
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