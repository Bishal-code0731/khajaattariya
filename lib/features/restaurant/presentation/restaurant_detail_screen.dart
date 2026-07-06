import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/router/navigation_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../cart/application/cart_notifier.dart';
import '../../home/application/restaurant_provider.dart';
import '../../home/domain/models/food_item_model.dart';
import '../../home/domain/models/restaurant_model.dart';
import '../../reviews/application/rating_provider.dart';
import '../../reviews/domain/models/rating_model.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/loading_indicator.dart';

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final String restaurantId;

  const RestaurantDetailScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  ConsumerState<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState
    extends ConsumerState<RestaurantDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = [
    'All',
    'Veg',
    'Non-Veg',
    'Offers',
    'Reviews',
  ];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
    );

    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Carts can now hold items from more than one restaurant at once —
  // adding always just adds to that restaurant's group in the cart
  // (created on first item) instead of prompting to clear an existing
  // cart from a different restaurant.
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

  Widget _buildMenuTab(
      bool? isVeg, {
        bool offersOnly = false,
      }) {
    final menuAsync =
    ref.watch(menuItemsProvider(widget.restaurantId));

    return menuAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
      error: (_, __) => Center(
        child: Text(
          'Could not load menu',
          style: TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
      ),
      data: (items) {
        var filtered = items;

        if (isVeg != null) {
          filtered = filtered
              .where((i) => i.isVeg == isVeg)
              .toList();
        }

        if (offersOnly) {
          filtered = filtered
              .where((i) => i.offer != null)
              .toList();
        }

        return _MenuList(
          items: filtered,
          onAddToCart: _onAddToCart,
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    final ratingsAsync = ref.watch(restaurantRatingsProvider(widget.restaurantId));
    return ratingsAsync.when(
      loading: () => const AppLoader.fullscreen(),
      error: (_, __) => AppErrorState(
        message: 'Could not load reviews',
        onRetry: () => ref.invalidate(restaurantRatingsProvider(widget.restaurantId)),
      ),
      data: (ratings) {
        if (ratings.isEmpty) {
          return const AppEmptyState(
            icon: Icons.rate_review_outlined,
            title: 'No reviews yet',
            subtitle: 'Be the first to review this restaurant after your order.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          itemCount: ratings.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) => _ReviewTile(rating: ratings[i]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final restaurantAsync = ref.watch(
      restaurantByIdProvider(widget.restaurantId),
    );

    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return restaurantAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      ),

      error: (_, __) => const Scaffold(
        body: Center(
          child: Text('Restaurant not found'),
        ),
      ),

      data: (restaurant) {
        if (restaurant == null) {
          return const Scaffold(
            body: Center(
              child: Text('Restaurant not found'),
            ),
          );
        }

        return Scaffold(
          backgroundColor:
          Theme.of(context).scaffoldBackgroundColor,
          body: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              _buildSliverAppBar(
                context,
                restaurant,
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  tabController: _tabController,
                  tabs: _tabs,
                  isDark: isDark,
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildMenuTab(null),
                _buildMenuTab(true),
                _buildMenuTab(false),
                _buildMenuTab(
                  null,
                  offersOnly: true,
                ),
                _buildReviewsTab(),
              ],
            ),
          ),
        );
      },
    );
  }

  SliverAppBar _buildSliverAppBar(
      BuildContext context,
      RestaurantModel restaurant,
      ) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.black45,
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => context.safeBack(),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: restaurant.imageUrl,
              fit: BoxFit.cover,
              memCacheWidth: 900,
              placeholder: (_, __) => Container(color: AppColors.border),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.border,
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: AppColors.textHint,
                  size: 48,
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black54,
                  ],
                ),
              ),
            ),
            if (!restaurant.isOpen)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Text(
                    'CLOSED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: _RestaurantInfoBar(
          restaurant: restaurant,
        ),
      ),
    );
  }
}

class _RestaurantInfoBar extends StatelessWidget {
  final RestaurantModel restaurant;

  const _RestaurantInfoBar({
    required this.restaurant,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
        AppSpacing.screenHorizontal,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  restaurant.name,
                  style: AppTypography.headingLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (restaurant.offer != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusSm,
                    ),
                  ),
                  child: Text(
                    restaurant.offer!,
                    style:
                    AppTypography.labelSmall.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            restaurant.cuisineType,
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _InfoChip(
                icon: Icons.star_rounded,
                iconColor: AppColors.accent,
                label:
                '${restaurant.rating} (${restaurant.reviewCount} reviews)',
              ),
              const SizedBox(width: AppSpacing.md),
              _InfoChip(
                icon: Icons.access_time_rounded,
                iconColor: AppColors.primary,
                label:
                '${restaurant.deliveryTimeMin} min',
              ),
              const SizedBox(width: AppSpacing.md),
              _InfoChip(
                icon: Icons.delivery_dining_rounded,
                iconColor: AppColors.textSecondary,
                label: restaurant.deliveryFee == 0
                    ? 'Free delivery'
                    : 'Rs. ${restaurant.deliveryFee.toInt()}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: iconColor,
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTypography.bodySmall,
        ),
      ],
    );
  }
}

