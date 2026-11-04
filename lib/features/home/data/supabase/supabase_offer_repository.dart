import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../payments/domain/models/coupon_model.dart';
import '../../domain/repositories/offer_repository.dart';

/// Supabase implementation: table `coupons` (RLS: signed-in users read active coupons only).
class SupabaseOfferRepository implements OfferRepository {
  const SupabaseOfferRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CouponModel>> availableCoupons() async {
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = await _client
        .from('coupons')
        .select(
            'id, code, description, discount_type, discount_value, min_order_amount, '
            'max_discount, max_uses, uses_count, is_active, valid_until, created_at')
        .eq('is_active', true)
        .lte('valid_from', now)
        .order('discount_value', ascending: false)
        .limit(50);
    return rows
        .map(CouponModel.fromMap)
        .where((c) => !c.isExpired && !c.isFull)
        .toList();
  }
}
