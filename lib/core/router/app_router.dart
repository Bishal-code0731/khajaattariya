import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/restaurant_dashboard/presentation/restaurant_dashboard_screen.dart';
import '../../features/rider_dashboard/presentation/rider_dashboard_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/admin_dashboard/presentation/admin_dashboard_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/address/presentation/address_book_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/restaurant_hours/presentation/restaurant_hours_screen.dart';
import '../../features/payments/presentation/payment_screen.dart';
import 'route_names.dart';

const _protectedRoutes = [
  RouteNames.orders,
  RouteNames.profile,
  RouteNames.cart,
  RouteNames.orderDetail,
  RouteNames.restaurantDashboard,
  RouteNames.riderDashboard,
  RouteNames.adminDashboard,
  RouteNames.notifications,
  RouteNames.addressBook,
  RouteNames.favorites,
  RouteNames.payment,
  RouteNames.support,
];

class _RouterNotifier extends ChangeNotifier {
  UserModel? _user;
  bool _initialized = false;
  bool get initialized => _initialized;
  UserModel? get user => _user;

  void update(UserModel? user, bool initialized) {
    _user = user;
    _initialized = initialized;
    notifyListeners();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier();

  ref.listen<AsyncValue<UserModel?>>(authStateProvider, (_, next) {
    next.when(
      data: (user) => notifier.update(user, true),
      loading: () {},
      error: (_, __) => notifier.update(null, true),
    );
  });

  final router = GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: (context, state) {
      if (!notifier.initialized) {
        return state.matchedLocation == RouteNames.splash ? null : RouteNames.splash;
      }
      final user = notifier.user;
      final isLoggedIn = user != null;
      final location = state.matchedLocation;
      final isAuthRoute = location == RouteNames.login ||
          location == RouteNames.signup ||
          location == RouteNames.forgotPassword;
      final isSplash = location == RouteNames.splash;
      final isProtected = _protectedRoutes.any((r) => location.startsWith(r));

      if (isSplash) return isLoggedIn ? _homeByRole(user) : RouteNames.home;
      if (isLoggedIn && isAuthRoute) return _homeByRole(user);
      if (!isLoggedIn && isProtected) return RouteNames.login;
      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        pageBuilder: (_, __) => const NoTransitionPage(child: SplashScreen()),
      ),
      GoRoute(
        path: RouteNames.home,
        pageBuilder: (_, __) => const NoTransitionPage(child: HomeScreen()),
      ),
      GoRoute(
        path: '${RouteNames.restaurant}/:id',
        pageBuilder: (_, state) => MaterialPage(
          child: RestaurantDetailScreen(restaurantId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: RouteNames.login,
        pageBuilder: (_, __) => const NoTransitionPage(child: LoginScreen()),
      ),
      GoRoute(
        path: RouteNames.signup,
        pageBuilder: (_, __) => const NoTransitionPage(child: SignupScreen()),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        pageBuilder: (_, __) => const NoTransitionPage(child: ForgotPasswordScreen()),
      ),
      GoRoute(
        path: RouteNames.cart,
        pageBuilder: (_, __) => const MaterialPage(child: CartScreen()),
      ),
      GoRoute(
        path: RouteNames.orders,
        pageBuilder: (_, __) => const MaterialPage(child: OrdersScreen()),
      ),
      GoRoute(
        path: '${RouteNames.orderDetail}/:id',
        pageBuilder: (_, state) => MaterialPage(
          child: OrderDetailScreen(orderId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: RouteNames.payment,
        pageBuilder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return MaterialPage(
            child: PaymentScreen(
              orderId: extra['orderId'] as String,
              amount: extra['amount'] as double,
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.restaurantDashboard,
        pageBuilder: (_, __) => const NoTransitionPage(child: RestaurantDashboardScreen()),
      ),
      GoRoute(
        path: RouteNames.riderDashboard,
        pageBuilder: (_, __) => const NoTransitionPage(child: RiderDashboardScreen()),
      ),
      GoRoute(
        path: RouteNames.profile,
        pageBuilder: (_, __) => const MaterialPage(child: ProfileScreen()),
      ),
      GoRoute(
        path: RouteNames.search,
        pageBuilder: (_, __) => const MaterialPage(child: SearchScreen()),
      ),
      GoRoute(
        path: RouteNames.adminDashboard,
        pageBuilder: (_, __) => const NoTransitionPage(child: AdminDashboardScreen()),
      ),
      GoRoute(
        path: RouteNames.notifications,
        pageBuilder: (_, __) => const MaterialPage(child: NotificationsScreen()),
      ),
      GoRoute(
        path: RouteNames.addressBook,
        pageBuilder: (_, __) => const MaterialPage(child: AddressBookScreen()),
      ),
      GoRoute(
        path: RouteNames.favorites,
        pageBuilder: (_, __) => const MaterialPage(child: FavoritesScreen()),
      ),
      GoRoute(
        path: '${RouteNames.restaurantHours}/:id',
        pageBuilder: (_, state) => MaterialPage(
          child: RestaurantHoursScreen(restaurantId: state.pathParameters['id']!),
        ),
      ),
    ],
    errorBuilder: (_, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );

  ref.onDispose(router.dispose);
  return router;
});

String _homeByRole(UserModel user) {
  switch (user.role) {
    case 'restaurant': return RouteNames.restaurantDashboard;
    case 'rider':      return RouteNames.riderDashboard;
    case 'admin':      return RouteNames.adminDashboard;
    default:           return RouteNames.home;
  }
}