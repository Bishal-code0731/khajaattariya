import 'package:flutter/material.dart';
import '../../core/router/navigation_extensions.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'language_toggle.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.showBack,
    this.onBack,
    this.bottom,
    this.showLanguageToggle = true,
    this.leading,
    this.centerTitle = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  /// null = automatic (shown when the route can pop).
  final bool? showBack;
  final VoidCallback? onBack;
  final PreferredSizeWidget? bottom;
  final bool showLanguageToggle;
  final Widget? leading;
  final bool centerTitle;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + 4 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final canPop = Navigator.of(context).canPop();
    final back = showBack ?? canPop;
    return AppBar(
      toolbarHeight: kToolbarHeight + 4,
      automaticallyImplyLeading: false,
      centerTitle: centerTitle,
      titleSpacing: back || leading != null ? 0 : AppSpacing.lg,
      leading: leading ??
          (back
              ? IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: onBack ?? () => context.safeBack(),
                )
              : null),
      title: Column(
        crossAxisAlignment:
            centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTypography.headingMedium.copyWith(color: p.textPrimary)),
          if (subtitle != null)
            Text(subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    AppTypography.bodySmall.copyWith(color: p.textSecondary)),
        ],
      ),
      actions: [
        ...actions,
        if (showLanguageToggle)
          const Padding(
            padding: EdgeInsets.only(left: AppSpacing.xs, right: AppSpacing.md),
            child: Center(child: LanguageToggle()),
          ),
      ],
      bottom: bottom,
    );
  }
}
