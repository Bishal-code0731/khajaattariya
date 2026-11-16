import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/address_provider.dart';
import '../../domain/models/address_model.dart';
import 'address_card.dart';
import '../../../../shared/widgets/busy_overlay.dart';

/// Opens the add / edit address sheet.
Future<void> showAddressFormSheet(
  BuildContext context, {
  required String userId,
  AddressModel? existing,
  bool forceDefault = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => AddressFormSheet(
        userId: userId, existing: existing, forceDefault: forceDefault),
  );
}

enum _LabelChoice { home, work, other, custom }

class AddressFormSheet extends ConsumerStatefulWidget {
  const AddressFormSheet(
      {super.key,
      required this.userId,
      this.existing,
      this.forceDefault = false});

  final String userId;
  final AddressModel? existing;
  final bool forceDefault;

  @override
  ConsumerState<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _address =
      TextEditingController(text: widget.existing?.fullAddress ?? '');
  late final TextEditingController _landmark =
      TextEditingController(text: widget.existing?.landmark ?? '');
  late final TextEditingController _customLabel = TextEditingController();
  late _LabelChoice _choice;
  late bool _isDefault;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final label = widget.existing?.label ?? addressLabelHome;
    _choice = switch (label.toLowerCase()) {
      'home' => _LabelChoice.home,
      'work' => _LabelChoice.work,
      'other' => _LabelChoice.other,
      _ => _LabelChoice.custom,
    };
    if (_choice == _LabelChoice.custom) _customLabel.text = label;
    _isDefault = widget.existing?.isDefault ?? widget.forceDefault;
  }

  @override
  void dispose() {
    _address.dispose();
    _landmark.dispose();
    _customLabel.dispose();
    super.dispose();
  }

  String get _labelValue => switch (_choice) {
        _LabelChoice.home => addressLabelHome,
        _LabelChoice.work => addressLabelWork,
        _LabelChoice.other => addressLabelOther,
        _LabelChoice.custom => _customLabel.text.trim(),
      };

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final notifier = ref.read(addressNotifierProvider.notifier);
    final landmark = _landmark.text.trim();
    try {
      if (_isEdit) {
        await notifier.updateAddress(
          addressId: widget.existing!.id,
          userId: widget.userId,
          label: _labelValue,
          fullAddress: _address.text.trim(),
          landmark: landmark.isEmpty ? null : landmark,
          isDefault: _isDefault,
        );
      } else {
        await notifier.addAddress(
          userId: widget.userId,
          label: _labelValue,
          fullAddress: _address.text.trim(),
          landmark: landmark.isEmpty ? null : landmark,
          isDefault: _isDefault,
        );
      }
      if (!mounted) return;
      final msg = context.s.account.addressSaved;
      Navigator.of(context).pop();
      AppSnackbar.success(context, msg);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) =>
      BusyOverlay(busy: _saving, child: _buildBusyContent(context));

  Widget _buildBusyContent(BuildContext context) {
    final a = context.s.account;
    final c = context.s.common;
    final p = context.palette;
    final v = context.validators;
    final lockedDefault = widget.existing?.isDefault ?? false;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_isEdit ? a.editAddress : a.newAddress,
                  style: context.text.h2),
              const SizedBox(height: AppSpacing.xl),
              Text(a.addressLabel, style: context.text.labelSecondary),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final choice in _LabelChoice.values)
                    ChoiceChip(
                      selected: _choice == choice,
                      onSelected: (_) => setState(() => _choice = choice),
                      avatar: Icon(
                        switch (choice) {
                          _LabelChoice.home => Icons.home_outlined,
                          _LabelChoice.work => Icons.work_outline_rounded,
                          _LabelChoice.other => Icons.place_outlined,
                          _LabelChoice.custom => Icons.bookmark_border_rounded,
                        },
                        size: 18,
                      ),
                      label: Text(switch (choice) {
                        _LabelChoice.home => a.labelHome,
                        _LabelChoice.work => a.labelWork,
                        _LabelChoice.other => a.labelOther,
                        _LabelChoice.custom => a.customLabel,
                      }),
                    ),
                ],
              ),
              if (_choice == _LabelChoice.custom) ...[
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: a.customLabel,
                  hint: a.customLabelHint,
                  controller: _customLabel,
                  prefixIcon: Icons.bookmark_border_rounded,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 30,
                  validator: v.text(a.customLabel, min: 2, max: 30),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: a.fullAddress,
                hint: a.fullAddressHint,
                controller: _address,
                prefixIcon: Icons.location_on_outlined,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                autofillHints: const [AutofillHints.fullStreetAddress],
                validator: v.address,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: a.landmark,
                hint: a.landmarkHint,
                controller: _landmark,
                prefixIcon: Icons.signpost_outlined,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                validator: v.text(a.landmarkField, max: 100, optional: true),
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _isDefault,
                onChanged: lockedDefault
                    ? null
                    : (value) => setState(() => _isDefault = value),
                title: Text(a.makeDefault, style: context.text.label),
                subtitle: Text(a.makeDefaultHint, style: context.text.caption),
                activeTrackColor: p.brand,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: _isEdit ? c.saveChanges : a.addAddress,
                isLoading: _saving,
                onPressed: _save,
                leadingIcon: _isEdit ? null : Icons.add_location_alt_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
