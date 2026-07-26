import 'dart:async';

import 'package:app/pages/short_story_read/widgets/catalog/catalog_positioning_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('目录估算定位会平滑经过中间位置', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ListView.builder(
          controller: controller,
          itemExtent: 50,
          itemCount: 100,
          itemBuilder: (BuildContext context, int index) {
            return Text('第 $index 项');
          },
        ),
      ),
    );

    unawaited(
      animate_catalog_position(
        controller: controller,
        target_offset: 1200,
        duration: const Duration(milliseconds: 560),
        curve: Curves.easeInOutCubic,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    expect(controller.offset, greaterThan(0));
    expect(controller.offset, lessThan(1200));

    await tester.pumpAndSettle();
    expect(controller.offset, closeTo(1200, 0.1));
  });
}
