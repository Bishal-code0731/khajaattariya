import '../../../core/cache/local_store.dart';
import '../../../core/cache/memory_cache.dart';
import '../../../main.dart';
import '../domain/models/category_model.dart';
import '../domain/models/food_item_model.dart';
import '../domain/models/restaurant_model.dart';
import '../domain/repositories/restaurant_repository.dart';

class RestaurantRepositoryImpl implements RestaurantRepository {
  final _cache = MemoryCache.instance;
  final _disk = LocalStore.instance;

  // Restaurant open/closed + featured/offer flags can change, so this
  // list is cached only briefly — long enough to absorb repeat reads
  // within the same session (re-entering Home, scroll rebuilds) without
  // serving stale "closed" badges for minutes.
  static const _shortTtl = Duration(seconds: 60);
  static const _longTtl = Duration(minutes: 15);

  // Disk cache keys — the offline-first providers in restaurant_provider.dart
  // read these directly for the "show cached data instantly" step, while
  // this repository writes to them as a side effect of every successful
  // network fetch ("refresh silently in background").
  static const restaurantsFirstPageDiskKey = 'restaurants:page0';
  static const categoriesDiskKey = 'categories';
  static const popularItemsDiskKey = 'menu_items:popular';
  static String menuItemsDiskKey(String restaurantId) => 'menu_items:$restaurantId';

  @override
  Future<List<RestaurantModel>> getRestaurants({int page = 0, int pageSize = 20}) {
    return _cache.fetch('restaurants:$page:$pageSize', () async {
      final from = page * pageSize;
      final to = from + pageSize - 1;
      final data = await supabase
          .from('restaurants')
          .select()
          .eq('is_active', true)
          .order('is_featured', ascending: false)
          .order('rating', ascending: false)
          .range(from, to);

      final rows = (data as List).cast<Map<String, dynamic>>();
      // Only the first page is what a cold, offline start needs to show
      // instantly — later pages are purely for infinite scroll.
      if (page == 0) await _disk.saveList(restaurantsFirstPageDiskKey, rows);
      return rows.map((map) => RestaurantModel.fromMap(map)).toList();
    }, ttl: _shortTtl);
  }

  @override
  Future<List<RestaurantModel>> getFeaturedRestaurants() {
    return _cache.fetch('restaurants:featured', () async {
      final data = await supabase
          .from('restaurants')
          .select()
          .eq('is_active', true)
          .eq('is_featured', true)
          .order('rating', ascending: false);

      return (data as List).map((map) => RestaurantModel.fromMap(map)).toList();
    }, ttl: _shortTtl);
  }

  @override
  Future<List<FoodItemModel>> getMenuItems(String restaurantId) {
    return _cache.fetch('menu_items:$restaurantId', () async {
      final data = await supabase
          .from('menu_items')
          .select('*, restaurants(name, rating, delivery_time_min)')
          .eq('restaurant_id', restaurantId)
          .eq('is_available', true)
          .order('sort_order');

      final rows = (data as List).cast<Map<String, dynamic>>();
      await _disk.saveList(menuItemsDiskKey(restaurantId), rows);
      return rows.map((map) => FoodItemModel.fromMap(map)).toList();
    }, ttl: _shortTtl);
  }

  @override
  Future<List<FoodItemModel>> getPopularItems() {
    return _cache.fetch('menu_items:popular', () async {
      // Gets top-rated items across all restaurants
      final data = await supabase
          .from('menu_items')
          .select('*, restaurants(name, rating, delivery_time_min)')
          .eq('is_available', true)
          .order('sort_order')
          .limit(10);

      final rows = (data as List).cast<Map<String, dynamic>>();
      await _disk.saveList(popularItemsDiskKey, rows);
      return rows.map((map) => FoodItemModel.fromMap(map)).toList();
    }, ttl: _shortTtl);
  }

  @override
  Future<List<FoodItemModel>> getFoodsByCategory(String categoryId) {
    return _cache.fetch('menu_items:category:$categoryId', () async {
      final data = await supabase
          .from('menu_items')
          .select('*, restaurants(name, rating, delivery_time_min)')
          .eq('category_id', categoryId)
          .eq('is_available', true)
          .order('sort_order');

      final rows = (data as List).cast<Map<String, dynamic>>();
      return rows.map((map) => FoodItemModel.fromMap(map)).toList();
    }, ttl: _shortTtl);
  }

  @override
  Future<List<CategoryModel>> getCategories() {
    // Categories are near-static reference data — safe to cache longer.
    return _cache.fetch('categories', () async {
      final data = await supabase
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('sort_order');

      final rows = (data as List).cast<Map<String, dynamic>>();
      await _disk.saveList(categoriesDiskKey, rows);
      return rows.map((map) => CategoryModel.fromMap(map)).toList();
    }, ttl: _longTtl);
  }
}