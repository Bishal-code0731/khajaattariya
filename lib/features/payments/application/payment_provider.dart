import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/app_logger.dart';
import '../../../main.dart';
import '../domain/models/payment_model.dart';

part 'payment_provider.g.dart';

const _khaltiReturnUrl = 'khajaattariya://payment/khalti-callback';
const _websiteUrl = 'https://khajaattariya.com';

/// Why a payment step failed, so the screen can show the right translated message.
enum PaymentFailure {
  /// A pending or completed payment already exists for the order.
  alreadyInProgress,

  /// Every order of this checkout is already paid.
  alreadyPaid,

  /// The gateway didn't return a checkout link.
  gatewayUnavailable,

  /// Khalti says the payment was cancelled, expired or refunded.
  notCompleted,

  /// Khalti hasn't finished processing the payment yet.
  stillPending,
}

class PaymentException implements Exception {
  const PaymentException(this.failure);
  final PaymentFailure failure;
  @override
  String toString() => 'PaymentException(${failure.name})';
}

/// Outcome of asking Khalti about a payment.
enum KhaltiCheckResult { received, pending, failed }

class PaymentState {
  final bool isLoading;
  final Object? error;
  final String? khaltiPaymentUrl;
  final String? khaltiPidx;
  final bool isSuccess;

  const PaymentState({
    this.isLoading = false,
    this.error,
    this.khaltiPaymentUrl,
    this.khaltiPidx,
    this.isSuccess = false,
  });

