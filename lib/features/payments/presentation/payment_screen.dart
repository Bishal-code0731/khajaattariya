import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/payment_deeplink_listener.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_logger.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../application/payment_provider.dart';
import '../../../main.dart';

enum PaymentMethod { khalti, stripe, cash }

class PaymentScreen extends ConsumerStatefulWidget {
  /// orderId -> that order's own total. A multi-restaurant checkout
  /// places one order per restaurant but pays for all of them here in
  /// a single step.
  final Map<String, double> orderAmounts;

  const PaymentScreen({super.key, required this.orderAmounts});

  double get amount => orderAmounts.values.fold(0.0, (s, a) => s + a);
  List<String> get orderIds => orderAmounts.keys.toList();

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.khalti;
  // The cash path inserts directly into `payments` instead of going
  // through paymentNotifierProvider, so paymentState.isLoading never
  // flips true for it — without this flag the Pay button stayed
  // enabled for the whole insert and a double-tap could place two
  // payment rows for the same order.
  bool _isProcessingCash = false;
  // True while we've sent the user to Khalti's browser checkout and are
  // waiting for either the deep-link callback or a manual pidx entry.
  bool _isWaitingForKhalti = false;

  @override
  void initState() {
    super.initState();
    // Picks up the khajaattariya://payment/khalti-callback redirect once
    // the user finishes (or cancels) checkout in the external browser,
    // so verification happens automatically instead of requiring the
    // user to copy/paste a pidx by hand.
    ref.read(paymentDeepLinkListenerProvider).start(_onKhaltiDeepLink);
  }

  void _onKhaltiDeepLink(String pidx) {
    if (!mounted) return;
    AppLogger.info('payment', 'khalti deep link received, verifying pidx=$pidx');
    _verifyKhalti(pidx);
  }

  @override
  void dispose() {
    ref.read(paymentDeepLinkListenerProvider).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final paymentState = ref.watch(paymentNotifierProvider);
    final settingsAsync = ref.watch(platformSettingsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          // Order total
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            borderRadius: AppSpacing.radiusLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order Total', style: AppTypography.headingSmall),
                    Text(
                      'Rs. ${widget.amount.toInt()}',
                      style: AppTypography.priceLarge.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
                if (widget.orderAmounts.length > 1) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${widget.orderAmounts.length} orders from different restaurants, paid together',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          Text('Select Payment Method', style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.md),

          // Payment method tiles from platform_settings
          settingsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: AppLoader()),
            ),
            error: (_, __) => AppErrorState(
              message: 'Could not load payment options',
              onRetry: () => ref.invalidate(platformSettingsProvider),
            ),
            data: (settings) => Column(
              children: [
                if (settings['khalti_enabled'] == 'true')
                  _PaymentTile(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Khalti',
                    subtitle: 'Pay with Khalti wallet',
                    value: PaymentMethod.khalti,
                    groupValue: _selectedMethod,
                    color: AppColors.khaltiPurple,
                    onChanged: (v) => setState(() => _selectedMethod = v!),
                  ),
                if (settings['stripe_enabled'] == 'true')
                  _PaymentTile(
                    icon: Icons.credit_card_rounded,
                    title: 'Card (Stripe)',
                    subtitle: 'Visa / Mastercard',
                    value: PaymentMethod.stripe,
                    groupValue: _selectedMethod,
                    color: AppColors.stripeIndigo,
                    onChanged: (v) => setState(() => _selectedMethod = v!),
                  ),
                if (settings['cash_enabled'] == 'true')
                  _PaymentTile(
                    icon: Icons.money_rounded,
                    title: 'Cash on Delivery',
                    subtitle: 'Pay when food arrives',
                    value: PaymentMethod.cash,
                    groupValue: _selectedMethod,
                    color: AppColors.success,
                    onChanged: (v) => setState(() => _selectedMethod = v!),
                  ),
              ],
            ),
          ),

