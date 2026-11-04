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

  static const _shortTtl = Duration(seconds: 60);
  static const _longTtl = Duration(minutes: 15);

  static const restaurantsFirstPageDiskKey = 'restaurants:page0';
  static const categoriesDiskKey = 'categories';
  static const popularItemsDiskKey = 'menu_items:popular';
  static String menuItemsDiskKey(String restaurantId) =>
      'menu_items:$restaurantId';

  @override
  Future<List<RestaurantModel>> getRestaurants(
      {int page = 0, int pageSize = 20}) {
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
          .select('*, restaurants(name, rating, delivery_time_min, is_open)')
          .eq('restaurant_id', restaurantId)
          .eq('is_available', true)
          .order('sort_order', ascending: true);

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
          .select('*, restaurants(name, rating, delivery_time_min, is_open)')
          .eq('is_available', true)
          .order('sort_order', ascending: true)
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
          .select('*, restaurants(name, rating, delivery_time_min, is_open)')
          .eq('category_id', categoryId)
          .eq('is_available', true)
          .order('sort_order', ascending: true);

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
          .order('sort_order', ascending: true);

      final rows = (data as List).cast<Map<String, dynamic>>();
      await _disk.saveList(categoriesDiskKey, rows);
      return rows.map((map) => CategoryModel.fromMap(map)).toList();
    }, ttl: _longTtl);
  }
}
