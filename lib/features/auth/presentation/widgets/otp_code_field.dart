import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Six boxes for a one-time code.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    required this.semanticLabel,
    this.length = 6,
    this.onCompleted,
    this.hasError = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String semanticLabel;
  final int length;
  final ValueChanged<String>? onCompleted;
  final bool hasError;
  final bool enabled;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _focus.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
    final text = widget.controller.text;
    if (text.length == widget.length) widget.onCompleted?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = widget.controller.text;

    final boxes = Row(
      children: [
        for (var i = 0; i < widget.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AnimatedContainer(
              duration: AppMotion.fast,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.enabled ? p.surface : p.surfaceAlt,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  width: _focus.hasFocus &&
                          i == text.length.clamp(0, widget.length - 1)
                      ? 1.8
                      : 1.2,
                  color: widget.hasError
                      ? p.error
                      : (_focus.hasFocus &&
                              i == text.length.clamp(0, widget.length - 1))
                          ? p.brand
                          : p.border,
                ),
              ),
              child: Text(
                i < text.length ? text[i] : '',
                style:
                    AppTypography.headingLarge.copyWith(color: p.textPrimary),
              ),
            ),
          ),
        ],
      ],
    );

    return Semantics(
      label: widget.semanticLabel,
      textField: true,
      child: Stack(
        children: [
          ExcludeSemantics(child: boxes),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                enabled: widget.enabled,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: widget.length,
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                decoration: const InputDecoration(
                    counterText: '', border: InputBorder.none, filled: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
