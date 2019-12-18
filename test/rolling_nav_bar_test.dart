import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rolling_nav_bar/rolling_nav_bar.dart';

void main() {
  // Helper function to remove lots of meaningless lines of code from
  // appearing and test after test below
  Widget _materialApp(
    RollingNavBar navBar, {
    double height: 100,
    double width: 400,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          child: navBar,
          height: height,
          width: width,
        ),
      ),
    );
  }

  group('RollingNavBar builds correctly', () {
    testWidgets('with simplest iconData parameters',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _materialApp(
          RollingNavBar.iconData(
            iconData: <IconData>[Icons.home, Icons.person, Icons.settings],
          ),
        ),
      );
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
    testWidgets('with simplest children parameters',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _materialApp(
          RollingNavBar.children(
            children: <Widget>[Text('Home'), Text('Friends'), Text('Settings')],
          ),
        ),
      );
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('with iconData and text', (WidgetTester tester) async {
      await tester.pumpWidget(
        _materialApp(
          RollingNavBar.iconData(
            iconData: <IconData>[Icons.home, Icons.person, Icons.settings],
            iconText: <Widget>[Text('Home'), Text('Friends'), Text('Settings')],
          ),
        ),
      );
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      // Finds nothing because is starting active widget
      expect(find.text('Home'), findsNothing);
      // Inactive tabs render their iconText
      expect(find.text('Friends'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
    testWidgets('with iconData and text and specified starting active index',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _materialApp(
          RollingNavBar.iconData(
            activeIndex: 1,
            iconData: <IconData>[Icons.home, Icons.person, Icons.settings],
            iconText: <Widget>[Text('Home'), Text('Friends'), Text('Settings')],
          ),
        ),
      );
      // Inactive tabs render their iconText
      expect(find.text('Home'), findsOneWidget);
      // Finds nothing because is starting active widget
      expect(find.text('Friends'), findsNothing);
      expect(find.text('Settings'), findsOneWidget);
    });
    testWidgets('with a custom active indicator color',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _materialApp(
          RollingNavBar.iconData(
            activeIndex: 1,
            iconData: <IconData>[Icons.home, Icons.person, Icons.settings],
            iconText: <Widget>[Text('Home'), Text('Friends'), Text('Settings')],
            indicatorColors: <Color>[Colors.orange],
          ),
        ),
      );
      // Inactive tabs render their iconText
      Finder activeIndicator = find.byType(ActiveIndicator);
      expect(activeIndicator, findsOneWidget);

      final activeIndicatorWidget =
          tester.firstWidget(activeIndicator) as ActiveIndicator;
      expect(activeIndicatorWidget.color, Colors.orange);
    });
  });
}
