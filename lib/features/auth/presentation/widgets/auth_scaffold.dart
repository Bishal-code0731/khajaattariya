import 'package:flutter/material.dart';

import '../../../../core/router/navigation_extensions.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/language_toggle.dart';
import 'auth_brand_panel.dart';

/// Width from which auth screens show the brand panel beside the form.
const double kAuthWideBreakpoint = 1000;

class AuthScaffold extends StatelessWidget {
  const AuthScaffold(
      {super.key, required this.child, this.showBack, this.onBack});

  final Widget child;

  /// null = show the back button only when the route can pop.
  final bool? showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final canPop = Navigator.of(context).canPop();
    final back = showBack ?? canPop;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= kAuthWideBreakpoint;
        final form = SafeArea(
          left: !wide,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      if (back)
                        IconButton(
                          tooltip: MaterialLocalizations.of(context)
                              .backButtonTooltip,
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: p.textPrimary,
                          onPressed: onBack ?? () => context.safeBack(),
                        ),
                      const Spacer(),
                      const Padding(
                        padding: EdgeInsets.only(right: AppSpacing.sm),
                        child: LanguageToggle(),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal,
                      AppSpacing.sm,
                      AppSpacing.screenHorizontal,
                      AppSpacing.xxl,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          minHeight:
                              box.maxHeight - AppSpacing.xxl - AppSpacing.sm),
                      child: Align(
                        alignment:
                            wide ? Alignment.center : Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                              maxWidth: AppSpacing.maxFormWidth),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        return Scaffold(
          backgroundColor: p.background,
          body: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Expanded(flex: 5, child: AuthBrandPanel()),
                    Expanded(flex: 6, child: form),
                  ],
                )
              : form,
        );
      },
    );
  }
}
