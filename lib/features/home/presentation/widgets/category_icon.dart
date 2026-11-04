import 'package:flutter/material.dart';

/// Keyword → icon, checked in order (first match wins).
const List<(List<String>, IconData)> _rules = [
  (['momo', 'dumpling', 'dim sum'], Icons.soup_kitchen_rounded),
  (['pizza'], Icons.local_pizza_rounded),
  (
    ['burger', 'fast food', 'fastfood', 'sandwich', 'snack', 'fries'],
    Icons.lunch_dining_rounded
  ),
  (
    ['noodle', 'chow', 'chinese', 'thukpa', 'ramen', 'pasta'],
    Icons.ramen_dining_rounded
  ),
  (
    [
      'sekuwa',
      'bbq',
      'barbecue',
      'kebab',
      'grill',
      'tandoor',
      'chicken',
      'meat'
    ],
    Icons.kebab_dining_rounded
  ),
  (['curry', 'indian', 'paneer', 'masala'], Icons.dinner_dining_rounded),
  (
    ['rice', 'dal', 'bhat', 'thali', 'khana', 'biryani', 'nepali', 'meal'],
    Icons.rice_bowl_rounded
  ),
  (['ice cream', 'icecream', 'kulfi'], Icons.icecream_rounded),
  (['cake', 'dessert', 'sweet', 'mithai'], Icons.cake_rounded),
  (['bakery', 'bread', 'roti', 'pastry'], Icons.bakery_dining_rounded),
  (['tea', 'coffee', 'cafe', 'chiya'], Icons.local_cafe_rounded),
  (
    ['drink', 'juice', 'lassi', 'beverage', 'shake', 'soda'],
    Icons.local_drink_rounded
  ),
  (['breakfast', 'egg'], Icons.egg_alt_rounded),
  (['veg', 'salad', 'healthy'], Icons.eco_rounded),
];

IconData categoryIcon(String name, {String? iconName}) {
  final key = '${iconName ?? ''} $name'.toLowerCase();
  for (final (words, icon) in _rules) {
    if (words.any(key.contains)) return icon;
  }
  return Icons.restaurant_rounded;
}
