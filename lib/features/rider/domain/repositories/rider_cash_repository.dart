import '../entities/cash_entry.dart';

/// A rider's cash-on-delivery balance and ledger (D-11).
abstract class RiderCashRepository {
  /// Confirmed cash the rider currently holds (0 when none).
  Future<double> fetchCashInHand(String riderId);

  /// Newest first.
  Future<List<CashEntry>> fetchLedger(String riderId, {int limit = 100});

  /// Asks the team to confirm that [amount] cash was handed over.
  Future<void> requestSettlement(
      {required String riderId, required double amount, String? note});
}
