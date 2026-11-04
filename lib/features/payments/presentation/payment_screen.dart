import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/s.dart';
import '../../../core/network/payment_deeplink_listener.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../orders/application/order_provider.dart';
import '../../orders/domain/models/order_model.dart';
import '../application/payment_provider.dart';
import 'widgets/khalti_waiting_card.dart';
import 'widgets/payment_method_card.dart';
import 'widgets/payment_summary_card.dart';
import '../../../shared/widgets/busy_overlay.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  /// orderId -> amount from checkout.
  final Map<String, double> orderAmounts;

  const PaymentScreen({super.key, required this.orderAmounts});

  List<String> get orderIds => orderAmounts.keys.toList();

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  late Future<List<OrderModel>> _ordersFuture;
  late final PaymentDeepLinkListener _deepLinks;
  PaymentMethod? _method;
  bool _waitingForKhalti = false;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
    _deepLinks = ref.read(paymentDeepLinkListenerProvider);
    _deepLinks.start(_onKhaltiDeepLink);
  }

  @override
  void dispose() {
    _deepLinks.stop();
    super.dispose();
  }

  Future<List<OrderModel>> _loadOrders() =>
      ref.read(orderRepositoryProvider).getOrdersByIds(widget.orderIds);

  void _onKhaltiDeepLink(String pidx) {
    if (!mounted) return;
    AppLogger.info('payment', 'khalti deep link received');
    _checkKhalti(pidx);
  }

  String? _failureText(Object? error) {
    if (error is! PaymentException) return null;
    final o = context.s.orders;
    return switch (error.failure) {
      PaymentFailure.alreadyInProgress => o.paymentInProgress,
      PaymentFailure.alreadyPaid => o.alreadyPaid,
      PaymentFailure.gatewayUnavailable => o.gatewayUnavailable,
      PaymentFailure.notCompleted => o.khaltiFailed,
      PaymentFailure.stillPending => o.khaltiStillPending,
    };
  }

  void _showError() {
    final error = ref.read(paymentNotifierProvider).error;
    AppSnackbar.error(context, _failureText(error) ?? error);
  }

  Future<void> _pay(String userId) async {
    switch (_method) {
      case PaymentMethod.cash:
        await _payCash(userId);
      case PaymentMethod.khalti:
        await _payKhalti(userId);
      case PaymentMethod.esewa:
        AppSnackbar.info(context, context.s.orders.esewaUnavailable);
      case null:
        break;
    }
  }

  Future<void> _payCash(String userId) async {
    final ok = await ref
        .read(paymentNotifierProvider.notifier)
        .placeCashOrder(orderIds: widget.orderIds, customerId: userId);
    if (!mounted) return;
    if (!ok) return _showError();
    ref.invalidate(customerPaymentsProvider(userId));
    ref.read(paymentNotifierProvider.notifier).reset();
    final message = context.s.orders.cashSuccess;
    context.go(RouteNames.orders);
    AppSnackbar.success(context, message);
  }

  Future<void> _payKhalti(String userId) async {
    final url = await ref
        .read(paymentNotifierProvider.notifier)
        .initiateKhaltiPayment(orderIds: widget.orderIds, customerId: userId);
    if (!mounted) return;
    if (url == null) return _showError();
    ref.invalidate(customerPaymentsProvider(userId));
    setState(() => _waitingForKhalti = true);
    await _openKhalti(url);
  }

  Future<void> _openKhalti(String url) async {
    final opened =
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)
            .catchError((_) => false);
    if (!opened && mounted) {
      AppSnackbar.error(context, context.s.orders.khaltiOpenFailed);
    }
  }

  Future<void> _checkKhalti(String pidx) async {
    if (pidx.isEmpty) return;
    final o = context.s.orders;
    final result = await ref
        .read(paymentNotifierProvider.notifier)
        .checkKhaltiPayment(pidx: pidx, orderIds: widget.orderIds);
    if (!mounted) return;
    switch (result) {
      case KhaltiCheckResult.received:
        // Only the server marks the order paid; the order screen shows the confirmed status live once it does.
        final userId = ref.read(authStateProvider).valueOrNull?.id;
        if (userId != null) ref.invalidate(customerPaymentsProvider(userId));
        ref.read(paymentNotifierProvider.notifier).reset();
        final ids = widget.orderIds;
        context.go(ids.length == 1
            ? '${RouteNames.orderDetail}/${ids.first}'
            : RouteNames.orders);
        AppSnackbar.success(context, o.khaltiReceived);
      case KhaltiCheckResult.pending:
        AppSnackbar.warning(context, o.khaltiStillPending);
      case KhaltiCheckResult.failed:
        setState(() => _waitingForKhalti = false);
        AppSnackbar.error(context, o.khaltiFailed);
    }
  }

  /// Debug-only fallback when the return link can't reach the app (e.g.
  Future<void> _debugEnterPidx() async {
    if (!kDebugMode) return;
    final o = context.s.orders;
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final pidx = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(o.debugEnterPidx),
        content: Form(
          key: formKey,
          child: AppTextField(
            label: o.pidxField,
            controller: controller,
            validator: ctx.validators.text(o.pidxField, min: 6, max: 100),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.s.common.cancel),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: Text(o.verify),
          ),
        ],
      ),
    );
    controller.dispose();
    if (pidx != null && mounted) await _checkKhalti(pidx);
  }

  Future<bool> _confirmLeave() async {
    if (!_waitingForKhalti) return true;
    return AppDialog.confirm(
      context,
      title: context.s.orders.khaltiWaitingTitle,
      message: context.s.orders.khaltiWaitingBody,
      confirmLabel: context.s.common.back,
    );
  }

  @override
  Widget build(BuildContext context) => BusyOverlay(
      busy: ref.watch(paymentNotifierProvider).isLoading,
      child: _buildBusyContent(context));

  Widget _buildBusyContent(BuildContext context) {
    final o = context.s.orders;
    final user = ref.watch(authStateProvider).valueOrNull;
    final paymentState = ref.watch(paymentNotifierProvider);
    final settingsAsync = ref.watch(platformSettingsProvider);

    return PopScope(
      canPop: !_waitingForKhalti,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) {
          setState(() => _waitingForKhalti = false);
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppTopBar(
          title: o.paymentTitle,
          subtitle: o.paymentSubtitle(widget.orderIds.length),
        ),
        body: FutureBuilder<List<OrderModel>>(
          future: _ordersFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const AppShimmerCardList(count: 3, itemHeight: 88);
            }
            if (snap.hasError || snap.data == null) {
              return AppErrorState(
                error: snap.error,
                onRetry: () => setState(() => _ordersFuture = _loadOrders()),
              );
            }
            final unpaid = snap.data!
                .where((x) => !x.isPaid && x.status != OrderStatus.cancelled)
                .toList();
            if (unpaid.isEmpty) {
              return AppEmptyState(
                icon: Icons.check_circle_outline_rounded,
                title: o.alreadyPaid,
                action: AppButton(
                  label: o.backToOrders,
                  expand: false,
                  onPressed: () => context.go(RouteNames.orders),
                ),
              );
            }
            return settingsAsync.when(
              loading: () => const AppShimmerCardList(count: 3, itemHeight: 88),
              error: (e, _) => AppErrorState(
                error: e,
                onRetry: () => ref.invalidate(platformSettingsProvider),
              ),
              data: (settings) => _content(
                context,
                orders: unpaid,
                settings: settings,
                busy: paymentState.isLoading,
                userId: user?.id,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context, {
    required List<OrderModel> orders,
    required Map<String, String> settings,
    required bool busy,
    required String? userId,
  }) {
    final o = context.s.orders;
    final p = context.palette;
    final enabled = {
      PaymentMethod.cash: settings['cash_enabled'] == 'true',
      PaymentMethod.khalti: settings['khalti_enabled'] == 'true',
      PaymentMethod.esewa: settings['esewa_enabled'] == 'true',
    };
    // Default to the first available method; drop a choice that was switched off in the meantime.
    if (_method == null || enabled[_method] != true) {
      _method = PaymentMethod.values
          .cast<PaymentMethod?>()
          .firstWhere((m) => enabled[m] == true, orElse: () => null);
    }
    final total = orders.fold<double>(0, (s, x) => s + x.totalAmount);
    final label = switch (_method) {
      PaymentMethod.cash => o.placeOrderCash,
      _ => o.payAmount(AppFormat.money(context, total)),
    };

    final methods = <Widget>[
      Text(o.howToPay, style: context.text.h3),
      const SizedBox(height: AppSpacing.md),
      if (_method == null)
        Text(o.noMethods, style: context.text.secondary)
      else
        for (final m in PaymentMethod.values) ...[
          PaymentMethodCard(
            method: m,
            selected: _method == m,
            enabled: enabled[m]! && !busy && !_waitingForKhalti,
            onTap: () => setState(() => _method = m),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      if (_waitingForKhalti) ...[
        const SizedBox(height: AppSpacing.sm),
        KhaltiWaitingCard(
          isChecking: busy,
          onCheck: () {
            final pidx = ref.read(paymentNotifierProvider).khaltiPidx;
            if (pidx != null) _checkKhalti(pidx);
          },
          onReopen: () {
            final url = ref.read(paymentNotifierProvider).khaltiPaymentUrl;
            if (url != null) _openKhalti(url);
          },
          onDebugPidx: _debugEnterPidx,
        ),
      ],
    ];

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final horizontal = constraints.maxWidth > AppSpacing.maxContentWidth
                ? (constraints.maxWidth - AppSpacing.maxContentWidth) / 2
                : AppSpacing.screenHorizontal;
            final padding = EdgeInsets.fromLTRB(
                horizontal, AppSpacing.lg, horizontal, AppSpacing.xxl);
            if (!wide) {
              return ListView(
                padding: padding,
                children: [
                  ...methods,
                  const SizedBox(height: AppSpacing.lg),
                  PaymentSummaryCard(orders: orders),
                ],
              );
            }
            return SingleChildScrollView(
              padding: padding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: methods,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(flex: 2, child: PaymentSummaryCard(orders: orders)),
                ],
              ),
            );
          }),
        ),
        if (!_waitingForKhalti)
          Container(
            decoration: BoxDecoration(
              color: p.surface,
              border: Border(top: BorderSide(color: p.border)),
            ),
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: AppSpacing.maxFormWidth),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                    child: AppButton(
                      label: label,
                      isLoading: busy,
                      leadingIcon: _method == PaymentMethod.cash
                          ? Icons.check_rounded
                          : Icons.lock_outline_rounded,
                      onPressed: busy || userId == null || _method == null
                          ? null
                          : () => _pay(userId),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
