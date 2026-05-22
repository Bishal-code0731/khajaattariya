import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/application/auth_provider.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import 'route_names.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  // Watch auth state — router rebuilds when user logs in or out
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == RouteNames.login ||
          state.matchedLocation == RouteNames.signup ||
          state.matchedLocation == RouteNames.forgotPassword ||
          state.matchedLocation == RouteNames.splash;

      // If logged in and trying to access auth screens → go home
      if (isLoggedIn && isAuthRoute && state.matchedLocation != RouteNames.splash) {
        return _getHomeByRole(authState.valueOrNull);
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        pageBuilder: (context, state) =>
        const NoTransitionPage(child: SplashScreen()),
      ),
      GoRoute(
        path: RouteNames.home,
        pageBuilder: (context, state) =>
            NoTransitionPage(child: HomeScreen()),
      ),
      GoRoute(
        path: RouteNames.login,
        pageBuilder: (context, state) =>
            NoTransitionPage(child: LoginScreen()),
      ),
      GoRoute(
        path: RouteNames.signup,
        pageBuilder: (context, state) =>
            NoTransitionPage(child: SignupScreen()),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        pageBuilder: (context, state) =>
            NoTransitionPage(child: ForgotPasswordScreen()),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
}

String _getHomeByRole(UserModel? user) {
  if (user == null) return RouteNames.home;
  switch (user.role) {
    case 'restaurant':
      return RouteNames.restaurantDashboard;
    case 'rider':
      return RouteNames.riderDashboard;
    case 'admin':
      return RouteNames.adminDashboard;
    default:
      return RouteNames.home;
  }
}