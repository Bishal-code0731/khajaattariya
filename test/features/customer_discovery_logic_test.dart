import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaja_attariya/features/cart/domain/models/cart_item_model.dart';
import 'package:khaja_attariya/features/cart/domain/models/cart_state.dart';
import 'package:khaja_attariya/features/home/application/restaurant_filter.dart';
import 'package:khaja_attariya/features/home/domain/models/food_item_model.dart';
import 'package:khaja_attariya/features/home/domain/models/restaurant_model.dart';
import 'package:khaja_attariya/features/home/presentation/widgets/category_icon.dart';
import 'package:khaja_attariya/features/restaurant/application/menu_sections.dart';

RestaurantModel _r(String id,
        {double rating = 4.2,
        int time = 25,
        bool open = true,
        String? offer}) =>
    RestaurantModel(
      id: id,
      name: id,
      imageUrl: '',
      cuisineType: 'Nepali',
      rating: rating,
      reviewCount: 10,
      deliveryTimeMin: time,
      deliveryFee: 0,
      isOpen: open,
      offer: offer,
    );

FoodItemModel _f(String id, {String? cat, bool veg = true}) => FoodItemModel(
      id: id,
      name: id,
      imageUrl: '',
      price: 100,
      restaurantName: 'R',
      restaurantId: 'r1',
      categoryId: cat,
      rating: 4,
      deliveryTimeMin: 30,
      isVeg: veg,
    );

void main() {
  group('RestaurantFilter', () {
    final list = [
      _r('a', rating: 3.8, time: 40),
      _r('b', rating: 4.6, time: 20, offer: '20% off'),
      _r('c', rating: 4.1, time: 35, open: false),
      _r('d', rating: 4.3, time: 15),
    ];

    test('recommended keeps server order but moves closed places last', () {
      expect(const RestaurantFilter().apply(list).map((r) => r.id),
          ['a', 'b', 'd', 'c']);
    });

    test('filters combine', () {
      const f = RestaurantFilter(minRating4: true, fastDelivery: true);
      expect(f.apply(list).map((r) => r.id), ['b', 'd']);
      expect(
          const RestaurantFilter(offersOnly: true).apply(list).map((r) => r.id),
          ['b']);
      expect(const RestaurantFilter(openNow: true).apply(list).map((r) => r.id),
          ['a', 'b', 'd']);
    });

    test('sorts by rating and by speed', () {
      expect(
          const RestaurantFilter(sort: RestaurantSort.rating)
              .apply(list)
              .map((r) => r.id),
          ['b', 'd', 'a', 'c']);
      expect(
          const RestaurantFilter(sort: RestaurantSort.fastest)
              .apply(list)
              .map((r) => r.id),
          ['d', 'b', 'a', 'c']);
    });

    test('onlyIds narrows to a category', () {
      expect(
          const RestaurantFilter()
              .apply(list, onlyIds: {'d', 'c'}).map((r) => r.id),
          ['d', 'c']);
    });
  });

  group('buildMenuSections', () {
    final items = [
      _f('1', cat: 'momo'),
      _f('2', cat: 'drinks', veg: false),
      _f('3'),
      _f('4', cat: 'momo')
    ];

    test('groups by category in menu order, uncategorised last', () {
      final s = buildMenuSections(items,
          categoryNames: {'momo': 'Momo', 'drinks': 'Drinks'},
          moreTitle: 'More');
      expect(s.map((e) => e.title), ['Momo', 'Drinks', 'More']);
      expect(s.first.items.map((e) => e.id), ['1', '4']);
    });

    test('veg only drops empty sections', () {
      final s = buildMenuSections(items,
          categoryNames: {'momo': 'Momo', 'drinks': 'Drinks'},
          moreTitle: 'More',
          vegOnly: true);
      expect(s.map((e) => e.title), ['Momo', 'More']);
    });
  });

  test('categoryIcon maps names to icons with a fallback', () {
    expect(categoryIcon('Jhol Momo'), Icons.soup_kitchen_rounded);
    expect(categoryIcon('Dal Bhat'), Icons.rice_bowl_rounded);
    expect(categoryIcon('Fast Food'), Icons.lunch_dining_rounded);
    expect(categoryIcon('Something else'), Icons.restaurant_rounded);
  });

  test('CartState.quantityOf', () {
    final cart = CartState(groups: [
      CartRestaurantGroup(
          restaurantId: 'r1',
          restaurantName: 'R',
          items: [CartItem(food: _f('1'), quantity: 3)]),
    ]);
    expect(cart.quantityOf('r1', '1'), 3);
    expect(cart.quantityOf('r1', '2'), 0);
    expect(cart.quantityOf('r2', '1'), 0);
  });
}
