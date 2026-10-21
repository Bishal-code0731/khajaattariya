import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/application/auth_provider.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/offers_screen.dart';
import '../../features/restaurant/presentation/restaurant_detail_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/restaurant_dashboard/presentation/restaurant_dashboard_screen.dart';
import '../../features/restaurant_dashboard/presentation/menu_management_screen.dart';
import '../../features/rider_dashboard/presentation/rider_dashboard_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/admin_dashboard/presentation/admin_dashboard_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/address/presentation/address_book_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/restaurant_hours/presentation/restaurant_hours_screen.dart';
import '../../features/payments/presentation/payment_screen.dart';
import '../../features/support/presentation/support_screen.dart';
import '../../features/support/presentation/ticket_detail_screen.dart';
import '../../features/tracking/presentation/order_tracking_screen.dart';
import '../../shared/widgets/app_back_guard.dart';
import '../../shared/widgets/route_error_screen.dart';
import '../enums/user_role.dart';
import '../utils/app_logger.dart';
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
  RouteNames.restaurantHours,
  RouteNames.menuManagement,
  RouteNames.tracking,
];

/// Routes that belong exclusively to one role.
const _roleExclusiveRoutes = {
  RouteNames.restaurantDashboard: UserRole.restaurant,
  RouteNames.menuManagement: UserRole.restaurant,
  RouteNames.restaurantHours: UserRole.restaurant,
  RouteNames.riderDashboard: UserRole.rider,
  RouteNames.adminDashboard: UserRole.admin,
};

/// Pages that only make sense for customers (ordering, paying, tracking).
const _customerOnlyRoutes = [
  RouteNames.offers,
  RouteNames.cart,
  RouteNames.payment,
  RouteNames.orders,
  RouteNames.tracking,
  RouteNames.addressBook,
  RouteNames.favorites,
];

class _RouterNotifier extends ChangeNotifier {
  UserModel? _user;
  bool _initialized = false;
  bool get initialized => _initialized;
  UserModel? get user => _user;

  // Captures a deep link (e.g.
  String? pendingDeepLink;

