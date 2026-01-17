import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smart Kisan Landing Page Smoke Test', (WidgetTester tester) async {
    // 1. Load the app
    await tester.pumpWidget(const SmartKisanApp() as Widget);

    // 2. Verify that the Title exists
    expect(find.text('Smart Kisan'), findsOneWidget);

    // 3. Verify that the "Get Started" button exists
    expect(find.text('Get Started'), findsOneWidget);

    // 4. Verify that the "Sign In" button exists
    expect(find.text('Sign In'), findsOneWidget);
  });
}

class SmartKisanApp {
  const SmartKisanApp();
}