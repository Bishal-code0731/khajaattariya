import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../main.dart';
import '../domain/models/refund_model.dart';

part 'refund_provider.g.dart';

/// A customer's own refund requests, most recent first.
@Riverpod(keepAlive: true)
Future<List<RefundModel>> customerRefunds(Ref ref, String customerId) async {
  final data = await supabase
      .from('refunds')
      .select('*, orders!inner(customer_id)')
      .eq('orders.customer_id', customerId)
      .order('created_at', ascending: false);
  return (data as List)
      .map((m) => RefundModel.fromMap(m as Map<String, dynamic>))
      .toList();
}

/// Admin: every refund request, most recent first.
@Riverpod(keepAlive: true)
Future<List<Map<String, dynamic>>> allRefunds(Ref ref) async {
  final data = await supabase
      .from('refunds')
      .select('*, orders(customer_id, total_amount, profiles!customer_id(full_name))')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(data);
}

@Riverpod(keepAlive: true)
class RefundNotifier extends _$RefundNotifier {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> requestRefund({
    required String orderId,
    required double amount,
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    try {
      final payment = await supabase
          .from('payments')
          .select('id, status')
          .eq('order_id', orderId)
          .maybeSingle();
      if (payment == null) {
        throw Exception('No payment found for this order.');
      }
      // A refund only makes sense once money was actually captured — a
      // cancelled order with a still-pending/failed payment row has
      // nothing to refund.
      if (payment['status'] != 'completed') {
        throw Exception('This order has no completed payment to refund.');
      }
      await supabase.from('refunds').insert({
        'payment_id': payment['id'],
        'order_id': orderId,
        'amount': amount,
        'reason': reason,
        'status': 'pending',
      });
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateStatus(String refundId, String status) async {
    state = const AsyncValue.loading();
    try {
      final updated = await supabase.from('refunds').update({
        'status': status,
        if (status != 'pending') 'processed_at': DateTime.now().toIso8601String(),
      }).eq('id', refundId).select('id');
      if (updated.isEmpty) {
        throw Exception('Could not update refund. Please try again.');
      }
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
