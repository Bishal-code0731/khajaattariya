import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../application/owner_restaurant_provider.dart';
import '../../application/restaurant_registration_provider.dart';
import '../../domain/models/owner_restaurant.dart';
import 'logout_button.dart';
import 'restaurant_details_form.dart';

class RestaurantRegistrationView extends ConsumerWidget {
  const RestaurantRegistrationView({super.key, required this.ownerId});

  final String ownerId;

  Future<bool> _submit(
      BuildContext context, WidgetRef ref, RestaurantDetailsInput input) async {
    final notifier = ref.read(restaurantRegistrationProvider.notifier);
    final ok = await notifier.register(
      ownerId: ownerId,
      name: input.name,
      cuisineType: input.cuisineType,
      address: input.address,
      phone: input.phone,
      imageUrl: input.imageUrl,
      deliveryTimeMin: input.deliveryTimeMin,
    );
    if (!context.mounted) return ok;
    if (ok) {
      AppSnackbar.success(context, context.s.restaurant.registerSubmitted);
      ref.invalidate(ownerRestaurantProvider(ownerId));
    } else {
      AppSnackbar.error(
          context, ref.read(restaurantRegistrationProvider).error);
    }
    return ok;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s.restaurant;
    final form = RestaurantDetailsForm(
      ownerId: ownerId,
      submitLabel: s.registerSubmit,
      onSubmit: (input) => _submit(context, ref, input),
    );

    return Scaffold(
      appBar: AppTopBar(
        title: s.registerTitle,
        showBack: false,
        actions: const [LogoutButton()],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;
        if (wide) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.xxl, horizontal: AppSpacing.xl),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(flex: 4, child: _RegistrationIntro()),
                    const SizedBox(width: AppSpacing.xxxl),
                    Expanded(flex: 5, child: form),
                  ],
                ),
              ),
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
            AppSpacing.screenHorizontal,
            AppSpacing.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppSpacing.maxFormWidth + 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _RegistrationIntro(),
                  const SizedBox(height: AppSpacing.xl),
                  form,
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _RegistrationIntro extends StatelessWidget {
  const _RegistrationIntro();

  @override
  Widget build(BuildContext context) {
    final s = context.s.restaurant;
    final p = context.palette;
    final steps = [s.nextStep1, s.nextStep2, s.nextStep3];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.registerSubtitle, style: context.text.bodyLarge),
        const SizedBox(height: AppSpacing.xl),
        Text(s.nextStepsTitle.toUpperCase(), style: context.text.overline),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == 0 ? p.brand : p.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: context.text.label
                        .copyWith(color: i == 0 ? p.onBrand : p.textSecondary),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(steps[i], style: context.text.body),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
