import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../main.dart';
import '../domain/models/rider_model.dart';
import '../domain/models/rider_earning_model.dart';

part 'rider_provider.g.dart';

@Riverpod(keepAlive: true)
Future<RiderModel?> riderProfile(Ref ref, String riderId) async {
  final data = await supabase
      .from('riders')
      .select('*, profiles(full_name, phone)')
      .eq('id', riderId)
      .maybeSingle();
  if (data == null) return null;
  return RiderModel.fromMap(data);
}

@Riverpod(keepAlive: true)
class RiderOnlineNotifier extends _$RiderOnlineNotifier {
  @override
  AsyncValue<bool> build() => const AsyncValue.data(false);

  Future<void> loadStatus(String riderId) async {
    try {
      final data = await supabase
          .from('riders').select('is_online').eq('id', riderId).maybeSingle();
      state = AsyncValue.data(data?['is_online'] as bool? ?? false);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggle(String riderId) async {
    final current = state.valueOrNull ?? false;
    state = const AsyncValue.loading();
    try {
      final updated = await supabase
          .from('riders')
          .update({'is_online': !current})
          .eq('id', riderId)
          .select('id');
      if (updated.isEmpty) {
        throw Exception('Could not update your status. Please try again.');
      }
      state = AsyncValue.data(!current);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

@Riverpod(keepAlive: true)
Future<List<RiderEarningModel>> riderEarnings(Ref ref, String riderId) async {
  final data = await supabase
      .from('rider_earnings').select().eq('rider_id', riderId)
      .order('created_at', ascending: false);
  return (data as List)
      .map((m) => RiderEarningModel.fromMap(m as Map<String, dynamic>))
      .toList();
}

@Riverpod(keepAlive: true)
Future<Map<String, double>> riderEarningsSummary(Ref ref, String riderId) async {
  final data = await supabase
      .from('riders').select('total_deliveries, total_earnings').eq('id', riderId).single();
  return {
    'total_deliveries': (data['total_deliveries'] as num).toDouble(),
    'total_earnings': (data['total_earnings'] as num).toDouble(),
  };
}

@Riverpod(keepAlive: true)
Future<List<RiderModel>> allRiders(Ref ref) async {
  final data = await supabase
      .from('riders').select('*, profiles(full_name, phone)')
      .order('created_at', ascending: false);
  return (data as List)
      .map((m) => RiderModel.fromMap(m as Map<String, dynamic>))
      .toList();
}

@Riverpod(keepAlive: true)
class RiderApprovalNotifier extends _$RiderApprovalNotifier {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> approveRider(String riderId) async {
    state = const AsyncValue.loading();
    try {
      final updated = await supabase.from('riders')
          .update({'is_approved': true, 'approval_note': null})
          .eq('id', riderId)
          .select('id');
      if (updated.isEmpty) {
        throw Exception('Could not approve rider. Please try again.');
      }
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) { state = AsyncValue.error(e, st); return false; }
  }

  Future<bool> rejectRider(String riderId, String note) async {
    state = const AsyncValue.loading();
    try {
      final updated = await supabase.from('riders')
          .update({'is_approved': false, 'approval_note': note})
          .eq('id', riderId)
          .select('id');
      if (updated.isEmpty) {
        throw Exception('Could not reject rider. Please try again.');
      }
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) { state = AsyncValue.error(e, st); return false; }
  }
}

@Riverpod(keepAlive: true)
class RiderRegistration extends _$RiderRegistration {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

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
