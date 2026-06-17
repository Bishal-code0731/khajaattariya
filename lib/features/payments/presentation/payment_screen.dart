import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../application/payment_provider.dart';
import '../../../main.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String orderId;
  final double amount;

  const PaymentScreen({super.key, required this.orderId, required this.amount});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selectedMethod = 'khalti';

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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order Total', style: AppTypography.headingSmall),
                Text(
                  'Rs. ${widget.amount.toInt()}',
                  style: AppTypography.priceLarge.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          Text('Select Payment Method', style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.md),

          // Payment method tiles from platform_settings
          settingsAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
            error: (_, __) => const SizedBox.shrink(),
            data: (settings) => Column(
              children: [
                if (settings['khalti_enabled'] == 'true')
                  _PaymentTile(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Khalti',
                    subtitle: 'Pay with Khalti wallet',
                    value: 'khalti',
                    groupValue: _selectedMethod,
                    color: const Color(0xFF5C2D91),
                    onChanged: (v) => setState(() => _selectedMethod = v!),
                  ),
                if (settings['stripe_enabled'] == 'true')
                  _PaymentTile(
                    icon: Icons.credit_card_rounded,
                    title: 'Card (Stripe)',
                    subtitle: 'Visa / Mastercard',
                    value: 'stripe',
                    groupValue: _selectedMethod,
                    color: const Color(0xFF635BFF),
                    onChanged: (v) => setState(() => _selectedMethod = v!),
                  ),
                if (settings['cash_enabled'] == 'true')
                  _PaymentTile(
                    icon: Icons.money_rounded,
                    title: 'Cash on Delivery',
                    subtitle: 'Pay when food arrives',
                    value: 'cash',
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
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
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
                if (_selectedMethod == 'khalti')
                  Text(
                    'Khalti test credentials:\nMobile: 9800000000\nMPIN: 1111\nOTP: 987654',
                    style: AppTypography.bodySmall,
                  ),
                if (_selectedMethod == 'stripe')
                  Text(
                    'Stripe test card:\n4242 4242 4242 4242\nExpiry: 12/34  CVV: 123',
                    style: AppTypography.bodySmall,
                  ),
                if (_selectedMethod == 'cash')
                  Text(
                    'Pay cash when your order arrives at your door.',
                    style: AppTypography.bodySmall,
                  ),
              ],
            ),
          ),

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
              onPressed: (paymentState.isLoading || user == null)
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
              child: paymentState.isLoading
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
      case 'khalti': return const Color(0xFF5C2D91);
      case 'stripe': return const Color(0xFF635BFF);
      default:       return AppColors.success;
    }
  }

  String get _buttonLabel {
    switch (_selectedMethod) {
      case 'khalti': return 'Pay with Khalti';
      case 'stripe': return 'Pay with Card';
      default:       return 'Place Order (Cash)';
    }
  }

  Future<void> _pay(String userId, String email) async {
    switch (_selectedMethod) {
      case 'khalti':
        await _payKhalti(userId);
        break;
      case 'stripe':
        await _payStripe(userId, email);
        break;
      case 'cash':
        await _payCash(userId);
        break;
    }
  }

  Future<void> _payKhalti(String userId) async {
    final url = await ref
        .read(paymentNotifierProvider.notifier)
        .initiateKhaltiPayment(
      orderId: widget.orderId,
      customerId: userId,
      amount: widget.amount,
    );

    if (url != null && mounted) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // After returning from Khalti browser show verify dialog
        if (mounted) _showKhaltiVerifyDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not open Khalti: $url'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _payStripe(String userId, String email) async {
    final clientSecret = await ref
        .read(paymentNotifierProvider.notifier)
        .initiateStripePayment(
      orderId: widget.orderId,
      customerId: userId,
      amount: widget.amount,
      customerEmail: email,
    );

    if (clientSecret != null && mounted) {
      _showStripeTestDialog(clientSecret);
    }
  }

  Future<void> _payCash(String userId) async {
    // Cash: just record payment and go to orders
    await supabase.from('payments').insert({
      'order_id': widget.orderId,
      'customer_id': userId,
      'method': 'cash',
      'status': 'pending',
      'amount': widget.amount,
      'currency': 'NPR',
    });
    if (mounted) {
      ref.read(paymentNotifierProvider.notifier).reset();
      context.go(RouteNames.orders);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Order placed! Pay on delivery.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showKhaltiVerifyDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify Khalti Payment'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            'After completing payment, paste the pidx from the Khalti return URL.',
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
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C2D91)),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref
                  .read(paymentNotifierProvider.notifier)
                  .verifyKhaltiPayment(
                pidx: ctrl.text.trim(),
                orderId: widget.orderId,
              );
              if (ok && mounted) {
                ref.read(paymentNotifierProvider.notifier).reset();
                context.go(RouteNames.orders);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Khalti payment verified! Order confirmed.'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: const Text('Verify',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showStripeTestDialog(String clientSecret) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Stripe Test Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Use these test card details:',
                style: AppTypography.labelMedium),
            const SizedBox(height: AppSpacing.sm),
            _CardRow('Card', '4242 4242 4242 4242'),
            _CardRow('Expiry', '12/34'),
            _CardRow('CVV', '123'),
            _CardRow('ZIP', '12345'),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius:
                BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                'Production: integrate flutter_stripe for real card UI.',
                style: AppTypography.bodySmall,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF635BFF)),
            onPressed: () async {
              Navigator.pop(ctx);
              final paymentIntentId = clientSecret.split('_secret_')[0];
              final ok = await ref
                  .read(paymentNotifierProvider.notifier)
                  .confirmStripePayment(
                paymentIntentId: paymentIntentId,
                orderId: widget.orderId,
              );
              if (ok && mounted) {
                ref.read(paymentNotifierProvider.notifier).reset();
                context.go(RouteNames.orders);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Card payment confirmed! Order placed.'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: const Text('Confirm Test Payment',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────

class _PaymentTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, value, groupValue;
  final Color color;
  final ValueChanged<String?> onChanged;

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
              ? color.withOpacity(0.08)
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
                  color: color.withOpacity(0.12),
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
          Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: color),
        ]),
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  final String label, value;
  const _CardRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        SizedBox(width: 55,
            child: Text(label, style: AppTypography.bodySmall)),
        Text(value, style: AppTypography.labelMedium),
      ]),
    );
  }
}