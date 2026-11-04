import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../main.dart';
import '../domain/models/rating_model.dart';

part 'rating_provider.g.dart';

/// All reviews for a restaurant, most recent first.
@Riverpod(keepAlive: true)
Future<List<RatingModel>> restaurantRatings(
    Ref ref, String restaurantId) async {
  final data = await supabase
      .from('ratings')
      .select('*, profiles!customer_id(full_name)')
      .eq('restaurant_id', restaurantId)
      .order('created_at', ascending: false);
  return (data as List)
      .map((m) => RatingModel.fromMap(m as Map<String, dynamic>))
      .toList();
}

@Riverpod(keepAlive: true)
class RatingNotifier extends _$RatingNotifier {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> submitRating({
    required String orderId,
    required String customerId,
    required String restaurantId,
    required int rating,
    String? review,
  }) async {
    state = const AsyncValue.loading();
    try {
      await supabase.from('ratings').insert({
        'order_id': orderId,
        'customer_id': customerId,
        'restaurant_id': restaurantId,
        'rating': rating,
        'review': review,
      });
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
