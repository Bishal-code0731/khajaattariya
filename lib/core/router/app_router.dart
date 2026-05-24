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
import '../../features/restaurant/presentation/restaurant_detail_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import 'route_names.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/restaurant_dashboard/presentation/restaurant_dashboard_screen.dart';
import '../../features/rider_dashboard/presentation/rider_dashboard_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/search/presentation/search_screen.dart';


part 'app_router.g.dart';

const _protectedRoutes = [
  RouteNames.orders,
  RouteNames.profile,
  RouteNames.cart,
  RouteNames.orderDetail,
  RouteNames.restaurantDashboard,
  RouteNames.riderDashboard,
];

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final location = state.matchedLocation;

      final isAuthRoute = location == RouteNames.login ||
          location == RouteNames.signup ||
          location == RouteNames.forgotPassword;

      final isProtected = _protectedRoutes.any(
            (r) => location.startsWith(r),
      );

      // Logged in + on auth screen → role-based home
      if (isLoggedIn && isAuthRoute) {
        return _getHomeByRole(user);
      }

      // Not logged in + protected route → login
      if (!isLoggedIn && isProtected) {
        return RouteNames.login;
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
        const NoTransitionPage(child: HomeScreen()),
      ),
      GoRoute(
        path: '${RouteNames.restaurant}/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return MaterialPage(
            child: RestaurantDetailScreen(restaurantId: id),
          );
        },
      ),
      GoRoute(
        path: RouteNames.login,
        pageBuilder: (context, state) =>
        const NoTransitionPage(child: LoginScreen()),
      ),
      GoRoute(
        path: RouteNames.signup,
        pageBuilder: (context, state) =>
        const NoTransitionPage(child: SignupScreen()),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        pageBuilder: (context, state) =>
        const NoTransitionPage(child: ForgotPasswordScreen()),
      ),
      GoRoute(
        path: RouteNames.cart,
        pageBuilder: (context, state) =>
        const MaterialPage(child: CartScreen()),
      ),
      GoRoute(
        path: RouteNames.orders,
        pageBuilder: (context, state) =>
        const MaterialPage(child: OrdersScreen()),
      ),
      GoRoute(
        path: '${RouteNames.orderDetail}/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return MaterialPage(child: OrderDetailScreen(orderId: id));
        },
      ),
      GoRoute(
        path: RouteNames.restaurantDashboard,
        pageBuilder: (context, state) =>
        const NoTransitionPage(child: RestaurantDashboardScreen()),
      ),
      GoRoute(
        path: RouteNames.riderDashboard,
        pageBuilder: (context, state) =>
        const NoTransitionPage(child: RiderDashboardScreen()),
      ),
      GoRoute(
        path: RouteNames.profile,
        pageBuilder: (context, state) =>
        const MaterialPage(child: ProfileScreen()),
      ),
      GoRoute(
        path: RouteNames.search,
        pageBuilder: (context, state) =>
        const MaterialPage(child: SearchScreen()),
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