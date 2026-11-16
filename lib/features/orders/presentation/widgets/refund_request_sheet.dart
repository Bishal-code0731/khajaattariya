import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../payments/application/refund_provider.dart';
import '../../domain/models/order_model.dart';
import '../../../../shared/widgets/busy_overlay.dart';

/// Bottom sheet where a customer explains what went wrong with a paid order.
class RefundRequestSheet extends ConsumerStatefulWidget {
  const RefundRequestSheet({super.key, required this.order});
  final OrderModel order;

  static Future<void> show(BuildContext context, OrderModel order) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) => RefundRequestSheet(order: order),
    );
  }

  @override
  ConsumerState<RefundRequestSheet> createState() => _RefundRequestSheetState();
}

class _RefundRequestSheetState extends ConsumerState<RefundRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    final o = context.s.orders;
    final ok = await ref.read(refundNotifierProvider.notifier).requestRefund(
          orderId: widget.order.id,
          amount: widget.order.totalAmount,
          reason: _reason.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      ref.invalidate(customerRefundsProvider(widget.order.customerId));
      Navigator.of(context).pop();
      AppSnackbar.success(context, o.refundSent);
      return;
    }
    final error = ref.read(refundNotifierProvider).error;
    if (error is NoRefundablePaymentException) {
      AppSnackbar.error(context, o.refundNoPayment);
    } else if ('$error'.contains('refunds_one_open_per_payment') ||
        '$error'.contains('23505')) {
      AppSnackbar.error(context, o.refundAlreadyOpen);
    } else {
      AppSnackbar.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) =>
      BusyOverlay(busy: _submitting, child: _buildBusyContent(context));

  Widget _buildBusyContent(BuildContext context) {
    final p = context.palette;
    final text = context.text;
    final o = context.s.orders;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(o.refundTitle, style: text.h2),
              const SizedBox(height: AppSpacing.sm),
              Text(
                o.refundBody(
                    AppFormat.money(context, widget.order.totalAmount)),
                style: text.secondary,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                label: o.refundReasonField,
                hint: o.refundReasonHint,
                controller: _reason,
                maxLines: 4,
                maxLength: 500,
                textInputAction: TextInputAction.newline,
                validator: context.validators
                    .text(o.refundReasonField, min: 10, max: 500),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: o.sendRequest,
                isLoading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
