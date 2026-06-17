import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../features/rider/application/rider_provider.dart';
import '../../../features/rider/domain/models/rider_model.dart';
import '../../../features/payments/application/coupon_provider.dart';
import '../../../features/payments/domain/models/coupon_model.dart';
import '../../../main.dart';
import '../../../shared/widgets/glass_card.dart';

final _allUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await supabase.from('profiles').select().order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(data);
});

final _allOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await supabase.from('orders')
      .select('*, restaurants(name), profiles!customer_id(full_name)')
      .order('created_at', ascending: false).limit(50);
  return List<Map<String, dynamic>>.from(data);
});

final _allRestaurantsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await supabase.from('restaurants')
      .select('*, profiles!owner_id(full_name)').order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(data);
});

final _analyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final orders = await supabase.from('orders').select('total_amount, status, created_at');
  final total     = (orders as List).length;
  final delivered = orders.where((o) => o['status'] == 'delivered').length;
  final revenue   = orders.where((o) => o['status'] == 'delivered')
      .fold<double>(0, (s, o) => s + (o['total_amount'] as num).toDouble());
  return {'total_orders': total, 'delivered_orders': delivered, 'total_revenue': revenue};
});

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() { super.initState(); _tabController = TabController(length: 6, vsync: this); }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [IconButton(icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut())],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary, unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary, dividerColor: AppColors.border,
          isScrollable: true, tabAlignment: TabAlignment.start,
          tabs: const [Tab(text: 'Analytics'), Tab(text: 'Users'), Tab(text: 'Restaurants'),
            Tab(text: 'Riders'), Tab(text: 'Orders'), Tab(text: 'Coupons')],
        ),
      ),
      body: TabBarView(controller: _tabController, children: [
        _AnalyticsTab(), _UsersTab(), _RestaurantsTab(), _RidersTab(), _OrdersTab(), _CouponsTab(),
      ]),
    );
  }
}

class _AnalyticsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_analyticsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const Center(child: Text('Could not load analytics')),
      data: (data) => ListView(padding: const EdgeInsets.all(AppSpacing.screenHorizontal), children: [
        const SizedBox(height: AppSpacing.md),
        Text('Platform Overview', style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          _ACard(label: 'Total Orders', value: '${data['total_orders']}',
              icon: Icons.receipt_long_rounded, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          _ACard(label: 'Delivered', value: '${data['delivered_orders']}',
              icon: Icons.check_circle_rounded, color: AppColors.success),
        ]),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(padding: const EdgeInsets.all(AppSpacing.md), borderRadius: AppSpacing.radiusLg,
          child: Row(children: [
            Container(width: 48, height: 48,
                decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.accent, size: 24)),
            const SizedBox(width: AppSpacing.md),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total Revenue', style: AppTypography.bodySmall),
              Text('Rs. ${(data['total_revenue'] as double).toInt()}',
                  style: AppTypography.headingSmall.copyWith(color: AppColors.accent)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _UsersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(_allUsersProvider);
    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Could not load users', style: AppTypography.bodyMedium),
        TextButton(onPressed: () => ref.invalidate(_allUsersProvider), child: const Text('Retry')),
      ])),
      data: (users) {
        final customers   = users.where((u) => u['role'] == 'customer').length;
        final restaurants = users.where((u) => u['role'] == 'restaurant').length;
        final riders      = users.where((u) => u['role'] == 'rider').length;
        return CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Row(children: [
              _Mini(label: 'Customers', value: '$customers', color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              _Mini(label: 'Restaurants', value: '$restaurants', color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              _Mini(label: 'Riders', value: '$riders', color: AppColors.riderColor),
            ]),
          )),
          SliverList(delegate: SliverChildBuilderDelegate(
                (context, index) {
              final user     = users[index];
              final isActive = user['is_active'] as bool? ?? true;
              return GlassCard(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.xs),
                padding: const EdgeInsets.all(AppSpacing.md), borderRadius: AppSpacing.radiusLg,
                child: Row(children: [
                  CircleAvatar(radius: 20, backgroundColor: AppColors.primary.withOpacity(0.15),
                      child: Text((user['full_name'] as String? ?? '?').isNotEmpty
                          ? (user['full_name'] as String)[0].toUpperCase() : '?',
                          style: AppTypography.labelMedium.copyWith(color: AppColors.primary))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user['full_name'] as String? ?? 'Unknown', style: AppTypography.bodyMedium,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(user['phone'] as String? ?? 'No phone', style: AppTypography.bodySmall),
                  ])),
                  _RoleBadge(role: user['role'] as String? ?? ''),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                      icon: Icon(isActive ? Icons.block_rounded : Icons.check_circle_rounded,
                          size: 18, color: isActive ? AppColors.error : AppColors.success),
                      onPressed: () async {
                        await supabase.from('profiles').update({'is_active': !isActive}).eq('id', user['id'] as String);
                        ref.invalidate(_allUsersProvider);
                      }),
                ]),
              );
            },
            childCount: users.length,
          )),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        ]);
      },
    );
  }
}

