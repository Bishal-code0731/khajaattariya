import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/s.dart';
import '../../../core/router/route_names.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../auth/application/auth_provider.dart';
import '../application/owner_restaurant_provider.dart';
import 'widgets/dashboard_shell.dart';
import 'widgets/logout_button.dart';
import 'widgets/restaurant_registration_view.dart';

class RestaurantDashboardScreen extends ConsumerWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      loading: () => const Scaffold(body: AppLoader.fullscreen()),
      error: (_, __) => const _LoginRequired(),
      data: (user) =>
          user == null ? const _LoginRequired() : _OwnerGate(ownerId: user.id),
    );
  }
}

class _OwnerGate extends ConsumerWidget {
  const _OwnerGate({required this.ownerId});

  final String ownerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s.restaurant;
    final restaurantAsync = ref.watch(ownerRestaurantProvider(ownerId));

    if (!restaurantAsync.hasValue) {
      return Scaffold(
        appBar: AppTopBar(
            title: s.dashboardTitle,
            showBack: false,
            actions: const [LogoutButton()]),
        body: restaurantAsync.hasError
            ? AppErrorState(
                error: restaurantAsync.error,
                onRetry: () => ref.invalidate(ownerRestaurantProvider(ownerId)),
              )
            : const AppShimmerCardList(count: 4, itemHeight: 88),
      );
    }

    final restaurant = restaurantAsync.value;
    if (restaurant == null) return RestaurantRegistrationView(ownerId: ownerId);
    return RestaurantDashboardShell(restaurant: restaurant, ownerId: ownerId);
  }
}

class _LoginRequired extends StatelessWidget {
  const _LoginRequired();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppTopBar(title: s.restaurant.dashboardTitle, showBack: false),
      body: AppEmptyState(
        icon: Icons.lock_outline_rounded,
        title: s.restaurant.loginRequiredTitle,
        subtitle: s.restaurant.loginRequiredBody,
        action: AppButton(
          label: s.common.login,
          expand: false,
          onPressed: () => context.go(RouteNames.login),
        ),
      ),
    );
  }
}
