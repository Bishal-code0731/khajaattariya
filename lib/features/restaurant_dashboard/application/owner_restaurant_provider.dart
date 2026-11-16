import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';
import '../domain/models/owner_restaurant.dart';

/// The restaurant owned by [ownerId], or null when the owner hasn't registered one yet.
final ownerRestaurantProvider = FutureProvider.autoDispose
    .family<OwnerRestaurant?, String>((ref, ownerId) async {
  final rows = await supabase
      .from('restaurants')
      .select(OwnerRestaurant.columns)
      .eq('owner_id', ownerId)
      .order('created_at', ascending: false)
      .limit(1);
  return rows.isEmpty ? null : OwnerRestaurant.fromMap(rows.first);
});

/// Owner-side writes to the `restaurants` row.
class OwnerRestaurantActions {
  const OwnerRestaurantActions();

  Future<void> setOpen(String restaurantId, bool isOpen) async {
    final updated = await supabase
        .from('restaurants')
        .update({'is_open': isOpen})
        .eq('id', restaurantId)
        .select('id');
    if (updated.isEmpty) throw StateError('restaurant row not updated');
  }

  Future<void> updateDetails(
      String restaurantId, RestaurantDetailsInput input) async {
    final updated = await supabase
        .from('restaurants')
        .update(input.toMap())
        .eq('id', restaurantId)
        .select('id');
    if (updated.isEmpty) throw StateError('restaurant row not updated');
  }
}

final ownerRestaurantActionsProvider = Provider<OwnerRestaurantActions>(
  (ref) => const OwnerRestaurantActions(),
);
