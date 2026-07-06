import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';

/// Wraps `app_links` so the Khalti checkout return
/// (`khajaattariya://payment/khalti-callback?pidx=...&status=...`) can be
/// picked up regardless of whether the app was already running
/// (foreground link) or was launched fresh by tapping the redirect
/// (initial link) after the user finishes paying in the external browser.
class PaymentDeepLinkListener {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  /// Calls [onKhaltiCallback] with the `pidx` query param whenever a
  /// `khajaattariya://payment/khalti-callback` link comes in. Safe to
  /// call more than once (e.g. re-entering the payment screen) — any
  /// previous subscription is cancelled first instead of stacking.
  Future<void> start(void Function(String pidx) onKhaltiCallback) async {
    stop();

    void handle(Uri uri) {
      AppLogger.info('paymentDeepLink', 'received: $uri');
      if (uri.host != 'payment') return;
      final pidx = uri.queryParameters['pidx'];
      if (pidx != null && pidx.isNotEmpty) onKhaltiCallback(pidx);
    }

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) handle(initial);
    } catch (e) {
      AppLogger.warning('paymentDeepLink', 'getInitialLink failed: $e');
    }

    _sub = _appLinks.uriLinkStream.listen(handle, onError: (e) {
      AppLogger.warning('paymentDeepLink', 'uriLinkStream error: $e');
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }
}

final paymentDeepLinkListenerProvider = Provider<PaymentDeepLinkListener>((ref) {
  final listener = PaymentDeepLinkListener();
  ref.onDispose(listener.stop);
  return listener;
});
