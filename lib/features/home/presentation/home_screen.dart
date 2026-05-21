import 'package:flutter/material.dart';
import '../../../core/constants/dummy_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/models/category_model.dart';
import '../domain/models/food_item_model.dart';
import '../domain/models/restaurant_model.dart';
import 'widgets/category_section.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/home_search_bar.dart';
import 'widgets/nearby_restaurants_section.dart';
import 'widgets/popular_foods_section.dart';
import 'widgets/promo_banner_slider.dart';

// The main home screen.
// Uses CustomScrollView with Slivers for smooth performance.
// CustomScrollView lets us mix different scroll behaviors —
// the app bar floats, the rest scrolls normally.

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Cart item count — will come from Riverpod provider later
  int _cartItemCount = 0;

  // Currently selected bottom nav index
  int _currentNavIndex = 0;

  // Selected category filter — null means show all
  CategoryModel? _selectedCategory;

  void _onAddToCart(FoodItemModel item) {
    setState(() {
      _cartItemCount++;
    });
    // Show a snackbar confirmation
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
      backgroundColor: AppColors.background,

      // CustomScrollView lets us use Slivers.
      // Slivers are scroll-aware widgets that can have
      // special behaviors like floating app bars.
      body: CustomScrollView(
        slivers: [

          // ── App Bar ───────────────────────────────────────
          HomeAppBar(
            cartItemCount: _cartItemCount,
            onNotificationTap: () {},
            onCartTap: () {},
          ),

          // SliverToBoxAdapter wraps regular (non-sliver) widgets
          // so they can live inside a CustomScrollView.
          // Everything below the app bar is wrapped in this.
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: AppSpacing.sm),

                // ── Search Bar ──────────────────────────────
                HomeSearchBar(onTap: () {}),

                const SizedBox(height: AppSpacing.md),

                // ── Promo Banner Slider ─────────────────────
                PromoBannerSlider(banners: DummyData.promoBanners),

                const SizedBox(height: AppSpacing.lg),

                // ── Categories ──────────────────────────────
                CategorySection(
                  onCategorySelected: (category) {
                    setState(() => _selectedCategory = category);
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Nearby Restaurants ──────────────────────
                NearbyRestaurantsSection(
                  restaurants: DummyData.restaurants,
                  onRestaurantTap: (restaurant) {},
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Popular Foods ───────────────────────────
                PopularFoodsSection(
                  items: DummyData.popularItems,
                  onAddToCart: _onAddToCart,
                ),

                // Bottom padding so last item isn't hidden by nav bar
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ],
      ),

      // ── Bottom Navigation Bar ────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) => setState(() => _currentNavIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_rounded),
            label: 'Menu',
          ),
        ],
      ),
    );
  }
}