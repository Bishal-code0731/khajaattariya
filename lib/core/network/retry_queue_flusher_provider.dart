import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/favorites/application/favorites_provider.dart';
import '../utils/app_logger.dart';
import 'connectivity_provider.dart';
import 'retry_queue.dart';

/// Registry of how to replay each queued request `type`. Add an entry
/// here whenever another feature starts enqueuing into [RetryQueue] —
/// see [performFavoriteToggle] for the reference pattern (a plain
/// `Future<void> Function(Map<String, dynamic>)` factored out of the
/// live mutation path so both share one implementation).
final _retryHandlers = <String, Future<void> Function(Map<String, dynamic>)>{
  favoriteToggleRequestType: performFavoriteToggle,
};

/// Watch this once near the app root (see `KhajaAttariyaApp`) to enable
/// automatic replay of queued offline writes: the moment connectivity
/// flips from offline to online, every pending request in [RetryQueue]
/// is replayed against the real backend.
final retryQueueFlusherProvider = Provider<void>((ref) {
  ref.listen<bool>(isOnlineProvider, (previous, next) {
    if (previous == false && next == true) {
      AppLogger.info('retryQueue', 'connectivity restored — flushing pending requests');
      RetryQueue.instance.flush(_retryHandlers);
    }
  });
});
