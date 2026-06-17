class CouponModel {
  final String id;
  final String code;
  final String? description;
  final String discountType;
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscount;
  final int? maxUses;
  final int usesCount;
  final DateTime validFrom;
  final DateTime? validUntil;
  final bool isActive;

  const CouponModel({
    required this.id, required this.code, this.description,
    required this.discountType, required this.discountValue,
    required this.minOrderAmount, this.maxDiscount, this.maxUses,
    required this.usesCount, required this.validFrom,
    this.validUntil, required this.isActive,
  });

  factory CouponModel.fromMap(Map<String, dynamic> map) {
    return CouponModel(
      id: map['id'] as String,
      code: map['code'] as String,
      description: map['description'] as String?,
      discountType: map['discount_type'] as String? ?? 'percent',
      discountValue: (map['discount_value'] as num).toDouble(),
      minOrderAmount: (map['min_order_amount'] as num).toDouble(),
      maxDiscount: (map['max_discount'] as num?)?.toDouble(),
      maxUses: map['max_uses'] as int?,
      usesCount: map['uses_count'] as int? ?? 0,
      validFrom: DateTime.parse(map['valid_from'] as String),
      validUntil: map['valid_until'] != null ? DateTime.parse(map['valid_until'] as String) : null,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  double calculateDiscount(double orderTotal) {
    if (orderTotal < minOrderAmount) return 0;
    if (discountType == 'fixed') return discountValue;
    final d = orderTotal * (discountValue / 100);
    return maxDiscount != null && d > maxDiscount! ? maxDiscount! : d;
  }

  bool get isExpired => validUntil != null && DateTime.now().isAfter(validUntil!);
  bool get isFull => maxUses != null && usesCount >= maxUses!;
  bool get isValid => isActive && !isExpired && !isFull;
}