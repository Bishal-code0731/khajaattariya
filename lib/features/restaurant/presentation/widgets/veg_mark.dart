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
    final color = isVeg ? p.success : p.error;
    final s = context.s.customer;
    return Semantics(
      label: isVeg ? s.veg : s.nonVeg,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: p.surface,
          border: Border.all(color: color, width: 1.4),
          borderRadius: BorderRadius.circular(2),
        ),
        alignment: Alignment.center,
        child: isVeg
            ? Container(
                width: size * 0.45,
                height: size * 0.45,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              )
            : Icon(Icons.change_history_rounded,
                size: size * 0.7, color: color),
      ),
    );
  }
}