class _RestaurantsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_allRestaurantsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Could not load restaurants', style: AppTypography.bodyMedium),
        TextButton(onPressed: () => ref.invalidate(_allRestaurantsProvider), child: const Text('Retry')),
      ])),
      data: (restaurants) => ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: restaurants.length,
        itemBuilder: (context, index) {
          final r          = restaurants[index];
          final owner      = r['profiles'] as Map<String, dynamic>? ?? {};
          final isApproved = r['is_approved'] as bool? ?? false;
          final isActive   = r['is_active'] as bool? ?? true;
          return GlassCard(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.xs),
            padding: const EdgeInsets.all(AppSpacing.md), borderRadius: AppSpacing.radiusLg,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 48, height: 48,
                    decoration: BoxDecoration(color: AppColors.border,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                    child: const Icon(Icons.restaurant_rounded, color: AppColors.textHint, size: 24)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r['name'] as String? ?? 'Unknown', style: AppTypography.bodyMedium),
                  Text('Owner: ${owner['full_name'] ?? 'Unknown'}', style: AppTypography.bodySmall),
                ])),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                    decoration: BoxDecoration(
                        color: isApproved ? AppColors.successLight : AppColors.warningLight,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                    child: Text(isApproved ? 'Approved' : 'Pending',
                        style: AppTypography.labelSmall.copyWith(
                            color: isApproved ? AppColors.success : AppColors.warning))),
              ]),
              const SizedBox(height: AppSpacing.sm),
              Row(children: [
                if (!isApproved) Expanded(child: OutlinedButton(
                    onPressed: () async {
                      await supabase.from('restaurants').update({'is_approved': true}).eq('id', r['id'] as String);
                      ref.invalidate(_allRestaurantsProvider);
                    },
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.success)),
                    child: const Text('Approve', style: TextStyle(color: AppColors.success)))),
                if (!isApproved) const SizedBox(width: AppSpacing.sm),
                Expanded(child: OutlinedButton(
                    onPressed: () async {
                      await supabase.from('restaurants').update({'is_active': !isActive}).eq('id', r['id'] as String);
                      ref.invalidate(_allRestaurantsProvider);
                    },
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isActive ? AppColors.error : AppColors.success)),
                    child: Text(isActive ? 'Deactivate' : 'Activate',
                        style: TextStyle(color: isActive ? AppColors.error : AppColors.success)))),
              ]),
            ]),
          );
        },
      ),
    );
  }
}

