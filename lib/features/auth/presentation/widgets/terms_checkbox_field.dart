import 'package:flutter/material.dart';

import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class TermsCheckboxField extends FormField<bool> {
  TermsCheckboxField({super.key, required String? Function(bool?) validator})
      : super(
          initialValue: false,
          validator: validator,
          builder: (state) => _TermsCheckbox(state: state),
        );
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.state});

  final FormFieldState<bool> state;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final checked = state.value ?? false;
    void toggle() {
      state.didChange(!checked);
      // Clear a shown error as soon as the box is ticked.
      if (state.hasError) state.validate();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MergeSemantics(
          child: InkWell(
            onTap: toggle,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Checkbox(
                    value: checked,
                    onChanged: (_) => toggle(),
                    activeColor: p.brand,
                    checkColor: p.onBrand,
                    side: BorderSide(
                        color: state.hasError ? p.error : p.textHint,
                        width: 1.5),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                      child: Text(context.s.auth.termsAgree,
                          style: context.text.body)),
                ],
              ),
            ),
          ),
        ),
        if (state.hasError)
          Padding(
            padding:
                const EdgeInsets.only(left: AppSpacing.md, top: AppSpacing.xxs),
            child: Semantics(
              liveRegion: true,
              child: Text(
                state.errorText ?? '',
                style: context.text.caption.copyWith(color: p.error),
              ),
            ),
          ),
      ],
    );
  }
}
