import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_logo.dart';
import 'auth_scaffold.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= kAuthWideBreakpoint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!wide) ...[
          const AppLogoMark(size: 52),
          const SizedBox(height: AppSpacing.xl),
        ],
        Semantics(header: true, child: Text(title, style: context.text.h1)),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(subtitle!, style: context.text.secondary),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
