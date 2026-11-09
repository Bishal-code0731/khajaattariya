import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../rider/application/rider_provider.dart';

/// Vehicle types the database accepts, with their icons.
const riderVehicleTypes = <(String, IconData)>[
  ('motorcycle', Icons.two_wheeler_rounded),
  ('scooter', Icons.moped_rounded),
  ('bicycle', Icons.pedal_bike_rounded),
  ('car', Icons.directions_car_rounded),
  ('other', Icons.more_horiz_rounded),
];

IconData riderVehicleIcon(String type) => riderVehicleTypes
    .firstWhere((v) => v.$1 == type, orElse: () => riderVehicleTypes.last)
    .$2;

/// Register (or, before approval, correct) the rider's vehicle.
class VehicleForm extends ConsumerStatefulWidget {
  const VehicleForm({
    super.key,
    required this.riderId,
    this.initialType = 'motorcycle',
    this.initialNumber,
    this.isUpdate = false,
    this.onDone,
  });

  final String riderId;
  final String initialType;
  final String? initialNumber;
  final bool isUpdate;
  final VoidCallback? onDone;

  @override
  ConsumerState<VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends ConsumerState<VehicleForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberCtrl =
      TextEditingController(text: widget.initialNumber ?? '');
  late String _type = riderVehicleTypes.any((v) => v.$1 == widget.initialType)
      ? widget.initialType
      : 'motorcycle';

  bool get _numberOptional => _type == 'bicycle';

  @override
  void dispose() {
    _numberCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final r = context.s.rider;
    final number = _numberCtrl.text.trim().toUpperCase();
    final ok = await ref.read(riderRegistrationProvider.notifier).register(
          riderId: widget.riderId,
          vehicleType: _type,
          vehicleNumber: number.isEmpty ? null : number,
        );
    if (!mounted) return;
    if (ok) {
      ref.invalidate(riderProfileProvider(widget.riderId));
      AppSnackbar.success(
          context, widget.isUpdate ? r.vehicleUpdated : r.registeredSuccess);
      widget.onDone?.call();
    } else {
      AppSnackbar.error(context, ref.read(riderRegistrationProvider).error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.s.rider;
    final isLoading = ref.watch(riderRegistrationProvider).isLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(r.vehicleType,
              style: AppTypography.labelMedium.copyWith(color: p.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final (type, icon) in riderVehicleTypes)
                ChoiceChip(
                  selected: _type == type,
                  onSelected:
                      isLoading ? null : (_) => setState(() => _type = type),
                  avatar: Icon(icon,
                      size: 20,
                      color: _type == type ? p.onBrandSoft : p.textSecondary),
                  showCheckmark: false,
                  label: Text(r.vehicleTypeLabel(type)),
                  labelStyle: AppTypography.labelMedium.copyWith(
                    color: _type == type ? p.onBrandSoft : p.textPrimary,
                  ),
                  selectedColor: p.brandSoft,
                  backgroundColor: p.surface,
                  side: BorderSide(color: _type == type ? p.brand : p.border),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: _numberOptional ? r.vehicleNumberOptional : r.vehicleNumber,
            hint: r.vehicleNumberHint,
            helper: _numberOptional ? r.vehicleNumberBicycleHelper : null,
            controller: _numberCtrl,
            prefixIcon: Icons.badge_outlined,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            maxLength: 20,
            validator: context.validators.text(r.vehicleNumber,
                min: 2, max: 20, optional: _numberOptional),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: widget.isUpdate ? r.updateDetails : r.submitForApproval,
            leadingIcon:
                widget.isUpdate ? Icons.save_outlined : Icons.send_rounded,
            isLoading: isLoading,
            onPressed: isLoading ? null : _submit,
          ),
        ],
      ),
    );
  }
}
