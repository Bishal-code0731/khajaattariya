class RiderModel {
  final String id;
  final String fullName;
  final String? phone;
  final String vehicleType;
  final String? vehicleNumber;
  final bool isOnline;
  final bool isApproved;
  final String? approvalNote;
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
    required this.totalDeliveries,
    required this.totalEarnings,
    required this.createdAt,
  });

  factory RiderModel.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>? ?? {};
    return RiderModel(
      id: map['id'] as String,
      fullName: profile['full_name'] as String? ?? '',
      phone: profile['phone'] as String?,
      vehicleType: map['vehicle_type'] as String? ?? 'motorcycle',
      vehicleNumber: map['vehicle_number'] as String?,
      isOnline: map['is_online'] as bool? ?? false,
      isApproved: map['is_approved'] as bool? ?? false,
      approvalNote: map['approval_note'] as String?,
      totalDeliveries: map['total_deliveries'] as int? ?? 0,
      totalEarnings: (map['total_earnings'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(
          map['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
