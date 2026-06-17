import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const ProviderScope(child: KhajaAttariyaApp()));
  initFcm(); // no await — runs in background after app starts
}

class KhajaAttariyaApp extends ConsumerWidget {
  const KhajaAttariyaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeNotifier = ref.watch(themeNotifierProvider.notifier);

    return MaterialApp.router(
      title: 'Khaja Attariya',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.flutterThemeMode,
      routerConfig: router,
    );
  }
}