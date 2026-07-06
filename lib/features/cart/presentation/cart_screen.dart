import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/navigation_extensions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../application/cart_notifier.dart';
import '../domain/models/cart_state.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../features/orders/application/order_provider.dart';
import '../../../features/payments/application/coupon_provider.dart';
import '../../../features/payments/domain/models/coupon_model.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _couponCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    _addressCtrl.dispose();
    _couponCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartNotifierProvider);
    final placeState = ref.watch(placeOrderProvider);
    final couponState = ref.watch(couponValidationProvider);
    final appliedCoupon = couponState.valueOrNull;

    // Delivery fee is per restaurant order (matches how placeOrder
    // charges it server-side) — shown here as a single combined line
    // for a cart with multiple restaurants.
    // Rs. 30 delivery fee per restaurant order (matches what
    // OrderRepositoryImpl actually charges per group server-side).
    final double deliveryFee = cart.groups.length * 30.0;
    final double subtotal = cart.totalAmount;
    final double discount = appliedCoupon?.calculateDiscount(subtotal) ?? 0;
    // Round each line to whole rupees first, then sum the rounded values
    // for the total — summing full-precision doubles and independently
    // truncating each displayed line (the old .toInt() approach) could
    // make "Subtotal + Delivery − Discount" not add up to the displayed
    // Total by a rupee or two.
    final int subtotalDisplay = subtotal.round();
    final int deliveryFeeDisplay = deliveryFee.round();
    final int discountDisplay = discount.round();
    final int totalDisplay = subtotalDisplay + deliveryFeeDisplay - discountDisplay;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Cart'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.safeBack()),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () {
                ref.read(cartNotifierProvider.notifier).clearCart();
                ref.read(couponValidationProvider.notifier).clear();
              },
              child: Text('Clear',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.error)),
            ),
        ],
      ),
      body: Column(children: [
        const OfflineBanner(),
        Expanded(
          child: cart.isEmpty
              ? _EmptyCart()
              : Form(
                  key: _formKey,
                  child: Column(children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        children: [
                          if (cart.groups.length > 1)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.screenHorizontal,
                                  vertical: AppSpacing.xs),
                              child: Row(children: [
                                const Icon(Icons.info_outline_rounded,
                                    size: 14, color: AppColors.info),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Ordering from ${cart.groups.length} restaurants — each becomes its own order, paid together.',
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.info),
                                  ),
                                ),
                              ]),
                            ),
                          for (final group in cart.groups) _RestaurantGroupSection(group: group),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.screenHorizontal,
                                vertical: AppSpacing.sm),
                            child: TextFormField(
                                controller: _addressCtrl,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                validator: Validators.address,
                                decoration: const InputDecoration(
                                    labelText: 'Delivery Address',
                                    hintText: 'Enter your full address',
                                    prefixIcon: Icon(Icons.location_on_outlined))),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.screenHorizontal,
                                vertical: AppSpacing.xs),
                            child: TextField(
                                controller: _notesCtrl,
                                decoration: const InputDecoration(
                                    labelText: 'Notes (optional)',
                                    hintText: 'e.g. no onions',
                                    prefixIcon: Icon(Icons.note_outlined))),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.screenHorizontal,
                                vertical: AppSpacing.sm),
                            child: Row(children: [
                              Expanded(
                                  child: TextField(
                                controller: _couponCtrl,
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  labelText: 'Coupon Code',
                                  hintText: 'Enter code',
                                  prefixIcon: const Icon(Icons.discount_outlined),
                                  suffixIcon: appliedCoupon != null
                                      ? IconButton(
                                          icon: const Icon(Icons.close_rounded,
                                              color: AppColors.error),
                                          onPressed: () {
                                            ref
                                                .read(couponValidationProvider
                                                    .notifier)
                                                .clear();
                                            _couponCtrl.clear();
                                          })
                                      : null,
                                ),
                              )),
                              const SizedBox(width: AppSpacing.sm),
                              ElevatedButton(
                                onPressed: couponState.isLoading
                                    ? null
                                    : () async {
                                        final user =
                                            ref.read(authStateProvider).valueOrNull;
                                        if (user == null) return;
                                        await ref
                                            .read(couponValidationProvider.notifier)
                                            .validateCoupon(
                                                code: _couponCtrl.text,
                                                orderTotal: subtotal,
                                                customerId: user.id);
                                      },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.sm)),
                                child: couponState.isLoading
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.white))
                                    : const Text('Apply',
                                        style: TextStyle(color: Colors.white)),
                              ),
                            ]),
                          ),
                          if (couponState.hasError)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.screenHorizontal),
                              child: Text(couponState.error.toString(),
                                  style: AppTypography.bodySmall
                                      .copyWith(color: AppColors.error)),
                            ),
                          if (appliedCoupon != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.screenHorizontal,
                                  vertical: AppSpacing.xs),
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                    color: AppColors.successLight,
                                    borderRadius:
                                        BorderRadius.circular(AppSpacing.radiusMd)),
                                child: Row(children: [
                                  const Icon(Icons.check_circle_rounded,
                                      color: AppColors.success, size: 16),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                      '${appliedCoupon.code} applied — Rs. $discountDisplay off',
                                      style: AppTypography.bodySmall
                                          .copyWith(color: AppColors.success)),
                                ]),
                              ),
                            ),
                          Padding(
                            padding:
                                const EdgeInsets.all(AppSpacing.screenHorizontal),
                            child: GlassCard(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              borderRadius: AppSpacing.radiusLg,
                              child: Column(children: [
                                _SummaryRow(
                                    label: 'Subtotal',
                                    value: 'Rs. $subtotalDisplay'),
                                _SummaryRow(
                                    label: cart.groups.length > 1
                                        ? 'Delivery Fee (${cart.groups.length} orders)'
                                        : 'Delivery Fee',
                                    value: 'Rs. $deliveryFeeDisplay'),
                                if (discount > 0)
                                  _SummaryRow(
                                      label: 'Discount',
                                      value: '- Rs. $discountDisplay',
                                      valueColor: AppColors.success),
                                const Divider(height: AppSpacing.md),
                                _SummaryRow(
                                    label: 'Total',
                                    value: 'Rs. $totalDisplay',
                                    bold: true),
                              ]),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                    SafeArea(
                        child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenHorizontal,
                          0,
                          AppSpacing.screenHorizontal,
                          AppSpacing.md),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: placeState.isLoading
                              ? null
                              : () => _checkout(context, discount, appliedCoupon),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd))),
                          child: placeState.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text('Proceed to Payment · Rs. $totalDisplay',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                    )),
                  ]),
                ),
        ),
      ]),
    );
  }

  Future<void> _checkout(
      BuildContext context, double discount, CouponModel? coupon) async {
    // Blocks checkout on a missing/too-short address instead of letting
    // an unusable delivery address reach the orders table.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      context.push(RouteNames.login);
      return;
    }
    final cart = ref.read(cartNotifierProvider);
    final orders = await ref.read(placeOrderProvider.notifier).placeOrder(
          cart: cart,
          customerId: user.id,
          deliveryAddress: _addressCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
    if (orders == null || orders.isEmpty || !context.mounted) return;

    // Spread the coupon discount proportionally across each order's own
    // amount so the sum charged still matches the discounted total,
    // while every payment row still points at exactly one real order.
    final rawTotal = orders.fold<double>(0, (s, o) => s + o.totalAmount);
    final discountPerOrder = <String, double>{
      for (final o in orders)
        o.id: discount > 0 && rawTotal > 0 ? discount * o.totalAmount / rawTotal : 0,
    };
    final orderAmounts = <String, double>{
      for (final o in orders) o.id: o.totalAmount - (discountPerOrder[o.id] ?? 0),
    };

    // The orders are already placed at this point — a failure recording
    // coupon usage is a secondary/non-critical write and must not strand
    // the user on the cart screen with no way forward and no error shown.
    if (coupon != null) {
      try {
        await ref.read(couponValidationProvider.notifier).recordUsageForOrders(
              couponId: coupon.id,
              customerId: user.id,
              discountPerOrder: discountPerOrder,
            );
      } catch (e, st) {
        AppLogger.error('cart.recordUsage', e, st);
      }
    }

    if (!context.mounted) return;
    ref.read(cartNotifierProvider.notifier).clearCart();
    ref.read(couponValidationProvider.notifier).clear();

    context.push(RouteNames.payment, extra: {'orderAmounts': orderAmounts});
  }
}

