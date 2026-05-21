// This file is for testing our app's widgets.
// We'll add real tests here later as we build each feature.
// For now we just make sure the app starts without crashing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khajaattariya/main.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const KhajaAttariyaApp());

    // Verify our starting text is on screen
    expect(find.text('Khaja Attariya is starting...'), findsOneWidget);
  });
}