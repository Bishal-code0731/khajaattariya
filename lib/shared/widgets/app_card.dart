import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.onTap,
    this.radius = AppSpacing.radiusLg,
    this.color,
    this.borderColor,
    this.elevated = false,
    this.clip = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double radius;
  final Color? color;
  final Color? borderColor;

  /// Adds a soft shadow (light mode).
  final bool elevated;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final borderRadius = BorderRadius.circular(radius);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor ?? p.border),
        boxShadow:
            elevated && !context.isDark ? AppShadows.card(p.shadow) : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        clipBehavior: clip ? Clip.antiAlias : Clip.none,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
