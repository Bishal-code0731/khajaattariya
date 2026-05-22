import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file first
  await dotenv.load(fileName: '.env');

  // Initialize Supabase with keys from .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const ProviderScope(child: KhajaAttariyaApp()));
}

// Global Supabase client — used anywhere in the app
final supabase = Supabase.instance.client;

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