import 'package:flutter/material.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/quantity_stepper.dart';
import '../../../home/domain/models/food_item_model.dart';
import 'veg_mark.dart';

class MenuItemTile extends StatelessWidget {
  const MenuItemTile({
    super.key,
    required this.item,
    required this.quantity,
    required this.canOrder,
    required this.onAdd,
    required this.onRemove,
  });

  final FoodItemModel item;
  final int quantity;

  /// False when the restaurant is closed.
  final bool canOrder;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  static const _photo = AppSpacing.menuItemImageSize;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.customer;
    final available = item.isAvailable;
    final hasPhoto = item.imageUrl.trim().isNotEmpty;
    final description = item.description?.trim() ?? '';
    final offer = item.offer?.trim() ?? '';
    final showStepper = available && (canOrder || quantity > 0);

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VegMark(isVeg: item.isVeg),
        const SizedBox(height: AppSpacing.xs),
        Text(item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.h3),
        const SizedBox(height: AppSpacing.xxs),
        Text(AppFormat.money(context, item.price), style: context.text.price),
        if (offer.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(Icons.local_offer_rounded, size: 14, color: p.accent),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(offer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall
                        .copyWith(color: p.textPrimary)),
              ),
            ],
          ),
        ],
        if (description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.caption),
        ],
      ],
    );

    final control = !available
        ? Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
            decoration: BoxDecoration(
              color: p.surfaceAlt,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: p.border),
            ),
            child: Text(s.soldOut, style: context.text.labelSecondary),
          )
        : showStepper
            ? QuantityStepper(
                quantity: quantity,
                addLabel: s.add,
                onIncrement: onAdd,
                onDecrement: onRemove)
            : null;

    return Opacity(
      opacity: available ? 1 : 0.55,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: details),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: _photo + 12,
              height: hasPhoto ? _photo + 18 : null,
              child: hasPhoto
                  ? Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        AppNetworkImage(
                          url: item.imageUrl,
                          width: _photo,
                          height: _photo,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          fallbackIcon: Icons.fastfood_rounded,
                        ),
                        if (control != null)
                          Positioned(bottom: 0, child: control),
                      ],
                    )
                  : (control == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xl),
                          child: Center(child: control),
                        )),
            ),
          ],
        ),
      ),
    );
  }
}
