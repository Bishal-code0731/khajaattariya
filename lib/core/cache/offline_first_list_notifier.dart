import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_store.dart';

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
    }
  }

  Future<void> refresh() => _load();
}
