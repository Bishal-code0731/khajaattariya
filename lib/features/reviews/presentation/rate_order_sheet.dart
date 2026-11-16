import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/s.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../orders/application/order_provider.dart';
import '../application/rating_provider.dart';

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
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
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
  static const _maxReview = 1000;

  final _formKey = GlobalKey<FormState>();
  final _reviewController = TextEditingController();
  final _tags = <String>{};
  int _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  String? _composeReview() {
    final typed = _reviewController.text.trim();
    final tagLine = _tags.join(' · ');
    final parts = [
      if (tagLine.isNotEmpty) tagLine,
      if (typed.isNotEmpty) typed
    ];
    if (parts.isEmpty) return null;
    final review = parts.join('\n');
    return review.length > _maxReview
        ? review.substring(0, _maxReview)
        : review;
  }

  Future<void> _submit() async {
    final o = context.s.orders;
    if (_isSubmitting) return;
    if (_rating == 0) {
      AppSnackbar.warning(context, o.pickRatingFirst);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    final ok = await ref.read(ratingNotifierProvider.notifier).submitRating(
          orderId: widget.orderId,
          customerId: widget.customerId,
          restaurantId: widget.restaurantId,
          rating: _rating,
          review: _composeReview(),
        );
    if (!mounted) return;
    if (ok) {
      ref.invalidate(orderRatingProvider(widget.orderId));
      ref.invalidate(restaurantRatingsProvider(widget.restaurantId));
      Navigator.of(context).pop();
      AppSnackbar.success(context, o.ratingThanks);
      return;
    }
    final error = ref.read(ratingNotifierProvider).error;
    // One rating per order: if it already exists, say so plainly.
    var alreadyRated = false;
    try {
      alreadyRated =
          await ref.refresh(orderRatingProvider(widget.orderId).future);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (alreadyRated) {
      Navigator.of(context).pop();
      AppSnackbar.info(context, o.alreadyRated);
    } else {
      AppSnackbar.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.text;
    final o = context.s.orders;
    final words = [o.rating1, o.rating2, o.rating3, o.rating4, o.rating5];
    final tags = [
      o.tagTasty,
      o.tagFresh,
      o.tagPortion,
      o.tagPacking,
      o.tagFast,
      o.tagRider,
    ];

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(o.rateTitle(widget.restaurantName), style: text.h2),
              const SizedBox(height: AppSpacing.xs),
              Text(o.rateSubtitle, style: text.secondary),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Semantics(
                        button: true,
                        selected: i == _rating,
                        label: o.starLabel(i),
                        excludeSemantics: true,
                        child: IconButton(
                          tooltip: o.starLabel(i),
                          iconSize: 40,
                          constraints:
                              const BoxConstraints(minWidth: 52, minHeight: 52),
                          onPressed: _isSubmitting
                              ? null
                              : () => setState(() => _rating = i),
                          icon: Icon(
                            i <= _rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: i <= _rating ? p.accent : p.textHint,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: Text(
                    _rating == 0 ? o.tapToRate : words[_rating - 1],
                    key: ValueKey(_rating),
                    style: _rating == 0
                        ? text.hint
                        : AppTypography.labelLarge
                            .copyWith(color: p.textPrimary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(o.tagsTitle, style: text.label),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final tag in tags)
                    FilterChip(
                      label: Text(tag),
                      selected: _tags.contains(tag),
                      showCheckmark: false,
                      labelStyle: AppTypography.labelMedium.copyWith(
                        color:
                            _tags.contains(tag) ? p.onBrandSoft : p.textPrimary,
                      ),
                      selectedColor: p.brandSoft,
                      backgroundColor: p.surface,
                      side: BorderSide(
                        color: _tags.contains(tag) ? p.brand : p.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      onSelected: _isSubmitting
                          ? null
                          : (on) => setState(
                              () => on ? _tags.add(tag) : _tags.remove(tag)),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                label: o.reviewField,
                hint: o.reviewHint,
                controller: _reviewController,
                maxLines: 3,
                maxLength: _maxReview,
                textInputAction: TextInputAction.newline,
                validator: context.validators
                    .text(o.reviewField, max: _maxReview, optional: true),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: o.submitRating,
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
