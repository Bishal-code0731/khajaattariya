import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../features/orders/application/order_provider.dart';
import '../../../features/orders/domain/models/order_model.dart';
import '../../../features/rider/application/rider_provider.dart';
import '../../../features/rider/domain/models/rider_model.dart';
import '../../../shared/widgets/glass_card.dart';

class RiderDashboardScreen extends ConsumerStatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  ConsumerState<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends ConsumerState<RiderDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user != null) ref.read(riderOnlineNotifierProvider.notifier).loadStatus(user.id);
    });
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final onlineState = ref.watch(riderOnlineNotifierProvider);
    final isOnline = onlineState.valueOrNull ?? false;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Rider Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          dividerColor: AppColors.border,
          tabs: const [Tab(text: 'Deliveries'), Tab(text: 'Earnings'), Tab(text: 'Profile')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DeliveriesTab(userId: user.id, isOnline: isOnline),
          _EarningsTab(userId: user.id),
          _RiderProfileTab(userId: user.id),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onlineState.isLoading
            ? null
            : () => ref.read(riderOnlineNotifierProvider.notifier).toggle(user.id),
        backgroundColor: isOnline ? AppColors.success : AppColors.textSecondary,
        icon: Icon(isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded, color: Colors.white),
        label: Text(isOnline ? 'Online' : 'Offline',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _DeliveriesTab extends ConsumerWidget {
  final String userId;
  final bool isOnline;
  const _DeliveriesTab({required this.userId, required this.isOnline});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableAsync = ref.watch(availableOrdersProvider);
    final activeAsync = ref.watch(riderActiveOrderProvider(userId));

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.all(AppSpacing.screenHorizontal),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isOnline ? AppColors.successLight : AppColors.border.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(children: [
            Container(width: 10, height: 10,
                decoration: BoxDecoration(
                    color: isOnline ? AppColors.success : AppColors.textHint, shape: BoxShape.circle)),
            const SizedBox(width: AppSpacing.sm),
            Text(
              isOnline ? 'You are online – available for deliveries' : 'You are offline – toggle to go online',
              style: AppTypography.bodySmall.copyWith(
                  color: isOnline ? AppColors.success : AppColors.textSecondary),
            ),
          ]),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal, 0, AppSpacing.screenHorizontal, AppSpacing.sm),
          child: Text('My Active Delivery', style: AppTypography.headingSmall),
        ),
      ),
      SliverToBoxAdapter(
        child: activeAsync.when(
          loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))),
          error: (_, __) => const SizedBox.shrink(),
          data: (activeOrder) => activeOrder == null
              ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpacing.md), borderRadius: AppSpacing.radiusLg,
                child: Row(children: [
                  const Icon(Icons.delivery_dining_rounded, color: AppColors.textHint, size: 32),
                  const SizedBox(width: AppSpacing.md),
                  Text('No active delivery', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                ]),
              ))
              : _ActiveDeliveryCard(order: activeOrder, riderId: userId),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal, AppSpacing.lg, AppSpacing.screenHorizontal, AppSpacing.sm),
          child: Text('Available Pickups', style: AppTypography.headingSmall),
        ),
      ),
      availableAsync.when(
        loading: () => const SliverToBoxAdapter(child: Center(
            child: Padding(padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)))),
        error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
        data: (orders) {
          if (!isOnline) {
            return SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpacing.md), borderRadius: AppSpacing.radiusLg,
                child: Column(children: [
                  const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textHint),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Go online to see available orders', style: AppTypography.bodyMedium),
                ]),
              ),
            ));
          }
          if (orders.isEmpty) {
            return SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpacing.md), borderRadius: AppSpacing.radiusLg,
                child: Column(children: [
                  const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textHint),
                  const SizedBox(height: AppSpacing.sm),
                  Text('No orders ready for pickup', style: AppTypography.bodyMedium),
                ]),
              ),
            ));
          }
          return SliverList(delegate: SliverChildBuilderDelegate(
                (context, index) => _AvailableOrderCard(order: orders[index], riderId: userId),
            childCount: orders.length,
          ));
        },
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ]);
  }
}

