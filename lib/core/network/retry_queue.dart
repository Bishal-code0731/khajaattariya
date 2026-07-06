import '../cache/local_store.dart';
import '../utils/app_logger.dart';

/// A single failed write waiting to be replayed once connectivity
/// returns — e.g. a favorite toggle made while offline.
class QueuedRequest {
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime queuedAt;
  final int attempts;

  QueuedRequest({
    required this.id,
    required this.type,
    required this.payload,
    required this.queuedAt,
    this.attempts = 0,
  });

  QueuedRequest withAttemptIncremented() => QueuedRequest(
        id: id,
        type: type,
        payload: payload,
        queuedAt: queuedAt,
        attempts: attempts + 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'payload': payload,
        'queued_at': queuedAt.toIso8601String(),
        'attempts': attempts,
      };

  factory QueuedRequest.fromMap(Map<String, dynamic> map) => QueuedRequest(
        id: map['id'] as String,
        type: map['type'] as String,
        payload: Map<String, dynamic>.from(map['payload'] as Map),
        queuedAt: DateTime.parse(map['queued_at'] as String),
        attempts: map['attempts'] as int? ?? 0,
      );
}

/// Persisted queue of writes that failed (most commonly because the
/// device was offline) so they survive an app restart and can be
/// replayed the next time connectivity is confirmed.
///
/// Handlers are registered per request `type` by whichever feature
/// enqueues that type — see [FavoriteToggleNotifier] for the reference
/// implementation. Extending this to another mutation (e.g. marking a
/// notification read) just means enqueuing a `QueuedRequest` with a new
/// `type` and registering a handler for it in [flush].
class RetryQueue {
  RetryQueue._();
  static final RetryQueue instance = RetryQueue._();

  static const _key = 'retry_queue';
  static const _maxAttempts = 5;

  // Every read-modify-write against the queue is chained onto this so
  // enqueue() and flush() (or two overlapping flush() calls, e.g. from a
  // flapping connection) can't race and silently drop each other's
  // writes — without this, "load list, mutate, save whole list" from two
  // callers at once means whichever save() lands second wins and erases
  // the other's change.
  Future<void> _lock = Future.value();

  Future<T> _synchronized<T>(Future<T> Function() action) {
    final result = _lock.then((_) => action());
    _lock = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<List<QueuedRequest>> _load() async {
    final raw = await LocalStore.instance.loadList(_key);
    if (raw == null) return [];
    return raw.map(QueuedRequest.fromMap).toList();
  }

  Future<void> _save(List<QueuedRequest> items) {
    return LocalStore.instance.saveList(_key, items.map((e) => e.toMap()).toList());
  }

  Future<void> enqueue(String type, Map<String, dynamic> payload) {
    return _synchronized(() async {
      final items = await _load();
      items.add(QueuedRequest(
        id: '${DateTime.now().microsecondsSinceEpoch}_${items.length}',
        type: type,
        payload: payload,
        queuedAt: DateTime.now(),
      ));
      await _save(items);
      AppLogger.info('retryQueue', 'queued $type (${items.length} pending)');
    });
  }

  Future<List<QueuedRequest>> pending() => _load();

  Future<int> pendingCount() async => (await _load()).length;

  /// Drops every queued item, e.g. on sign-out — a queued write made by
  /// one account should never replay under a different account's
  /// session on a shared device.
  Future<void> clear() => _synchronized(() => _save(const []));

  /// Replays every queued request whose `type` has a registered handler
  /// in [handlers]. Requests that fail again (still offline, or a real
  /// error) stay queued for the next flush, up to [_maxAttempts] before
  /// being dropped as permanently broken; unknown types are dropped
  /// immediately with a warning rather than retried forever.
  Future<void> flush(Map<String, Future<void> Function(Map<String, dynamic>)> handlers) {
    return _synchronized(() async {
      final items = await _load();
      if (items.isEmpty) return;

      final failed = <QueuedRequest>[];
      for (final item in items) {
        final handler = handlers[item.type];
        if (handler == null) {
          AppLogger.warning('retryQueue', 'no handler registered for ${item.type}, dropping');
          continue;
        }
        try {
          await handler(item.payload);
          AppLogger.info('retryQueue', 'replayed ${item.type} successfully');
        } catch (e) {
          final next = item.withAttemptIncremented();
          if (next.attempts >= _maxAttempts) {
            AppLogger.warning('retryQueue',
                'replay of ${item.type} failed $_maxAttempts times, dropping: $e');
          } else {
            AppLogger.warning('retryQueue', 'replay of ${item.type} failed again: $e');
            failed.add(next);
          }
        }
      }
      // Re-read (inside the same lock) instead of blindly overwriting
      // with `failed` — an enqueue() that ran between our initial _load()
      // and now must not be erased by this save.
      final current = await _load();
      final processedIds = items.map((e) => e.id).toSet();
      final untouched = current.where((e) => !processedIds.contains(e.id));
      await _save([...untouched, ...failed]);
    });
  }
}
