import 'package:flutter/material.dart';
import '../../../../core/constants/dummy_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/category_model.dart';

// Horizontal scrollable row of food categories.
// Momo, Thali, Chowmein, Pizza, Burger etc.
// Tapping a category filters the restaurants and food items.

class CategorySection extends StatefulWidget {
  final Function(CategoryModel?) onCategorySelected;

  const CategorySection({
    super.key,
    required this.onCategorySelected,
  });

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection> {
  // Tracks which category is currently selected.
  // null means "All" — no filter applied.
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: const Text('Categories', style: AppTypography.headingSmall),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Horizontal scrollable list
        SizedBox(
          height: 90,
          child: ListView.builder(
            // Horizontal scroll direction
            scrollDirection: Axis.horizontal,
            // Padding on left and right of the whole list
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            itemCount: DummyData.categories.length,
            itemBuilder: (context, index) {
              final category = DummyData.categories[index];
              final isSelected = _selectedId == category.id;

              return _CategoryChip(
                category: category,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    // If already selected, deselect it (show all)
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
      ],
    );
  }
}

// A single category chip
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
            // Icon circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                // Selected = red background, unselected = light surface
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
            // Category name
            Text(
              category.name,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}