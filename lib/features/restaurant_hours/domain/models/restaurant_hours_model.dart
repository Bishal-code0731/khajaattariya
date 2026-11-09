class RestaurantHoursModel {
  final String id;
  final String restaurantId;
  final int weekday;
  final bool isOpen;
  final String? openTime;
  final String? closeTime;

  const RestaurantHoursModel({
    required this.id,
    required this.restaurantId,
    required this.weekday,
    required this.isOpen,
    this.openTime,
    this.closeTime,
  });

  String get weekdayName {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(weekday - 1).clamp(0, 6)];
  }

  String get dayName => weekdayName;

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
}