class _RidersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridersAsync  = ref.watch(allRidersProvider);
    final approvalState = ref.watch(riderApprovalNotifierProvider);
    return ridersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const Center(child: Text('Could not load riders')),
      data: (riders) {
        if (riders.isEmpty) return const Center(child: Text('No riders registered'));
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: riders.length,
          itemBuilder: (context, index) {
            final rider = riders[index];
            return GlassCard(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.xs),
              padding: const EdgeInsets.all(AppSpacing.md), borderRadius: AppSpacing.radiusLg,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(radius: 20, backgroundColor: AppColors.riderColor.withOpacity(0.15),
                      child: Text(rider.fullName.isNotEmpty ? rider.fullName[0].toUpperCase() : 'R',
                          style: AppTypography.labelMedium.copyWith(color: AppColors.riderColor))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(rider.fullName, style: AppTypography.bodyMedium),
                    Text('${rider.vehicleType.toUpperCase()} · ${rider.totalDeliveries} deliveries',
                        style: AppTypography.bodySmall),
                  ])),
                  Container(width: 10, height: 10,
                      decoration: BoxDecoration(
                          color: rider.isOnline ? AppColors.success : AppColors.textHint,
                          shape: BoxShape.circle)),
                ]),
                if (!rider.isApproved) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(children: [
                    Expanded(child: ElevatedButton(
                        onPressed: approvalState.isLoading ? null : () async {
                          final ok = await ref.read(riderApprovalNotifierProvider.notifier).approveRider(rider.id);
                          if (ok) ref.invalidate(allRidersProvider);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs)),
                        child: const Text('Approve', style: TextStyle(color: Colors.white)))),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: OutlinedButton(
                        onPressed: () => _showRejectDialog(context, ref, rider),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs)),
                        child: const Text('Reject', style: TextStyle(color: AppColors.error)))),
                  ]),
                ] else Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Row(children: [
                    const Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text('Approved Rider', style: AppTypography.labelSmall.copyWith(color: AppColors.success)),
                    const Spacer(),
                    Text('Rs. ${rider.totalEarnings.toInt()} earned', style: AppTypography.bodySmall),
                  ]),
                ),
              ]),
            );
          },
        );
      },
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref, RiderModel rider) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Reject Rider'),
      content: TextField(controller: ctrl,
          decoration: const InputDecoration(hintText: 'Reason (optional)', labelText: 'Note')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
            onPressed: () async {
              await ref.read(riderApprovalNotifierProvider.notifier).rejectRider(rider.id, ctrl.text.trim());
              ref.invalidate(allRidersProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject', style: TextStyle(color: Colors.white))),
      ],
    ));
  }
}

class _OrdersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_allOrdersProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const Center(child: Text('Could not load orders')),
      data: (orders) {
        if (orders.isEmpty) return const Center(child: Text('No orders yet'));
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final o          = orders[index];
            final restaurant = o['restaurants'] as Map<String, dynamic>? ?? {};
            final customer   = o['profiles'] as Map<String, dynamic>? ?? {};
            final status     = o['status'] as String? ?? 'pending';
            return GlassCard(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.xs),
              padding: const EdgeInsets.all(AppSpacing.md), borderRadius: AppSpacing.radiusLg,
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(restaurant['name'] as String? ?? 'Unknown', style: AppTypography.bodyMedium,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('By: ${customer['full_name'] ?? 'Unknown'}', style: AppTypography.bodySmall),
                  Text('Rs. ${(o['total_amount'] as num?)?.toInt() ?? 0}',
                      style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
                ])),
                _OStatusBadge(status: status),
              ]),
            );
          },
        );
      },
    );
  }
}

