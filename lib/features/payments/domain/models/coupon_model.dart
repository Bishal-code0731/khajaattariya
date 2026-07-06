class CouponModel {
  final String id;
  final String code;
  final String? description;
  final String discountType; // 'percent' | 'fixed'
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscount;
  final int? maxUses;
  final int usesCount;
  final bool isActive;
  final DateTime? validUntil;
  final DateTime createdAt;

  const CouponModel({
    required this.id,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    this.maxDiscount,
    this.maxUses,
    required this.usesCount,
    required this.isActive,
    this.validUntil,
    required this.createdAt,
  });

  bool get isExpired =>
      validUntil != null && validUntil!.isBefore(DateTime.now());

  bool get isFull => maxUses != null && usesCount >= maxUses!;

  double calculateDiscount(double orderTotal) {
    double discount;
    if (discountType == 'percent') {
      discount = orderTotal * (discountValue / 100);
      if (maxDiscount != null && discount > maxDiscount!) {
        discount = maxDiscount!;
      }
    } else {
      discount = discountValue;
    }
    return discount > orderTotal ? orderTotal : discount;
  }

  factory CouponModel.fromMap(Map<String, dynamic> map) {
    return CouponModel(
      id: map['id'] as String,
      code: map['code'] as String,
      description: map['description'] as String?,
      discountType: map['discount_type'] as String,
      discountValue: (map['discount_value'] as num).toDouble(),
      minOrderAmount: (map['min_order_amount'] as num).toDouble(),
      maxDiscount: (map['max_discount'] as num?)?.toDouble(),
      maxUses: map['max_uses'] as int?,
      usesCount: map['uses_count'] as int? ?? 0,
      isActive: map['is_active'] as bool? ?? true,
      validUntil: map['valid_until'] != null
          ? DateTime.parse(map['valid_until'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
