import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'app_icon_painter.dart';

/// Not a real test — a one-off tool that renders AppIconPainter to
/// real PNG files at 1024x1024, run via `flutter test` because that's
/// the only place in this project with a Flutter engine available to
/// rasterize a CustomPainter to pixels. Run once with:
///   flutter test test/icon_export/export_icon_test.dart
void main() {
  testWidgets('export app icon PNGs', (tester) async {
    await _export(tester, foregroundOnly: false, path: 'assets/icon/app_icon_master.png');
    await _export(tester, foregroundOnly: true, path: 'assets/icon/app_icon_foreground.png');
  });
}

Future<void> _export(
  WidgetTester tester, {
  required bool foregroundOnly,
  required String path,
}) async {
  const size = 1024.0;
  final key = GlobalKey();

  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: AppIconPainter(foregroundOnly: foregroundOnly)),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // toImage()/toByteData() and real file I/O need the real event loop,
  // not the fake-async zone widget tests normally run in.
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    final file = File(path);
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}
