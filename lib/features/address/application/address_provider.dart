import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';
import '../domain/models/address_model.dart';

final addressListProvider =
StreamProvider.family<List<AddressModel>, String>((ref, userId) {
  return supabase
      .from('addresses')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('is_default', ascending: false)
      .map((data) =>
      data.map((m) => AddressModel.fromMap(m)).toList());
});

final addressNotifierProvider =
StateNotifierProvider<AddressNotifier, AsyncValue<void>>(
        (ref) => AddressNotifier());

class AddressNotifier extends StateNotifier<AsyncValue<void>> {
  AddressNotifier() : super(const AsyncValue.data(null));

  Future<bool> addAddress({
    required String userId,
    required String label,
    required String fullAddress,
    String? landmark,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      // If setting as default, unset existing default first
      if (isDefault) {
        await supabase
            .from('addresses')
            .update({'is_default': false}).eq('user_id', userId);
      }
      await supabase.from('addresses').insert({
        'user_id': userId,
        'label': label,
        'full_address': fullAddress,
        'landmark': landmark,
        'latitude': latitude,
        'longitude': longitude,
        'is_default': isDefault,
      });
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> updateAddress({
    required String addressId,
    required String userId,
    required String label,
    required String fullAddress,
    String? landmark,
    bool isDefault = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      if (isDefault) {
        await supabase
            .from('addresses')
            .update({'is_default': false}).eq('user_id', userId);
      }
      await supabase.from('addresses').update({
        'label': label,
        'full_address': fullAddress,
        'landmark': landmark,
        'is_default': isDefault,
      }).eq('id', addressId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<void> setDefault({
    required String addressId,
    required String userId,
  }) async {
    try {
      await supabase
          .from('addresses')
          .update({'is_default': false}).eq('user_id', userId);
      await supabase
          .from('addresses')
          .update({'is_default': true}).eq('id', addressId);
    } catch (_) {}
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      await supabase.from('addresses').delete().eq('id', addressId);
    } catch (_) {}
  }
}