          // Sandbox info box
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.info, size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  Text('Test Mode',
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.info)),
                ]),
                const SizedBox(height: AppSpacing.xs),
                if (_selectedMethod == PaymentMethod.khalti)
                  Text(
                    'Khalti test credentials:\nMobile: 9800000000\nMPIN: 1111\nOTP: 987654',
                    style: AppTypography.bodySmall,
                  ),
                if (_selectedMethod == PaymentMethod.stripe)
                  Text(
                    'Stripe test card (enter in the real payment sheet):\n4242 4242 4242 4242\nAny future expiry · any CVC · any ZIP',
                    style: AppTypography.bodySmall,
                  ),
                if (_selectedMethod == PaymentMethod.cash)
                  Text(
                    'Pay cash when your order arrives at your door.',
                    style: AppTypography.bodySmall,
                  ),
              ],
            ),
          ),

          if (_isWaitingForKhalti) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.info),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text('Waiting for you to finish payment in Khalti…',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.info)),
                    ),
                  ]),
                  TextButton(
                    onPressed: _showKhaltiManualEntry,
                    child: const Text("Weren't redirected back automatically? Tap here"),
                  ),
                ],
              ),
            ),
          ],

          // Error
          if (paymentState.error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(paymentState.error!,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.error)),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Pay button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (paymentState.isLoading || _isProcessingCash || user == null)
                  ? null
                  : () => _pay(user.id, user.email),
              style: ElevatedButton.styleFrom(
                backgroundColor: _buttonColor,
                padding:
                const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd)),
              ),
              child: (paymentState.isLoading || _isProcessingCash)
                  ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : Text(
                _buttonLabel,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color get _buttonColor {
    switch (_selectedMethod) {
      case PaymentMethod.khalti: return AppColors.khaltiPurple;
      case PaymentMethod.stripe: return AppColors.stripeIndigo;
      case PaymentMethod.cash:   return AppColors.success;
    }
  }

  String get _buttonLabel {
    switch (_selectedMethod) {
      case PaymentMethod.khalti: return 'Pay with Khalti';
      case PaymentMethod.stripe: return 'Pay with Card';
      case PaymentMethod.cash:   return 'Place Order (Cash)';
    }
  }

  Future<void> _pay(String userId, String email) async {
    switch (_selectedMethod) {
      case PaymentMethod.khalti:
        await _payKhalti(userId);
        break;
      case PaymentMethod.stripe:
        await _payStripe(userId, email);
        break;
      case PaymentMethod.cash:
        await _payCash(userId);
        break;
    }
  }

  Future<void> _payKhalti(String userId) async {
    final url = await ref
        .read(paymentNotifierProvider.notifier)
        .initiateKhaltiPayment(
      orderAmounts: widget.orderAmounts,
      customerId: userId,
    );

    if (url != null && mounted) {
      final uri = Uri.parse(url);
      final canLaunch = await canLaunchUrl(uri);
      if (!mounted) return;
      if (canLaunch) {
        setState(() => _isWaitingForKhalti = true);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // Verification now happens automatically via
        // PaymentDeepLinkListener when Khalti redirects back to
        // khajaattariya://payment/khalti-callback. _showKhaltiManualEntry
        // below stays available as a fallback for that redirect.
      } else {
        AppSnackbar.error(context, 'Could not open Khalti checkout page');
      }
    }
  }

  Future<void> _verifyKhalti(String pidx) async {
    if (pidx.isEmpty) return;
    final ok = await ref
        .read(paymentNotifierProvider.notifier)
        .verifyKhaltiPayment(pidx: pidx, orderIds: widget.orderIds);
    if (!mounted) return;
    setState(() => _isWaitingForKhalti = false);
    if (ok) {
      ref.read(paymentNotifierProvider.notifier).reset();
      context.go(RouteNames.orders);
      AppSnackbar.success(context, 'Khalti payment verified! Order confirmed.');
    } else {
      AppSnackbar.error(context, 'Could not verify Khalti payment yet — try again once the payment has gone through.');
    }
  }

  Future<void> _payStripe(String userId, String email) async {
    if (Stripe.publishableKey.isEmpty) {
      AppSnackbar.error(
        context,
        'Stripe is not configured — set STRIPE_PUBLISHABLE_KEY in .env.',
      );
      return;
    }

    final clientSecret = await ref
        .read(paymentNotifierProvider.notifier)
        .initiateStripePayment(
      orderAmounts: widget.orderAmounts,
      customerId: userId,
      customerEmail: email,
    );

    if (clientSecret == null || !mounted) return;

    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Khaja Attariya',
          billingDetails: BillingDetails(email: email),
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      // presentPaymentSheet completing without throwing means Stripe
      // itself already confirmed the charge — this call just records
      // that outcome in our own `payments`/`orders` tables.
      final paymentIntentId = clientSecret.split('_secret_')[0];
      final ok = await ref
          .read(paymentNotifierProvider.notifier)
          .confirmStripePayment(paymentIntentId: paymentIntentId, orderIds: widget.orderIds);
      if (ok && mounted) {
        ref.read(paymentNotifierProvider.notifier).reset();
        context.go(RouteNames.orders);
        AppSnackbar.success(context, 'Card payment confirmed! Order placed.');
      }
    } on StripeException catch (e) {
      // Includes the user simply cancelling the sheet — not a real error.
      if (mounted && e.error.code != FailureCode.Canceled) {
        AppSnackbar.error(context, e.error.localizedMessage ?? 'Card payment failed');
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Could not complete card payment: $e');
    }
  }

  Future<void> _payCash(String userId) async {
    if (_isProcessingCash) return;
    setState(() => _isProcessingCash = true);
    try {
      // Skip orders that already have a payments row — otherwise a retry
      // after a partial failure (order 2 of 3 threw last time) would
      // re-insert a duplicate row for order 1, which already succeeded.
      final existing = await supabase
          .from('payments')
          .select('order_id')
          .inFilter('order_id', widget.orderAmounts.keys.toList());
      final alreadyPaid = existing.map((p) => p['order_id'] as String).toSet();

      // One row per order — same reasoning as the gateway paths: a
      // multi-restaurant checkout places multiple orders, and
      // payments.order_id can only ever point at one of them.
      for (final entry in widget.orderAmounts.entries) {
        if (alreadyPaid.contains(entry.key)) continue;
        await supabase.from('payments').insert({
          'order_id': entry.key,
          'customer_id': userId,
          'method': 'cash',
          'status': 'pending',
          'amount': entry.value,
          'currency': 'NPR',
        });
      }
      if (!mounted) return;
      ref.read(paymentNotifierProvider.notifier).reset();
      context.go(RouteNames.orders);
      AppSnackbar.success(context, 'Order placed! Pay on delivery.');
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Could not place cash order: $e');
    } finally {
      if (mounted) setState(() => _isProcessingCash = false);
    }
  }

  /// Fallback for when the khajaattariya://payment/khalti-callback
  /// redirect doesn't fire (e.g. an emulator without the scheme
  /// registered, or the user switching apps in a way that drops the
  /// link) — lets them paste the pidx from Khalti's return URL by hand.
  void _showKhaltiManualEntry() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Khalti Reference'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            "If you weren't redirected back automatically, paste the pidx from the Khalti return URL.",
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: ctrl,
            decoration: const InputDecoration(
                labelText: 'pidx', hintText: 'Paste pidx here'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.khaltiPurple),
            onPressed: () {
              Navigator.pop(ctx);
              _verifyKhalti(ctrl.text.trim());
            },
            child: const Text('Verify', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────

class _PaymentTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final PaymentMethod value, groupValue;
  final Color color;
  final ValueChanged<PaymentMethod?> onChanged;

  const _PaymentTile({
    required this.icon, required this.title, required this.subtitle,
    required this.value, required this.groupValue,
    required this.color, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.08)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 2 : 1),
        ),
        child: Row(children: [
          Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius:
                  BorderRadius.circular(AppSpacing.radiusSm)),
              child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMedium),
                Text(subtitle, style: AppTypography.bodySmall),
              ])),
          Radio<PaymentMethod>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: color),
        ]),
      ),
    );
  }
}

