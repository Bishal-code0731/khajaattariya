import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';
import '../domain/models/rider_model.dart';
import '../domain/models/rider_earning_model.dart';

final riderProfileProvider = FutureProvider.family<RiderModel?, String>((ref, riderId) async {
  final data = await supabase
      .from('riders')
      .select('*, profiles(full_name, phone)')
      .eq('id', riderId)
      .maybeSingle();
  if (data == null) return null;
  return RiderModel.fromMap(data);
});

final riderOnlineNotifierProvider =
StateNotifierProvider<RiderOnlineNotifier, AsyncValue<bool>>((ref) {
  return RiderOnlineNotifier();
});

class RiderOnlineNotifier extends StateNotifier<AsyncValue<bool>> {
  RiderOnlineNotifier() : super(const AsyncValue.data(false));

  Future<void> loadStatus(String riderId) async {
    final data = await supabase
        .from('riders').select('is_online').eq('id', riderId).maybeSingle();
    state = AsyncValue.data(data?['is_online'] as bool? ?? false);
  }

  Future<void> toggle(String riderId) async {
    final current = state.valueOrNull ?? false;
    state = const AsyncValue.loading();
    try {
      await supabase.from('riders').update({'is_online': !current}).eq('id', riderId);
      state = AsyncValue.data(!current);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final riderEarningsProvider =
FutureProvider.family<List<RiderEarningModel>, String>((ref, riderId) async {
  final data = await supabase
      .from('rider_earnings').select().eq('rider_id', riderId)
      .order('created_at', ascending: false);
  return (data as List)
      .map((m) => RiderEarningModel.fromMap(m as Map<String, dynamic>))
      .toList();
});

final riderEarningsSummaryProvider =
FutureProvider.family<Map<String, double>, String>((ref, riderId) async {
  final data = await supabase
      .from('riders').select('total_deliveries, total_earnings').eq('id', riderId).single();
  return {
    'total_deliveries': (data['total_deliveries'] as num).toDouble(),
    'total_earnings': (data['total_earnings'] as num).toDouble(),
  };
});

final allRidersProvider = FutureProvider<List<RiderModel>>((ref) async {
  final data = await supabase
      .from('riders').select('*, profiles(full_name, phone)')
      .order('created_at', ascending: false);
  return (data as List)
      .map((m) => RiderModel.fromMap(m as Map<String, dynamic>))
      .toList();
});

final riderApprovalNotifierProvider =
StateNotifierProvider<RiderApprovalNotifier, AsyncValue<void>>((ref) {
  return RiderApprovalNotifier();
});

class RiderApprovalNotifier extends StateNotifier<AsyncValue<void>> {
  RiderApprovalNotifier() : super(const AsyncValue.data(null));

  Future<bool> approveRider(String riderId) async {
    state = const AsyncValue.loading();
    try {
      await supabase.from('riders')
          .update({'is_approved': true, 'approval_note': null}).eq('id', riderId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) { state = AsyncValue.error(e, st); return false; }
  }

  Future<bool> rejectRider(String riderId, String note) async {
    state = const AsyncValue.loading();
    try {
      await supabase.from('riders')
          .update({'is_approved': false, 'approval_note': note}).eq('id', riderId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) { state = AsyncValue.error(e, st); return false; }
  }
}

final riderRegistrationProvider =
StateNotifierProvider<RiderRegistrationNotifier, AsyncValue<void>>((ref) {
  return RiderRegistrationNotifier();
});

class RiderRegistrationNotifier extends StateNotifier<AsyncValue<void>> {
  RiderRegistrationNotifier() : super(const AsyncValue.data(null));

  Future<bool> register({
    required String riderId,
    required String vehicleType,
    String? vehicleNumber,
  }) async {
    state = const AsyncValue.loading();
    try {
      await supabase.from('riders').upsert({
        'id': riderId, 'vehicle_type': vehicleType,
        'vehicle_number': vehicleNumber, 'is_online': false, 'is_approved': false,
      });
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) { state = AsyncValue.error(e, st); return false; }
  }
}