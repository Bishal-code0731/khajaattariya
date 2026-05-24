import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../main.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../home/domain/models/food_item_model.dart';
import '../../home/domain/models/restaurant_model.dart';

// Search results state
class SearchResults {
  final List<RestaurantModel> restaurants;
  final List<FoodItemModel> foodItems;

  const SearchResults({
    this.restaurants = const [],
    this.foodItems = const [],
  });

  bool get isEmpty => restaurants.isEmpty && foodItems.isEmpty;
}

// Search notifier with debounce
final searchProvider =
StateNotifierProvider<SearchNotifier, AsyncValue<SearchResults>>(
      (ref) => SearchNotifier(),
);

class SearchNotifier extends StateNotifier<AsyncValue<SearchResults>> {
  SearchNotifier() : super(const AsyncValue.data(SearchResults()));

  // Track last query to avoid stale results
  String _lastQuery = '';

  Future<void> search(String query) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      state = const AsyncValue.data(SearchResults());
      return;
    }

    if (trimmed == _lastQuery) return;
    _lastQuery = trimmed;

    state = const AsyncValue.loading();
    try {
      // Run both queries in parallel
      final results = await Future.wait([
        supabase
            .from('restaurants')
            .select()
            .eq('is_active', true)
            .ilike('name', '%$trimmed%')
            .order('rating', ascending: false)
            .limit(10),
        supabase
            .from('menu_items')
            .select('*, restaurants(name, rating, delivery_time_min)')
            .eq('is_available', true)
            .ilike('name', '%$trimmed%')
            .limit(15),
      ]);

      // Only update if query hasn't changed during fetch
      if (_lastQuery != trimmed) return;

      final restaurants = (results[0] as List)
          .map((m) => RestaurantModel.fromMap(m))
          .toList();

      final foodItems = (results[1] as List)
          .map((m) => FoodItemModel.fromMap(m))
          .toList();

      state = AsyncValue.data(
        SearchResults(restaurants: restaurants, foodItems: foodItems),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void clear() {
    _lastQuery = '';
    state = const AsyncValue.data(SearchResults());
  }
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  // Debounce timer
  DateTime? _lastTyped;

  @override
  void initState() {
    super.initState();
    // Auto focus on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    ref.read(searchProvider.notifier).clear();
    super.dispose();
  }

  void _onChanged(String value) {
    _lastTyped = DateTime.now();
    final typed = _lastTyped;

    Future.delayed(const Duration(milliseconds: 400), () {
      if (_lastTyped == typed && mounted) {
        ref.read(searchProvider.notifier).search(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(RouteNames.home),
        ),
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onChanged,
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search restaurants or food...',
            hintStyle: AppTypography.bodyMedium
                .copyWith(color: AppColors.textHint),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.close_rounded,
                  size: 18, color: AppColors.textHint),
              onPressed: () {
                _controller.clear();
                ref.read(searchProvider.notifier).clear();
                setState(() {});
              },
            )
                : null,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: searchState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
        error: (_, __) => Center(
          child: Text('Search failed. Try again.',
              style: AppTypography.bodyMedium),
        ),
        data: (results) {
          if (_controller.text.trim().isEmpty) {
            return _EmptySearch();
          }
          if (results.isEmpty) {
            return _NoResults(query: _controller.text.trim());
          }
          return _SearchResults(results: results);
        },
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_rounded,
              size: 64, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.md),
          Text('Search for restaurants or food',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;

  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 64, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.md),
          Text('No results for "$query"',
              style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.sm),
          Text('Try a different search term',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final SearchResults results;

  const _SearchResults({required this.results});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        if (results.restaurants.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.sm,
              AppSpacing.screenHorizontal,
              AppSpacing.xs,
            ),
            child: Text('Restaurants',
                style: AppTypography.headingSmall),
          ),
          ...results.restaurants.map(
                (r) => _RestaurantResultTile(restaurant: r),
          ),
        ],
        if (results.foodItems.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.md,
              AppSpacing.screenHorizontal,
              AppSpacing.xs,
            ),
            child: Text('Food Items', style: AppTypography.headingSmall),
          ),
          ...results.foodItems.map(
                (f) => _FoodResultTile(food: f),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _RestaurantResultTile extends StatelessWidget {
  final RestaurantModel restaurant;

  const _RestaurantResultTile({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      borderRadius: AppSpacing.radiusLg,
      onTap: () =>
          context.go('${RouteNames.restaurant}/${restaurant.id}'),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Image.network(
              restaurant.imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 56,
                height: 56,
                color: AppColors.border,
                child: const Icon(Icons.restaurant_rounded,
                    color: AppColors.textHint),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(restaurant.name,
                    style: AppTypography.headingSmall
                        .copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(restaurant.cuisineType,
                    style: AppTypography.bodySmall),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 13, color: AppColors.accent),
                    const SizedBox(width: 2),
                    Text('${restaurant.rating}',
                        style: AppTypography.bodySmall),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.circle,
                        size: 3, color: AppColors.textHint),
                    const SizedBox(width: AppSpacing.xs),
                    Text('${restaurant.deliveryTimeMin} min',
                        style: AppTypography.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          if (!restaurant.isOpen)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius:
                BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text('Closed',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.error)),
            ),
        ],
      ),
    );
  }
}

class _FoodResultTile extends StatelessWidget {
  final FoodItemModel food;

  const _FoodResultTile({required this.food});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      borderRadius: AppSpacing.radiusLg,
      onTap: () =>
          context.go('${RouteNames.restaurant}/${food.restaurantId}'),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                BorderRadius.circular(AppSpacing.radiusMd),
                child: Image.network(
                  food.imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: AppColors.border,
                    child: const Icon(Icons.fastfood_rounded,
                        color: AppColors.textHint),
                  ),
                ),
              ),
              Positioned(
                top: 3,
                left: 3,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(
                      color: food.isVeg
                          ? AppColors.success
                          : AppColors.error,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: food.isVeg
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food.name,
                    style: AppTypography.headingSmall
                        .copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(food.restaurantName,
                    style: AppTypography.bodySmall),
              ],
            ),
          ),
          Text('Rs. ${food.price.toInt()}',
              style: AppTypography.priceMedium),
        ],
      ),
    );
  }
}