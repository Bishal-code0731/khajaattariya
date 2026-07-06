import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/image_upload.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../features/orders/application/order_provider.dart';
import '../../../features/orders/domain/models/order_model.dart';
import '../application/analytics_provider.dart';
import '../application/restaurant_registration_provider.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_stat_tile.dart';
import '../../../shared/widgets/app_status_badge.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/order_items_list.dart';
import '../../../main.dart';
import 'order_prep_gantt_view.dart';
import 'restaurant_analytics_tab.dart';

class RestaurantDashboardScreen extends ConsumerWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(body: AppLoader.fullscreen()),
      error: (_, __) => Scaffold(
        body: AppEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Please log in',
          subtitle: 'Log in as a restaurant owner to view your dashboard.',
          action: FilledButton(
            onPressed: () => context.go(RouteNames.login),
            child: const Text('Go to Login'),
          ),
        ),
      ),
      data: (user) {
        if (user == null) {
          return Scaffold(
            body: AppEmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Please log in',
              subtitle: 'Log in as a restaurant owner to view your dashboard.',
              action: FilledButton(
                onPressed: () => context.go(RouteNames.login),
                child: const Text('Go to Login'),
              ),
            ),
          );
        }
        // Restaurant owner needs their restaurant id
        // For now we fetch it from restaurants table by owner_id
        return _RestaurantDashboardBody(ownerId: user.id, ownerName: user.fullName);
      },
    );
  }
}

class _RestaurantDashboardBody extends ConsumerWidget {
  final String ownerId;
  final String ownerName;

  const _RestaurantDashboardBody({
    required this.ownerId,
    required this.ownerName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch this owner's restaurant id first
    final restaurantAsync = ref.watch(_ownerRestaurantProvider(ownerId));

    return restaurantAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Restaurant Dashboard')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Restaurant Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              const Text('Could not load restaurant data'),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => ref.invalidate(_ownerRestaurantProvider(ownerId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (restaurant) {
        if (restaurant == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Restaurant Dashboard'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
                ),
              ],
            ),
            body: _RestaurantRegistrationView(ownerId: ownerId),
          );
        }

        final restaurantId = restaurant['id'] as String;
        final restaurantName = restaurant['name'] as String;
        final isApproved = restaurant['is_approved'] as bool? ?? false;

        // Wide screens (tablet landscape / desktop): show Orders and
        // Analytics side by side instead of behind tabs, since there's
        // enough width for both without cramming.
        return LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          if (isWide) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Restaurant Dashboard'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout_rounded),
                    onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
                  ),
                ],
              ),
              body: Column(
                children: [
                  if (!isApproved) const _PendingApprovalBanner(),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _OrdersView(restaurantId: restaurantId, restaurantName: restaurantName),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(
                          flex: 2,
                          child: RestaurantAnalyticsTab(
                            restaurantId: restaurantId,
                            restaurantName: restaurantName,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Restaurant Dashboard'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout_rounded),
                    onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
                  ),
                ],
                bottom: const TabBar(
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [Tab(text: 'Orders'), Tab(text: 'Timeline'), Tab(text: 'Analytics')],
                ),
              ),
              body: Column(
                children: [
                  if (!isApproved) const _PendingApprovalBanner(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _OrdersView(restaurantId: restaurantId, restaurantName: restaurantName),
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                          child: OrderPrepGanttView(restaurantId: restaurantId),
                        ),
                        RestaurantAnalyticsTab(restaurantId: restaurantId, restaurantName: restaurantName),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

// Fetches the restaurant owned by this user
final _ownerRestaurantProvider =
FutureProvider.family<Map<String, dynamic>?, String>((ref, ownerId) async {
  // .maybeSingle() throws if more than one row matches — an owner can end
  // up with multiple restaurant rows (e.g. a resubmitted registration
  // form), so take the most recently created one instead of asserting
  // there's exactly one.
  final rows = await supabase
      .from('restaurants')
      .select('id, name, is_approved')
      .eq('owner_id', ownerId)
      .order('created_at', ascending: false)
      .limit(1);
  return rows.isEmpty ? null : rows.first;
});

class _PendingApprovalBanner extends StatelessWidget {
  const _PendingApprovalBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.warning,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hourglass_top_rounded, size: 14, color: AppColors.white),
          const SizedBox(width: 6),
          Text('Awaiting admin approval — customers may not see your restaurant yet',
              style: AppTypography.labelSmall.copyWith(color: AppColors.white)),
        ],
      ),
    );
  }
}

class _RestaurantRegistrationView extends ConsumerStatefulWidget {
  final String ownerId;
  const _RestaurantRegistrationView({required this.ownerId});

