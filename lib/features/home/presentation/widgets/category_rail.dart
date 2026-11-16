import 'package:flutter/material.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../../domain/models/category_model.dart';
import 'category_icon.dart';

/// Horizontal row of round category buttons ("Momo", "Thali", …).
class CategoryRail extends StatelessWidget {
  const CategoryRail({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CategoryModel> categories;
  final String? selectedId;
  final ValueChanged<CategoryModel?> onSelected;

  static double heightFor(BuildContext context) =>
      64 +
      MediaQuery.textScalerOf(context)
              .scale(AppTypography.labelSmall.fontSize ?? 12) *
          2.6 +
      AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: heightFor(context),
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final selected = cat.id == selectedId;
          return _CategoryButton(
            category: cat,
            selected: selected,
            onTap: () => onSelected(selected ? null : cat),
          );
        },
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton(
      {required this.category, required this.selected, required this.onTap});

  final CategoryModel category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: category.name,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: SizedBox(
          width: 76,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xs),
              AnimatedContainer(
                duration: AppMotion.fast,
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: selected ? p.brand : p.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? p.brand : p.border),
                ),
                child: Icon(
                  categoryIcon(category.name, iconName: category.iconName),
                  size: 26,
                  color: selected ? p.onBrand : p.brand,
                ),
              ),
              const SizedBox(height: AppSpacing.xs + 2),
              Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.labelSmall.copyWith(
                  color: selected ? p.brand : p.textPrimary,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for [CategoryRail] while categories load.
class CategoryRailSkeleton extends StatelessWidget {
  const CategoryRailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CategoryRail.heightFor(context),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (_, __) => SizedBox(
          width: 76,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xs),
              AppShimmer(
                  width: 56,
                  height: 56,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull)),
              const SizedBox(height: AppSpacing.sm),
              const AppShimmer(width: 48, height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
