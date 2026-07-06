import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../orders/application/order_provider.dart';
import '../application/rating_provider.dart';

/// Bottom sheet letting a customer rate a delivered order.
/// Call [show] from order_detail_screen once the order is delivered
/// and hasn't been rated yet (see [orderRatingProvider]).
class RateOrderSheet extends ConsumerStatefulWidget {
  final String orderId;
  final String customerId;
  final String restaurantId;
  final String restaurantName;

  const RateOrderSheet({
    super.key,
    required this.orderId,
    required this.customerId,
    required this.restaurantId,
    required this.restaurantName,
  });

  static Future<void> show(
    BuildContext context, {
    required String orderId,
    required String customerId,
    required String restaurantId,
    required String restaurantName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RateOrderSheet(
        orderId: orderId,
        customerId: customerId,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
      ),
    );
  }

  @override
  ConsumerState<RateOrderSheet> createState() => _RateOrderSheetState();
}

class _RateOrderSheetState extends ConsumerState<RateOrderSheet> {
  int _rating = 5;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final ok = await ref.read(ratingNotifierProvider.notifier).submitRating(
          orderId: widget.orderId,
          customerId: widget.customerId,
          restaurantId: widget.restaurantId,
          rating: _rating,
          review: _reviewController.text.trim().isEmpty
              ? null
              : _reviewController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (ok) {
      ref.invalidate(orderRatingProvider(widget.orderId));
      ref.invalidate(restaurantRatingsProvider(widget.restaurantId));
      Navigator.of(context).pop();
      AppSnackbar.success(context, 'Thanks for your review!');
    } else {
      AppSnackbar.error(context, 'Could not submit your review. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Rate ${widget.restaurantName}', style: AppTypography.headingMedium),
            const SizedBox(height: AppSpacing.sm),
            Text('How was your food and delivery?', style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starIndex = i + 1;
                return IconButton(
                  onPressed: () => setState(() => _rating = starIndex),
                  icon: Icon(
                    starIndex <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.accent,
                    size: 36,
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _reviewController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Share more about your experience (optional)',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Submit Review',
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
