import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/router/navigation_extensions.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../application/cart_notifier.dart';

class ViewCartBar extends ConsumerWidget {
  const ViewCartBar({super.key, this.safeArea = true});

  /// Pad for the system gesture area (false when a nav bar sits below).
  final bool safeArea;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartNotifierProvider.select((c) => c.totalItems));
    final total = ref.watch(cartNotifierProvider.select((c) => c.totalAmount));
    final p = context.palette;
    final s = context.s.customer;

    final bar = AnimatedSwitcher(
      duration: AppMotion.normal,
      switchInCurve: AppMotion.curve,
      transitionBuilder: (child, anim) =>
          SizeTransition(sizeFactor: anim, axisAlignment: -1, child: child),
      child: count == 0
          ? const SizedBox(width: double.infinity, key: ValueKey('empty'))
          : Padding(
              key: const ValueKey('bar'),
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
                  AppSpacing.sm, AppSpacing.screenHorizontal, AppSpacing.sm),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Semantics(
                    button: true,
                    label: s.viewCartSemantics(
                        count, AppFormat.money(context, total)),
                    excludeSemantics: true,
                    child: Material(
                      color: p.brand,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      elevation: context.isDark ? 0 : 3,
                      shadowColor: p.shadow,
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        onTap: () => context.pushOnce(RouteNames.cart),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 56),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.sm),
                            child: Row(
                              children: [
                                Container(
                                  constraints:
                                      const BoxConstraints(minWidth: 28),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: p.onBrand.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusXs),
                                  ),
                                  child: Text('$count',
                                      textAlign: TextAlign.center,
                                      style: AppTypography.labelMedium
                                          .copyWith(color: p.onBrand)),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        AppFormat.money(context, total),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.labelLarge
                                            .copyWith(color: p.onBrand),
                                      ),
                                      Text(
                                        '${s.itemsCount(count)} · ${s.plusDelivery}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.bodySmall.copyWith(
                                            color: p.onBrand
                                                .withValues(alpha: 0.85)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(s.viewCart,
                                    style: AppTypography.labelLarge
                                        .copyWith(color: p.onBrand)),
                                const SizedBox(width: AppSpacing.xs),
                                Icon(Icons.arrow_forward_rounded,
                                    size: 20, color: p.onBrand),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
    return safeArea && count > 0 ? SafeArea(top: false, child: bar) : bar;
  }
}
