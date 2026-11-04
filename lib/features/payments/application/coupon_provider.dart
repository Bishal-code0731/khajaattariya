import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../main.dart';
import '../domain/models/coupon_model.dart';

part 'coupon_provider.g.dart';

@Riverpod(keepAlive: true)
class CouponValidation extends _$CouponValidation {
  @override
  AsyncValue<CouponModel?> build() => const AsyncValue.data(null);

  Future<CouponModel?> validateCoupon({
    required String code,
    required double orderTotal,
    required String customerId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final data = await supabase
          .from('coupons')
          .select()
          .eq('code', code.toUpperCase())
          .eq('is_active', true)
          .maybeSingle();
      if (data == null) throw Exception('Coupon not found or inactive');
      final coupon = CouponModel.fromMap(data);
      if (coupon.isExpired) throw Exception('Coupon has expired');
      if (coupon.isFull) throw Exception('Coupon usage limit reached');
      if (orderTotal < coupon.minOrderAmount) {
        throw Exception(
            'Minimum order Rs. ${coupon.minOrderAmount.toInt()} required');
      }
      final used = await supabase
          .from('coupon_usage')
          .select('id')
          .eq('coupon_id', coupon.id)
          .eq('customer_id', customerId)
          .maybeSingle();
      if (used != null) throw Exception('You have already used this coupon');
      state = AsyncValue.data(coupon);
      return coupon;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void clear() => state = const AsyncValue.data(null);

  Future<void> recordUsage({
    required String couponId,
    required String customerId,
    required String orderId,
    required double discountApplied,
  }) async {
    await supabase.from('coupon_usage').insert({
      'coupon_id': couponId,
      'customer_id': customerId,
      'order_id': orderId,
      'discount_applied': discountApplied,
    });
    await supabase
        .rpc('increment_coupon_uses', params: {'coupon_id': couponId});
  }

  Future<void> recordUsageForOrders({
    required String couponId,
    required String customerId,
    required Map<String, double> discountPerOrder,
  }) async {
    await supabase.from('coupon_usage').insert([
      for (final entry in discountPerOrder.entries)
        {
          'coupon_id': couponId,
          'customer_id': customerId,
          'order_id': entry.key,
          'discount_applied': entry.value,
        },
    ]);
    await supabase
        .rpc('increment_coupon_uses', params: {'coupon_id': couponId});
  }
}

@Riverpod(keepAlive: true)
Future<List<CouponModel>> allCoupons(Ref ref) async {
  final data = await supabase
      .from('coupons')
      .select()
      .order('created_at', ascending: false);
  return (data as List)
      .map((m) => CouponModel.fromMap(m as Map<String, dynamic>))
      .toList();
}

@Riverpod(keepAlive: true)
class CreateCoupon extends _$CreateCoupon {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> create({
    required String code,
    required String discountType,
    required double discountValue,
    required double minOrderAmount,
    double? maxDiscount,
    int? maxUses,
    DateTime? validUntil,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      await supabase.from('coupons').insert({
        'code': code.toUpperCase(),
        'description': description,
        'discount_type': discountType,
        'discount_value': discountValue,
        'min_order_amount': minOrderAmount,
        'max_discount': maxDiscount,
        'max_uses': maxUses,
        'valid_until': validUntil?.toIso8601String(),
        'is_active': true,
      });
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> toggleActive(String couponId, bool newValue) async {
    state = const AsyncValue.loading();
    try {
      await supabase
          .from('coupons')
          .update({'is_active': newValue}).eq('id', couponId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
