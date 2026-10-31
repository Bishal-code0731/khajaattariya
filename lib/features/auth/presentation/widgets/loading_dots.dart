import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Three softly pulsing dots ("loading…").
class LoadingDots extends StatefulWidget {
  const LoadingDots(
      {super.key, required this.color, this.size = 9, this.semanticLabel});

  final Color color;
  final double size;
  final String? semanticLabel;

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    Widget dot(double t) {
      // Each dot rises and brightens in turn.
      final wave = reduceMotion ? 0.5 : (math.sin((t * 2 * math.pi)) + 1) / 2;
      return Transform.translate(
        offset: Offset(0, -wave * widget.size * 0.6),
        child: Container(
          width: widget.size,
          height: widget.size,
          margin: EdgeInsets.symmetric(horizontal: widget.size * 0.45),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.35 + 0.65 * wave),
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    return Semantics(
      label: widget.semanticLabel,
      child: SizedBox(
        height: widget.size * 2,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [for (var i = 0; i < 3; i++) dot(_c.value - i * 0.18)],
          ),
        ),
      ),
    );
  }
}
