// ignore_for_file: non_constant_identifier_names
import 'package:app/pages/tile_quest/widgets/quest_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('icon presses down immediately and springs back on release', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuestIconButton(
            icon: Icons.refresh_rounded,
            label: 'reset',
            on_tap: () => taps++,
          ),
        ),
      ),
    );
    expect(taps, 0);
    final scale_finder = find.descendant(
      of: find.byType(QuestIconButton),
      matching: find.byType(AnimatedScale),
    );
    expect(scale_finder, findsOneWidget);
    double scale_of() => tester.widget<AnimatedScale>(scale_finder).scale;
    expect(scale_of(), 1);
    final center = tester.getCenter(find.byType(QuestIconButton));
    final gesture = await tester.startGesture(center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(scale_of(), lessThan(1));
    expect(taps, 0, reason: 'press must not fire the action yet');
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(taps, 1);
    await tester.pumpAndSettle();
    expect(scale_of(), closeTo(1, .001));
    expect(tester.takeException(), isNull);
  });
}
