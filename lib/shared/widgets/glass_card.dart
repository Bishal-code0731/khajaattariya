import 'package:flutter/material.dart';
import 'app_card.dart';

/// Legacy name kept so older screens compile.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.onTap,
    this.elevation,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final double? elevation;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: padding ?? EdgeInsets.zero,
        margin: margin,
        radius: borderRadius,
        onTap: onTap,
        elevated: (elevation ?? 0) > 0,
        child: child,
      );
}
