import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/app_language.dart';
import '../../core/l10n/s.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// EN | ने switch.
class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key, this.onDark = false});

  /// Use light colours when placed over a dark image / brand background.
  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(languageNotifierProvider);
    final p = context.palette;
    final borderColor = onDark ? Colors.white.withValues(alpha: 0.5) : p.border;

    Widget segment(AppLanguage lang) {
      final selected = current == lang;
      final fg = selected
          ? (onDark ? AppColors.pineDeep : p.onBrand)
          : (onDark ? Colors.white : p.textSecondary);
      return Semantics(
        button: true,
        selected: selected,
        label: lang.nativeName,
        child: InkWell(
          onTap: selected
              ? null
              : () =>
                  ref.read(languageNotifierProvider.notifier).setLanguage(lang),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            constraints: const BoxConstraints(
                minWidth: 36, minHeight: 28, maxHeight: 28),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: selected
                  ? (onDark ? Colors.white : p.brand)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(lang.shortLabel,
                style: AppTypography.labelSmall
                    .copyWith(color: fg, fontSize: 12.5)),
          ),
        ),
      );
    }

    return Tooltip(
      message: context.s.common.switchLanguage,
      child: Container(
        height: 34,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [segment(AppLanguage.en), segment(AppLanguage.ne)],
        ),
      ),
    );
  }
}
