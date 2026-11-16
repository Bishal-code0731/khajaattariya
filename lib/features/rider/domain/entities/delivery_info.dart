class DeliveryInfo {
  const DeliveryInfo({
    required this.orderId,
    required this.isCash,
    required this.isPaid,
    this.restaurantAddress,
    this.restaurantPhone,
  });

  final String orderId;

  /// Cash on delivery (vs.
  final bool isCash;

  /// Set by the server only (payment_status = paid).
  final bool isPaid;
  final String? restaurantAddress;
  final String? restaurantPhone;

  /// The rider must collect cash at the door.
  bool get mustCollectCash => isCash && !isPaid;
}
