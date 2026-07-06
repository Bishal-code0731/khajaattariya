class RiderEarningModel {
  final String id;
  final String riderId;
  final String orderId;
  final double amount;
  final DateTime createdAt;

  const RiderEarningModel({
    required this.id,
    required this.riderId,
    required this.orderId,
    required this.amount,
    required this.createdAt,
  });

  factory RiderEarningModel.fromMap(Map<String, dynamic> map) {
    return RiderEarningModel(
      id: map['id'] as String,
      riderId: map['rider_id'] as String,
      orderId: map['order_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
