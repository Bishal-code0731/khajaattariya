class RiderEarningModel {
  final String id;
  final String riderId;
  final String orderId;
  final double amount;
  final String status;
  final DateTime? paidAt;
  final DateTime createdAt;

  const RiderEarningModel({
    required this.id,
    required this.riderId,
    required this.orderId,
    required this.amount,
    required this.status,
    this.paidAt,
    required this.createdAt,
  });

  factory RiderEarningModel.fromMap(Map<String, dynamic> map) {
    return RiderEarningModel(
      id: map['id'] as String,
      riderId: map['rider_id'] as String,
      orderId: map['order_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      status: map['status'] as String? ?? 'pending',
      paidAt: map['paid_at'] != null ? DateTime.parse(map['paid_at'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}