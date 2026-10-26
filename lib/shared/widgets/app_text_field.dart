import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Labelled text field used in every form.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.helper,
    this.controller,
    this.initialValue,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.suffix,
    this.isPassword = false,
    this.enabled = true,
    this.readOnly = false,
    this.validator,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.autofillHints,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.focusNode,
    this.showToggleTooltip,
    this.hideToggleTooltip,
  });

  final String label;
  final String? hint;
  final String? helper;
  final TextEditingController? controller;
  final String? initialValue;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool isPassword;
  final bool enabled;
  final bool readOnly;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? showToggleTooltip;
  final String? hideToggleTooltip;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final w = widget;

    Widget? suffix = w.suffix;
    if (w.isPassword) {
      suffix = IconButton(
        tooltip: _obscure
            ? (w.showToggleTooltip ?? 'Show password')
            : (w.hideToggleTooltip ?? 'Hide password'),
        icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20),
        onPressed: () => setState(() => _obscure = !_obscure),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2, left: 2),
          child: Text(
            w.label,
            style: AppTypography.labelMedium
                .copyWith(color: w.enabled ? p.textPrimary : p.textHint),
          ),
        ),
        TextFormField(
          controller: w.controller,
          initialValue: w.controller == null ? w.initialValue : null,
          focusNode: w.focusNode,
          keyboardType:
              w.isPassword ? TextInputType.visiblePassword : w.keyboardType,
          textInputAction: w.textInputAction ??
              (w.maxLines > 1 ? TextInputAction.newline : TextInputAction.next),
          obscureText: w.isPassword && _obscure,
          enableSuggestions: !w.isPassword,
          autocorrect: !w.isPassword,
          enabled: w.enabled,
          readOnly: w.readOnly,
          autofocus: w.autofocus,
          validator: w.validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          maxLines: w.isPassword ? 1 : w.maxLines,
          minLines: w.minLines,
          maxLength: w.maxLength,
          onChanged: w.onChanged,
          onFieldSubmitted: w.onSubmitted,
          onTap: w.onTap,
          autofillHints: w.autofillHints,
          inputFormatters: w.inputFormatters,
          textCapitalization: w.textCapitalization,
          style: AppTypography.bodyLarge
              .copyWith(color: w.enabled ? p.textPrimary : p.textHint),
          cursorColor: p.brand,
          decoration: InputDecoration(
            hintText: w.hint,
            helperText: w.helper,
            helperMaxLines: 2,
            errorMaxLines: 3,
            counterText: w.maxLength != null && w.maxLines > 1 ? null : '',
            prefixIcon:
                w.prefixIcon != null ? Icon(w.prefixIcon, size: 20) : null,
            suffixIcon: suffix,
            fillColor: w.enabled ? p.surface : p.surfaceAlt,
          ),
        ),
      ],
    );
  }
}

/// Rounded search box (home, search, menus, admin lists).
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
    this.onClear,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final bool readOnly;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      readOnly: readOnly,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      style: AppTypography.bodyLarge.copyWith(color: p.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: onClear),
        fillColor: p.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          borderSide: BorderSide(color: p.brand, width: 1.4),
        ),
      ),
    );
  }
}
