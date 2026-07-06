import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_names.dart';
import '../../core/utils/app_logger.dart';
import '../../features/auth/application/auth_provider.dart';
import 'app_snackbar.dart';

/// Wraps every routed screen so the Android hardware back button (and
/// the iOS swipe-back gesture) always does something sensible instead
/// of silently exiting the app.
///
/// Most screens in this app are reached via `go()` from the side menu
/// or bottom nav, which replaces the whole navigation stack — so by the
/// time the user presses back there's nothing left to pop, and Flutter's
/// default behaviour is to close the app. This widget intercepts that:
///  - If there IS something to pop (screen was reached via `push`),
///    pop normally — no change in behaviour.
///  - If there's nothing to pop and this is a top-level "home" screen
///    for the signed-in role ([isAppRoot]), require a second back press
///    within 2s to exit (standard Android pattern) instead of exiting
///    immediately.
///  - Otherwise (a secondary screen with an empty stack), send the user
///    back to their role's home screen rather than exiting the app.
class AppBackGuard extends ConsumerStatefulWidget {
  final Widget child;
  final bool isAppRoot;

  const AppBackGuard({super.key, required this.child, this.isAppRoot = false});

  @override
  ConsumerState<AppBackGuard> createState() => _AppBackGuardState();
}

class _AppBackGuardState extends ConsumerState<AppBackGuard> {
  DateTime? _lastBackPressAt;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: widget.child,
    );
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    if (widget.isAppRoot) {
      _handleExitConfirmation(context);
      return;
    }

    final user = ref.read(authStateProvider).valueOrNull;
    final fallback = user?.userRole.homeRoute ?? RouteNames.home;
    AppLogger.nav('AppBackGuard: empty stack on non-root screen, returning to $fallback');
    context.go(fallback);
  }

  void _handleExitConfirmation(BuildContext context) {
    final now = DateTime.now();
    final last = _lastBackPressAt;
    if (last == null || now.difference(last) > const Duration(seconds: 2)) {
      _lastBackPressAt = now;
      AppSnackbar.info(context, 'Press back again to exit');
      return;
    }
    AppLogger.nav('AppBackGuard: exiting app from root screen');
    SystemNavigator.pop();
  }
}