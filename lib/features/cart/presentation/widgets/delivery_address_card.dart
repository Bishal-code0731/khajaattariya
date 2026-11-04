import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/router/navigation_extensions.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../address/application/address_provider.dart';
import '../../../address/domain/models/address_model.dart';

/// "Deliver to": pick one of the saved addresses or type another one.
class DeliveryAddressCard extends ConsumerWidget {
  const DeliveryAddressCard({
    super.key,
    required this.userId,
    required this.controller,
    required this.selectedId,
    required this.onSelect,
  });

  final String? userId;
  final TextEditingController controller;
  final String? selectedId;

  /// Called with the chosen saved address, or null for "type another".
  final ValueChanged<AddressModel?> onSelect;

  /// Text sent as the delivery address for a saved address.
  static String addressText(BuildContext context, AddressModel a) {
    final landmark = a.landmark?.trim() ?? '';
    return landmark.isEmpty
        ? a.fullAddress.trim()
        : '${a.fullAddress.trim()} (${context.s.customer.nearLandmark(landmark)})';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final s = context.s.customer;
    final saved = userId == null
        ? const <AddressModel>[]
        : (ref.watch(addressListProvider(userId!)).valueOrNull ??
            const <AddressModel>[]);
    final typing = selectedId == null || !saved.any((a) => a.id == selectedId);

    Widget option(
        {required bool selected,
        required String title,
        String? subtitle,
        required VoidCallback onTap,
        IconData icon = Icons.place_outlined,
        Widget? badge}) {
      return Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: selected ? p.brandSoft : null,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                  color: selected ? p.brand : p.border,
                  width: selected ? 1.4 : 1),
            ),
            child: Row(
              children: [
                Icon(icon,
                    size: 20,
                    color: selected ? p.onBrandSoft : p.textSecondary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.label.copyWith(
                                  color: selected ? p.onBrandSoft : null)),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          badge
                        ],
                      ]),
                      if (subtitle != null)
                        Text(subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.caption),
                    ],
                  ),
                ),
                Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: selected ? p.brand : p.textHint),
              ],
            ),
          ),
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(s.deliverTo, style: context.text.h3)),
              if (userId != null)
                TextButton(
                  onPressed: () => context.pushOnce(RouteNames.addressBook),
                  child: Text(s.manageAddresses),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final a in saved) ...[
            option(
              selected: !typing && a.id == selectedId,
              title: a.label,
              subtitle: addressText(context, a),
              icon: a.isDefault ? Icons.home_rounded : Icons.place_outlined,
              badge: a.isDefault
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: p.surfaceAlt,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXs),
                      ),
                      child:
                          Text(s.defaultAddress, style: context.text.overline),
                    )
                  : null,
              onTap: () => onSelect(a),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (saved.isNotEmpty)
            option(
              selected: typing,
              title: s.typeAnotherAddress,
              icon: Icons.edit_location_alt_outlined,
              onTap: () => onSelect(null),
            ),
          if (typing) ...[
            if (saved.isNotEmpty) const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: s.addressFieldLabel,
              hint: s.addressHint,
              helper: s.addressHelper,
              controller: controller,
              prefixIcon: Icons.place_outlined,
              keyboardType: TextInputType.streetAddress,
              textCapitalization: TextCapitalization.words,
              maxLines: 2,
              maxLength: 250,
              autofillHints: const [AutofillHints.fullStreetAddress],
              validator: context.validators.address,
            ),
          ],
        ],
      ),
    );
  }
}
