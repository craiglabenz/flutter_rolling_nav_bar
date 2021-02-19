import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './stateful_test_widget.dart';

void main() {
  Widget _rollingNavBarApp([Function(int)? onTap]) {
    return MaterialApp(
      home: StatefulTestWidget(onTap),
    );
  }

  group('RollingNavBar renders correctly', () {
    testWidgets(
      'with on an ontap that doesn\'t call setState',
      (WidgetTester tester) async {
        final app = _rollingNavBarApp();
        await tester.pumpWidget(app);
        await tester.tap(find.byKey(Key('nav-bar-child-2')));
        await tester.pump();
        // Not just that the onTap callback was fired,
        // but that the new stuff renders.
        expect(find.text('Active Index: 2'), findsOneWidget);
      },
    );

    testWidgets(
      'with calls onTap when tapped index is already active',
      (WidgetTester tester) async {
        bool callbackFired = false;
        final app = _rollingNavBarApp((_) => callbackFired = true);
        await tester.pumpWidget(app);
        await tester.tap(find.byKey(Key('nav-bar-child-0')));
        await tester.pump();
        // Not just that the onTap callback was fired,
        // but that the new stuff renders.
        expect(callbackFired, true);
      },
    );

    testWidgets(
      'with on separate action that forces a new index',
      (WidgetTester tester) async {
        final app = _rollingNavBarApp();
        await tester.pumpWidget(app);
        // Taps on the FAB increment the index
        await tester.tap(find.byKey(Key('FAB')));
        await tester.pump();
        // Not just that the onTap callback was fired,
        // but that the new stuff renders.
        expect(find.text('Active Index: 1'), findsOneWidget);
      },
    );
  });
}
