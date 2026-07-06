import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/cache/local_store.dart';
import '../../../core/cache/offline_first_list_notifier.dart';
import '../data/restaurant_repository_impl.dart';
import '../domain/models/category_model.dart';
import '../domain/models/food_item_model.dart';
import '../domain/models/restaurant_model.dart';
import '../domain/repositories/restaurant_repository.dart';
import '../../../main.dart';

part 'restaurant_provider.g.dart';

@riverpod
RestaurantRepository restaurantRepository(Ref ref) {
  return RestaurantRepositoryImpl();
}

const _restaurantsPageSize = 20;

/// Paginated restaurant list for the home screen. Exposes the same
/// `AsyncValue<List<RestaurantModel>>` shape a `FutureProvider` would
/// (so existing `.when(...)` call sites don't change), plus [loadMore]
/// / [hasMore] for infinite scroll instead of fetching every restaurant
/// up front.
///
/// keepAlive: true preserves the old StateNotifierProvider's behavior of
/// living for the whole app session (the home feed shouldn't reset and
/// re-fetch every time the screen is briefly unmounted).
@Riverpod(keepAlive: true)
class Restaurants extends _$Restaurants {
  late final RestaurantRepository _repository;
  int _page = 0;
  bool hasMore = true;
  bool _isLoadingMore = false;

  @override
  AsyncValue<List<RestaurantModel>> build() {
    _repository = ref.watch(restaurantRepositoryProvider);
    _loadFirstPage();
    return const AsyncValue.loading();
  }

  Future<void> _loadFirstPage() async {
    // Offline-first: show whatever's on disk instantly (no spinner), then
    // silently replace it once the network call resolves. If we're
    // actually offline, the network call below fails and we just keep
    // showing the cached page — the OfflineBanner explains why.
    final cached = await LocalStore.instance
        .loadList(RestaurantRepositoryImpl.restaurantsFirstPageDiskKey);
    if (cached != null) {
      state = AsyncValue.data(cached.map(RestaurantModel.fromMap).toList());
    } else {
      state = const AsyncValue.loading();
    }

    try {
      final fresh = await _repository.getRestaurants(page: 0, pageSize: _restaurantsPageSize);
      state = AsyncValue.data(fresh);
      _page = 0;
      hasMore = fresh.length >= _restaurantsPageSize;
    } catch (e, st) {
      if (state is! AsyncData) state = AsyncValue.error(e, st);
      _page = 0;
      hasMore = false;
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;
    final current = state.valueOrNull;
    if (current == null) return;

    _isLoadingMore = true;
    try {
      final nextPage = _page + 1;
      final more = await _repository.getRestaurants(
        page: nextPage,
        pageSize: _restaurantsPageSize,
      );
      _page = nextPage;
      hasMore = more.length >= _restaurantsPageSize;
      state = AsyncValue.data([...current, ...more]);
    } catch (_) {
      // Keep showing what we already have; the user can trigger another
      // loadMore by scrolling again instead of losing the whole list.
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() => _loadFirstPage();
}

// Popular items — used in home screen. Offline-first: instant from disk,
// then refreshed from the network (see OfflineFirstListNotifier).
final popularItemsProvider =
StateNotifierProvider<OfflineFirstListNotifier<FoodItemModel>, AsyncValue<List<FoodItemModel>>>(
    (ref) {
  final repo = ref.watch(restaurantRepositoryProvider);
  return OfflineFirstListNotifier(
    diskKey: RestaurantRepositoryImpl.popularItemsDiskKey,
    fromMap: FoodItemModel.fromMap,
    fetch: repo.getPopularItems,
  );
});

// Foods filtered to one category — used when a category chip is
// selected on the home screen. autoDispose since it's only relevant
// while that filter is active, unlike the always-shown popular list.
final foodsByCategoryProvider =
FutureProvider.autoDispose.family<List<FoodItemModel>, String>((ref, categoryId) {
  return ref.watch(restaurantRepositoryProvider).getFoodsByCategory(categoryId);
});

// Categories — used in home screen category section. Offline-first.
final categoriesProvider =
StateNotifierProvider<OfflineFirstListNotifier<CategoryModel>, AsyncValue<List<CategoryModel>>>(
    (ref) {
  final repo = ref.watch(restaurantRepositoryProvider);
  return OfflineFirstListNotifier(
    diskKey: RestaurantRepositoryImpl.categoriesDiskKey,
    fromMap: CategoryModel.fromMap,
    fetch: repo.getCategories,
  );
});

// Menu items per restaurant — used in restaurant detail screen.
// Offline-first + autoDispose: this data is only relevant while that
// screen is open, so the in-memory AsyncValue is released once the user
// navigates away; the disk cache (written by the repository) is what
// makes it available instantly again offline or on the next visit.
final menuItemsProvider = StateNotifierProvider.autoDispose
    .family<OfflineFirstListNotifier<FoodItemModel>, AsyncValue<List<FoodItemModel>>, String>(
        (ref, restaurantId) {
  final repo = ref.watch(restaurantRepositoryProvider);
  return OfflineFirstListNotifier(
    diskKey: RestaurantRepositoryImpl.menuItemsDiskKey(restaurantId),
    fromMap: FoodItemModel.fromMap,
    fetch: () => repo.getMenuItems(restaurantId),
  );
});

final restaurantByIdProvider =
FutureProvider.autoDispose.family<RestaurantModel?, String>((ref, id) async {
  final data = await supabase
      .from('restaurants')
      .select()
      .eq('id', id)
      .maybeSingle();
  if (data == null) return null;
  return RestaurantModel.fromMap(data);
});

final bannersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await supabase
      .from('banners')
      .select()
      .eq('is_active', true)
      .order('sort_order');
  return List<Map<String, dynamic>>.from(data as List);
});