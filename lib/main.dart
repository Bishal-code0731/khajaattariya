import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: KhajaAttariyaApp()));
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