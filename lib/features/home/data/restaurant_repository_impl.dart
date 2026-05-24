import '../../../main.dart';
import '../domain/models/category_model.dart';
import '../domain/models/food_item_model.dart';
import '../domain/models/restaurant_model.dart';
import '../domain/repositories/restaurant_repository.dart';

class RestaurantRepositoryImpl implements RestaurantRepository {
  @override
  Future<List<RestaurantModel>> getRestaurants() async {
    final data = await supabase
        .from('restaurants')
        .select()
        .eq('is_active', true)
        .order('is_featured', ascending: false)
        .order('rating', ascending: false);

    return (data as List)
        .map((map) => RestaurantModel.fromMap(map))
        .toList();
  }

  @override
  Future<List<RestaurantModel>> getFeaturedRestaurants() async {
    final data = await supabase
        .from('restaurants')
        .select()
        .eq('is_active', true)
        .eq('is_featured', true)
        .order('rating', ascending: false);

    return (data as List)
        .map((map) => RestaurantModel.fromMap(map))
        .toList();
  }

  @override
  Future<List<FoodItemModel>> getMenuItems(String restaurantId) async {
    final data = await supabase
        .from('menu_items')
        .select('*, restaurants(name, rating, delivery_time_min)')
        .eq('restaurant_id', restaurantId)
        .eq('is_available', true)
        .order('sort_order');

    return (data as List)
        .map((map) => FoodItemModel.fromMap(map))
        .toList();
  }

  @override
  Future<List<FoodItemModel>> getPopularItems() async {
    // Gets top-rated items across all restaurants
    final data = await supabase
        .from('menu_items')
        .select('*, restaurants(name, rating, delivery_time_min)')
        .eq('is_available', true)
        .order('sort_order')
        .limit(10);

    return (data as List)
        .map((map) => FoodItemModel.fromMap(map))
        .toList();
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    final data = await supabase
        .from('categories')
        .select()
        .eq('is_active', true)
        .order('sort_order');

    return (data as List)
        .map((map) => CategoryModel.fromMap(map))
        .toList();
  }
}