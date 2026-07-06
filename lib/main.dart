import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/network/retry_queue_flusher_provider.dart';
import 'core/responsive/responsive.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_logger.dart';
import 'firebase_options.dart';
import 'shared/providers/theme_provider.dart';

final supabase = Supabase.instance.client;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> initFcm() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Permission (iOS + Android 13+)
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Get initial token
  final token = await messaging.getToken();
  final userId = supabase.auth.currentUser?.id;

  if (token != null && userId != null) {
    await supabase.from('profiles').update({
      'fcm_token': token,
    }).eq('id', userId);
  }

  // Handle token refresh
  messaging.onTokenRefresh.listen((newToken) async {
    final userId = supabase.auth.currentUser?.id;

    if (userId != null) {
      await supabase.from('profiles').update({
        'fcm_token': newToken,
      }).eq('id', userId);
    }
  });
}

/// Renders a friendly message instead of Flutter's default red/grey
/// error box whenever a widget throws while building — a build error
/// used to mean a genuinely blank/broken-looking screen for the user
/// with no way back; this at least gives them a way out.
Widget _errorScreenBuilder(FlutterErrorDetails details) {
  return Material(
    child: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong on this screen.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 8),
                Text(
                  details.exceptionAsString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

void _installGlobalErrorHandlers() {
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error('FlutterError', details.exceptionAsString(), details.stack);
    originalOnError?.call(details);
  };
  ErrorWidget.builder = _errorScreenBuilder;

  // Catches uncaught errors from async code (e.g. an un-awaited Future,
  // or an error in a callback outside the widget build phase) that
  // would otherwise crash the isolate or vanish silently in release.
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('PlatformDispatcher', error, stack);
    return true;
  };
}

Future<void> main() async {
  await runZonedGuarded(() async {
    // Binding init must happen in the same zone as runApp() below, or
    // Flutter throws a "Zone mismatch" assertion at startup.
    WidgetsFlutterBinding.ensureInitialized();
    _installGlobalErrorHandlers();

    // dotenv.load and Firebase.initializeApp don't depend on each other
    // (only Supabase.initialize needs the loaded env vars) — running
    // them concurrently instead of sequentially shaves real time off
    // the splash screen on every cold start.
    await Future.wait([
      dotenv.load(fileName: '.env'),
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    ]);

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );

    // Test-mode publishable key — safe to embed client-side by design.
    // If it's missing, leave Stripe uninitialized rather than crash the
    // whole app on startup; the payment screen surfaces a clear error
    // instead when the user actually tries to pay with a card.
    // flutter_stripe checks Platform.isIOS/isAndroid internally, which
    // throws on web (no dart:io there) — skip it on that platform.
    final stripeKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
    if (!kIsWeb && stripeKey != null && stripeKey.isNotEmpty) {
      Stripe.publishableKey = stripeKey;
      await Stripe.instance.applySettings();
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    runApp(const ProviderScope(child: KhajaAttariyaApp()));
    initFcm(); // no await — runs in background after app starts
  }, (error, stack) {
    AppLogger.error('main', error, stack);
    // Without this, a startup failure above means runApp() never ran —
    // the user just sees a permanently blank screen with no indication
    // anything went wrong, in debug and release alike.
    runApp(_StartupErrorApp(error: error));
  });
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  const Text(
                    'Khaja Attariya failed to start.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class KhajaAttariyaApp extends ConsumerWidget {
  const KhajaAttariyaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // Watching the provider's *state* (not `.notifier`) is what makes
    // the app actually rebuild with the new theme when setTheme() is
    // called — watching `.notifier` only rebuilds if the notifier
    // instance itself is replaced, never when its state changes.
    final themeMode = ref.watch(themeNotifierProvider);
    // Watched once at the root so it's always active: replays any queued
    // offline writes (see RetryQueue) the moment connectivity returns.
    ref.watch(retryQueueFlusherProvider);

    return MaterialApp.router(
      title: 'Khaja Attariya',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode.flutterThemeMode,
      routerConfig: router,
      builder: (context, child) {
        // Clamp the system font-scale app-wide instead of per-screen —
        // an accessibility "huge text" setting can otherwise overflow
        // fixed-height cards throughout the app. Still allows real
        // scaling for readability, just bounded.
        return MediaQuery(
          data: MediaQuery.of(context).withClampedTextScale(),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}