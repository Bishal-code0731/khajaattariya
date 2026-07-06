import 'dart:async';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:geolocator/geolocator.dart';
import '../../../main.dart';
import '../domain/models/delivery_position_model.dart';

part 'tracking_provider.g.dart';

/// Latest known rider position for one order. `delivery_tracking` is
/// realtime-enabled, so this stays live while the customer watches.
@riverpod
Stream<DeliveryPositionModel?> orderPosition(Ref ref, String orderId) {
  return supabase
      .from('delivery_tracking')
      .stream(primaryKey: ['id'])
      .eq('order_id', orderId)
      .order('recorded_at', ascending: false)
      .limit(1)
      .map((rows) => rows.isEmpty ? null : DeliveryPositionModel.fromMap(rows.first));
}

/// Broadcasts the rider's device location for an active delivery on a
/// throttled interval — NOT continuous — to keep `delivery_tracking`
/// row growth bounded on the free-tier database. Call [start] once an
/// order is picked up and [stop] once it's delivered/cancelled or the
/// rider goes offline.
@Riverpod(keepAlive: true)
class RiderLocationBroadcaster extends _$RiderLocationBroadcaster {
  Timer? _timer;
  static const _interval = Duration(seconds: 25);

  @override
  bool build() {
    ref.onDispose(() => _timer?.cancel());
    return false;
  }

  Future<void> start({required String orderId, required String riderId}) async {
    if (state) return; // already broadcasting
    final hasPermission = await _ensurePermission();
    if (!hasPermission) return;

    state = true;
    await _sendOnce(orderId: orderId, riderId: riderId);
    _timer = Timer.periodic(_interval, (_) => _sendOnce(orderId: orderId, riderId: riderId));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    state = false;
  }

  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Future<void> _sendOnce({required String orderId, required String riderId}) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await supabase.from('delivery_tracking').insert({
        'order_id': orderId,
        'rider_id': riderId,
        'lat': position.latitude,
        'lng': position.longitude,
      });
    } catch (_) {
      // Non-fatal: a missed location ping just delays the customer's view.
    }
  }
}
