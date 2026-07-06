import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/connectivity_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Slim strip shown above a screen's content when the device is
/// offline. Collapses to nothing (zero height) when online, so it never
/// pushes the surrounding UI's layout around beyond what it needs.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: isOnline
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              color: AppColors.warning,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 14, color: AppColors.white),
                  const SizedBox(width: 6),
                  Text(
                    "You're offline — showing saved data",
                    style: AppTypography.labelSmall.copyWith(color: AppColors.white),
                  ),
                ],
              ),
            ),
    );
  }
}
