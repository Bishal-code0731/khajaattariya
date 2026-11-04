import 'package:flutter/material.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/rating_badge.dart';
import '../../../home/domain/models/restaurant_model.dart';
import '../../../home/presentation/widgets/restaurant_card.dart';
import '../../../restaurant_hours/domain/models/restaurant_hours_model.dart';
import 'restaurant_info_section.dart';

class RestaurantInfoHeader extends StatelessWidget {
  const RestaurantInfoHeader(
      {super.key, required this.restaurant, this.today, this.onRatingTap});

  final RestaurantModel restaurant;

  /// Today's opening hours row, when the restaurant has set them.
  final RestaurantHoursModel? today;
  final VoidCallback? onRatingTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.customer;
    final r = restaurant;

    String? hoursText;
    final t = today;
    if (t != null) {
      hoursText = (!t.isOpen || t.openTime == null || t.closeTime == null)
          ? s.closedToday
          : s.todayHours(formatHoursTime(context, t.openTime!),
              formatHoursTime(context, t.closeTime!));
    }
    final statusColor = r.isOpen ? p.success : p.error;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
          AppSpacing.lg, AppSpacing.screenHorizontal, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(r.name, style: context.text.h1)),
          if (r.cuisineType.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(r.cuisineType, style: context.text.secondary),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                button: onRatingTap != null,
                label: r.reviewCount > 0
                    ? s.ratingSemantics(
                        r.rating.toStringAsFixed(1), r.reviewCount)
                    : s.newRestaurant,
                excludeSemantics: true,
                child: InkWell(
                  onTap: onRatingTap,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  child: RatingBadge(
                      rating: r.rating,
                      count: r.reviewCount,
                      newLabel: s.newRestaurant),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delivery_dining_rounded, size: 18, color: p.brand),
                  const SizedBox(width: AppSpacing.xs),
                  Text(restaurantInfoLine(context, r),
                      style: context.text.label),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(r.isOpen ? Icons.circle : Icons.do_not_disturb_on_rounded,
                  size: 10, color: statusColor),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: r.isOpen ? s.openNow : s.closedNow,
                      style: AppTypography.labelMedium
                          .copyWith(color: statusColor),
                    ),
                    if (hoursText != null)
                      TextSpan(
                          text: '  ·  $hoursText', style: context.text.caption),
                  ]),
                ),
              ),
            ],
          ),
          if (r.hasOffer) ...[
            const SizedBox(height: AppSpacing.md),
            _Notice(
                icon: Icons.local_offer_rounded,
                text: r.offer!.trim(),
                bg: p.accentSoft,
                fg: p.textPrimary,
                iconColor: p.accent),
          ],
          if (!r.isOpen) ...[
            const SizedBox(height: AppSpacing.md),
            _Notice(
                icon: Icons.schedule_rounded,
                text: s.closedNotice,
                bg: p.warningSoft,
                fg: p.textPrimary,
                iconColor: p.warning),
          ],
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(
      {required this.icon,
      required this.text,
      required this.bg,
      required this.fg,
      required this.iconColor});

  final IconData icon;
  final String text;
  final Color bg;
  final Color fg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
              child: Text(text,
                  style: AppTypography.labelMedium.copyWith(color: fg))),
        ],
      ),
    );
  }
}
