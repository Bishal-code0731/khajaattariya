import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Shown when go_router can't match a route (bad/typo'd deep link,
/// stale push-notification payload, etc). Replaces the old raw
/// "Page not found: <error>" text screen that had no way back.
class RouteErrorScreen extends StatelessWidget {
  final String? details;

  const RouteErrorScreen({super.key, this.details});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wrong_location_rounded, size: 64, color: AppColors.textHint),
                const SizedBox(height: AppSpacing.lg),
                Text('Page not found', style: AppTypography.headingMedium, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  "The link you followed doesn't exist or may have moved.",
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton.icon(
                  onPressed: () => context.go(RouteNames.home),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Go to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}