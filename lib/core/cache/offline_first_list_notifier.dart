import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_store.dart';

/// Generic "show cached data immediately, then refresh silently in the
/// background" notifier for a `List<T>` read from Supabase.
///
/// On construction it emits whatever is on disk (if anything) as an
/// already-loaded `AsyncValue.data` — no spinner — then kicks off the
/// real network fetch. If the network call succeeds, the fresher list
/// replaces it (the repository itself is responsible for writing the
/// new data back to [diskKey] — this class only reads on startup). If
/// it fails while we already have cached data on screen, the failure is
/// swallowed and the cached list keeps showing (that's what "offline"
/// looks like to the user); it only surfaces as an error state when
/// there was nothing cached to fall back to.
class OfflineFirstListNotifier<T> extends StateNotifier<AsyncValue<List<T>>> {
  final String diskKey;
  final T Function(Map<String, dynamic>) fromMap;
  final Future<List<T>> Function() fetch;

  OfflineFirstListNotifier({
    required this.diskKey,
    required this.fromMap,
    required this.fetch,
  }) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    final cached = await LocalStore.instance.loadList(diskKey);
    if (cached != null) {
      state = AsyncValue.data(cached.map(fromMap).toList());
    }

    try {
      final fresh = await fetch();
      state = AsyncValue.data(fresh);
    } catch (e, st) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
      // else: keep serving the cached list — the OfflineBanner tells the
      // user why it might not be perfectly fresh.
    }
  }

  Future<void> refresh() => _load();
}
