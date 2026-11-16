import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class AuthStatusPanel extends StatelessWidget {
  const AuthStatusPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.hint,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String body;
  final String? hint;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: p.brandSoft,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Icon(icon, size: 32, color: p.onBrandSoft),
        ),
        const SizedBox(height: AppSpacing.xl),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(title, style: context.text.h1),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(body, style: context.text.bodyLarge),
        if (hint != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(hint!, style: context.text.secondary),
        ],
        const SizedBox(height: AppSpacing.xxl),
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          actions[i],
        ],
      ],
    );
  }
}
