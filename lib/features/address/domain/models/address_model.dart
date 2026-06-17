class AddressModel {
  final String id;
  final String userId;
  final String label; // Home, Work, Other
  final String fullAddress;
  final String? landmark;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime createdAt;

  const AddressModel({
    required this.id,
    required this.userId,
    required this.label,
    required this.fullAddress,
    this.landmark,
    this.latitude,
    this.longitude,
    required this.isDefault,
    required this.createdAt,
  });

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      label: map['label'] as String,
      fullAddress: map['full_address'] as String,
      landmark: map['landmark'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      isDefault: map['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'label': label,
      'full_address': fullAddress,
      'landmark': landmark,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault,
    };
  }
}