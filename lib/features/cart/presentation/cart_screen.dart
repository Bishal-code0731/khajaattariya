import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/s.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../address/application/address_provider.dart';
import '../../address/domain/models/address_model.dart';
import '../../auth/application/auth_provider.dart';
import '../../orders/application/order_provider.dart';
import '../../payments/application/coupon_provider.dart';
import '../../payments/domain/models/coupon_model.dart';
import '../application/cart_notifier.dart';
import '../domain/delivery_fee_estimate.dart';
import 'widgets/bill_details_card.dart';
import 'widgets/cart_group_card.dart';
import 'widgets/coupon_card.dart';
import 'widgets/delivery_address_card.dart';
import '../../../shared/widgets/busy_overlay.dart';

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

  /// Saved address the user picked; null = default (first) saved address.
  String? _pickedAddressId;

  /// The user chose "Type a different address".
  bool _typeOwnAddress = false;
  bool _submitting = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    _addressCtrl.dispose();
    _couponCtrl.dispose();
    super.dispose();
  }

  List<AddressModel> _savedAddresses(String? userId) => userId == null
      ? const []
      : (ref.watch(addressListProvider(userId)).valueOrNull ?? const []);

  AddressModel? _selectedAddress(List<AddressModel> saved) {
    if (_typeOwnAddress || saved.isEmpty) return null;
    for (final a in saved) {
      if (a.id == _pickedAddressId) return a;
    }
    return saved.first; // list is ordered default-first
  }

  Future<void> _confirmClear() async {
    final s = context.s.customer;
    final ok = await AppDialog.confirm(
      context,
      title: s.clearCartTitle,
      message: s.clearCartBody,
      confirmLabel: s.clearCart,
      destructive: true,
      icon: Icons.remove_shopping_cart_outlined,
    );
    if (!ok || !mounted) return;
    ref.read(cartNotifierProvider.notifier).clearCart();
    ref.read(couponValidationProvider.notifier).clear();
  }

  Future<void> _applyCoupon(double subtotal) async {
    final s = context.s.customer;
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) {
      AppSnackbar.warning(context, s.couponEnterCode);
      return;
    }
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      context.push(RouteNames.login);
      return;
    }
    FocusScope.of(context).unfocus();
    await ref
        .read(couponValidationProvider.notifier)
        .validateCoupon(code: code, orderTotal: subtotal, customerId: user.id);
  }

  void _removeCoupon() {
    ref.read(couponValidationProvider.notifier).clear();
    _couponCtrl.clear();
    AppSnackbar.info(context, context.s.customer.couponRemoved);
  }

  Future<void> _checkout(double discount, CouponModel? coupon) async {
    if (_submitting) return;
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      context.push(RouteNames.login);
      return;
    }

    // Resolve the delivery address: a saved one (validated too) or typed.
    final selected = _selectedAddress(
        ref.read(addressListProvider(user.id)).valueOrNull ?? const []);
    String address;
    if (selected != null) {
      address = DeliveryAddressCard.addressText(context, selected);
      if (context.validators.address(address) != null) {
        // Saved address is unusable — let the user fix it as text.
        setState(() {
          _typeOwnAddress = true;
          _addressCtrl.text = address;
        });
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _formKey.currentState?.validate());
        return;
      }
    } else {
      address = _addressCtrl.text.trim();
    }
    // Validates the typed address (when shown) and the note.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      final cart = ref.read(cartNotifierProvider);
      final orders = await ref.read(placeOrderProvider.notifier).placeOrder(
            cart: cart,
            customerId: user.id,
            deliveryAddress: address,
            notes:
                _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );
      if (!mounted) return;
      if (orders == null || orders.isEmpty) {
        final err = ref.read(placeOrderProvider).error;
        AppSnackbar.error(context, err);
        return;
      }

      // Server-computed totals.
      final rawTotal = orders.fold<double>(0, (s, o) => s + o.totalAmount);
      final discountPerOrder = <String, double>{
        for (final o in orders)
          o.id: discount > 0 && rawTotal > 0
              ? discount * o.totalAmount / rawTotal
              : 0,
      };
      final orderAmounts = <String, double>{
        for (final o in orders)
          o.id: o.totalAmount - (discountPerOrder[o.id] ?? 0),
      };

      if (coupon != null) {
        try {
          await ref
              .read(couponValidationProvider.notifier)
              .recordUsageForOrders(
                couponId: coupon.id,
                customerId: user.id,
                discountPerOrder: discountPerOrder,
              );
        } catch (e, st) {
          AppLogger.error('cart.recordUsage', e, st);
        }
      }

      if (!mounted) return;
      final finalTotal = orderAmounts.values.fold<double>(0, (a, b) => a + b);
      ref.read(cartNotifierProvider.notifier).clearCart();
      ref.read(couponValidationProvider.notifier).clear();
      AppSnackbar.success(
          context,
          context.s.customer
              .orderPlaced(AppFormat.money(context, finalTotal.round())));
      context.push(RouteNames.payment, extra: {'orderAmounts': orderAmounts});
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      BusyOverlay(busy: _submitting, child: _buildBusyContent(context));

  Widget _buildBusyContent(BuildContext context) {
    final p = context.palette;
    final s = context.s.customer;
    final cart = ref.watch(cartNotifierProvider);
    final authAsync = ref.watch(authStateProvider);
    final user = authAsync.valueOrNull;
    final placing = ref.watch(placeOrderProvider).isLoading || _submitting;
    final couponState = ref.watch(couponValidationProvider);
    final appliedCoupon = couponState.valueOrNull;

    final subtotal = cart.totalAmount;
    final discount = appliedCoupon?.calculateDiscount(subtotal) ?? 0;
    final bill = BillDetailsCard(
      subtotal: subtotal.round(),
      deliveryFee: (cart.groups.length * kEstimatedDeliveryFeePerOrder).round(),
      discount: discount.round(),
      orderCount: cart.groups.length,
    );

    Widget body;
    Widget? bottom;
    if (cart.isEmpty) {
      body = AppEmptyState(
        icon: Icons.shopping_bag_outlined,
        title: s.emptyCartTitle,
        subtitle: s.emptyCartBody,
        action: AppButton(
          label: s.backToHome,
          expand: false,
          leadingIcon: Icons.storefront_outlined,
          onPressed: () => context.go(RouteNames.home),
        ),
      );
    } else if (user == null && !authAsync.isLoading) {
      body = AppEmptyState(
        icon: Icons.lock_outline_rounded,
        title: s.loginToOrderTitle,
        subtitle: s.loginToOrderBody,
        action: AppButton(
          label: context.s.common.login,
          expand: false,
          onPressed: () => context.push(RouteNames.login),
        ),
      );
    } else {
      final saved = _savedAddresses(user?.id);
      final selected = _selectedAddress(saved);
      body = Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
              AppSpacing.md, AppSpacing.screenHorizontal, AppSpacing.xxl),
          children: [
            if (cart.groups.length > 1) ...[
              AppCard(
                color: p.infoSoft,
                borderColor: p.info.withValues(alpha: 0.3),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: p.info),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                        child: Text(s.multiRestaurantNote(cart.groups.length),
                            style: context.text.body)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            for (final group in cart.groups) ...[
              CartGroupCard(key: ValueKey(group.restaurantId), group: group),
              const SizedBox(height: AppSpacing.md),
            ],
            DeliveryAddressCard(
              userId: user?.id,
              controller: _addressCtrl,
              selectedId: selected?.id,
              onSelect: (a) => setState(() {
                _typeOwnAddress = a == null;
                _pickedAddressId = a?.id;
              }),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: AppTextField(
                label: s.notesLabel,
                hint: s.notesHint,
                controller: _notesCtrl,
                prefixIcon: Icons.sticky_note_2_outlined,
                maxLines: 3,
                minLines: 1,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                validator: context.validators
                    .text(s.notesField, max: 200, optional: true),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            CouponCard(
              controller: _couponCtrl,
              applied: appliedCoupon,
              estimatedDiscount: discount,
              isLoading: couponState.isLoading,
              error: couponState.hasError ? couponState.error : null,
              onApply: () => _applyCoupon(subtotal),
              onRemove: _removeCoupon,
            ),
            const SizedBox(height: AppSpacing.md),
            bill,
          ],
        ),
      );
      bottom = DecoratedBox(
        decoration: BoxDecoration(
            color: p.surface, border: Border(top: BorderSide(color: p.border))),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
                AppSpacing.md, AppSpacing.screenHorizontal, AppSpacing.md),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: AppButton(
                  label: s.placeOrder(AppFormat.money(context, bill.total)),
                  isLoading: placing,
                  onPressed:
                      placing ? null : () => _checkout(discount, appliedCoupon),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppTopBar(
        title: s.cartTitle,
        subtitle: cart.isEmpty ? null : s.itemsCount(cart.totalItems),
        actions: [
          if (!cart.isEmpty)
            IconButton(
              tooltip: s.clearCart,
              icon: Icon(Icons.delete_sweep_outlined, color: p.error),
              onPressed: placing ? null : _confirmClear,
            ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: body),
            ),
          ),
        ],
      ),
      bottomNavigationBar: bottom,
    );
  }
}
