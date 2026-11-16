class RefundModel {
  final String id;
  final String paymentId;
  final String orderId;
  final double amount;
  final String? reason;
  final String status;
  final DateTime createdAt;

  const RefundModel({
    required this.id,
    required this.paymentId,
    required this.orderId,
    required this.amount,
    this.reason,
    required this.status,
    required this.createdAt,
  });

  factory RefundModel.fromMap(Map<String, dynamic> map) {
    return RefundModel(
      id: map['id'] as String,
      paymentId: map['payment_id'] as String,
      orderId: map['order_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      reason: map['reason'] as String?,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
