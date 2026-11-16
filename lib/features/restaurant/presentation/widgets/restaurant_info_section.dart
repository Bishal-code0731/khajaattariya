import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../home/domain/models/restaurant_model.dart';
import '../../../restaurant_hours/domain/models/restaurant_hours_model.dart';

/// "09:30" (as stored) → "9:30 AM" in the app language.
String formatHoursTime(BuildContext context, String hm) {
  final parts = hm.split(':');
  final h = int.tryParse(parts.first);
  final m = parts.length > 1 ? int.tryParse(parts[1]) : 0;
  if (h == null || m == null) return hm;
  final now = DateTime.now();
  return AppFormat.time(context, DateTime(now.year, now.month, now.day, h, m));
}

/// Address, phone (with a call button) and the weekly opening hours.
class RestaurantInfoSection extends StatelessWidget {
  const RestaurantInfoSection(
      {super.key, required this.restaurant, required this.hours});

  final RestaurantModel restaurant;

  /// null while loading or when hours could not be loaded.
  final List<RestaurantHoursModel>? hours;

  Future<void> _call(BuildContext context, String phone) async {
    final uri =
        Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), ''));
    final message = context.s.customer.callFailed;
    try {
      final ok = await launchUrl(uri);
      if (!ok && context.mounted) AppSnackbar.warning(context, message);
    } catch (_) {
      if (context.mounted) AppSnackbar.warning(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.customer;
    final address = restaurant.address?.trim() ?? '';
    final phone = restaurant.phone?.trim() ?? '';
    final today = DateTime.now().weekday;
    final locale = context.s.isNe ? 'ne' : 'en';

    Widget row(IconData icon, String label, String value,
            {bool muted = false, Widget? trailing}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: p.brandSoft,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                child: Icon(icon, size: 20, color: p.onBrandSoft),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: context.text.overline),
                    Text(value,
                        style: muted ? context.text.hint : context.text.body),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing
              ],
            ],
          ),
        );

    final sorted = [...?hours]..sort((a, b) => a.weekday.compareTo(b.weekday));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: s.infoTitle),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row(Icons.place_outlined, s.address,
                  address.isEmpty ? s.addressNotListed : address,
                  muted: address.isEmpty),
              row(
                Icons.call_outlined,
                s.phone,
                phone.isEmpty ? s.phoneNotListed : AppFormat.phone(phone),
                muted: phone.isEmpty,
                trailing: phone.isEmpty
                    ? null
                    : AppButton(
                        label: s.callRestaurant,
                        leadingIcon: Icons.call_rounded,
                        variant: AppButtonVariant.tonal,
                        size: AppButtonSize.small,
                        expand: false,
                        onPressed: () => _call(context, phone),
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(s.openingHours, style: context.text.label),
              const SizedBox(height: AppSpacing.xs),
              if (sorted.isEmpty)
                Text(s.hoursNotSet, style: context.text.hint)
              else
                for (final h in sorted)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxs + 1),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            h.weekday == today
                                ? '${_weekday(locale, h.weekday)} · ${s.today}'
                                : _weekday(locale, h.weekday),
                            style: h.weekday == today
                                ? context.text.label
                                : context.text.secondary,
                          ),
                        ),
                        Text(
                          (!h.isOpen ||
                                  h.openTime == null ||
                                  h.closeTime == null)
                              ? s.closed
                              : '${formatHoursTime(context, h.openTime!)} – ${formatHoursTime(context, h.closeTime!)}',
                          style: h.weekday == today
                              ? context.text.label
                              : context.text.secondary,
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  // weekday 1 = Monday; 2024-01-01 was a Monday.
  static String _weekday(String locale, int weekday) {
    try {
      return DateFormat.EEEE(locale)
          .format(DateTime(2024, 1, weekday.clamp(1, 7)));
    } catch (_) {
      return DateFormat.EEEE('en')
          .format(DateTime(2024, 1, weekday.clamp(1, 7)));
    }
  }
}
