import 'package:flutter/material.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class AdminFilterOption<T> {
  const AdminFilterOption(this.value, this.label, {this.count});
  final T value;
  final String label;
  final int? count;
}

/// One-line, horizontally scrolling row of filter chips with counts.
class AdminFilterBar<T> extends StatelessWidget {
  const AdminFilterBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.padding =
        const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
  });

  final List<AdminFilterOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final o = options[i];
          final isSelected = o.value == selected;
          return Center(
            child: ChoiceChip(
              selected: isSelected,
              onSelected: (_) => onSelected(o.value),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(o.label,
                      style: AppTypography.labelMedium.copyWith(
                          color: isSelected ? p.onBrandSoft : p.textPrimary)),
                  if (o.count != null) ...[
                    const SizedBox(width: 6),
                    Text('${o.count}',
                        style: AppTypography.labelSmall.copyWith(
                            color:
                                isSelected ? p.onBrandSoft : p.textSecondary)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
