import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool _hasConnection(List<ConnectivityResult> results) =>
    results.isNotEmpty && results.any((r) => r != ConnectivityResult.none);

/// Raw connectivity stream (WiFi/mobile/none/...). Most UI code should
/// prefer [isOnlineProvider] below instead of interpreting this itself.
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Best-known online/offline status as a plain bool, for gating
/// offline-first reads and driving the "You're offline" banner.
///
/// Defaults to `true` (optimistic) until the first connectivity event
/// arrives, since a false "offline" flash on cold start would be more
/// misleading than briefly assuming online — the offline-first repositories
/// fall back to cache regardless if a request actually fails.
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityStreamProvider);
  return connectivity.maybeWhen(
    data: _hasConnection,
    orElse: () => true,
  );
});

/// One-shot check for code that isn't already inside a widget tree
/// watching [isOnlineProvider] (e.g. a repository deciding whether to
/// bother hitting the network at all).
Future<bool> checkIsOnline() async {
  final results = await Connectivity().checkConnectivity();
  return _hasConnection(results);
}
