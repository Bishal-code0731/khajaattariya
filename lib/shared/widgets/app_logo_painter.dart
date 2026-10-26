import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Draws the Khaja Attariya mark (also used by tool/generate_icons_test.dart).
class AppLogoPainter extends CustomPainter {
  const AppLogoPainter({this.tile = true});

  final bool tile;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final fill = Paint()..isAntiAlias = true;

    if (tile) {
      fill.color = AppColors.pine;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Offset.zero & Size.square(s), Radius.circular(s * 0.26)),
        fill,
      );
    }

    // Map pin: one teardrop — circle head joined by straight tangents to the tip.
    final c = Offset(s * 0.5, s * 0.42);
    final r = s * 0.27;
    final tip = Offset(s * 0.5, s * 0.865);
    final alpha = math.acos(r / (tip.dy - c.dy));
    final rightAngle = math.pi / 2 - alpha;
    final pin = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(c.dx + r * math.cos(rightAngle), c.dy + r * math.sin(rightAngle))
      ..arcTo(Rect.fromCircle(center: c, radius: r), rightAngle,
          -(2 * math.pi - 2 * alpha), false)
      ..close();
    fill.color = Colors.white;
    canvas.drawPath(pin, fill);

    // Bowl
    final bowlCenter = Offset(c.dx, c.dy + s * 0.015);
    final bowlR = s * 0.145;
    fill.color = AppColors.marigold;
    canvas.drawArc(Rect.fromCircle(center: bowlCenter, radius: bowlR), 0,
        math.pi, true, fill);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: bowlCenter, width: bowlR * 2.35, height: s * 0.035),
        Radius.circular(s * 0.02),
      ),
      fill,
    );

    // Steam
    final steam = Paint()
      ..color = AppColors.pine
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.03
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    for (final dx in [-0.055, 0.055]) {
      final x = c.dx + s * dx;
      final y0 = c.dy - s * 0.025;
      final path = Path()
        ..moveTo(x, y0)
        ..cubicTo(x - s * 0.035, y0 - s * 0.04, x + s * 0.035, y0 - s * 0.07, x,
            y0 - s * 0.115);
      canvas.drawPath(path, steam);
    }
  }

  @override
  bool shouldRepaint(covariant AppLogoPainter oldDelegate) =>
      oldDelegate.tile != tile;
}