class _TabBarDelegate
    extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final List<String> tabs;
  final bool isDark;

  _TabBarDelegate({
    required this.tabController,
    required this.tabs,
    required this.isDark,
  });

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.primary,
        unselectedLabelColor:
        AppColors.textSecondary,
        labelStyle: AppTypography.labelMedium,
        unselectedLabelStyle:
        AppTypography.bodyMedium,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.border,
        tabs: tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  @override
  bool shouldRebuild(
      _TabBarDelegate oldDelegate,
      ) {
    return oldDelegate.tabController !=
        tabController ||
        oldDelegate.isDark != isDark;
  }
}

class _MenuList extends StatelessWidget {
  final List<FoodItemModel> items;
  final Function(FoodItemModel) onAddToCart;

  const _MenuList({
    required this.items,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.restaurant_menu_rounded,
              size: 48,
              color: AppColors.textHint,
            ),
            const SizedBox(
              height: AppSpacing.md,
            ),
            Text(
              'No items here',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _FoodItemTile(
        item: items[index],
        onAddToCart: () =>
            onAddToCart(items[index]),
      ),
    );
  }
}

class _FoodItemTile extends StatelessWidget {
  final FoodItemModel item;
  final VoidCallback onAddToCart;

  const _FoodItemTile({
    required this.item,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(
        AppSpacing.sm,
      ),
      borderRadius: AppSpacing.radiusLg,
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  AppSpacing.radiusMd,
                ),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: AppSpacing.menuItemImageSize,
                  height: AppSpacing.menuItemImageSize,
                  fit: BoxFit.cover,
                  // menuItemImageSize is a small thumbnail — no reason to
                  // decode the source image at full resolution for it.
                  memCacheWidth: (AppSpacing.menuItemImageSize * 2).round(),
                  placeholder: (context, url) => Container(
                    width: AppSpacing.menuItemImageSize,
                    height: AppSpacing.menuItemImageSize,
                    color: AppColors.border,
                  ),
                  errorWidget:
                      (_, __, ___) => Container(
                    width:
                    AppSpacing.menuItemImageSize,
                    height:
                    AppSpacing.menuItemImageSize,
                    color: AppColors.border,
                    child: const Icon(
                      Icons.fastfood_rounded,
                      color: AppColors.textHint,
                      size: 28,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius:
                    BorderRadius.circular(2),
                    border: Border.all(
                      color: item.isVeg
                          ? AppColors.success
                          : AppColors.error,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: item.isVeg
                            ? AppColors.success
                            : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: AppTypography
                            .headingSmall
                            .copyWith(fontSize: 14),
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.offer != null)
                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal:
                          AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                          AppColors.successLight,
                          borderRadius:
                          BorderRadius.circular(
                            4,
                          ),
                        ),
                        child: Text(
                          item.offer!,
                          style: AppTypography
                              .labelSmall
                              .copyWith(
                            color:
                            AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.accent,
                      size: 13,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${item.rating}',
                      style: AppTypography.labelSmall
                          .copyWith(
                        color:
                        AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(
                      width: AppSpacing.xs,
                    ),
                    const Icon(
                      Icons.circle,
                      size: 3,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(
                      width: AppSpacing.xs,
                    ),
                    Text(
                      '${item.deliveryTimeMin} min',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              Text(
                'Rs. ${item.price.toInt()}',
                style: AppTypography.priceMedium,
              ),
              const SizedBox(
                height: AppSpacing.xs,
              ),
              GestureDetector(
                onTap: onAddToCart,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius:
                    BorderRadius.circular(
                      AppSpacing.radiusSm,
                    ),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final RatingModel rating;
  const _ReviewTile({required this.rating});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(rating.customerName ?? 'Anonymous', style: AppTypography.labelMedium),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < rating.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: AppColors.accent,
                  size: 16,
                )),
              ),
            ],
          ),
          if (rating.review != null && rating.review!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(rating.review!, style: AppTypography.bodyMedium),
          ],
        ],
      ),
    );
  }
}