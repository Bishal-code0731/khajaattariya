import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  // WidgetsFlutterBinding.ensureInitialized() makes sure
  // Flutter's engine is fully ready before we run any code.
  // Required when doing async work before runApp().
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // ProviderScope is required for Riverpod to work.
    // It wraps the entire app and manages all providers.
    // Every Riverpod provider in the app lives inside this scope.
    const ProviderScope(
      child: KhajaAttariyaApp(),
    ),
  );
}

// ConsumerWidget instead of StatelessWidget.
// ConsumerWidget can read Riverpod providers.
// We need this to read our appRouterProvider.
class KhajaAttariyaApp extends ConsumerWidget {
  const KhajaAttariyaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch watches the appRouterProvider.
    // If auth state changes, the router updates automatically.
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Khaja Attariya',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Instead of home: we now use routerConfig:
      // go_router takes full control of navigation
      routerConfig: router,
    );
  }
}