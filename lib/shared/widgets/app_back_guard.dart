import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_names.dart';
import '../../core/utils/app_logger.dart';
import '../../features/auth/application/auth_provider.dart';
import 'app_snackbar.dart';

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
    AppLogger.nav(
        'AppBackGuard: empty stack on non-root screen, returning to $fallback');
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
