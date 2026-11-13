// Generates every app/launcher/web icon from the logo painter.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaja_attariya/core/theme/app_colors.dart';
import 'package:khaja_attariya/shared/widgets/app_logo_painter.dart';

enum _Style {
  /// Pine rounded tile (Android legacy, web).
  tile,

  /// Full-bleed square, no transparency (iOS masks the corners itself).
  square,

  /// Full-bleed with extra padding so the mark survives circular masks (maskable).
  maskable,
}

Future<void> _render(String path, int size, _Style style) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final s = size.toDouble();

  if (style == _Style.tile) {
    const AppLogoPainter().paint(canvas, Size.square(s));
  } else {
    canvas.drawRect(Rect.fromLTWH(0, 0, s, s), Paint()..color = AppColors.pine);
    final scale = style == _Style.maskable ? 0.72 : 0.92;
    final inset = s * (1 - scale) / 2;
    canvas.save();
    canvas.translate(inset, inset);
    const AppLogoPainter(tile: false).paint(canvas, Size.square(s * scale));
    canvas.restore();
  }

  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('generate icons', () async {
    await _render('assets/icon/app_icon_master.png', 1024, _Style.tile);

    const android = {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192
    };
    for (final e in android.entries) {
      await _render('android/app/src/main/res/mipmap-${e.key}/ic_launcher.png',
          e.value, _Style.tile);
    }

    const ios = {
      'Icon-App-20x20@1x.png': 20,
      'Icon-App-20x20@2x.png': 40,
      'Icon-App-20x20@3x.png': 60,
      'Icon-App-29x29@1x.png': 29,
      'Icon-App-29x29@2x.png': 58,
      'Icon-App-29x29@3x.png': 87,
      'Icon-App-40x40@1x.png': 40,
      'Icon-App-40x40@2x.png': 80,
      'Icon-App-40x40@3x.png': 120,
      'Icon-App-60x60@2x.png': 120,
      'Icon-App-60x60@3x.png': 180,
      'Icon-App-76x76@1x.png': 76,
      'Icon-App-76x76@2x.png': 152,
      'Icon-App-83.5x83.5@2x.png': 167,
      'Icon-App-1024x1024@1x.png': 1024,
    };
    for (final e in ios.entries) {
      await _render('ios/Runner/Assets.xcassets/AppIcon.appiconset/${e.key}',
          e.value, _Style.square);
    }

    await _render('web/icons/Icon-192.png', 192, _Style.tile);
    await _render('web/icons/Icon-512.png', 512, _Style.tile);
    await _render('web/icons/Icon-maskable-192.png', 192, _Style.maskable);
    await _render('web/icons/Icon-maskable-512.png', 512, _Style.maskable);
    await _render('web/favicon.png', 48, _Style.tile);
  });
}
