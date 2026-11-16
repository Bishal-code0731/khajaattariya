/// Read models for the admin console.
library;

DateTime _date(Object? v) => v is String ? DateTime.parse(v) : DateTime.now();
double _num(Object? v) => (v as num?)?.toDouble() ?? 0;
Map<String, dynamic> _map(Object? v) =>
    v is Map<String, dynamic> ? v : const {};

class AdminUser {
  const AdminUser({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String fullName;
  final String? phone;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  factory AdminUser.fromMap(Map<String, dynamic> m) => AdminUser(
        id: m['id'] as String,
        fullName: (m['full_name'] as String? ?? '').trim(),
        phone: m['phone'] as String?,
        role: m['role'] as String? ?? 'customer',
        isActive: m['is_active'] as bool? ?? true,
        createdAt: _date(m['created_at']),
      );
}

enum RestaurantQueue { pending, active, inactive }

class AdminRestaurant {
  const AdminRestaurant({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.ownerPhone,
    required this.imageUrl,
    required this.cuisine,
    required this.address,
    required this.isApproved,
    required this.isActive,
    required this.isFeatured,
    required this.approvalNote,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? ownerName;
  final String? ownerPhone;
  final String? imageUrl;
  final String cuisine;
  final String? address;
  final bool isApproved;
  final bool isActive;
  final bool isFeatured;
  final String? approvalNote;
  final DateTime createdAt;

  bool get isRejected =>
      !isApproved && (approvalNote?.trim().isNotEmpty ?? false);

  /// Pending = never reviewed.
  RestaurantQueue get queue {
    if (!isApproved && !isRejected) return RestaurantQueue.pending;
    if (isApproved && isActive) return RestaurantQueue.active;
    return RestaurantQueue.inactive;
  }

  factory AdminRestaurant.fromMap(Map<String, dynamic> m) {
    final owner = _map(m['profiles']);
    return AdminRestaurant(
      id: m['id'] as String,
      name: m['name'] as String? ?? '',
      ownerName: owner['full_name'] as String?,
      ownerPhone: owner['phone'] as String?,
      imageUrl: m['image_url'] as String?,
      cuisine: m['cuisine_type'] as String? ?? '',
      address: m['address'] as String?,
      isApproved: m['is_approved'] as bool? ?? false,
      isActive: m['is_active'] as bool? ?? true,
      isFeatured: m['is_featured'] as bool? ?? false,
      approvalNote: m['approval_note'] as String?,
      createdAt: _date(m['created_at']),
    );
  }
}

class AdminOrder {
  const AdminOrder({
    required this.id,
    required this.status,
    required this.restaurantName,
    required this.customerName,
    required this.totalAmount,
    required this.paymentMethod,
    required this.createdAt,
  });

  final String id;

  /// Raw database status (`picked_up`, …) — map with OrderStatus.fromString.
  final String status;
  final String? restaurantName;
  final String? customerName;
  final double totalAmount;
  final String paymentMethod;
  final DateTime createdAt;

  factory AdminOrder.fromMap(Map<String, dynamic> m) => AdminOrder(
        id: m['id'] as String,
        status: m['status'] as String? ?? 'pending',
        restaurantName: _map(m['restaurants'])['name'] as String?,
        customerName: _map(m['profiles'])['full_name'] as String?,
        totalAmount: _num(m['total_amount']),
        paymentMethod: m['payment_method'] as String? ?? 'cash',
        createdAt: _date(m['created_at']),
      );
}

enum CouponState { live, paused, scheduled, expired, usedUp }

class AdminCoupon {
  const AdminCoupon({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    required this.maxDiscount,
    required this.maxUses,
    required this.maxUsesPerCustomer,
    required this.usesCount,
    required this.validFrom,
    required this.validUntil,
    required this.isActive,
  });

  final String id;
  final String code;
  final String? description;
  final String discountType; // percent | fixed
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscount;
  final int? maxUses;
  final int maxUsesPerCustomer;
  final int usesCount;
  final DateTime validFrom;
  final DateTime? validUntil;
  final bool isActive;

  bool get isPercent => discountType == 'percent';

  CouponState stateAt(DateTime now) {
    if (validUntil != null && validUntil!.isBefore(now)) {
      return CouponState.expired;
    }
    if (maxUses != null && usesCount >= maxUses!) return CouponState.usedUp;
    if (!isActive) return CouponState.paused;
    if (validFrom.isAfter(now)) return CouponState.scheduled;
    return CouponState.live;
  }

  factory AdminCoupon.fromMap(Map<String, dynamic> m) => AdminCoupon(
        id: m['id'] as String,
        code: m['code'] as String? ?? '',
        description: m['description'] as String?,
        discountType: m['discount_type'] as String? ?? 'percent',
        discountValue: _num(m['discount_value']),
        minOrderAmount: _num(m['min_order_amount']),
        maxDiscount: (m['max_discount'] as num?)?.toDouble(),
        maxUses: m['max_uses'] as int?,
        maxUsesPerCustomer: m['max_uses_per_customer'] as int? ?? 1,
        usesCount: m['uses_count'] as int? ?? 0,
        validFrom: _date(m['valid_from'] ?? m['created_at']),
        validUntil: m['valid_until'] is String
            ? DateTime.parse(m['valid_until'] as String)
            : null,
        isActive: m['is_active'] as bool? ?? true,
      );
}

/// What the coupon form submits.
class CouponDraft {
  const CouponDraft({
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    required this.maxDiscount,
    required this.maxUses,
    required this.maxUsesPerCustomer,
    required this.validFrom,
    required this.validUntil,
  });

  final String code;
  final String? description;
  final String discountType;
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscount;
  final int? maxUses;
  final int maxUsesPerCustomer;
  final DateTime validFrom;
  final DateTime? validUntil;

  Map<String, dynamic> toRow() => {
        'code': code.toUpperCase(),
        'description': description,
        'discount_type': discountType,
        'discount_value': discountValue,
        'min_order_amount': minOrderAmount,
        'max_discount': discountType == 'percent' ? maxDiscount : null,
        'max_uses': maxUses,
        'max_uses_per_customer': maxUsesPerCustomer,
        'valid_from': validFrom.toUtc().toIso8601String(),
        'valid_until': validUntil?.toUtc().toIso8601String(),
      };
}

class AdminRefund {
  const AdminRefund({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.reason,
    required this.status,
    required this.customerName,
    required this.orderTotal,
    required this.createdAt,
  });

  final String id;
  final String? orderId;
  final double amount;
  final String? reason;
  final String status; // pending | approved | rejected | processed
  final String? customerName;
  final double? orderTotal;
  final DateTime createdAt;

  factory AdminRefund.fromMap(Map<String, dynamic> m) {
    final order = _map(m['orders']);
    return AdminRefund(
      id: m['id'] as String,
      orderId: m['order_id'] as String?,
      amount: _num(m['amount']),
      reason: m['reason'] as String?,
      status: m['status'] as String? ?? 'pending',
      customerName: _map(order['profiles'])['full_name'] as String?,
      orderTotal: (order['total_amount'] as num?)?.toDouble(),
      createdAt: _date(m['created_at']),
    );
  }
}

class AdminSettlement {
  const AdminSettlement({
    required this.id,
    required this.riderId,
    required this.riderName,
    required this.riderPhone,
    required this.amount,
    required this.status,
    required this.note,
    required this.createdAt,
    required this.confirmedAt,
  });

  final String id;
  final String riderId;
  final String? riderName;
  final String? riderPhone;
  final double amount;
  final String status; // pending | confirmed | rejected
  final String? note;
  final DateTime createdAt;
  final DateTime? confirmedAt;

  factory AdminSettlement.fromMap(Map<String, dynamic> m) {
    final profile = _map(_map(m['riders'])['profiles']);
    return AdminSettlement(
      id: m['id'] as String,
      riderId: m['rider_id'] as String,
      riderName: profile['full_name'] as String?,
      riderPhone: profile['phone'] as String?,
      amount: _num(m['amount']),
      status: m['status'] as String? ?? 'pending',
      note: m['note'] as String?,
      createdAt: _date(m['created_at']),
      confirmedAt: m['confirmed_at'] is String
          ? DateTime.parse(m['confirmed_at'] as String)
          : null,
    );
  }
}

class AdminAuditEntry {
  const AdminAuditEntry({
    required this.id,
    required this.action,
    required this.actorName,
    required this.targetTable,
    required this.targetId,
    required this.createdAt,
  });

  final String id;
  final String action;
  final String? actorName;
  final String? targetTable;
  final String? targetId;
  final DateTime createdAt;

  factory AdminAuditEntry.fromMap(Map<String, dynamic> m) => AdminAuditEntry(
        id: m['id'] as String,
        action: m['action'] as String? ?? '',
        actorName: _map(m['profiles'])['full_name'] as String?,
        targetTable: m['target_table'] as String?,
        targetId: m['target_id'] as String?,
        createdAt: _date(m['created_at']),
      );
}

/// Counts for the overview tiles and navigation badges.
class AdminOverview {
  const AdminOverview({
    required this.ordersToday,
    required this.deliveredToday,
    required this.deliveredValueToday,
    required this.activeRestaurants,
    required this.pendingRestaurants,
    required this.pendingRiders,
    required this.openTickets,
    required this.pendingRefunds,
    required this.pendingSettlements,
    required this.pendingSettlementAmount,
  });

  final int ordersToday;
  final int deliveredToday;
  final double deliveredValueToday;
  final int activeRestaurants;
  final int pendingRestaurants;
  final int pendingRiders;
  final int openTickets;
  final int pendingRefunds;
  final int pendingSettlements;
  final double pendingSettlementAmount;

  int get pendingApprovals => pendingRestaurants + pendingRiders;
}
