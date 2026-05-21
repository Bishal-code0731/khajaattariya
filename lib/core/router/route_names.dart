// Every route name in Khaja Attariya lives here.
// Never write '/home' or '/login' directly anywhere.
// Always use RouteNames.home or RouteNames.login.
// This way if you rename a route, you change it in one place only.

class RouteNames {
  // ── Core ──────────────────────────────────────────────
  static const String splash  = '/';
  static const String home    = '/home';

  // ── Auth ──────────────────────────────────────────────
  static const String login          = '/login';
  static const String signup         = '/signup';
  static const String forgotPassword = '/forgot-password';

  // ── Customer ──────────────────────────────────────────
  static const String restaurant = '/restaurant';
  static const String cart       = '/cart';
  static const String orders     = '/orders';
  static const String orderDetail= '/order-detail';
  static const String messages   = '/messages';
  static const String chat       = '/chat';
  static const String profile    = '/profile';
  static const String search     = '/search';

  // ── Restaurant Dashboard ───────────────────────────────
  static const String restaurantDashboard = '/restaurant-dashboard';
  static const String menuManagement      = '/menu-management';

  // ── Rider ─────────────────────────────────────────────
  static const String riderDashboard = '/rider-dashboard';

  // ── Admin ─────────────────────────────────────────────
  static const String adminDashboard = '/admin-dashboard';
}