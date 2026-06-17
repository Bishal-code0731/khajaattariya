class RiderModel {
  final String id;
  final String fullName;
  final String? phone;
  final String vehicleType;
  final String? vehicleNumber;
  final bool isOnline;
  final bool isApproved;
  final String? approvalNote;
  final double? currentLat;
  final double? currentLng;
  final int totalDeliveries;
  final double totalEarnings;
  final DateTime createdAt;

  const RiderModel({
    required this.id,
    required this.fullName,
    this.phone,
    required this.vehicleType,
    this.vehicleNumber,
    required this.isOnline,
    required this.isApproved,
    this.approvalNote,
    this.currentLat,
    this.currentLng,
    required this.totalDeliveries,
    required this.totalEarnings,
    required this.createdAt,
  });

  factory RiderModel.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>? ?? {};
    return RiderModel(
      id: map['id'] as String,
      fullName: profile['full_name'] as String? ?? map['full_name'] as String? ?? '',
      phone: profile['phone'] as String? ?? map['phone'] as String?,
      vehicleType: map['vehicle_type'] as String? ?? 'motorcycle',
      vehicleNumber: map['vehicle_number'] as String?,
      isOnline: map['is_online'] as bool? ?? false,
      isApproved: map['is_approved'] as bool? ?? false,
      approvalNote: map['approval_note'] as String?,
      currentLat: (map['current_lat'] as num?)?.toDouble(),
      currentLng: (map['current_lng'] as num?)?.toDouble(),
      totalDeliveries: map['total_deliveries'] as int? ?? 0,
      totalEarnings: (map['total_earnings'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  RiderModel copyWith({bool? isOnline, double? currentLat, double? currentLng, bool? isApproved}) {
    return RiderModel(
      id: id, fullName: fullName, phone: phone,
      vehicleType: vehicleType, vehicleNumber: vehicleNumber,
      isOnline: isOnline ?? this.isOnline,
      isApproved: isApproved ?? this.isApproved,
      approvalNote: approvalNote,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      totalDeliveries: totalDeliveries, totalEarnings: totalEarnings, createdAt: createdAt,
    );
  }
}