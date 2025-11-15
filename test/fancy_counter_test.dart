import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fancy_counter/fancy_counter.dart';

void main() {
  // --- Group 1: AnimatedTextCounter Tests ---
  group('AnimatedTextCounter', () {
    testWidgets('renders and animates from 0 to target value by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedTextCounter(
              value: 100,
              duration: Duration(milliseconds: 500),
            ),
          ),
        ),
      );

      // Expect the initial value (0, from _previousValue)
      expect(find.text('0'), findsOneWidget);

      // Wait for the animation to complete
      await tester.pumpAndSettle();

      // Expect the final target value
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets(
      'renders target value immediately when animateOnFirstBuild is false',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedTextCounter(
                value: 100,
                duration: Duration(milliseconds: 500),
                animateOnFirstBuild: false,
              ),
            ),
          ),
        );

        // Expect the target value immediately, without settling.
        expect(find.text('100'), findsOneWidget);
      },
    );

    testWidgets('renders with prefix, postfix, and fractionDigits', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedTextCounter(
              value: 50,
              duration: Duration(milliseconds: 100),
              prefix: '₺',
              postfix: ' TL',
              fractionDigits: 2,
            ),
          ),
        ),
      );

      // Expect initial formatted value
      expect(find.text('₺0.00 TL'), findsOneWidget);

      await tester.pumpAndSettle();

      // Expect final formatted value
      expect(find.text('₺50.00 TL'), findsOneWidget);
    });
  });

  // --- Group 2: FlipCounter Tests ---
  group('FlipCounter', () {
    /// Helper function to find all Text widgets within the counter's Row
    /// and join their string data.
    ///
    /// This is necessary because FlipCounter renders two Text widgets
    /// (incoming and outgoing) for each digit slot.
    String getRenderedText(WidgetTester tester) {
      final finder = find.descendant(
        of: find.byType(Row),
        matching: find.byType(Text),
      );

      final Iterable<Text> textWidgets = tester.widgetList<Text>(finder);
      return textWidgets.map((text) => text.data!).join('');
    }

    testWidgets('renders and animates from 0 to target value by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlipCounter(
              value: 123,
              duration: Duration(milliseconds: 500),
            ),
          ),
        ),
      );

      // Expect the initial state text.
      // Each _SingleDigitScroll(value: 0.0) renders '0' (opacity 1.0)
      // and '1' (opacity 0.0).
      // prevPadded = "000"
      // lerp(0, 1, 0.0) -> renders "01"
      // lerp(0, 2, 0.0) -> renders "01"
      // lerp(0, 3, 0.0) -> renders "01"
      // Result: "010101"
      expect(getRenderedText(tester), '010101');

      await tester.pumpAndSettle();

      // Expect the final state text.
      // lerp(0, 1, 1.0) -> renders "12"
      // lerp(0, 2, 1.0) -> renders "23"
      // lerp(0, 3, 1.0) -> renders "34"
      // Result: "122334"
      expect(getRenderedText(tester), '122334');
    });

    testWidgets(
      'renders with prefix, postfix, fractionDigits, and decimal point',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FlipCounter(
                value: 45.67,
                duration: Duration(milliseconds: 100),
                prefix: '₺',
                postfix: '!',
                fractionDigits: 2,
              ),
            ),
          ),
        );

        // Expect initial state: "₺" + "01" + "01" + "." + "01" + "01" + "!"
        expect(getRenderedText(tester), '₺0101.0101!');

        await tester.pumpAndSettle();

        // Expect final state: "₺" + "45" + "56" + "." + "67" + "78" + "!"
        expect(getRenderedText(tester), '₺4556.6778!');
      },
    );
  });
}
