import '../utils/app_logger.dart';

class _CacheEntry {
  final dynamic value;
  final DateTime expiresAt;
  _CacheEntry(this.value, this.expiresAt);
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Small process-wide TTL cache for repository-level reads (restaurant
/// lists, categories, menu items, etc). Two jobs:
///
///  1. Serve repeated reads of the same key within [ttl] from memory
///     instead of hitting Supabase again (e.g. re-opening a restaurant
///     detail screen you just backed out of).
///  2. Collapse concurrent calls for the same key into a single
///     in-flight request, so two widgets asking for the same data at
///     the same moment (e.g. a rebuild racing a provider rebuild)
///     don't fire the request twice.
///
/// Not meant to replace real-time correctness: callers doing writes
/// should [invalidate] the relevant key(s) afterwards. Short TTLs (as
/// used by the repositories below) keep the staleness window small
/// even when a call site forgets to invalidate.
class MemoryCache {
  MemoryCache._();
  static final MemoryCache instance = MemoryCache._();

  final _store = <String, _CacheEntry>{};
  final _inFlight = <String, Future<dynamic>>{};

  T? peek<T>(String key) {
    final entry = _store[key];
    if (entry == null || entry.isExpired) return null;
    return entry.value as T;
  }

  void put<T>(String key, T value, Duration ttl) {
    _store[key] = _CacheEntry(value, DateTime.now().add(ttl));
  }

  void invalidate(String key) => _store.remove(key);

  void invalidateWhere(bool Function(String key) test) {
    _store.removeWhere((key, _) => test(key));
  }

  void clear() {
    _store.clear();
    _inFlight.clear();
  }

  /// Returns the cached value for [key] if fresh; otherwise runs
  /// [loader] (de-duplicated against concurrent callers) and caches the
  /// result for [ttl].
  Future<T> fetch<T>(String key, Future<T> Function() loader, {required Duration ttl}) {
    final cached = peek<T>(key);
    if (cached != null) return Future.value(cached);

    final pending = _inFlight[key];
    if (pending != null) {
      AppLogger.info('cache', 'joined in-flight request for $key');
      return pending as Future<T>;
    }

    final future = loader().then((value) {
      put(key, value, ttl);
      _inFlight.remove(key);
      return value;
    }, onError: (e) {
      _inFlight.remove(key);
      throw e;
    });
    _inFlight[key] = future;
    return future;
  }
}
