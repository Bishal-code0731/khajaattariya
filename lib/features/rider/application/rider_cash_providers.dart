import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../main.dart';
import '../data/supabase/supabase_rider_cash_repository.dart';
import '../domain/entities/cash_entry.dart';
import '../domain/repositories/rider_cash_repository.dart';

part 'rider_cash_providers.g.dart';

/// Binds the cash ledger interface to its Supabase implementation.
@riverpod
RiderCashRepository riderCashRepository(Ref ref) =>
    SupabaseRiderCashRepository(supabase);

/// Confirmed cash the rider holds right now.
@riverpod
Future<double> riderCashBalance(Ref ref, String riderId) =>
    ref.watch(riderCashRepositoryProvider).fetchCashInHand(riderId);

/// Ledger rows, newest first.
@riverpod
Future<List<CashEntry>> riderCashLedger(Ref ref, String riderId) =>
    ref.watch(riderCashRepositoryProvider).fetchLedger(riderId);

/// Sends a settlement request (the rider says they handed cash over).
@riverpod
class SettlementRequest extends _$SettlementRequest {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Returns true on success; on failure the error is in [state].
  Future<bool> submit(
      {required String riderId, required double amount, String? note}) async {
    if (state.isLoading) return false;
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => ref
          .read(riderCashRepositoryProvider)
          .requestSettlement(riderId: riderId, amount: amount, note: note),
    );
    state = result;
    if (result.hasError) return false;
    ref
      ..invalidate(riderCashLedgerProvider(riderId))
      ..invalidate(riderCashBalanceProvider(riderId));
    return true;
  }
}