class _EarningsTab extends ConsumerWidget {
  final String userId;
  const _EarningsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(riderEarningsSummaryProvider(userId));
    final earningsAsync = ref.watch(riderEarningsProvider(userId));

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: summaryAsync.when(
          loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
          error: (_, __) => const SizedBox.shrink(),
          data: (summary) => Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Row(children: [
              _EarningStat(label: 'Total Deliveries',
                  value: '${summary['total_deliveries']!.toInt()}',
                  icon: Icons.delivery_dining_rounded, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              _EarningStat(label: 'Total Earned',
                  value: 'Rs. ${summary['total_earnings']!.toInt()}',
                  icon: Icons.account_balance_wallet_rounded, color: AppColors.success),
            ]),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal, 0, AppSpacing.screenHorizontal, AppSpacing.sm),
          child: Text('Earnings History', style: AppTypography.headingSmall),
        ),
      ),
      earningsAsync.when(
        loading: () => const SliverToBoxAdapter(child: Center(
            child: Padding(padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(color: AppColors.primary)))),
        error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
        data: (earnings) {
          if (earnings.isEmpty) {
            return SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpacing.xl), borderRadius: AppSpacing.radiusLg,
                child: Column(children: [
                  const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textHint),
                  const SizedBox(height: AppSpacing.sm),
                  Text('No earnings yet', style: AppTypography.bodyMedium),
                ]),
              ),
            ));
          }
          return SliverList(delegate: SliverChildBuilderDelegate(
                (context, index) {
              final e = earnings[index];
              return GlassCard(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.xs),
                padding: const EdgeInsets.all(AppSpacing.md), borderRadius: AppSpacing.radiusMd,
                child: Row(children: [
                  Container(width: 36, height: 36,
                      decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, color: AppColors.success, size: 18)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Order #${e.orderId.substring(0, 8).toUpperCase()}', style: AppTypography.bodyMedium),
                    Text('${e.createdAt.day}/${e.createdAt.month}/${e.createdAt.year}', style: AppTypography.bodySmall),
                  ])),
                  Text('+Rs. ${e.amount.toInt()}',
                      style: AppTypography.priceMedium.copyWith(color: AppColors.success)),
                ]),
              );
            },
            childCount: earnings.length,
          ));
        },
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
    ]);
  }
}

class _RiderProfileTab extends ConsumerWidget {
  final String userId;
  const _RiderProfileTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(riderProfileProvider(userId));
    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => Center(child: Text('Could not load profile', style: AppTypography.bodyMedium)),
      data: (rider) {
        if (rider == null) return _RiderRegistrationView(userId: userId);
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          children: [
            const SizedBox(height: AppSpacing.md),
            Center(child: CircleAvatar(
              radius: 40, backgroundColor: AppColors.riderColor.withOpacity(0.15),
              child: Text(rider.fullName.isNotEmpty ? rider.fullName[0].toUpperCase() : 'R',
                  style: AppTypography.headingLarge.copyWith(color: AppColors.riderColor)),
            )),
            const SizedBox(height: AppSpacing.md),
            Center(child: Text(rider.fullName, style: AppTypography.headingSmall)),
            const SizedBox(height: AppSpacing.xs),
            Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
              decoration: BoxDecoration(
                color: rider.isApproved ? AppColors.successLight : AppColors.warningLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(rider.isApproved ? 'Approved Rider' : 'Pending Approval',
                  style: AppTypography.labelSmall.copyWith(
                      color: rider.isApproved ? AppColors.success : AppColors.warning)),
            )),
            const SizedBox(height: AppSpacing.lg),
            _ProfileRow(icon: Icons.phone_rounded, label: 'Phone', value: rider.phone ?? '-'),
            _ProfileRow(icon: Icons.two_wheeler_rounded, label: 'Vehicle Type', value: rider.vehicleType.toUpperCase()),
            if (rider.vehicleNumber != null)
              _ProfileRow(icon: Icons.credit_card_rounded, label: 'Vehicle Number', value: rider.vehicleNumber!),
            _ProfileRow(icon: Icons.delivery_dining_rounded, label: 'Total Deliveries', value: '${rider.totalDeliveries}'),
            _ProfileRow(icon: Icons.account_balance_wallet_rounded, label: 'Total Earnings', value: 'Rs. ${rider.totalEarnings.toInt()}'),
          ],
        );
      },
    );
  }
}

class _RiderRegistrationView extends ConsumerStatefulWidget {
  final String userId;
  const _RiderRegistrationView({required this.userId});
  @override
  ConsumerState<_RiderRegistrationView> createState() => _RiderRegistrationViewState();
}

class _RiderRegistrationViewState extends ConsumerState<_RiderRegistrationView> {
  final _vehicleNumberCtrl = TextEditingController();
  String _vehicleType = 'motorcycle';