  PaymentState copyWith({
    bool? isLoading,
    Object? error,
    String? khaltiPaymentUrl,
    String? khaltiPidx,
    bool? isSuccess,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      khaltiPaymentUrl: khaltiPaymentUrl ?? this.khaltiPaymentUrl,
      khaltiPidx: khaltiPidx ?? this.khaltiPidx,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

@Riverpod(keepAlive: true)
class PaymentNotifier extends _$PaymentNotifier {
  @override
  PaymentState build() => const PaymentState();

  /// Server totals for the given orders, skipping already-paid ones.
  Future<Map<String, double>> _unpaidServerTotals(List<String> orderIds) async {
    final rows = await supabase
        .from('orders')
        .select('id, total_amount, payment_status, status')
        .inFilter('id', orderIds);
    final totals = <String, double>{};
    for (final row in rows) {
      if (row['payment_status'] == 'paid' || row['status'] == 'cancelled') {
        continue;
      }
      totals[row['id'] as String] = (row['total_amount'] as num).toDouble();
    }
    return totals;
  }

  Future<void> _assertNoActivePayment(Iterable<String> orderIds) async {
    final existing = await supabase
        .from('payments')
        .select('order_id')
        .inFilter('order_id', orderIds.toList())
        .inFilter('status', ['pending', 'completed']);
    if (existing.isNotEmpty) {
      throw const PaymentException(PaymentFailure.alreadyInProgress);
    }
  }

  // KHALTI

  Future<String?> initiateKhaltiPayment({
    required List<String> orderIds,
    required String customerId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final totals = await _unpaidServerTotals(orderIds);
      if (totals.isEmpty) {
        throw const PaymentException(PaymentFailure.alreadyPaid);
      }
      await _assertNoActivePayment(totals.keys);
      final totalAmount = totals.values.fold<double>(0, (s, a) => s + a);

      final response = await supabase.functions.invoke(
        'khalti-initiate',
        body: {
          'order_id': totals.keys.first,
          'amount': (totalAmount * 100).round(), // rupees → paisa
          'purchase_order_name': totals.length > 1
              ? 'KhajaAttariya Order (${totals.length} restaurants)'
              : 'KhajaAttariya Order',
          'return_url': _khaltiReturnUrl,
          'website_url': _websiteUrl,
        },
      );
      final data = response.data;
      if (data is! Map ||
          data['pidx'] is! String ||
          data['payment_url'] is! String) {
        AppLogger.warning('Payment', 'khalti-initiate returned no pidx');
        throw const PaymentException(PaymentFailure.gatewayUnavailable);
      }
      final payload = Map<String, dynamic>.from(data);
      final pidx = payload['pidx'] as String;
      final paymentUrl = payload['payment_url'] as String;

      for (final orderId in totals.keys) {
        await supabase.from('payments').insert({
          'order_id': orderId,
          'customer_id': customerId,
          'method': 'khalti',
          'status': 'pending',
          'currency': 'NPR',
          'gateway_ref': pidx,
          'gateway_payload': payload,
        });
        await _logEvent(
            orderId: orderId, pidx: pidx, event: 'initiated', payload: payload);
      }

      state = state.copyWith(
          isLoading: false, khaltiPaymentUrl: paymentUrl, khaltiPidx: pidx);
      return paymentUrl;
    } catch (e) {
      AppLogger.warning('Payment', 'khalti initiate failed: $e');
      state = state.copyWith(isLoading: false, error: e);
      return null;
    }
  }

  /// Asks Khalti (through the khalti-verify function) how the payment went.
  Future<KhaltiCheckResult> checkKhaltiPayment({
    required String pidx,
    required List<String> orderIds,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await supabase.functions.invoke(
        'khalti-verify',
        body: {'pidx': pidx},
      );
      final data = response.data;
      final status = data is Map ? data['status'] as String? : null;
      final payload =
          data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

      final KhaltiCheckResult result;
      switch (status) {
        case 'Completed':
          result = KhaltiCheckResult.received;
        case 'Pending':
        case 'Initiated':
          result = KhaltiCheckResult.pending;
        default:
          result = KhaltiCheckResult.failed;
      }
      for (final orderId in orderIds) {
        await _logEvent(
          orderId: orderId,
          pidx: pidx,
          event: 'client_checked_${status ?? 'unknown'}',
          payload: payload,
        );
      }
      state = state.copyWith(
        isLoading: false,
        isSuccess: result == KhaltiCheckResult.received,
      );
      return result;
    } catch (e) {
      AppLogger.warning('Payment', 'khalti check failed: $e');
      state = state.copyWith(isLoading: false, error: e);
      return KhaltiCheckResult.pending;
    }
  }

  // CASH

  Future<bool> placeCashOrder({
    required List<String> orderIds,
    required String customerId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final totals = await _unpaidServerTotals(orderIds);
      final existing = await supabase
          .from('payments')
          .select('order_id, method, status')
          .inFilter('order_id', totals.keys.toList())
          .inFilter('status', ['pending', 'completed']);
      final covered = {
        for (final p in existing)
          if (p['status'] == 'completed' || p['method'] == 'cash')
            p['order_id'] as String,
      };
      for (final orderId in totals.keys) {
        if (covered.contains(orderId)) continue;
        await supabase.from('payments').insert({
          'order_id': orderId,
          'customer_id': customerId,
          'method': 'cash',
          'status': 'pending',
          'currency': 'NPR',
        });
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      AppLogger.warning('Payment', 'cash order failed: $e');
      state = state.copyWith(isLoading: false, error: e);
      return false;
    }
  }

  // HELPER

  Future<void> _logEvent({
    required String orderId,
    required String pidx,
    required String event,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final payment = await supabase
          .from('payments')
          .select('id')
          .eq('order_id', orderId)
          .eq('gateway_ref', pidx)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (payment != null) {
        await supabase.from('payment_logs').insert({
          'payment_id': payment['id'],
          'event': event,
          'payload': payload,
        });
      }
    } catch (e) {
      AppLogger.warning(
          'Payment', 'Failed to log event "$event" for order $orderId: $e');
    }
  }

  void reset() => state = const PaymentState();
}

// Providers

@Riverpod(keepAlive: true)
Future<Map<String, String>> platformSettings(Ref ref) async {
  final data = await supabase.from('platform_settings').select();
  return {
    for (final row in (data as List))
      row['key'] as String: row['value'] as String
  };
}

@Riverpod(keepAlive: true)
Future<List<PaymentModel>> customerPayments(Ref ref, String customerId) async {
  final data = await supabase
      .from('payments')
      .select()
      .eq('customer_id', customerId)
      .order('created_at', ascending: false);
  return (data as List)
      .map((m) => PaymentModel.fromMap(m as Map<String, dynamic>))
      .toList();
}
