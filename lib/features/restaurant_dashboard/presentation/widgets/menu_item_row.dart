import 'package:flutter/material.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../domain/models/owner_menu_item.dart';
import 'veg_mark.dart';

class MenuItemRow extends StatelessWidget {
  const MenuItemRow({
    super.key,
    required this.item,
    required this.isAvailable,
    required this.busy,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final OwnerMenuItem item;

  /// Shown value (may be optimistic while saving).
  final bool isAvailable;
  final bool busy;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.restaurant;
    final c = context.s.common;
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final offer = item.offer?.trim() ?? '';

    return InkWell(
      onTap: busy ? null : onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Opacity(
              opacity: isAvailable ? 1 : 0.5,
              child: AppNetworkImage(
                url: item.imageUrl,
                width: 60,
                height: 60,
                fallbackIcon: Icons.ramen_dining_outlined,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      VegMark(isVeg: item.isVeg),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.label.copyWith(
                              color: isAvailable
                                  ? p.textPrimary
                                  : p.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(AppFormat.money(context, item.price),
                          style: context.text.price),
                      if (offer.isNotEmpty)
                        Text(offer,
                            style:
                                context.text.caption.copyWith(color: p.warning),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // One accessible node: "<dish> is available…" + the toggle.
            MergeSemantics(
              child: Semantics(
                label: s.availabilitySemantics(item.name, isAvailable),
                child: SizedBox(
                  width: 76,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (busy)
                        const SizedBox(
                            height: 40,
                            child: Center(child: AppLoader(size: 20)))
                      else
                        Switch(value: isAvailable, onChanged: onToggle),
                      ExcludeSemantics(
                        child: Text(
                          isAvailable ? s.available : s.hidden,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.caption.copyWith(
                              color: isAvailable ? p.success : p.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (wide) ...[
              IconButton(
                tooltip: s.editDish,
                icon: const Icon(Icons.edit_outlined),
                onPressed: busy ? null : onEdit,
              ),
              IconButton(
                tooltip: s.deleteDish,
                icon: Icon(Icons.delete_outline_rounded,
                    color: busy ? null : p.error),
                onPressed: busy ? null : onDelete,
              ),
            ] else
              PopupMenuButton<int>(
                tooltip: '${c.edit} / ${c.delete}',
                enabled: !busy,
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (v) => v == 0 ? onEdit() : onDelete(),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 0,
                    child: Row(children: [
                      const Icon(Icons.edit_outlined, size: 20),
                      const SizedBox(width: AppSpacing.md),
                      Text(s.editDish),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 1,
                    child: Row(children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 20, color: p.error),
                      const SizedBox(width: AppSpacing.md),
                      Text(s.deleteDish, style: TextStyle(color: p.error)),
                    ]),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
