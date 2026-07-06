class DeliveryPositionModel {
  final String orderId;
  final String riderId;
  final double lat;
  final double lng;
  final DateTime recordedAt;

  const DeliveryPositionModel({
    required this.orderId,
    required this.riderId,
    required this.lat,
    required this.lng,
    required this.recordedAt,
  });

  factory DeliveryPositionModel.fromMap(Map<String, dynamic> map) {
    return DeliveryPositionModel(
      orderId: map['order_id'] as String,
      riderId: map['rider_id'] as String,
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      recordedAt: DateTime.parse(map['recorded_at'] as String),
    );
  }
}
