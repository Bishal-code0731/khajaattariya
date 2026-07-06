import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/glass_card.dart';
import '../application/address_provider.dart';
import '../domain/models/address_model.dart';

class AddressBookScreen extends ConsumerStatefulWidget {
  const AddressBookScreen({super.key});

  @override
  ConsumerState<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends ConsumerState<AddressBookScreen> {
  // Which address rows have a set-default/delete request in flight —
  // only that row's action chips are disabled, everything else in the
  // list stays interactive.
  final _busyAddressIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Address Book')),
        body: const AppEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Please log in',
          subtitle: 'Log in to view and manage your addresses.',
        ),
      );
    }

    final addressesAsync = ref.watch(addressListProvider(user.id));
    final notifier = ref.read(addressNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Address Book'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddressSheet(
          context: context,
          ref: ref,
          userId: user.id,
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Add Address',
            style: AppTypography.labelMedium
                .copyWith(color: Colors.white)),
      ),
      body: AsyncValueView(
        value: addressesAsync,
        errorMessage: 'Could not load addresses',
        onRetry: () => ref.invalidate(addressListProvider(user.id)),
        data: (addresses) {
          if (addresses.isEmpty) {
            return const AppEmptyState(
              icon: Icons.location_off_outlined,
              title: 'No saved addresses',
              subtitle: 'Add your delivery addresses',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.md,
            ),
            itemCount: addresses.length,
            separatorBuilder: (_, __) =>
            const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final address = addresses[index];
              final isBusy = _busyAddressIds.contains(address.id);
              return _AddressTile(
                address: address,
                isBusy: isBusy,
                onSetDefault: isBusy ? null : () async {
                  setState(() => _busyAddressIds.add(address.id));
                  final ok = await notifier.setDefault(
                    addressId: address.id,
                    userId: user.id,
                  );
                  if (!context.mounted) return;
                  setState(() => _busyAddressIds.remove(address.id));
                  if (!ok) AppSnackbar.error(context, 'Could not set default address');
                },
                onEdit: () => _showAddressSheet(
                  context: context,
                  ref: ref,
                  userId: user.id,
                  existing: address,
                ),
                onDelete: isBusy ? null : () async {
                  setState(() => _busyAddressIds.add(address.id));
                  final ok = await notifier.deleteAddress(address.id, user.id);
                  if (!context.mounted) return;
                  setState(() => _busyAddressIds.remove(address.id));
                  if (ok) {
                    AppSnackbar.success(context, 'Address deleted');
                  } else {
                    AppSnackbar.error(context, 'Could not delete address');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showAddressSheet({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    AddressModel? existing,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressSheet(
        userId: userId,
        existing: existing,
        ref: ref,
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final AddressModel address;
  final bool isBusy;
  final VoidCallback? onSetDefault;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _AddressTile({
    required this.address,
    required this.isBusy,
    required this.onSetDefault,
    required this.onEdit,
    required this.onDelete,
  });

  IconData get _labelIcon {
    switch (address.label.toLowerCase()) {
      case 'home':
        return Icons.home_outlined;
      case 'work':
        return Icons.work_outline_rounded;
      default:
        return Icons.location_on_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.radiusLg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius:
              BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(_labelIcon,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(address.label,
                        style: AppTypography.labelMedium),
                    if (address.isDefault) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm),
                        ),
                        child: Text('Default',
                            style: AppTypography.labelSmall
                                .copyWith(color: AppColors.success)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(address.fullAddress,
                    style: AppTypography.bodyMedium),
                if (address.landmark != null) ...[
                  const SizedBox(height: 2),
                  Text('Near: ${address.landmark}',
                      style: AppTypography.bodySmall),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    if (!address.isDefault)
                      _ActionChip(
                        label: 'Set Default',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.success,
                        onTap: onSetDefault,
                        isBusy: isBusy,
                      ),
                    if (!address.isDefault)
                      const SizedBox(width: AppSpacing.sm),
                    _ActionChip(
                      label: 'Edit',
                      icon: Icons.edit_outlined,
                      color: AppColors.info,
                      onTap: isBusy ? null : onEdit,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ActionChip(
                      label: 'Delete',
                      icon: Icons.delete_outline_rounded,
                      color: AppColors.error,
                      onTap: onDelete,
                      isBusy: isBusy,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isBusy;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isBusy ? 0.05 : 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isBusy
                ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: color))
                : Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: AppTypography.labelSmall.copyWith(color: isBusy ? color.withValues(alpha: 0.5) : color)),
          ],
        ),
      ),
    );
  }
}

class _AddressSheet extends StatefulWidget {
  final String userId;
  final AddressModel? existing;
  final WidgetRef ref;

  const _AddressSheet({
    required this.userId,
    required this.ref,
    this.existing,
  });

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _addressController;
  late TextEditingController _landmarkController;
  String _selectedLabel = 'Home';
  bool _isDefault = false;
  bool _isLoading = false;

  static const _labels = ['Home', 'Work', 'Other'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _addressController =
        TextEditingController(text: e?.fullAddress ?? '');
    _landmarkController =
        TextEditingController(text: e?.landmark ?? '');
    _selectedLabel = e?.label ?? 'Home';
    _isDefault = e?.isDefault ?? false;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final notifier =
    widget.ref.read(addressNotifierProvider.notifier);
    bool success;

    if (widget.existing != null) {
      success = await notifier.updateAddress(
        addressId: widget.existing!.id,
        userId: widget.userId,
        label: _selectedLabel,
        fullAddress: _addressController.text.trim(),
        landmark: _landmarkController.text.trim().isEmpty
            ? null
            : _landmarkController.text.trim(),
        isDefault: _isDefault,
      );
    } else {
      success = await notifier.addAddress(
        userId: widget.userId,
        label: _selectedLabel,
        fullAddress: _addressController.text.trim(),
        landmark: _landmarkController.text.trim().isEmpty
            ? null
            : _landmarkController.text.trim(),
        isDefault: _isDefault,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXl)),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius:
                    BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(isEdit ? 'Edit Address' : 'Add New Address',
                  style: AppTypography.headingMedium),
              const SizedBox(height: AppSpacing.lg),
              // Label selector
              Text('Label', style: AppTypography.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: _labels.map((label) {
                  final selected = _selectedLabel == label;
                  return Padding(
                    padding:
                    const EdgeInsets.only(right: AppSpacing.sm),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedLabel = label),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          label,
                          style: AppTypography.labelMedium.copyWith(
                            color: selected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Full Address',
                hint: 'Street, area, city',
                controller: _addressController,
                prefixIcon: Icons.location_on_outlined,
                maxLines: 2,
                validator: Validators.address,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Landmark (optional)',
                hint: 'Near a landmark',
                controller: _landmarkController,
                prefixIcon: Icons.place_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Checkbox(
                    value: _isDefault,
                    activeColor: AppColors.primary,
                    onChanged: (v) =>
                        setState(() => _isDefault = v ?? false),
                  ),
                  Text('Set as default address',
                      style: AppTypography.bodyMedium),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: isEdit ? 'Update Address' : 'Save Address',
                isLoading: _isLoading,
                onPressed: _save,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}