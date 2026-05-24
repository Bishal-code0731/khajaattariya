import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/restaurant_provider.dart';
import '../../domain/models/category_model.dart';

class CategorySection extends ConsumerStatefulWidget {
  final Function(CategoryModel?) onCategorySelected;

  const CategorySection({
    super.key,
    required this.onCategorySelected,
  });

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
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: const Text('Categories', style: AppTypography.headingSmall),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 90,
          child: categoriesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (categories) => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedId == category.id;
                return _CategoryChip(
                  category: category,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      if (_selectedId == category.id) {
                        _selectedId = null;
                        widget.onCategorySelected(null);
                      } else {
                        _selectedId = category.id;
                        widget.onCategorySelected(category);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final CategoryModel category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  category.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              category.name,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}