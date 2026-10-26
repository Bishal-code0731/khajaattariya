import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/s.dart';
import '../../core/network/connectivity_provider.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final p = context.palette;
    return AnimatedSize(
      duration: AppMotion.normal,
      child: isOnline
          ? const SizedBox(width: double.infinity)
          : Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                color: p.warningSoft,
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm, horizontal: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 16, color: p.warning),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(context.s.common.offlineBanner,
                          style: AppTypography.labelSmall
                              .copyWith(color: p.textPrimary)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
