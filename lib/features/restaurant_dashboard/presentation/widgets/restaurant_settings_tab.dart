import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../application/owner_restaurant_provider.dart';
import '../../domain/models/owner_restaurant.dart';
import 'logout_button.dart';
import 'restaurant_details_form.dart';

/// Settings tab: edit the restaurant's public details, and log out.
class RestaurantSettingsTab extends ConsumerWidget {
  const RestaurantSettingsTab(
      {super.key, required this.restaurant, required this.ownerId});

  final OwnerRestaurant restaurant;
  final String ownerId;

  Future<bool> _save(
      BuildContext context, WidgetRef ref, RestaurantDetailsInput input) async {
    try {
      await ref
          .read(ownerRestaurantActionsProvider)
          .updateDetails(restaurant.id, input);
      ref.invalidate(ownerRestaurantProvider(ownerId));
      if (context.mounted) {
        AppSnackbar.success(context, context.s.restaurant.detailsSaved);
      }
      return true;
    } catch (e) {
      if (context.mounted) AppSnackbar.error(context, e);
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s.restaurant;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
          AppSpacing.lg, AppSpacing.screenHorizontal, AppSpacing.xxl),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.detailsTitle, style: context.text.h2),
              Text(s.detailsSubtitle, style: context.text.caption),
              const SizedBox(height: AppSpacing.xl),
              RestaurantDetailsForm(
                ownerId: ownerId,
                initial: restaurant,
                showOffer: true,
                submitLabel: context.s.common.saveChanges,
                onSubmit: (input) => _save(context, ref, input),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Align(
                alignment: Alignment.centerLeft,
                child: AppButton(
                  label: context.s.common.logout,
                  leadingIcon: Icons.logout_rounded,
                  variant: AppButtonVariant.text,
                  expand: false,
                  onPressed: () => confirmAndLogout(context, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
