import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// "Nothing here yet" — always say what the user can do next ([action]).
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: compact ? 64 : 88,
                height: compact ? 64 : 88,
                decoration:
                    BoxDecoration(color: p.brandSoft, shape: BoxShape.circle),
                child:
                    Icon(icon, size: compact ? 30 : 40, color: p.onBrandSoft),
              ),
              SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
              Text(title,
                  style: AppTypography.headingMedium
                      .copyWith(color: p.textPrimary),
                  textAlign: TextAlign.center),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(subtitle!,
                    style: AppTypography.bodyMedium
                        .copyWith(color: p.textSecondary),
                    textAlign: TextAlign.center),
              ],
              if (action != null) ...[
                const SizedBox(height: AppSpacing.xl),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
