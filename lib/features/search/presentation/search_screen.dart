import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/router/navigation_extensions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../main.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../home/domain/models/food_item_model.dart';
import '../../home/domain/models/restaurant_model.dart';

part 'search_screen.g.dart';

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
@Riverpod(keepAlive: true)
class Search extends _$Search {
  @override
  AsyncValue<SearchResults> build() => const AsyncValue.data(SearchResults());

  // Dedupes identical repeated queries...
  String _lastQuery = '';
  // ...while _requestId guards the async gap: if the user types again (or
  // clears) before this request's queries resolve, the stale response is
  // dropped instead of overwriting newer results ("request cancellation"
  // — Supabase's client doesn't expose a real abort, so we ignore the
  // result instead of racing it into state).
  int _requestId = 0;

  Future<void> search(String query) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      _requestId++;
      _lastQuery = '';
      state = const AsyncValue.data(SearchResults());
      return;
    }

    if (trimmed == _lastQuery) return;
    _lastQuery = trimmed;
    final requestId = ++_requestId;

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

      if (requestId != _requestId) return; // superseded — drop this result

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
      if (requestId != _requestId) return;
      // Reset _lastQuery on failure — otherwise retyping the exact same
      // text after a transient error (the common case) short-circuits at
      // the `trimmed == _lastQuery` guard above and never retries.
      _lastQuery = '';
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void clear() {
    _requestId++;
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

  Timer? _debounce;

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
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    ref.read(searchProvider.notifier).clear();
    super.dispose();
  }

  void _onChanged(String value) {
    // A single cancellable Timer instead of spawning a new Future.delayed
    // per keystroke — the old approach left N pending futures alive (each
    // still doing a timestamp comparison) for every character typed.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) ref.read(searchProvider.notifier).search(value);
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
          onPressed: () => context.safeBack(),
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
        loading: () => const AppShimmerCardList(count: 5, itemHeight: 56),
        error: (_, __) => Center(
          child: Text('Search failed. Try again.',
              style: AppTypography.bodyMedium),
        ),
        data: (results) {
          if (_controller.text.trim().isEmpty) {
            return const AppEmptyState(
              icon: Icons.search_rounded,
              title: 'Search for restaurants or food',
            );
          }
          if (results.isEmpty) {
            return AppEmptyState(
              icon: Icons.search_off_rounded,
              title: 'No results for "${_controller.text.trim()}"',
              subtitle: 'Try a different search term',
            );
          }
          return _SearchResults(results: results);
        },
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
          context.pushOnce('${RouteNames.restaurant}/${restaurant.id}'),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: CachedNetworkImage(
              imageUrl: restaurant.imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              memCacheWidth: 112,
              placeholder: (_, __) => Container(width: 56, height: 56, color: AppColors.border),
              errorWidget: (_, __, ___) => Container(
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
                color: AppColors.error.withValues(alpha: 0.1),
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
          context.pushOnce('${RouteNames.restaurant}/${food.restaurantId}'),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                BorderRadius.circular(AppSpacing.radiusMd),
                child: CachedNetworkImage(
                  imageUrl: food.imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  memCacheWidth: 112,
                  placeholder: (_, __) =>
                      Container(width: 56, height: 56, color: AppColors.border),
                  errorWidget: (_, __, ___) => Container(
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