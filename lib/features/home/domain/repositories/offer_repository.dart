import '../../../payments/domain/models/coupon_model.dart';

/// Read-only access to the deals shown on the Offers tab.
abstract class OfferRepository {
  /// Coupons the signed-in customer can use right now (active, not expired, not used up).
  Future<List<CouponModel>> availableCoupons();
}
