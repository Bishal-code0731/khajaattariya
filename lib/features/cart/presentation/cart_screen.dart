import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../application/cart_notifier.dart';
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
  final _notesCtrl    = TextEditingController();
  final _addressCtrl  = TextEditingController();
  final _couponCtrl   = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose(); _addressCtrl.dispose(); _couponCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart          = ref.watch(cartNotifierProvider);
    final placeState    = ref.watch(placeOrderProvider);
    final couponState   = ref.watch(couponValidationProvider);
    final appliedCoupon = couponState.valueOrNull;

    final double subtotal    = cart.totalAmount;
    final double deliveryFee = 50;
    final double discount    = appliedCoupon?.calculateDiscount(subtotal) ?? 0;
    final double total       = subtotal + deliveryFee - discount;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Cart'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () {
                ref.read(cartNotifierProvider.notifier).clearCart();
                ref.read(couponValidationProvider.notifier).clear();
              },
              child: Text('Clear', style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
            ),
        ],
      ),
      body: cart.isEmpty ? _EmptyCart() : Column(children: [
        Container(
          margin: const EdgeInsets.all(AppSpacing.screenHorizontal),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.store_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text('Ordering from ${cart.restaurantName}',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.primary)),
          ]),
        ),
        Expanded(child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          children: [
            ...cart.items.map((item) => _CartItemTile(item: item)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.sm),
              child: TextField(controller: _addressCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Delivery Address', hintText: 'Enter your full address',
                      prefixIcon: Icon(Icons.location_on_outlined))),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.xs),
              child: TextField(controller: _notesCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Notes (optional)', hintText: 'e.g. no onions',
                      prefixIcon: Icon(Icons.note_outlined))),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.sm),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: _couponCtrl, textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Coupon Code', hintText: 'Enter code',
                    prefixIcon: const Icon(Icons.discount_outlined),
                    suffixIcon: appliedCoupon != null
                        ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.error),
                        onPressed: () {
                          ref.read(couponValidationProvider.notifier).clear();
                          _couponCtrl.clear();
                        })
                        : null,
                  ),
                )),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: couponState.isLoading ? null : () async {
                    final user = ref.read(authStateProvider).valueOrNull;
                    if (user == null) return;
                    await ref.read(couponValidationProvider.notifier).validateCoupon(
                        code: _couponCtrl.text, orderTotal: subtotal, customerId: user.id);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm)),
                  child: couponState.isLoading
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Apply', style: TextStyle(color: Colors.white)),
                ),
              ]),
            ),
            if (couponState.hasError)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
                child: Text(couponState.error.toString(),
                    style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
              ),
            if (appliedCoupon != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.xs),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                    const SizedBox(width: AppSpacing.xs),
                    Text('${appliedCoupon.code} applied — Rs. ${discount.toInt()} off',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.success)),
                  ]),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpacing.md), borderRadius: AppSpacing.radiusLg,
                child: Column(children: [
                  _SummaryRow(label: 'Subtotal',    value: 'Rs. ${subtotal.toInt()}'),
                  _SummaryRow(label: 'Delivery Fee', value: 'Rs. ${deliveryFee.toInt()}'),
                  if (discount > 0)
                    _SummaryRow(label: 'Discount', value: '- Rs. ${discount.toInt()}', valueColor: AppColors.success),
                  const Divider(height: AppSpacing.md),
                  _SummaryRow(label: 'Total', value: 'Rs. ${total.toInt()}', bold: true),
                ]),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        )),
        SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal, 0, AppSpacing.screenHorizontal, AppSpacing.md),
          child: SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: placeState.isLoading ? null : () => _checkout(context, total, appliedCoupon),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))),
              child: placeState.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Proceed to Payment · Rs. ${total.toInt()}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        )),
      ]),
    );
  }

  Future<void> _checkout(BuildContext context, double total, CouponModel? coupon) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) { context.push(RouteNames.login); return; }
    final cart = ref.read(cartNotifierProvider);
    final order = await ref.read(placeOrderProvider.notifier).placeOrder(
      cart: cart,
      customerId: user.id,
      deliveryAddress: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    if (order == null || !context.mounted) return;
    if (coupon != null) {
      await ref.read(couponValidationProvider.notifier).recordUsage(
        couponId: coupon.id, customerId: user.id,
        orderId: order.id, discountApplied: coupon.calculateDiscount(cart.totalAmount),
      );
    }
    ref.read(cartNotifierProvider.notifier).clearCart();
    ref.read(couponValidationProvider.notifier).clear();
    context.push(RouteNames.payment, extra: {'orderId': order.id, 'amount': total});
  }
}

class _CartItemTile extends ConsumerWidget {
  final dynamic item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm), borderRadius: AppSpacing.radiusMd,
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.food.name, style: AppTypography.bodyMedium),
          Text('Rs. ${item.food.price.toInt()} each', style: AppTypography.bodySmall),
        ])),
        Row(children: [
          IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded, size: 22, color: AppColors.primary),
              onPressed: () => ref.read(cartNotifierProvider.notifier).decrementQuantity(item.food.id)),
          Text('${item.quantity}', style: AppTypography.labelMedium),
          IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 22, color: AppColors.primary),
              onPressed: () => ref.read(cartNotifierProvider.notifier).incrementQuantity(item.food.id)),
        ]),
        SizedBox(width: 60,
            child: Text('Rs. ${(item.food.price * item.quantity).toInt()}',
                style: AppTypography.labelMedium.copyWith(color: AppColors.primary), textAlign: TextAlign.right)),
      ]),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label; final String value; final bool bold; final Color? valueColor;
  const _SummaryRow({required this.label, required this.value, this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final style = bold ? AppTypography.headingSmall : AppTypography.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: style),
        Text(value, style: style.copyWith(color: valueColor ?? (bold ? AppColors.primary : null))),
      ]),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.shopping_cart_outlined, size: 72, color: AppColors.textHint),
      const SizedBox(height: AppSpacing.md),
      Text('Your cart is empty', style: AppTypography.headingSmall),
      const SizedBox(height: AppSpacing.xs),
      Text('Add items from a restaurant to get started',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
    ]));
  }
}