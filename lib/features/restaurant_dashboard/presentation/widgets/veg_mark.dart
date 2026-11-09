import 'package:flutter/material.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';

class VegMark extends StatelessWidget {
  const VegMark({super.key, required this.isVeg, this.size = 14});

  final bool isVeg;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.restaurant;
    final color = isVeg ? p.success : p.error;
    final label = isVeg ? s.veg : s.nonVeg;
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: color, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Container(
            width: size * 0.45,
            height: size * 0.45,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
