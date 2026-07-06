import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/restaurant_provider.dart';
import '../../domain/models/category_model.dart';

class CategorySection extends ConsumerStatefulWidget {
  final ValueChanged<CategoryModel?> onCategorySelected;

  const CategorySection({super.key, required this.onCategorySelected});

  @override
  ConsumerState<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends ConsumerState<CategorySection> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
          child: Text('Categories', style: AppTypography.headingSmall),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 80,
          child: categoriesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (categories) => ListView.separated(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = _selectedId == cat.id;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedId = isSelected ? null : cat.id;
                    });
                    widget.onCategorySelected(isSelected ? null : cat);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 70,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.06),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          cat.iconEmoji ?? '🍽️',
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cat.name,
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected
                                ? AppColors.white
                                : AppColors.textPrimary,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
