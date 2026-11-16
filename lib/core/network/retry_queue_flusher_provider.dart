import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/favorites/application/favorites_provider.dart';
import '../utils/app_logger.dart';
import 'connectivity_provider.dart';
import 'retry_queue.dart';

/// Registry of how to replay each queued request `type`.
final _retryHandlers = <String, Future<void> Function(Map<String, dynamic>)>{
  favoriteToggleRequestType: performFavoriteToggle,
};

final retryQueueFlusherProvider = Provider<void>((ref) {
  ref.listen<bool>(isOnlineProvider, (previous, next) {
    if (previous == false && next == true) {
      AppLogger.info(
          'retryQueue', 'connectivity restored — flushing pending requests');
      RetryQueue.instance.flush(_retryHandlers);
    }
  });
});
