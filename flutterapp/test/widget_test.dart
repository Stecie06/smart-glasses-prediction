// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_glasses_app/main.dart'; // Replace with your app name from pubspec.yaml

void main() {
  testWidgets('Home screen shows app title', (WidgetTester tester) async {
    // 1. Build our app
    await tester.pumpWidget(const SmartGlassesApp());
    
    // 2. Verify the title exists
    expect(find.text('Smart Glasses'), findsOneWidget);
  });

  testWidgets('Predict Demand button exists', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartGlassesApp());
    expect(find.text('Predict Demand'), findsOneWidget);
  });
}