class _CouponsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allCouponsProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreate(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Coupon', style: TextStyle(color: Colors.white)),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => const Center(child: Text('Could not load coupons')),
        data: (coupons) {
          if (coupons.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.discount_outlined, size: 56, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.md),
            Text('No coupons created yet', style: AppTypography.bodyMedium),
          ]));
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final c = coupons[index];
              return GlassCard(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.xs),
                padding: const EdgeInsets.all(AppSpacing.md), borderRadius: AppSpacing.radiusLg,
                child: Row(children: [
                  Container(padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                      child: const Icon(Icons.discount_rounded, color: AppColors.accent, size: 20)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.code, style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
                    Text(c.discountType == 'percent'
                        ? '${c.discountValue.toInt()}% off' : 'Rs. ${c.discountValue.toInt()} off',
                        style: AppTypography.bodyMedium),
                    Text('Used: ${c.usesCount}${c.maxUses != null ? '/${c.maxUses}' : ''} · Min: Rs. ${c.minOrderAmount.toInt()}',
                        style: AppTypography.bodySmall),
                  ])),
                  Switch(
                      value: c.isActive,
                      onChanged: (v) async {
                        await ref.read(createCouponProvider.notifier).toggleActive(c.id, v);
                        ref.invalidate(allCouponsProvider);
                      },
                      activeColor: AppColors.success),
                ]),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreate(BuildContext context, WidgetRef ref) {
    final codeCtrl  = TextEditingController();
    final valueCtrl = TextEditingController();
    final minCtrl   = TextEditingController(text: '0');
    String type     = 'percent';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Create Coupon'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: codeCtrl,
              decoration: const InputDecoration(labelText: 'Code'), textCapitalization: TextCapitalization.characters),
          const SizedBox(height: 8),
          SegmentedButton<String>(
              segments: const [ButtonSegment(value: 'percent', label: Text('Percent')),
                ButtonSegment(value: 'fixed', label: Text('Fixed'))],
              selected: {type}, onSelectionChanged: (s) => setState(() => type = s.first)),
          const SizedBox(height: 8),
          TextField(controller: valueCtrl, keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: type == 'percent' ? 'Discount %' : 'Amount (Rs.)')),
          const SizedBox(height: 8),
          TextField(controller: minCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Min Order (Rs.)')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () async {
                final ok = await ref.read(createCouponProvider.notifier).create(
                    code: codeCtrl.text, discountType: type,
                    discountValue: double.tryParse(valueCtrl.text) ?? 0,
                    minOrderAmount: double.tryParse(minCtrl.text) ?? 0);
                if (ok) { ref.invalidate(allCouponsProvider); if (ctx.mounted) Navigator.pop(ctx); }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Create', style: TextStyle(color: Colors.white))),
        ],
      ),
    ));
  }
}

// ── Shared helper widgets ──────────────────────────────────

class _ACard extends StatelessWidget {
  final String label; final String value; final IconData icon; final Color color;
  const _ACard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: GlassCard(padding: const EdgeInsets.all(AppSpacing.md), borderRadius: AppSpacing.radiusLg,
        child: Column(children: [
          Icon(icon, color: color, size: 28), const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTypography.headingSmall.copyWith(color: color)),
          Text(label, style: AppTypography.bodySmall),
        ])));
  }
}

class _Mini extends StatelessWidget {
  final String label; final String value; final Color color;
  const _Mini({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: GlassCard(padding: const EdgeInsets.all(AppSpacing.sm), borderRadius: AppSpacing.radiusMd,
        child: Column(children: [
          Text(value, style: AppTypography.headingSmall.copyWith(color: color)),
          Text(label, style: AppTypography.bodySmall),
        ])));
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  Color get _color {
    switch (role) {
      case 'restaurant': return AppColors.restaurantColor;
      case 'rider':      return AppColors.riderColor;
      case 'admin':      return AppColors.adminColor;
      default:           return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
        decoration: BoxDecoration(color: _color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: _color.withOpacity(0.3))),
        child: Text(role.toUpperCase(), style: AppTypography.labelSmall.copyWith(color: _color)));
  }
}

class _OStatusBadge extends StatelessWidget {
  final String status;
  const _OStatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case 'pending':   return AppColors.accent;
      case 'confirmed': case 'preparing': return AppColors.primary;
      case 'ready': case 'picked_up': case 'delivered': return AppColors.success;
      case 'cancelled': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
        decoration: BoxDecoration(color: _color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: _color.withOpacity(0.3))),
        child: Text(status.replaceAll('_', ' ').toUpperCase(),
            style: AppTypography.labelSmall.copyWith(color: _color)));
  }
}