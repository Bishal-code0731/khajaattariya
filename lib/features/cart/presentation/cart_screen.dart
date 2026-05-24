import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_card.dart';
import '../application/cart_notifier.dart';
import '../domain/models/cart_item_model.dart';
import '../domain/models/cart_state.dart';
import '../../../core/router/route_names.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../features/orders/application/order_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Cart'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () => ref.read(cartNotifierProvider.notifier).clearCart(),
              child: Text(
                'Clear',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.error),
              ),
            ),
        ],
      ),
      body: cart.isEmpty
          ? _EmptyCart()
          : Column(
        children: [
          // Restaurant info bar
          Container(
            margin: const EdgeInsets.all(AppSpacing.screenHorizontal),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.store_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Ordering from ${cart.restaurantName}',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          // Items list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs),
              itemCount: cart.items.length,
              itemBuilder: (context, index) =>
                  _CartItemTile(item: cart.items[index]),
            ),
          ),
          // Order summary + checkout
          _OrderSummary(cart: cart),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined,
              size: 72, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.md),
          const Text('Your cart is empty',
              style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add items from a restaurant to get started',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: 180,
            child: AppButton(
              label: 'Browse Restaurants',
              onPressed: () => context.go('/home'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final CartItem item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartNotifierProvider.notifier);

    return GlassCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      borderRadius: AppSpacing.radiusLg,
      child: Row(
        children: [
          // Veg/non-veg dot
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: item.food.isVeg ? AppColors.success : AppColors.error,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color:
                  item.food.isVeg ? AppColors.success : AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.food.name,
                  style: AppTypography.headingSmall.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text('Rs. ${item.food.price.toInt()} each',
                    style: AppTypography.bodySmall),
              ],
            ),
          ),
          // Quantity controls
          Row(
            children: [
              _QtyButton(
                icon: Icons.remove_rounded,
                onTap: () => notifier.decrementQuantity(item.food.id),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '${item.quantity}',
                  textAlign: TextAlign.center,
                  style: AppTypography.headingSmall.copyWith(fontSize: 15),
                ),
              ),
              _QtyButton(
                icon: Icons.add_rounded,
                onTap: () => notifier.incrementQuantity(item.food.id),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          // Item total
          SizedBox(
            width: 64,
            child: Text(
              'Rs. ${item.totalPrice.toInt()}',
              textAlign: TextAlign.end,
              style: AppTypography.priceMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }
}

class _OrderSummary extends ConsumerWidget {
  final CartState cart;

  const _OrderSummary({required this.cart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const deliveryFee = 30.0;
    final total = cart.totalAmount + deliveryFee;
    final placeOrderState = ref.watch(placeOrderProvider);
    final isLoading = placeOrderState.isLoading;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          _SummaryRow(
              label: 'Subtotal',
              value: 'Rs. ${cart.totalAmount.toInt()}'),
          const SizedBox(height: AppSpacing.xs),
          _SummaryRow(
              label: 'Delivery fee',
              value: 'Rs. ${deliveryFee.toInt()}'),
          const Divider(height: AppSpacing.lg),
          _SummaryRow(
            label: 'Total',
            value: 'Rs. ${total.toInt()}',
            isTotal: true,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Place Order • Rs. ${total.toInt()}',
            isLoading: isLoading,
            onPressed: () => _placeOrder(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authStateProvider).valueOrNull;

    if (user == null) {
      context.go(RouteNames.login);
      return;
    }

    final order = await ref.read(placeOrderProvider.notifier).placeOrder(
      cart: cart,
      customerId: user.id,
    );

    if (!context.mounted) return;

    if (order != null) {
      ref.read(cartNotifierProvider.notifier).clearCart();
      // Invalidate orders list so it refreshes
      ref.invalidate(customerOrdersProvider(user.id));
      context.go('${RouteNames.orderDetail}/${order.id}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to place order. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = isTotal ? AppTypography.headingSmall : AppTypography.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value,
            style: isTotal
                ? AppTypography.priceMedium
                : AppTypography.bodyMedium),
      ],
    );
  }
}