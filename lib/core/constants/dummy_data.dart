import '../../features/home/domain/models/category_model.dart';
import '../../features/home/domain/models/food_item_model.dart';
import '../../features/home/domain/models/restaurant_model.dart';

// Dummy data for development.
// This makes the UI look real before we connect Supabase.
// When we connect the backend, we delete this file
// and the UI stays exactly the same.

class DummyData {

  // ── Categories ────────────────────────────────────────
  static const List<CategoryModel> categories = [
    CategoryModel(id: '1', name: 'Momo',    emoji: '🥟'),
    CategoryModel(id: '2', name: 'Thali',   emoji: '🍱'),
    CategoryModel(id: '3', name: 'Chowmein',emoji: '🍜'),
    CategoryModel(id: '4', name: 'Pizza',   emoji: '🍕'),
    CategoryModel(id: '5', name: 'Burger',  emoji: '🍔'),
    CategoryModel(id: '6', name: 'Rice',    emoji: '🍚'),
    CategoryModel(id: '7', name: 'Soup',    emoji: '🍲'),
    CategoryModel(id: '8', name: 'Snacks',  emoji: '🍿'),
    CategoryModel(id: '9', name: 'Drinks',  emoji: '🥤'),
    CategoryModel(id: '10',name: 'Sweets',  emoji: '🍮'),
  ];

  // ── Restaurants ───────────────────────────────────────
  static const List<RestaurantModel> restaurants = [
    RestaurantModel(
      id: '1',
      name: 'Hamro Kitchen',
      imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400',
      cuisineType: 'Nepali, Chinese',
      rating: 4.5,
      reviewCount: 120,
      deliveryTimeMin: 20,
      deliveryFee: 30,
      isOpen: true,
      isFeatured: true,
      offer: '20% off',
    ),
    RestaurantModel(
      id: '2',
      name: 'Sita Bhoj',
      imageUrl: 'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=400',
      cuisineType: 'Nepali Thali',
      rating: 4.3,
      reviewCount: 89,
      deliveryTimeMin: 25,
      deliveryFee: 20,
      isOpen: true,
    ),
    RestaurantModel(
      id: '3',
      name: 'Momo Palace',
      imageUrl: 'https://images.unsplash.com/photo-1534482421-64566f976cfa?w=400',
      cuisineType: 'Momo, Chowmein',
      rating: 4.7,
      reviewCount: 200,
      deliveryTimeMin: 15,
      deliveryFee: 25,
      isOpen: true,
      isFeatured: true,
      offer: 'Free delivery',
    ),
    RestaurantModel(
      id: '4',
      name: 'Attariya Chiya Ghar',
      imageUrl: 'https://images.unsplash.com/photo-1600093463592-8e36ae95ef56?w=400',
      cuisineType: 'Snacks, Drinks',
      rating: 4.1,
      reviewCount: 55,
      deliveryTimeMin: 10,
      deliveryFee: 15,
      isOpen: false,
    ),
  ];

  // ── Popular Food Items ─────────────────────────────────
  static const List<FoodItemModel> popularItems = [
    FoodItemModel(
      id: '1',
      name: 'Steam Momo (10 pcs)',
      imageUrl: 'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?w=400',
      price: 120,
      restaurantName: 'Momo Palace',
      restaurantId: '3',
      rating: 4.8,
      deliveryTimeMin: 15,
      isVeg: false,
      offer: '10% off',
    ),
    FoodItemModel(
      id: '2',
      name: 'Dal Bhat Tarkari',
      imageUrl: 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400',
      price: 180,
      restaurantName: 'Sita Bhoj',
      restaurantId: '2',
      rating: 4.5,
      deliveryTimeMin: 25,
      isVeg: true,
    ),
    FoodItemModel(
      id: '3',
      name: 'Veg Chowmein',
      imageUrl: 'https://images.unsplash.com/photo-1612929633738-8fe44f7ec841?w=400',
      price: 100,
      restaurantName: 'Hamro Kitchen',
      restaurantId: '1',
      rating: 4.3,
      deliveryTimeMin: 20,
      isVeg: true,
    ),
    FoodItemModel(
      id: '4',
      name: 'Chicken Thali',
      imageUrl: 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400',
      price: 250,
      restaurantName: 'Hamro Kitchen',
      restaurantId: '1',
      rating: 4.6,
      deliveryTimeMin: 20,
      isVeg: false,
      offer: 'Free drink',
    ),
    FoodItemModel(
      id: '5',
      name: 'Paneer Momo (8 pcs)',
      imageUrl: 'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?w=400',
      price: 150,
      restaurantName: 'Momo Palace',
      restaurantId: '3',
      rating: 4.7,
      deliveryTimeMin: 15,
      isVeg: true,
    ),
  ];

  // ── Promo Banners ─────────────────────────────────────
  // Each banner has a title, subtitle, color, and emoji.
  // Later these will be real images from Supabase storage.
  static const List<Map<String, dynamic>> promoBanners = [
    {
      'id': '1',
      'title': '20% Off First Order',
      'subtitle': 'Use code: KHAJA20',
      'emoji': '🎉',
      'color': 0xFFC0392B, // primary red
    },
    {
      'id': '2',
      'title': 'Free Delivery Today',
      'subtitle': 'On orders above Rs. 300',
      'emoji': '🛵',
      'color': 0xFF8E44AD, // purple
    },
    {
      'id': '3',
      'title': 'Momo Monday',
      'subtitle': 'Rs. 20 off on all momos',
      'emoji': '🥟',
      'color': 0xFF1ABC9C, // teal
    },
    {
      'id': '4',
      'title': 'New Restaurant Alert',
      'subtitle': 'Sita Bhoj is now on Khaja!',
      'emoji': '🍽️',
      'color': 0xFFF39C12, // accent yellow
    },
  ];
}