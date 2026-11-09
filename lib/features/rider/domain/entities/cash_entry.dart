/// One line of a rider's cash-on-delivery ledger (D-11).
enum CashEntryType { codCollected, settlement }

enum CashEntryStatus { pending, confirmed, rejected }

class CashEntry {
  const CashEntry({
    required this.id,
    required this.riderId,
    required this.type,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.orderId,
    this.note,
    this.confirmedAt,
  });

  final String id;
  final String riderId;
  final String? orderId;
  final CashEntryType type;

  /// Always positive; see [signedAmount] for the effect on cash in hand.
  final double amount;
  final CashEntryStatus status;
  final String? note;
  final DateTime createdAt;
  final DateTime? confirmedAt;

  bool get isCollected => type == CashEntryType.codCollected;

  /// + for cash collected, − for cash handed over.
  double get signedAmount => isCollected ? amount : -amount;
}
