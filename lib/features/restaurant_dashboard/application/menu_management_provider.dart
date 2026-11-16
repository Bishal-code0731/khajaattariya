import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';
import '../domain/models/owner_menu_item.dart';

/// Every dish of a restaurant, hidden ones included (owner view).
final ownerMenuItemsProvider = FutureProvider.autoDispose
    .family<List<OwnerMenuItem>, String>((ref, restaurantId) async {
  final data = await supabase
      .from('menu_items')
      .select()
      .eq('restaurant_id', restaurantId)
      .order('sort_order', ascending: true)
      .order('name', ascending: true);
  return (data as List)
      .map((m) => OwnerMenuItem.fromMap(m as Map<String, dynamic>))
      .toList();
});

/// Active food categories (admin-managed) for the dish form's picker.
final menuCategoriesProvider =
    FutureProvider.autoDispose<List<MenuCategory>>((ref) async {
  final data = await supabase
      .from('categories')
      .select('id, name')
      .eq('is_active', true)
      .order('sort_order', ascending: true);
  return (data as List)
      .map((m) => MenuCategory.fromMap(m as Map<String, dynamic>))
      .toList();
});

/// Thrown when a dish can't be deleted because past orders point at it.
class MenuItemInUseException implements Exception {
  const MenuItemInUseException();
}

/// Owner writes to `menu_items`.
class MenuItemActions {
  const MenuItemActions();

  Future<void> create(String restaurantId, MenuItemInput input) async {
    await supabase.from('menu_items').insert({
      ...input.toMap(),
      'restaurant_id': restaurantId,
      'is_available': true,
    });
  }

  /// Leaves `is_available` alone: editing a hidden dish must not re-list it.
  Future<void> update(String itemId, MenuItemInput input) async {
    final updated = await supabase
        .from('menu_items')
        .update(input.toMap())
        .eq('id', itemId)
        .select('id');
    if (updated.isEmpty) throw StateError('menu item not updated');
  }

  Future<void> setAvailable(String itemId, bool isAvailable) async {
    final updated = await supabase
        .from('menu_items')
        .update({'is_available': isAvailable})
        .eq('id', itemId)
        .select('id');
    if (updated.isEmpty) throw StateError('menu item not updated');
  }

  Future<void> delete(String itemId) async {
    try {
      final deleted = await supabase
          .from('menu_items')
          .delete()
          .eq('id', itemId)
          .select('id');
      if (deleted.isEmpty) throw StateError('menu item not deleted');
    } catch (e) {
      if (_isForeignKeyViolation(e)) throw const MenuItemInUseException();
      rethrow;
    }
  }

  static bool _isForeignKeyViolation(Object e) {
    final text = e.toString().toLowerCase();
    return text.contains('23503') || text.contains('foreign key');
  }
}

final menuItemActionsProvider =
    Provider<MenuItemActions>((ref) => const MenuItemActions());