  void update(UserModel? user, bool initialized) {
    _user = user;
    _initialized = initialized;
    notifyListeners();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier();

  final splashShownAt = DateTime.now();
  const minSplash = Duration(milliseconds: 1200);
  void apply(UserModel? user) {
    if (notifier.initialized) return notifier.update(user, true);
    final wait = minSplash - DateTime.now().difference(splashShownAt);
    if (wait <= Duration.zero) return notifier.update(user, true);
    Future.delayed(wait, () => notifier.update(user, true));
  }

  ref.listen<AsyncValue<UserModel?>>(authStateProvider, (_, next) {
    next.when(
      data: apply,
      loading: () {},
      error: (_, __) => apply(null),
    );
  });

  final router = GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: (context, state) {
      if (!notifier.initialized) {
        if (state.matchedLocation != RouteNames.splash) {
          notifier.pendingDeepLink = state.uri.toString();
          AppLogger.nav(
              'redirect: auth not initialized yet → ${RouteNames.splash} (captured deep link ${notifier.pendingDeepLink})');
          return RouteNames.splash;
        }
        return null;
      }
      final user = notifier.user;
      final isLoggedIn = user != null;
      final location = state.matchedLocation;
      final isAuthRoute = location == RouteNames.login ||
          location == RouteNames.signup ||
          location == RouteNames.forgotPassword;
      final isSplash = location == RouteNames.splash;
      final isProtected = _protectedRoutes.any((r) => location.startsWith(r));

      if (isSplash) {
        final deepLink = notifier.pendingDeepLink;
        if (deepLink != null) {
          notifier.pendingDeepLink = null;
          AppLogger.nav(
              'redirect: splash → $deepLink (restoring captured deep link)');
          return deepLink;
        }
        final target = isLoggedIn ? user.userRole.homeRoute : RouteNames.home;
        AppLogger.nav('redirect: splash → $target (loggedIn=$isLoggedIn)');
        return target;
      }
      if (isLoggedIn && isAuthRoute) {
        AppLogger.nav(
            'redirect: already logged in, leaving $location → ${user.userRole.homeRoute}');
        return user.userRole.homeRoute;
      }
      if (!isLoggedIn && isProtected) {
        AppLogger.nav(
            'redirect: $location requires login → ${RouteNames.login}');
        return RouteNames.login;
      }

      if (isLoggedIn) {
        if (user.userRole != UserRole.customer &&
            (location == RouteNames.home ||
                _customerOnlyRoutes.any((r) => location.startsWith(r)))) {
          AppLogger.nav(
              'redirect: ${user.userRole.name} not allowed on customer page $location → ${user.userRole.homeRoute}');
          return user.userRole.homeRoute;
        }
        for (final entry in _roleExclusiveRoutes.entries) {
          if (location.startsWith(entry.key) && user.userRole != entry.value) {
            AppLogger.nav(
                'redirect: ${user.userRole.name} not allowed on $location → ${user.userRole.homeRoute}');
            return user.userRole.homeRoute;
          }
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        pageBuilder: (_, __) => const NoTransitionPage(child: SplashScreen()),
      ),
      GoRoute(
        path: RouteNames.home,
        pageBuilder: (_, __) => const NoTransitionPage(
            child: AppBackGuard(isAppRoot: true, child: HomeScreen())),
      ),
      GoRoute(
        path: RouteNames.offers,
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: AppBackGuard(child: OffersScreen())),
      ),
      GoRoute(
        path: '${RouteNames.restaurant}/:id',
        pageBuilder: (_, state) => MaterialPage(
          child: AppBackGuard(
            child: RestaurantDetailScreen(
                restaurantId: state.pathParameters['id']!),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.login,
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: AppBackGuard(child: LoginScreen())),
      ),
      GoRoute(
        path: RouteNames.signup,
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: AppBackGuard(child: SignupScreen())),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        pageBuilder: (_, __) => const NoTransitionPage(
            child: AppBackGuard(child: ForgotPasswordScreen())),
      ),
      GoRoute(
        path: RouteNames.verifyEmail,
        // The email travels in `extra` (never in the URL — privacy).
        pageBuilder: (_, state) {
          final email = (state.extra as Map?)?['email'] as String?;
          return NoTransitionPage(
            child: AppBackGuard(
              child: email == null
                  ? const LoginScreen()
                  : VerifyEmailScreen(email: email),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.resetPassword,
        pageBuilder: (_, __) => const NoTransitionPage(
            child: AppBackGuard(child: ResetPasswordScreen())),
      ),
      GoRoute(
        path: RouteNames.cart,
        pageBuilder: (_, __) =>
            const MaterialPage(child: AppBackGuard(child: CartScreen())),
      ),
      GoRoute(
        path: RouteNames.orders,
        pageBuilder: (_, __) =>
            const MaterialPage(child: AppBackGuard(child: OrdersScreen())),
      ),
      GoRoute(
        path: '${RouteNames.orderDetail}/:id',
        pageBuilder: (_, state) => MaterialPage(
          child: AppBackGuard(
            child: OrderDetailScreen(orderId: state.pathParameters['id']!),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.payment,
        pageBuilder: (_, state) {
          final extra = state.extra;
          final rawAmounts = extra is Map ? extra['orderAmounts'] : null;
          if (rawAmounts is! Map || rawAmounts.isEmpty) {
            AppLogger.warning(
                'router', 'payment route opened without valid extra data');
            return MaterialPage(
              child: AppBackGuard(
                child: Scaffold(
                  appBar: AppBar(title: const Text('Payment')),
                  body: const Center(
                    child: Text(
                        'Missing order details. Please go back and try again.'),
                  ),
                ),
              ),
            );
          }
          final orderAmounts = rawAmounts.map(
            (key, value) => MapEntry(key as String, (value as num).toDouble()),
          );
          return MaterialPage(
            child: AppBackGuard(
              child: PaymentScreen(orderAmounts: orderAmounts),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.restaurantDashboard,
        pageBuilder: (_, __) => const NoTransitionPage(
          child:
              AppBackGuard(isAppRoot: true, child: RestaurantDashboardScreen()),
        ),
      ),
      GoRoute(
        path: '${RouteNames.menuManagement}/:id',
        pageBuilder: (_, state) => MaterialPage(
          child: AppBackGuard(
            child: MenuManagementScreen(
              restaurantId: state.pathParameters['id']!,
              restaurantName: (state.extra as String?) ?? 'My Restaurant',
            ),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.riderDashboard,
        pageBuilder: (_, __) => const NoTransitionPage(
          child: AppBackGuard(isAppRoot: true, child: RiderDashboardScreen()),
        ),
      ),
      GoRoute(
        path: RouteNames.profile,
        pageBuilder: (_, __) =>
            const MaterialPage(child: AppBackGuard(child: ProfileScreen())),
      ),
      GoRoute(
        path: RouteNames.search,
        pageBuilder: (_, __) =>
            const MaterialPage(child: AppBackGuard(child: SearchScreen())),
      ),
      GoRoute(
        path: RouteNames.adminDashboard,
        pageBuilder: (_, __) => const NoTransitionPage(
          child: AppBackGuard(isAppRoot: true, child: AdminDashboardScreen()),
        ),
      ),
      GoRoute(
        path: RouteNames.notifications,
        pageBuilder: (_, __) => const MaterialPage(
            child: AppBackGuard(child: NotificationsScreen())),
      ),
      GoRoute(
        path: RouteNames.addressBook,
        pageBuilder: (_, __) =>
            const MaterialPage(child: AppBackGuard(child: AddressBookScreen())),
      ),
      GoRoute(
        path: RouteNames.favorites,
        pageBuilder: (_, __) =>
            const MaterialPage(child: AppBackGuard(child: FavoritesScreen())),
      ),
      GoRoute(
        path: '${RouteNames.restaurantHours}/:id',
        pageBuilder: (_, state) => MaterialPage(
          child: AppBackGuard(
            child: RestaurantHoursScreen(
                restaurantId: state.pathParameters['id']!),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.support,
        pageBuilder: (_, __) =>
            const MaterialPage(child: AppBackGuard(child: SupportScreen())),
      ),
      GoRoute(
        path: '${RouteNames.support}/:id',
        pageBuilder: (_, state) => MaterialPage(
          child: AppBackGuard(
            child: TicketDetailScreen(ticketId: state.pathParameters['id']!),
          ),
        ),
      ),
      GoRoute(
        path: '${RouteNames.tracking}/:id',
        pageBuilder: (_, state) => MaterialPage(
          child: AppBackGuard(
            child: OrderTrackingScreen(orderId: state.pathParameters['id']!),
          ),
        ),
      ),
    ],
    errorBuilder: (_, state) {
      AppLogger.warning(
          'router', 'no route matched "${state.uri}": ${state.error}');
      return RouteErrorScreen(details: state.error?.toString());
    },
  );

  ref.onDispose(router.dispose);
  // A password-reset link opens a recovery session: show the set-new-password screen.
  final recoverySub = ref
      .read(authRepositoryProvider)
      .passwordRecoveryEvents
      .listen((_) => router.go(RouteNames.resetPassword));
  ref.onDispose(recoverySub.cancel);

  return router;
});
