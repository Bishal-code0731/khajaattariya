import 'package:flutter/material.dart';

/// Khaja Attariya app icon mark: a steaming plate, in the app's own
/// warm red/gold palette — original to this app, not modeled on any
/// specific brand's icon.
///
/// [foregroundOnly] draws just the gold plate+steam mark on a
/// transparent background (for the Android adaptive-icon foreground
/// layer, whose background color is supplied separately). Otherwise
/// draws the full icon with the solid red background baked in (used
/// for iOS and the legacy Android icon).
class AppIconPainter extends CustomPainter {
  final bool foregroundOnly;

  const AppIconPainter({this.foregroundOnly = false});

  static const _red = Color(0xFFC0392B);
  static const _gold = Color(0xFFE8A33D);
  static const _cream = Color(0xFFF6DDB0);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (!foregroundOnly) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = _red);
    }

    // Adaptive icons crop ~33% off each edge in the safe zone, so the
    // foreground mark is scaled down and re-centered slightly lower
    // than the full-bleed version to stay clear of that crop.
    final scale = foregroundOnly ? 0.62 : 1.0;
    final centerY = foregroundOnly ? h * 0.52 : h * 0.56;

    final plateCenter = Offset(w * 0.5, centerY);
    final plateRadius = w * 0.26 * scale;

    canvas.drawCircle(
      plateCenter,
      plateRadius,
      Paint()
        ..color = _gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045 * scale,
    );
    canvas.drawCircle(plateCenter, plateRadius * 0.52, Paint()..color = _cream);

    final steamPaint = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035 * scale
      ..strokeCap = StrokeCap.round;

    for (final dx in [-0.13, 0.0, 0.13]) {
      final baseX = w * 0.5 + w * dx * scale;
      final baseY = centerY - plateRadius - h * 0.14 * scale;
      final path = Path()
        ..moveTo(baseX, baseY + h * 0.11 * scale)
        ..quadraticBezierTo(
          baseX - w * 0.045 * scale, baseY + h * 0.05 * scale,
          baseX, baseY,
        )
        ..quadraticBezierTo(
          baseX + w * 0.045 * scale, baseY - h * 0.05 * scale,
          baseX, baseY - h * 0.08 * scale,
        );
      canvas.drawPath(path, steamPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
