/// Reads rider-related values from the public `platform_settings` map (see `platformSettingsProvider`).
class RiderSettings {
  const RiderSettings._(
      this.codCashLimit, this.riderSharePercent, this.supportPhone);

  factory RiderSettings.from(Map<String, String>? settings) {
    final phone = settings?['support_phone']?.trim();
    return RiderSettings._(
      double.tryParse(settings?['cod_cash_limit'] ?? '') ?? 5000,
      double.tryParse(settings?['rider_share_percent'] ?? ''),
      (phone == null || phone.isEmpty) ? null : phone,
    );
  }

  /// Most cash a rider may hold before cash orders are refused (D-11).
  final double codCashLimit;

  /// Share of the delivery fee paid to the rider (BR-12); null if unknown.
  final double? riderSharePercent;

  /// Optional support line; when missing the app opens the help screen.
  final String? supportPhone;

  double estimatedEarning(double deliveryFee) {
    final share = riderSharePercent;
    if (share == null) return deliveryFee;
    return (deliveryFee * share / 100).roundToDouble();
  }

  /// Would taking a cash order of [orderTotal] push the rider over the limit?
  bool wouldExceedLimit(
          {required double cashInHand, required double orderTotal}) =>
      cashInHand + orderTotal > codCashLimit;
}
