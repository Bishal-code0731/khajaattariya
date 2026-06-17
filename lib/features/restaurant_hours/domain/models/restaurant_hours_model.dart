class RestaurantHoursModel {
  final String id;
  final String restaurantId;
  final int weekday; // 1=Monday … 7=Sunday (matches DateTime.weekday)
  final bool isOpen;
  final String? openTime;  // "09:00"
  final String? closeTime; // "22:00"

  const RestaurantHoursModel({
    required this.id,
    required this.restaurantId,
    required this.weekday,
    required this.isOpen,
    this.openTime,
    this.closeTime,
  });

  factory RestaurantHoursModel.fromMap(Map<String, dynamic> map) {
    return RestaurantHoursModel(
      id: map['id'] as String,
      restaurantId: map['restaurant_id'] as String,
      weekday: map['weekday'] as int,
      isOpen: map['is_open'] as bool? ?? true,
      openTime: map['open_time'] as String?,
      closeTime: map['close_time'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurant_id': restaurantId,
      'weekday': weekday,
      'is_open': isOpen,
      'open_time': openTime,
      'close_time': closeTime,
    };
  }

  String get dayName {
    const days = [
      '', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return days[weekday];
  }

  RestaurantHoursModel copyWith({
    bool? isOpen,
    String? openTime,
    String? closeTime,
  }) {
    return RestaurantHoursModel(
      id: id,
      restaurantId: restaurantId,
      weekday: weekday,
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }
}