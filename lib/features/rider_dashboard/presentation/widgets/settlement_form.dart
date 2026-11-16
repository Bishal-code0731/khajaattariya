import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../rider/application/rider_cash_providers.dart';

/// "Hand over cash" request.
class SettlementForm extends ConsumerStatefulWidget {
  const SettlementForm(
      {super.key, required this.riderId, required this.maxAmount});

  final String riderId;
  final double maxAmount;

  @override
  ConsumerState<SettlementForm> createState() => _SettlementFormState();
}

class _SettlementFormState extends ConsumerState<SettlementForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    final r = context.s.rider;
    final base = context.validators.nonNegative(r.settleAmount)(value);
    if (base != null) return base;
    final n = double.parse(value!.trim());
    if (n <= 0) return r.amountMustBePositive;
    if (n > widget.maxAmount) {
      return r.amountTooHigh(AppFormat.money(context, widget.maxAmount));
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final r = context.s.rider;
    final ok = await ref.read(settlementRequestProvider.notifier).submit(
          riderId: widget.riderId,
          amount: double.parse(_amountCtrl.text.trim()),
          note: _noteCtrl.text,
        );
    if (!mounted) return;
    if (ok) {
      _amountCtrl.clear();
      _noteCtrl.clear();
      _formKey.currentState?.reset();
      AppSnackbar.success(context, r.settleSuccess);
    } else {
      AppSnackbar.error(context, ref.read(settlementRequestProvider).error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.s.rider;
    final isLoading = ref.watch(settlementRequestProvider).isLoading;
    final canSettle = widget.maxAmount > 0;

    return AppCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.storefront_outlined, color: p.brand),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: Text(r.settleTitle,
                        style: AppTypography.headingSmall
                            .copyWith(color: p.textPrimary))),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(r.settleBody,
                style:
                    AppTypography.bodyMedium.copyWith(color: p.textSecondary)),
            const SizedBox(height: AppSpacing.lg),
            if (!canSettle)
              Text(r.nothingToSettle,
                  style:
                      AppTypography.bodyMedium.copyWith(color: p.textSecondary))
            else ...[
              AppTextField(
                label: r.settleAmount,
                controller: _amountCtrl,
                prefixIcon: Icons.payments_outlined,
                helper: r.settleAmountHelper(
                    AppFormat.money(context, widget.maxAmount)),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
                ],
                validator: _validateAmount,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: r.settleNote,
                hint: r.settleNoteHint,
                controller: _noteCtrl,
                prefixIcon: Icons.notes_rounded,
                maxLength: 200,
                textInputAction: TextInputAction.done,
                validator: context.validators
                    .text(r.settleNoteField, max: 200, optional: true),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: r.settleSubmit,
                leadingIcon: Icons.send_rounded,
                isLoading: isLoading,
                onPressed: isLoading ? null : _submit,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
