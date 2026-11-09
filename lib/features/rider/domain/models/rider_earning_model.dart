class RiderEarningModel {
  final String id;
  final String riderId;
  final String orderId;
  final double amount;

  /// 'pending' until an admin marks it paid.
  final String status;
  final DateTime? paidAt;
  final DateTime createdAt;

  const RiderEarningModel({
    required this.id,
    required this.riderId,
    required this.orderId,
    required this.amount,
    required this.createdAt,
    this.status = 'pending',
    this.paidAt,
  });

  bool get isPaid => status == 'paid';

  factory RiderEarningModel.fromMap(Map<String, dynamic> map) {
    return RiderEarningModel(
      id: map['id'] as String,
      riderId: map['rider_id'] as String,
      orderId: map['order_id'] as String,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'pending',
      paidAt: DateTime.tryParse(map['paid_at'] as String? ?? ''),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
