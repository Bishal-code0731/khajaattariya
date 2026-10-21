import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool _hasConnection(List<ConnectivityResult> results) =>
    results.isNotEmpty && results.any((r) => r != ConnectivityResult.none);

/// Raw connectivity stream (WiFi/mobile/none/...).
final connectivityStreamProvider =
    StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityStreamProvider);
  return connectivity.maybeWhen(
    data: _hasConnection,
    orElse: () => true,
  );
});

/// One-shot check for code that isn't already inside a widget tree watching [isOnlineProvider] (e.g.
Future<bool> checkIsOnline() async {
  final results = await Connectivity().checkConnectivity();
  return _hasConnection(results);
}