  @override
  ConsumerState<_RestaurantRegistrationView> createState() => _RestaurantRegistrationViewState();
}

class _RestaurantRegistrationViewState extends ConsumerState<_RestaurantRegistrationView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cuisineCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  bool _isUploadingLogo = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cuisineCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadLogo() async {
    if (_isUploadingLogo) return;
    setState(() => _isUploadingLogo = true);
    try {
      final url = await ImageUpload.pickCompressAndUpload(
        supabase: supabase,
        bucket: 'restaurant-media',
        path: 'logos/${widget.ownerId}/logo.jpg',
        maxDimension: 800,
      );
      if (url != null) _imageCtrl.text = url;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not upload logo: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  bool _submitting = false;

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    _submitting = true;
    final ok = await ref.read(restaurantRegistrationProvider.notifier).register(
          ownerId: widget.ownerId,
          name: _nameCtrl.text.trim(),
          cuisineType: _cuisineCtrl.text.trim(),
          address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          imageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
        );
    _submitting = false;
    if (!mounted) return;
    if (ok) {
      ref.invalidate(_ownerRestaurantProvider(widget.ownerId));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Restaurant created! Awaiting admin approval.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not create restaurant. Please try again.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final registrationState = ref.watch(restaurantRegistrationProvider);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          const SizedBox(height: AppSpacing.lg),
          const Icon(Icons.storefront_rounded, size: 64, color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          Text('Set Up Your Restaurant', style: AppTypography.headingSmall, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tell customers about your restaurant — you can add your menu right after.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: 'Restaurant Name',
            hint: 'e.g. Khaja Ghar',
            controller: _nameCtrl,
            prefixIcon: Icons.storefront_outlined,
            validator: Validators.restaurantName,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Cuisine Type',
            hint: 'e.g. Nepali, Fast Food, Indian',
            controller: _cuisineCtrl,
            prefixIcon: Icons.restaurant_menu_rounded,
            validator: Validators.cuisineType,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Address (optional)',
            hint: 'Street, area, city',
            controller: _addressCtrl,
            prefixIcon: Icons.location_on_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Phone (optional)',
            hint: '98XXXXXXXX',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            validator: (v) => Validators.phone(v, optional: true),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Cover Image URL (optional)',
            hint: 'https://... or upload a photo below',
            controller: _imageCtrl,
            prefixIcon: Icons.image_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _isUploadingLogo ? null : _pickAndUploadLogo,
            icon: _isUploadingLogo
                ? const AppLoader.button(color: AppColors.primary)
                : const Icon(Icons.upload_rounded, size: 18),
            label: Text(_isUploadingLogo ? 'Uploading…' : 'Upload Logo'),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Create Restaurant',
            isLoading: registrationState.isLoading,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _OrdersView extends ConsumerWidget {
  final String restaurantId;
  final String restaurantName;

  const _OrdersView({
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(restaurantOrdersProvider(restaurantId));

    return ordersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Could not load orders', style: AppTypography.bodyMedium),
            TextButton(
              onPressed: () =>
                  ref.invalidate(restaurantOrdersProvider(restaurantId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (orders) {
        final active = orders
            .where((o) => o.status != OrderStatus.delivered &&
            o.status != OrderStatus.cancelled)
            .toList();
        final completed = orders
            .where((o) =>
        o.status == OrderStatus.delivered ||
            o.status == OrderStatus.cancelled)
            .toList();

        final pendingCount = orders
            .where((o) => o.status == OrderStatus.pending)
            .length;

        return CustomScrollView(
          slivers: [
            // Stats bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(restaurantName,
                        style: AppTypography.headingLarge),
                    TextButton.icon(
                      onPressed: () => context.push(
                        '${RouteNames.menuManagement}/$restaurantId',
                        extra: restaurantName,
                      ),
                      icon: const Icon(Icons.restaurant_menu_rounded,
                          size: 16, color: AppColors.primary),
                      label: Text('Manage Menu',
                          style: AppTypography.labelSmall
                              .copyWith(color: AppColors.primary)),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Consumer(builder: (context, ref, _) {
                      final salesAsync = ref.watch(restaurantDailySalesProvider(restaurantId));
                      final today = DateTime.now();
                      final todayStr = DateTime(today.year, today.month, today.day);
                      return salesAsync.when(
                        loading: () => const Row(children: [
                          Expanded(child: SizedBox(height: 76)),
                        ]),
                        error: (_, __) => Row(
                          children: [
                            AppStatTile(
                              label: "Pending",
                              value: '$pendingCount',
                              icon: Icons.pending_outlined,
                              color: AppColors.accent,
                            ),
                          ],
                        ),
                        data: (sales) {
                          final todaySales = sales.where((s) =>
                              s.date.year == todayStr.year &&
                              s.date.month == todayStr.month &&
                              s.date.day == todayStr.day);
                          final todayOrders = todaySales.fold<int>(0, (s, d) => s + d.totalOrders);
                          final todayRevenue = todaySales.fold<double>(0, (s, d) => s + d.totalRevenue);
                          return Column(
                            children: [
                              Row(
                                children: [
                                  AppStatTile(
                                    label: "Today's Orders",
                                    value: '$todayOrders',
                                    icon: Icons.receipt_long_rounded,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  AppStatTile(
                                    label: "Revenue",
                                    value: 'Rs. ${todayRevenue.toInt()}',
                                    icon: Icons.payments_outlined,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  AppStatTile(
                                    label: "Pending",
                                    value: '$pendingCount',
                                    icon: Icons.pending_outlined,
                                    color: AppColors.accent,
                                  ),
                                ],
                              ),
                              if (sales.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.md),
                                _WeeklyTrendChart(sales: sales),
                              ],
                            ],
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Active orders
            if (active.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.md,
                    AppSpacing.screenHorizontal,
                    AppSpacing.sm,
                  ),
                  child: Text('Active Orders',
                      style: AppTypography.headingSmall),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) => _RestaurantOrderCard(
                    order: active[index],
                    isRestaurant: true,
                  ),
                  childCount: active.length,
                ),
              ),
            ],

            // Completed orders
            if (completed.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.md,
                    AppSpacing.screenHorizontal,
                    AppSpacing.sm,
                  ),
                  child: Text('Completed',
                      style: AppTypography.headingSmall),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) => _RestaurantOrderCard(
                    order: completed[index],
                    isRestaurant: true,
                  ),
                  childCount: completed.length,
                ),
              ),
            ],

            if (orders.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox_outlined,
                          size: 64, color: AppColors.textHint),
                      const SizedBox(height: AppSpacing.md),
                      Text('No orders yet',
                          style: AppTypography.headingSmall),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'New orders will appear here in real-time',
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xl),
            ),
          ],
        );
      },
    );
  }
}

class _WeeklyTrendChart extends StatelessWidget {
  final List<DailySales> sales;
  const _WeeklyTrendChart({required this.sales});

  @override
  Widget build(BuildContext context) {
    final maxRevenue = sales.fold<double>(1, (m, s) => s.totalRevenue > m ? s.totalRevenue : m);
    const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last 7 Days', style: AppTypography.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 72,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: sales.map((s) {
                final heightFraction = (s.totalRevenue / maxRevenue).clamp(0.05, 1.0);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 48 * heightFraction,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          weekdayLabels[s.date.weekday - 1],
                          style: AppTypography.bodySmall.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantOrderCard extends ConsumerWidget {
  final OrderModel order;
  final bool isRestaurant;

  const _RestaurantOrderCard({
    required this.order,
    required this.isRestaurant,
  });

  OrderStatus? get _nextStatus {
    switch (order.status) {
      case OrderStatus.pending:   return OrderStatus.confirmed;
      case OrderStatus.confirmed: return OrderStatus.preparing;
      case OrderStatus.preparing: return OrderStatus.ready;
      default: return null;
    }
  }

  String? get _actionLabel {
    switch (order.status) {
      case OrderStatus.pending:   return 'Confirm Order';
      case OrderStatus.confirmed: return 'Start Preparing';
      case OrderStatus.preparing: return 'Mark Ready';
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUpdating = ref.watch(orderStatusNotifierProvider).isLoading;

    return GlassCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8).toUpperCase()}',
                      style: AppTypography.headingSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.items.length} item${order.items.length == 1 ? '' : 's'} • Rs. ${order.totalAmount.toInt()}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              AppStatusBadge(status: order.status),
            ],
          ),
          if (order.items.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            OrderItemsList(items: order.items, showSubtotals: true),
          ],
          if (order.notes != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.note_outlined,
                    size: 13, color: AppColors.textHint),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(order.notes!,
                      style: AppTypography.bodySmall),
                ),
              ],
            ),
          ],
          if (_nextStatus != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: _actionLabel!,
              isLoading: isUpdating,
              onPressed: () async {
                final success = await ref
                    .read(orderStatusNotifierProvider.notifier)
                    .updateStatus(order.id, _nextStatus!);
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update status'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
          if (order.status == OrderStatus.cancelled) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.cancel_outlined,
                    size: 14, color: AppColors.error),
                const SizedBox(width: 4),
                Text('Cancelled',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.error)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

