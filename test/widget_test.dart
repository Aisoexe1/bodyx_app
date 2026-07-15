// Basic smoke test: the app boots on the splash screen without throwing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bodyx_app/app.dart';

void main() {
  testWidgets('BodyX boots to the splash screen then the sign-in screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BodyXApp());
    await tester.pump();

    expect(find.text('BodyX'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);

    // Let the splash screen's auto-navigation timer and the cross-fade
    // transition into the sign-in screen finish, so no timers are left
    // pending when the test tears down.
    await tester.pumpAndSettle(const Duration(milliseconds: 2200));

    expect(find.text('Welcome back'), findsOneWidget);
  });
}
