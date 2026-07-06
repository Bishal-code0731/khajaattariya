// This file is for testing our app's widgets.
// We'll add real tests here later as we build each feature.
// For now we just make sure the app starts without crashing.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaja_attariya/main.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const ProviderScope(child: KhajaAttariyaApp()));

    // Verify the app renders without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}