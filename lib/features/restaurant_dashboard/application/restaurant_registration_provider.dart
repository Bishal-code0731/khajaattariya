import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../main.dart';

part 'restaurant_registration_provider.g.dart';

@Riverpod(keepAlive: true)
class RestaurantRegistration extends _$RestaurantRegistration {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> register({
    required String ownerId,
    required String name,
    required String cuisineType,
    String? address,
    String? phone,
    String? imageUrl,
    int deliveryTimeMin = 30,
    double deliveryFee = 0,
  }) async {
    state = const AsyncValue.loading();
    try {
      await supabase.from('restaurants').insert({
        'owner_id': ownerId,
        'name': name,
        'cuisine_type': cuisineType,
        'address': address,
        'phone': phone,
        'image_url': imageUrl,
        'delivery_time_min': deliveryTimeMin,
        'delivery_fee': deliveryFee,
      });
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