  @override
  Widget build(BuildContext context) {
    final registrationState = ref.watch(riderRegistrationProvider);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      children: [
        const SizedBox(height: AppSpacing.xl),
        const Icon(Icons.delivery_dining_rounded, size: 64, color: AppColors.riderColor),
        const SizedBox(height: AppSpacing.md),
        Text('Complete Rider Profile', style: AppTypography.headingSmall, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xs),
        Text('Register your vehicle to start accepting deliveries',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xl),
        Text('Vehicle Type', style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'motorcycle', label: Text('Motorcycle')),
            ButtonSegment(value: 'bicycle', label: Text('Bicycle')),
            ButtonSegment(value: 'scooter', label: Text('Scooter')),
          ],
          selected: {_vehicleType},
          onSelectionChanged: (s) => setState(() => _vehicleType = s.first),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(controller: _vehicleNumberCtrl,
            decoration: const InputDecoration(labelText: 'Vehicle Number (optional)', hintText: 'e.g. BA 1 CHA 2345')),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: registrationState.isLoading ? null : () async {
              final success = await ref.read(riderRegistrationProvider.notifier).register(
                riderId: widget.userId, vehicleType: _vehicleType,
                vehicleNumber: _vehicleNumberCtrl.text.trim().isEmpty ? null : _vehicleNumberCtrl.text.trim(),
              );
              if (success && context.mounted) {
                ref.invalidate(riderProfileProvider(widget.userId));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Profile submitted! Awaiting admin approval.'),
                  backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))),
            child: registrationState.isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Submit for Approval', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

class _EarningStat extends StatelessWidget {
  final String label; final String value; final IconData icon; final Color color;
  const _EarningStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md), borderRadius: AppSpacing.radiusLg,
      child: Column(children: [
        Icon(icon, color: color, size: 28), const SizedBox(height: AppSpacing.xs),
        Text(value, style: AppTypography.headingSmall.copyWith(color: color), textAlign: TextAlign.center),
        Text(label, style: AppTypography.bodySmall, textAlign: TextAlign.center),
      ]),
    ));
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon; final String label; final String value;
  const _ProfileRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(children: [
        Icon(icon, color: AppColors.primary, size: 20), const SizedBox(width: AppSpacing.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTypography.bodySmall),
          Text(value, style: AppTypography.bodyMedium),
        ])),
      ]),
    );
  }
}

class _ActiveDeliveryCard extends ConsumerWidget {
  final OrderModel order; final String riderId;
  const _ActiveDeliveryCard({required this.order, required this.riderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUpdating = ref.watch(orderStatusNotifierProvider).isLoading;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md), borderRadius: AppSpacing.radiusLg,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.delivery_dining_rounded, color: AppColors.success)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(order.restaurantName, style: AppTypography.headingSmall),
              Text('Order #${order.id.substring(0, 8).toUpperCase()}', style: AppTypography.bodySmall),
            ])),
          ]),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(children: [
              Text('${item.quantity}×  ', style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
              Expanded(child: Text(item.name, style: AppTypography.bodySmall)),
            ]),
          )),
          if (order.deliveryAddress != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Expanded(child: Text(order.deliveryAddress!, style: AppTypography.bodySmall)),
            ]),
          ],
          const SizedBox(height: AppSpacing.sm),
          if (order.status == OrderStatus.pickedUp)
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: isUpdating ? null : () async {
                  final success = await ref.read(orderStatusNotifierProvider.notifier)
                      .updateStatus(order.id, OrderStatus.delivered);
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Failed to update'), backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))),
                child: isUpdating
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Mark as Delivered', style: TextStyle(color: Colors.white)),
              ),
            ),
        ]),
      ),
    );
  }
}

class _AvailableOrderCard extends ConsumerWidget {
  final OrderModel order; final String riderId;
  const _AvailableOrderCard({required this.order, required this.riderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUpdating = ref.watch(orderStatusNotifierProvider).isLoading;
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md), borderRadius: AppSpacing.radiusLg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(order.restaurantName, style: AppTypography.headingSmall),
            Text('Order #${order.id.substring(0, 8).toUpperCase()}', style: AppTypography.bodySmall),
          ])),
          Text('Rs. ${order.totalAmount.toInt()}', style: AppTypography.priceMedium),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Text('${order.items.length} item${order.items.length == 1 ? '' : 's'}', style: AppTypography.bodySmall),
        if (order.deliveryAddress != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textHint),
            const SizedBox(width: 4),
            Expanded(child: Text(order.deliveryAddress!, style: AppTypography.bodySmall,
                maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ],
        const SizedBox(height: AppSpacing.sm),
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: isUpdating ? null : () async {
              final success = await ref.read(orderStatusNotifierProvider.notifier)
                  .assignRider(order.id, riderId);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Failed to accept order'), backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))),
            child: isUpdating
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Accept & Pick Up', style: TextStyle(color: Colors.white)),
          ),
        ),
      ]),
    );
  }
}