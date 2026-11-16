import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/s.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../auth/application/auth_provider.dart';
import '../../profile/presentation/widgets/account_bottom_bar.dart';
import '../application/address_provider.dart';
import '../domain/models/address_model.dart';
import 'widgets/address_card.dart';
import 'widgets/address_form_sheet.dart';

/// Saved delivery addresses: list, set default, edit, delete, add.
class AddressBookScreen extends ConsumerStatefulWidget {
  const AddressBookScreen({super.key});

  @override
  ConsumerState<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends ConsumerState<AddressBookScreen> {
  final _busyIds = <String>{};

  Future<void> _runOnRow(
      String id, Future<void> Function() action, String successMessage) async {
    if (_busyIds.contains(id)) return;
    setState(() => _busyIds.add(id));
    try {
      await action();
      if (mounted) AppSnackbar.success(context, successMessage);
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e);
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  Future<void> _delete(AddressModel address, String userId) async {
    final a = context.s.account;
    final ok = await AppDialog.confirm(
      context,
      title: a.deleteAddressTitle,
      message: a.deleteAddressMessage(addressLabelText(context, address.label)),
      confirmLabel: context.s.common.delete,
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !mounted) return;
    await _runOnRow(
      address.id,
      () => ref
          .read(addressNotifierProvider.notifier)
          .deleteAddress(address.id, userId),
      a.addressDeleted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = context.s.account;
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return Scaffold(
          appBar: AppTopBar(title: a.addressesTitle),
          body: const AppShimmerCardList(itemHeight: 64));
    }
    final async = ref.watch(addressListProvider(user.id));
    final addresses = async.valueOrNull ?? const <AddressModel>[];

    return Scaffold(
      appBar: AppTopBar(title: a.addressesTitle),
      body: async.when(
        skipLoadingOnReload: true,
        loading: () => const AppShimmerCardList(count: 3, itemHeight: 64),
        error: (e, _) => AppErrorState(
            error: e,
            onRetry: () => ref.invalidate(addressListProvider(user.id))),
        data: (_) {
          if (addresses.isEmpty) {
            return AppEmptyState(
              icon: Icons.add_location_alt_outlined,
              title: a.noAddressesTitle,
              subtitle: a.noAddressesBody,
              action: AppButton(
                label: a.addAddress,
                leadingIcon: Icons.add_rounded,
                expand: false,
                onPressed: () => showAddressFormSheet(context,
                    userId: user.id, forceDefault: true),
              ),
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720 ? 2 : 1;
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: _AddressList(
                    columns: columns,
                    children: [
                      for (final address in addresses)
                        AddressCard(
                          key: ValueKey(address.id),
                          address: address,
                          isBusy: _busyIds.contains(address.id),
                          onEdit: () => showAddressFormSheet(context,
                              userId: user.id, existing: address),
                          onDelete: () => _delete(address, user.id),
                          onSetDefault: () => _runOnRow(
                            address.id,
                            () => ref
                                .read(addressNotifierProvider.notifier)
                                .setDefault(
                                    addressId: address.id, userId: user.id),
                            a.defaultUpdated,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: addresses.isEmpty
          ? null
          : AccountBottomBar(
              child: AppButton(
                label: a.addAddress,
                leadingIcon: Icons.add_rounded,
                onPressed: () => showAddressFormSheet(context, userId: user.id),
              ),
            ),
    );
  }
}

/// One column on phones, two on wide screens (rows align at the top).
class _AddressList extends StatelessWidget {
  const _AddressList({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const pad = EdgeInsets.fromLTRB(
      AppSpacing.screenHorizontal,
      AppSpacing.lg,
      AppSpacing.screenHorizontal,
      AppSpacing.xl,
    );
    if (columns == 1) {
      return ListView.separated(
        padding: pad,
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, i) => children[i],
      );
    }
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: children[i]),
            const SizedBox(width: AppSpacing.md),
            Expanded(
                child: i + 1 < children.length
                    ? children[i + 1]
                    : const SizedBox.shrink()),
          ],
        ),
      ));
    }
    return ListView.separated(
      padding: pad,
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) => rows[i],
    );
  }
}
