import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';

/// Spinner for small inline waits.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.size = 28, this.color});

  const factory AppLoader.fullscreen({Key? key}) = _FullscreenLoader;
  const factory AppLoader.button({Key? key, Color? color}) = _ButtonLoader;

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
            strokeWidth: 2.6, color: color ?? context.palette.brand),
      );
}

class _FullscreenLoader extends AppLoader {
  const _FullscreenLoader({super.key}) : super(size: 30);

  @override
  Widget build(BuildContext context) => Center(child: super.build(context));
}

class _ButtonLoader extends AppLoader {
  const _ButtonLoader({super.key, super.color}) : super(size: 18);

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: color ?? context.palette.onBrand),
      );
}
