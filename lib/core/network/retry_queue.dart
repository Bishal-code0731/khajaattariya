import '../cache/local_store.dart';
import '../utils/app_logger.dart';

/// A single failed write waiting to be replayed once connectivity returns — e.g.
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

class RetryQueue {
  RetryQueue._();
  static final RetryQueue instance = RetryQueue._();

  static const _key = 'retry_queue';
  static const _maxAttempts = 5;

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
    return LocalStore.instance
        .saveList(_key, items.map((e) => e.toMap()).toList());
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

  /// Drops every queued item, e.g.
  Future<void> clear() => _synchronized(() => _save(const []));

  /// Replays every queued request whose `type` has a registered handler in [handlers].
  Future<void> flush(
      Map<String, Future<void> Function(Map<String, dynamic>)> handlers) {
    return _synchronized(() async {
      final items = await _load();
      if (items.isEmpty) return;

      final failed = <QueuedRequest>[];
      for (final item in items) {
        final handler = handlers[item.type];
        if (handler == null) {
          AppLogger.warning(
              'retryQueue', 'no handler registered for ${item.type}, dropping');
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
            AppLogger.warning(
                'retryQueue', 'replay of ${item.type} failed again: $e');
            failed.add(next);
          }
        }
      }
      final current = await _load();
      final processedIds = items.map((e) => e.id).toSet();
      final untouched = current.where((e) => !processedIds.contains(e.id));
      await _save([...untouched, ...failed]);
    });
  }
}
