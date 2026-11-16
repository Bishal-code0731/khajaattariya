/// Where an owner's restaurant stands with the admin team.
enum RestaurantApproval {
  /// Live: customers can see it.
  approved,

  /// Submitted, waiting for an admin.
  pending,

  /// An admin turned it down (see [OwnerRestaurant.approvalNote]).
  rejected,
}

/// The restaurant row as its owner sees it (includes unapproved data).
class OwnerRestaurant {
  const OwnerRestaurant({
    required this.id,
    required this.name,
    required this.cuisineType,
    required this.deliveryTimeMin,
    required this.isOpen,
    required this.isApproved,
    required this.isActive,
    this.imageUrl,
    this.address,
    this.phone,
    this.offer,
    this.approvalNote,
  });

  final String id;
  final String name;
  final String cuisineType;
  final int deliveryTimeMin;
  final bool isOpen;
  final bool isApproved;
  final bool isActive;
  final String? imageUrl;
  final String? address;
  final String? phone;
  final String? offer;
  final String? approvalNote;

  static const columns =
      'id, name, image_url, cuisine_type, delivery_time_min, is_open, is_approved, '
      'is_active, approval_note, offer, address, phone';

  RestaurantApproval get approval {
    if (isApproved && isActive) return RestaurantApproval.approved;
    final note = approvalNote?.trim() ?? '';
    if (note.isNotEmpty || !isActive) {
      return RestaurantApproval.rejected;
    }
    return RestaurantApproval.pending;
  }

  factory OwnerRestaurant.fromMap(Map<String, dynamic> map) {
    return OwnerRestaurant(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      cuisineType: map['cuisine_type'] as String? ?? '',
      deliveryTimeMin: (map['delivery_time_min'] as num?)?.toInt() ?? 30,
      isOpen: map['is_open'] as bool? ?? true,
      isApproved: map['is_approved'] as bool? ?? false,
      isActive: map['is_active'] as bool? ?? true,
      imageUrl: map['image_url'] as String?,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      offer: map['offer'] as String?,
      approvalNote: map['approval_note'] as String?,
    );
  }
}

/// Owner-editable restaurant fields (registration and the details form).
class RestaurantDetailsInput {
  const RestaurantDetailsInput({
    required this.name,
    required this.cuisineType,
    required this.address,
    required this.phone,
    required this.deliveryTimeMin,
    this.imageUrl,
    this.offer,
  });

  final String name;
  final String cuisineType;
  final String address;
  final String phone;
  final int deliveryTimeMin;
  final String? imageUrl;
  final String? offer;

  Map<String, dynamic> toMap() => {
        'name': name,
        'cuisine_type': cuisineType,
        'address': address,
        'phone': phone,
        'delivery_time_min': deliveryTimeMin,
        'image_url': imageUrl,
        'offer': offer,
      };
}
