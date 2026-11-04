import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_language.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../../shared/widgets/app_logo.dart';

/// App version shown in About (matches pubspec `version`).
const appVersion = '1.0.0';

String themeModeLabel(BuildContext context, AppThemeMode mode) {
  final c = context.s.common;
  return switch (mode) {
    AppThemeMode.light => c.themeLight,
    AppThemeMode.dark => c.themeDark,
    AppThemeMode.system => c.themeSystem,
  };
}

Future<void> showLanguageSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => const _LanguageSheet(),
    );

Future<void> showAppearanceSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => const _AppearanceSheet(),
    );

Future<void> showAboutSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => const _AboutSheet(),
    );

class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(languageNotifierProvider);
    return _ChoiceList(
      title: context.s.account.chooseLanguage,
      children: [
        for (final lang in AppLanguage.values)
          _ChoiceRow(
            icon: Icons.translate_rounded,
            title: lang.nativeName,
            selected: lang == current,
            onTap: () {
              ref.read(languageNotifierProvider.notifier).setLanguage(lang);
              Navigator.of(context).pop();
            },
          ),
      ],
    );
  }
}

class _AppearanceSheet extends ConsumerWidget {
  const _AppearanceSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeNotifierProvider);
    return _ChoiceList(
      title: context.s.account.chooseAppearance,
      children: [
        for (final mode in AppThemeMode.values)
          _ChoiceRow(
            icon: switch (mode) {
              AppThemeMode.light => Icons.light_mode_outlined,
              AppThemeMode.dark => Icons.dark_mode_outlined,
              AppThemeMode.system => Icons.brightness_auto_outlined,
            },
            title: themeModeLabel(context, mode),
            subtitle: mode == AppThemeMode.system
                ? context.s.account.themeSystemHint
                : null,
            selected: mode == current,
            onTap: () {
              ref.read(themeNotifierProvider.notifier).setTheme(mode);
              Navigator.of(context).pop();
            },
          ),
      ],
    );
  }
}

class _ChoiceList extends StatelessWidget {
  const _ChoiceList({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(title, style: context.text.h2),
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Material(
          color: selected ? p.brandSoft : p.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: BorderSide(color: selected ? p.brand : p.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(icon,
                        color: selected ? p.onBrandSoft : p.textSecondary),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: context.text.label.copyWith(
                                  color: selected
                                      ? p.onBrandSoft
                                      : p.textPrimary)),
                          if (subtitle != null)
                            Text(subtitle!, style: context.text.caption),
                        ],
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: selected ? p.brand : p.textHint,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutSheet extends StatelessWidget {
  const _AboutSheet();

  @override
  Widget build(BuildContext context) {
    final a = context.s.account;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppLogo(size: 44, showTagline: true),
          const SizedBox(height: AppSpacing.xl),
          Text(a.aboutBody, style: context.text.bodyLarge),
          const SizedBox(height: AppSpacing.lg),
          Text(a.version(appVersion), style: context.text.caption),
        ],
      ),
    );
  }
}