class _RestaurantGroupSection extends StatelessWidget {
  final CartRestaurantGroup group;
  const _RestaurantGroupSection({required this.group});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal, AppSpacing.sm, AppSpacing.screenHorizontal, 0),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.store_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text('Ordering from ${group.restaurantName}',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.primary)),
            ),
            Text('Rs. ${group.subtotal.toInt()}',
                style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
          ]),
        ),
        ...group.items.map((item) => _CartItemTile(restaurantId: group.restaurantId, item: item)),
      ],
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final String restaurantId;
  final dynamic item;
  const _CartItemTile({required this.restaurantId, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      borderRadius: AppSpacing.radiusMd,
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.food.name, style: AppTypography.bodyMedium),
          Text('Rs. ${item.food.price.toInt()} each',
              style: AppTypography.bodySmall),
        ])),
        Row(children: [
          IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded,
                  size: 22, color: AppColors.primary),
              onPressed: () => ref
                  .read(cartNotifierProvider.notifier)
                  .decrementQuantity(restaurantId, item.food.id)),
          Text('${item.quantity}', style: AppTypography.labelMedium),
          IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded,
                  size: 22, color: AppColors.primary),
              onPressed: () => ref
                  .read(cartNotifierProvider.notifier)
                  .incrementQuantity(restaurantId, item.food.id)),
        ]),
        SizedBox(
            width: 60,
            child: Text('Rs. ${(item.food.price * item.quantity).toInt()}',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.primary),
                textAlign: TextAlign.right)),
      ]),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  const _SummaryRow(
      {required this.label,
      required this.value,
      this.bold = false,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    final style = bold ? AppTypography.headingSmall : AppTypography.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: style),
        Text(value,
            style: style.copyWith(
                color: valueColor ?? (bold ? AppColors.primary : null))),
      ]),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.shopping_cart_outlined,
      title: 'Your cart is empty',
      subtitle: 'Add items from a restaurant to get started',
    );
  }
}
