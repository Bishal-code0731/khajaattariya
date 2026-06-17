import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../main.dart';
import '../domain/models/payment_model.dart';

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

final paymentNotifierProvider =
StateNotifierProvider<PaymentNotifier, PaymentState>((ref) => PaymentNotifier());

class PaymentNotifier extends StateNotifier<PaymentState> {
  PaymentNotifier() : super(const PaymentState());

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${supabase.auth.currentSession?.accessToken}',
  };

  // ── KHALTI ────────────────────────────────────────────────

  Future<String?> initiateKhaltiPayment({
    required String orderId,
    required String customerId,
    required double amount,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.post(
        Uri.parse('$_supabaseUrl/functions/v1/khalti-initiate'),
        headers: _headers,
        body: jsonEncode({
          'order_id': orderId,
          'amount': (amount * 100).toInt(), // Rs to paisa
          'purchase_order_name': 'KhajaAttariya Order',
          'return_url': '$_supabaseUrl/functions/v1/khalti-return',
          'website_url': 'https://khajaattariya.com',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Khalti error: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final pidx = data['pidx'] as String;
      final paymentUrl = data['payment_url'] as String;

      await supabase.from('payments').insert({
        'order_id': orderId,
        'customer_id': customerId,
        'method': 'khalti',
        'status': 'pending',
        'amount': amount,
        'currency': 'NPR',
        'gateway_ref': pidx,
        'gateway_payload': data,
      });

      await _logEvent(orderId: orderId, event: 'initiated', payload: data);

      state = state.copyWith(isLoading: false, khaltiPaymentUrl: paymentUrl);
      return paymentUrl;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> verifyKhaltiPayment({
    required String pidx,
    required String orderId,
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
        await supabase.from('payments')
            .update({'status': 'completed', 'gateway_payload': data})
            .eq('gateway_ref', pidx);

        await supabase.from('orders')
            .update({'payment_status': 'paid'})
            .eq('id', orderId);

        await _logEvent(orderId: orderId, event: 'verified', payload: data);

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
    required String orderId,
    required String customerId,
    required double amount,
    String? customerEmail,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.post(
        Uri.parse('$_supabaseUrl/functions/v1/stripe-initiate'),
        headers: _headers,
        body: jsonEncode({
          'order_id': orderId,
          'amount': (amount * 100).toInt(), // cents
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

      await supabase.from('payments').insert({
        'order_id': orderId,
        'customer_id': customerId,
        'method': 'stripe',
        'status': 'pending',
        'amount': amount,
        'currency': 'usd',
        'gateway_ref': paymentIntentId,
        'gateway_payload': data,
      });

      await _logEvent(orderId: orderId, event: 'initiated', payload: data);

      state = state.copyWith(isLoading: false, stripeClientSecret: clientSecret);
      return clientSecret;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> confirmStripePayment({
    required String paymentIntentId,
    required String orderId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await supabase.from('payments')
          .update({'status': 'completed'})
          .eq('gateway_ref', paymentIntentId);

      await supabase.from('orders')
          .update({'payment_status': 'paid'})
          .eq('id', orderId);

      await _logEvent(
        orderId: orderId,
        event: 'verified',
        payload: {'payment_intent_id': paymentIntentId},
      );

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
    } catch (_) {}
  }

  void reset() => state = const PaymentState();
}

// ── Providers ──────────────────────────────────────────────

final platformSettingsProvider = FutureProvider<Map<String, String>>((ref) async {
  final data = await supabase.from('platform_settings').select();
  return {
    for (final row in (data as List))
      row['key'] as String: row['value'] as String
  };
});

final customerPaymentsProvider =
FutureProvider.family<List<PaymentModel>, String>((ref, customerId) async {
  final data = await supabase
      .from('payments').select().eq('customer_id', customerId)
      .order('created_at', ascending: false);
  return (data as List)
      .map((m) => PaymentModel.fromMap(m as Map<String, dynamic>))
      .toList();
});