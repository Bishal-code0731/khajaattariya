import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/cash_entry.dart';
import '../../domain/repositories/rider_cash_repository.dart';

class SupabaseRiderCashRepository implements RiderCashRepository {
  const SupabaseRiderCashRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<double> fetchCashInHand(String riderId) async {
    final row = await _client
        .from('rider_cash_balances')
        .select('cash_in_hand')
        .eq('rider_id', riderId)
        .maybeSingle();
    return (row?['cash_in_hand'] as num?)?.toDouble() ?? 0;
  }

  @override
  Future<List<CashEntry>> fetchLedger(String riderId, {int limit = 100}) async {
    final rows = await _client
        .from('rider_cash_ledger')
        .select(
            'id, rider_id, order_id, entry_type, amount, status, note, created_at, confirmed_at')
        .eq('rider_id', riderId)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> requestSettlement(
      {required String riderId, required double amount, String? note}) async {
    // RLS only lets a rider insert a pending settlement for themselves with no order and no confirmer.
    await _client.from('rider_cash_ledger').insert({
      'rider_id': riderId,
      'entry_type': 'settlement',
      'status': 'pending',
      'amount': amount,
      'note': (note == null || note.trim().isEmpty) ? null : note.trim(),
    });
  }

  static CashEntry _fromRow(Map<String, dynamic> row) => CashEntry(
        id: row['id'] as String,
        riderId: row['rider_id'] as String,
        orderId: row['order_id'] as String?,
        type: row['entry_type'] == 'cod_collected'
            ? CashEntryType.codCollected
            : CashEntryType.settlement,
        amount: (row['amount'] as num?)?.toDouble() ?? 0,
        status: switch (row['status']) {
          'confirmed' => CashEntryStatus.confirmed,
          'rejected' => CashEntryStatus.rejected,
          _ => CashEntryStatus.pending,
        },
        note: row['note'] as String?,
        createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
            DateTime.now(),
        confirmedAt: DateTime.tryParse(row['confirmed_at'] as String? ?? ''),
      );
}
