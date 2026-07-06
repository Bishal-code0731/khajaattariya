import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Standard loading spinner. Replaces the 39+ ad-hoc
/// `CircularProgressIndicator()` calls scattered across screens.
class AppLoader extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLoader({super.key, this.size = 32, this.color});

  /// A loader centered to fill available space — the common
  /// `Center(child: CircularProgressIndicator())` pattern.
  const factory AppLoader.fullscreen({Key? key}) = _FullscreenLoader;

  /// A small inline loader for buttons (e.g. AppButton's own spinner).
  const factory AppLoader.button({Key? key, Color? color}) = _ButtonLoader;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: color ?? AppColors.primary,
      ),
    );
  }
}

class _FullscreenLoader extends AppLoader {
  const _FullscreenLoader({super.key}) : super(size: 32);

  @override
  Widget build(BuildContext context) => Center(child: super.build(context));
}

class _ButtonLoader extends AppLoader {
  const _ButtonLoader({super.key, super.color}) : super(size: 18);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: 2, color: color ?? AppColors.white),
    );
  }
}
