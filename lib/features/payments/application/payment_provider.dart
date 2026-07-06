import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/app_logger.dart';
import '../../../main.dart';
import '../domain/models/payment_model.dart';

part 'payment_provider.g.dart';

const _supabaseUrl = 'https://xuupnxmqqvipfegxtoqm.supabase.co';

class PaymentState {
  final bool isLoading;
  final String? error;
  final String? khaltiPaymentUrl;
  final String? stripeClientSecret;
  final bool isSuccess;

  const PaymentState({
    this.isLoading = false,
    this.error,
    this.khaltiPaymentUrl,
    this.stripeClientSecret,
    this.isSuccess = false,
  });

  PaymentState copyWith({
    bool? isLoading,
    String? error,
    String? khaltiPaymentUrl,
    String? stripeClientSecret,
    bool? isSuccess,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      khaltiPaymentUrl: khaltiPaymentUrl ?? this.khaltiPaymentUrl,
      stripeClientSecret: stripeClientSecret ?? this.stripeClientSecret,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

@Riverpod(keepAlive: true)
class PaymentNotifier extends _$PaymentNotifier {
  @override
  PaymentState build() => const PaymentState();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${supabase.auth.currentSession?.accessToken}',
  };

  // ── KHALTI ────────────────────────────────────────────────

  /// [orderAmounts] maps orderId -> that order's own total. A
  /// multi-restaurant checkout places one order per restaurant, but the
  /// user still pays once — one gateway transaction for the combined
  /// total, then one `payments` row per order (payments.order_id is a
  /// single FK, so a combined row isn't representable) all sharing the
  /// same gateway_ref so they're traceable back to one real transaction.
  /// A double-tap on "Pay" (or a retry after a transient error) before
  /// this order's first pending/completed payment row exists would
  /// otherwise create a second gateway transaction for the same order —
  /// this blocks that instead of silently double-charging.
  Future<void> _assertNoActivePayment(Iterable<String> orderIds) async {
    final existing = await supabase
        .from('payments')
        .select('order_id, status')
        .inFilter('order_id', orderIds.toList())
        .inFilter('status', ['pending', 'completed']);
    if (existing.isNotEmpty) {
      throw Exception('A payment for this order is already in progress or completed.');
    }
  }

  Future<String?> initiateKhaltiPayment({
    required Map<String, double> orderAmounts,
    required String customerId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _assertNoActivePayment(orderAmounts.keys);
      final totalAmount = orderAmounts.values.fold<double>(0, (s, a) => s + a);
      final primaryOrderId = orderAmounts.keys.first;

      final response = await http.post(
        Uri.parse('$_supabaseUrl/functions/v1/khalti-initiate'),
        headers: _headers,
        body: jsonEncode({
          'order_id': primaryOrderId,
          'amount': (totalAmount * 100).toInt(), // Rs to paisa
          'purchase_order_name': orderAmounts.length > 1
              ? 'KhajaAttariya Order (${orderAmounts.length} restaurants)'
              : 'KhajaAttariya Order',
          // Custom app scheme (see AndroidManifest.xml / Info.plist) —
          // Khalti's hosted checkout redirects here on completion, and
          // PaymentDeepLinkListener picks it up to auto-verify instead
          // of requiring the user to paste the pidx back in by hand.
          'return_url': 'khajaattariya://payment/khalti-callback',
          'website_url': 'https://khajaattariya.com',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Khalti error: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final pidx = data['pidx'] as String;
      final paymentUrl = data['payment_url'] as String;

      for (final entry in orderAmounts.entries) {
        await supabase.from('payments').insert({
          'order_id': entry.key,
          'customer_id': customerId,
          'method': 'khalti',
          'status': 'pending',
          'amount': entry.value,
          'currency': 'NPR',
          'gateway_ref': pidx,
          'gateway_payload': data,
        });
        await _logEvent(orderId: entry.key, event: 'initiated', payload: data);
      }

      state = state.copyWith(isLoading: false, khaltiPaymentUrl: paymentUrl);
      return paymentUrl;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> verifyKhaltiPayment({
    required String pidx,
    required List<String> orderIds,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.post(
        Uri.parse('$_supabaseUrl/functions/v1/khalti-verify'),
        headers: _headers,
        body: jsonEncode({'pidx': pidx}),
      );

      if (response.statusCode != 200) throw Exception('Khalti verify failed');

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String?;

      if (status == 'Completed') {
        // Only mark orders paid whose payments row was actually found and
        // updated — trusting the caller-supplied orderIds blindly would
        // mark an order paid even if its payments row was never created
        // (e.g. a partial failure during initiate).
        final updatedPayments = await supabase.from('payments')
            .update({'status': 'completed', 'gateway_payload': data})
            .eq('gateway_ref', pidx)
            .select('order_id');
        final confirmedOrderIds = updatedPayments.map((p) => p['order_id'] as String).toSet();

        for (final orderId in orderIds) {
          if (!confirmedOrderIds.contains(orderId)) continue;
          await supabase.from('orders')
              .update({'payment_status': 'paid'})
              .eq('id', orderId);
          await _logEvent(orderId: orderId, event: 'verified', payload: data);
        }

        state = state.copyWith(isLoading: false, isSuccess: true);
        return true;
      }
      throw Exception('Payment not completed. Status: $status');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── STRIPE ────────────────────────────────────────────────

  Future<String?> initiateStripePayment({
    required Map<String, double> orderAmounts,
    required String customerId,
    String? customerEmail,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _assertNoActivePayment(orderAmounts.keys);
      final totalAmount = orderAmounts.values.fold<double>(0, (s, a) => s + a);
      final primaryOrderId = orderAmounts.keys.first;

      final response = await http.post(
        Uri.parse('$_supabaseUrl/functions/v1/stripe-initiate'),
        headers: _headers,
        body: jsonEncode({
          'order_id': primaryOrderId,
          'amount': (totalAmount * 100).toInt(), // cents
          'currency': 'usd',
          'customer_email': customerEmail,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Stripe error: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final clientSecret = data['client_secret'] as String;
      final paymentIntentId = data['id'] as String;

      for (final entry in orderAmounts.entries) {
        await supabase.from('payments').insert({
          'order_id': entry.key,
          'customer_id': customerId,
          'method': 'stripe',
          'status': 'pending',
          'amount': entry.value,
          'currency': 'usd',
          'gateway_ref': paymentIntentId,
          'gateway_payload': data,
        });
        await _logEvent(orderId: entry.key, event: 'initiated', payload: data);
      }

      state = state.copyWith(isLoading: false, stripeClientSecret: clientSecret);
      return clientSecret;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> confirmStripePayment({
    required String paymentIntentId,
    required List<String> orderIds,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Don't trust presentPaymentSheet() not throwing as proof of
      // payment — re-check the PaymentIntent's real status with Stripe
      // server-side (via the stripe-verify function) before marking
      // anything paid, same as the Khalti flow already does.
      final verifyResponse = await http.post(
        Uri.parse('$_supabaseUrl/functions/v1/stripe-verify'),
        headers: _headers,
        body: jsonEncode({'payment_intent_id': paymentIntentId}),
      );
      if (verifyResponse.statusCode != 200) {
        throw Exception('Stripe verify failed');
      }
      final verifyData = jsonDecode(verifyResponse.body) as Map<String, dynamic>;
      if (verifyData['status'] != 'succeeded') {
        throw Exception('Payment not completed. Status: ${verifyData['status']}');
      }

      final updatedPayments = await supabase.from('payments')
          .update({'status': 'completed', 'gateway_payload': verifyData})
          .eq('gateway_ref', paymentIntentId)
          .select('order_id');
      final confirmedOrderIds = updatedPayments.map((p) => p['order_id'] as String).toSet();

      for (final orderId in orderIds) {
        if (!confirmedOrderIds.contains(orderId)) continue;
        await supabase.from('orders')
            .update({'payment_status': 'paid'})
            .eq('id', orderId);
        await _logEvent(
          orderId: orderId,
          event: 'verified',
          payload: {'payment_intent_id': paymentIntentId},
        );
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── HELPER ────────────────────────────────────────────────

  Future<void> _logEvent({
    required String orderId,
    required String event,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final payment = await supabase
          .from('payments').select('id').eq('order_id', orderId).maybeSingle();
      if (payment != null) {
        await supabase.from('payment_logs').insert({
          'payment_id': payment['id'],
          'event': event,
          'payload': payload,
        });
      }
    } catch (e) {
      AppLogger.warning('Payment', 'Failed to log event "$event" for order $orderId: $e');
    }
  }

  void reset() => state = const PaymentState();
}

// ── Providers ──────────────────────────────────────────────

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
      .from('payments').select().eq('customer_id', customerId)
      .order('created_at', ascending: false);
  return (data as List)
      .map((m) => PaymentModel.fromMap(m as Map<String, dynamic>))
      .toList();
}
