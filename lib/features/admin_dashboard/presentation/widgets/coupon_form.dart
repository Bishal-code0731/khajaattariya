import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/admin_actions.dart';
import '../../domain/admin_models.dart';
import '../../../../shared/widgets/busy_overlay.dart';

/// Opens the create / edit coupon form: a dialog on wide screens, a full-height sheet on phones.
Future<void> showCouponForm(BuildContext context, {AdminCoupon? coupon}) {
  if (MediaQuery.sizeOf(context).width >= 600) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
          child: _CouponForm(coupon: coupon),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => FractionallySizedBox(
        heightFactor: 0.94, child: _CouponForm(coupon: coupon)),
  );
}

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
          TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}

class _CouponForm extends ConsumerStatefulWidget {
  const _CouponForm({this.coupon});
  final AdminCoupon? coupon;

  @override
  ConsumerState<_CouponForm> createState() => _CouponFormState();
}

class _CouponFormState extends ConsumerState<_CouponForm> {
  static final _codePattern = RegExp(r'^[A-Z0-9]{4,20}$');

  final _formKey = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.coupon?.code ?? '');
  late final _value =
      TextEditingController(text: _num(widget.coupon?.discountValue));
  late final _minOrder = TextEditingController(
      text: widget.coupon == null ? '0' : _num(widget.coupon!.minOrderAmount));
  late final _maxDiscount =
      TextEditingController(text: _num(widget.coupon?.maxDiscount));
  late final _maxUses =
      TextEditingController(text: widget.coupon?.maxUses?.toString() ?? '');
  late final _perCustomer =
      TextEditingController(text: '${widget.coupon?.maxUsesPerCustomer ?? 1}');
  late final _description =
      TextEditingController(text: widget.coupon?.description ?? '');
  final _fromText = TextEditingController();
  final _untilText = TextEditingController();

  late String _type = widget.coupon?.discountType ?? 'percent';
  late DateTime _from = widget.coupon?.validFrom ?? DateTime.now();
  late DateTime? _until = widget.coupon?.validUntil;
  bool _saving = false;

  static String _num(double? v) {
    if (v == null) return '';
    return v % 1 == 0 ? v.toStringAsFixed(0) : v.toString();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncDates();
  }

  void _syncDates() {
    _fromText.text = AppFormat.date(context, _from);
    _untilText.text = _until == null ? '' : AppFormat.date(context, _until!);
  }

  @override
  void dispose() {
    for (final c in [
      _code,
      _value,
      _minOrder,
      _maxDiscount,
      _maxUses,
      _perCustomer,
      _description,
      _fromText,
      _untilText
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFrom() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate:
          _from.isBefore(now) ? _from : DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null || !mounted) return;
    setState(() {
      final today = DateTime(now.year, now.month, now.day);
      // Today means "start now"; a later day starts at midnight.
      _from = picked.isAtSameMomentAs(today) ? now : picked;
      _syncDates();
    });
  }

  Future<void> _pickUntil() async {
    final first = _from.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _until != null && _until!.isAfter(first) ? _until! : first,
      firstDate: DateTime(first.year, first.month, first.day),
      lastDate: DateTime(first.year + 3),
    );
    if (picked == null || !mounted) return;
    setState(() {
      // Valid through the end of the chosen day.
      _until = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      _syncDates();
    });
  }

  String? _validateValue(String? v) {
    final s = context.s.admin;
    final c = context.s.common;
    final n = double.tryParse((v ?? '').trim());
    if ((v ?? '').trim().isEmpty) {
      return c.required(_type == 'percent' ? s.fieldPercent : s.fieldAmount);
    }
    if (n == null) return c.invalidNumber;
    if (_type == 'percent') return (n > 0 && n <= 100) ? null : s.percentRange;
    return (n > 0 && n <= 10000) ? null : s.amountRange;
  }

  FieldValidator _optionalPositive(
          {bool integer = false, int maxInt = 100000}) =>
      (v) {
        final s = context.s.admin;
        final t = (v ?? '').trim();
        if (t.isEmpty) return null;
        if (integer) {
          final n = int.tryParse(t);
          return (n == null || n < 1 || n > maxInt) ? s.wholeNumberRange : null;
        }
        final n = double.tryParse(t);
        if (n == null) return context.s.common.invalidNumber;
        return n > 0 ? null : s.mustBePositive;
      };

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final s = context.s.admin;
    final desc = _description.text.trim();
    final draft = CouponDraft(
      code: _code.text.trim(),
      description: desc.isEmpty ? null : desc,
      discountType: _type,
      discountValue: double.parse(_value.text.trim()),
      minOrderAmount: double.parse(_minOrder.text.trim()),
      maxDiscount:
          _type == 'percent' ? double.tryParse(_maxDiscount.text.trim()) : null,
      maxUses: int.tryParse(_maxUses.text.trim()),
      maxUsesPerCustomer: int.parse(_perCustomer.text.trim()),
      validFrom: _from,
      validUntil: _until,
    );
    setState(() => _saving = true);
    try {
      await ref
          .read(adminActionsProvider)
          .saveCoupon(draft, couponId: widget.coupon?.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      AppSnackbar.success(context, s.couponSaved);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackbar.error(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      BusyOverlay(busy: _saving, child: _buildBusyContent(context));

  Widget _buildBusyContent(BuildContext context) {
    final s = context.s.admin;
    final v = context.validators;
    final editing = widget.coupon != null;
    final isPercent = _type == 'percent';
    const numberKeyboard = TextInputType.numberWithOptions(decimal: true);
    final digitsOnly = [FilteringTextInputFormatter.digitsOnly];
    final decimal = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];

    Widget pair(Widget a, Widget b) => LayoutBuilder(builder: (context, c) {
          if (c.maxWidth < 420) {
            return Column(
                children: [a, const SizedBox(height: AppSpacing.lg), b]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: a),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: b),
          ]);
        });

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.lg, AppSpacing.sm, AppSpacing.sm),
            child: Row(children: [
              Expanded(
                  child: Text(editing ? s.editCoupon : s.newCoupon,
                      style: context.text.h2)),
              IconButton(
                tooltip: context.s.common.close,
                icon: const Icon(Icons.close_rounded),
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
              ),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
              children: [
                AppTextField(
                  label: s.fieldCode,
                  helper: s.codeHelper,
                  controller: _code,
                  maxLength: 20,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                    _UpperCase()
                  ],
                  validator: AppValidators.combine([
                    v.requiredField(s.fieldCode),
                    (x) => _codePattern.hasMatch((x ?? '').trim())
                        ? null
                        : s.codeInvalid,
                  ]),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(s.discountType, style: context.text.label),
                const SizedBox(height: AppSpacing.xs + 2),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                        value: 'percent',
                        label: Text(s.typePercent),
                        icon: const Icon(Icons.percent_rounded)),
                    ButtonSegment(
                        value: 'fixed',
                        label: Text(s.typeFixed),
                        icon: const Icon(Icons.payments_outlined)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (set) =>
                      setState(() => _type = set.first),
                ),
                const SizedBox(height: AppSpacing.lg),
                pair(
                  AppTextField(
                    key: ValueKey('value-$_type'),
                    label: isPercent ? s.fieldPercent : s.fieldAmount,
                    controller: _value,
                    keyboardType: numberKeyboard,
                    inputFormatters: decimal,
                    validator: _validateValue,
                  ),
                  isPercent
                      ? AppTextField(
                          label: s.fieldMaxDiscount,
                          helper: s.optionalHelper,
                          controller: _maxDiscount,
                          keyboardType: numberKeyboard,
                          inputFormatters: decimal,
                          validator: _optionalPositive(),
                        )
                      : AppTextField(
                          label: s.fieldMinOrder,
                          controller: _minOrder,
                          keyboardType: numberKeyboard,
                          inputFormatters: decimal,
                          validator:
                              v.nonNegative(s.fieldMinOrder, max: 100000),
                        ),
                ),
                if (isPercent) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: s.fieldMinOrder,
                    controller: _minOrder,
                    keyboardType: numberKeyboard,
                    inputFormatters: decimal,
                    validator: v.nonNegative(s.fieldMinOrder, max: 100000),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                pair(
                  AppTextField(
                    label: s.fieldMaxUses,
                    helper: s.optionalHelper,
                    controller: _maxUses,
                    keyboardType: TextInputType.number,
                    inputFormatters: digitsOnly,
                    validator: _optionalPositive(integer: true),
                  ),
                  AppTextField(
                    label: s.fieldPerCustomer,
                    controller: _perCustomer,
                    keyboardType: TextInputType.number,
                    inputFormatters: digitsOnly,
                    validator: (x) {
                      final n = int.tryParse((x ?? '').trim());
                      return (n == null || n < 1 || n > 100)
                          ? s.perCustomerRange
                          : null;
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                pair(
                  AppTextField(
                    label: s.fieldValidFrom,
                    controller: _fromText,
                    readOnly: true,
                    prefixIcon: Icons.event_rounded,
                    onTap: _pickFrom,
                  ),
                  AppTextField(
                    label: s.fieldValidUntil,
                    hint: s.noExpiry,
                    controller: _untilText,
                    readOnly: true,
                    prefixIcon: Icons.event_busy_rounded,
                    onTap: _pickUntil,
                    suffix: _until == null
                        ? null
                        : IconButton(
                            tooltip: s.clearDate,
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => setState(() {
                              _until = null;
                              _syncDates();
                            }),
                          ),
                    validator: (_) => _until != null && !_until!.isAfter(_from)
                        ? s.untilAfterFrom
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: s.fieldDescription,
                  hint: s.descriptionHint,
                  helper: s.optionalHelper,
                  controller: _description,
                  maxLines: 2,
                  maxLength: 200,
                  textCapitalization: TextCapitalization.sentences,
                  validator:
                      v.text(s.fieldDescription, max: 200, optional: true),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
            child: AppButton(
              label: editing ? context.s.common.saveChanges : s.createCoupon,
              isLoading: _saving,
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}
