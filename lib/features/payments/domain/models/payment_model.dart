class PaymentModel {
  final String id;
  final String orderId;
  final String customerId;
  final String method; // 'cash' | 'khalti' | 'esewa'
  final String
      status; // 'pending' | 'completed' | 'failed' | 'expired' | 'refunded'
  final double amount;
  final String currency;
  final String? gatewayRef;
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.method,
    required this.status,
    required this.amount,
    required this.currency,
    this.gatewayRef,
    required this.createdAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      customerId: map['customer_id'] as String,
      method: map['method'] as String,
      status: map['status'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'NPR',
      gatewayRef: map['gateway_ref'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
