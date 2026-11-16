import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/delivery_info.dart';
import '../../domain/repositories/rider_delivery_repository.dart';

class SupabaseRiderDeliveryRepository implements RiderDeliveryRepository {
  const SupabaseRiderDeliveryRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, DeliveryInfo>> fetchDeliveryInfo(
      List<String> orderIds) async {
    if (orderIds.isEmpty) return const {};
    final rows = await _client
        .from('orders')
        .select(
            'id, payment_method, payment_status, restaurants(address, phone)')
        .inFilter('id', orderIds);
    return {
      for (final row in rows) row['id'] as String: _fromRow(row),
    };
  }

  static DeliveryInfo _fromRow(Map<String, dynamic> row) {
    final restaurant = row['restaurants'] as Map<String, dynamic>? ?? const {};
    return DeliveryInfo(
      orderId: row['id'] as String,
      isCash: (row['payment_method'] as String? ?? 'cash') == 'cash',
      isPaid: row['payment_status'] == 'paid',
      restaurantAddress: restaurant['address'] as String?,
      restaurantPhone: restaurant['phone'] as String?,
    );
  }
}
