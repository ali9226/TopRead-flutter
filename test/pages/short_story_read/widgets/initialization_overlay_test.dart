import 'package:app/pages/short_story_read/widgets/initialization_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('撤下初始化骨架后保留正文滚动位置', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    final ValueNotifier<bool> show_overlay = ValueNotifier<bool>(true);
    addTearDown(() {
      show_overlay.dispose();
      controller.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: show_overlay,
          builder: (BuildContext context, bool show, Widget? child) {
            return ShortStoryInitializationOverlay(
              show_overlay: show,
              content: ListView.builder(
                controller: controller,
                itemExtent: 50,
                itemCount: 100,
                itemBuilder: (BuildContext context, int index) {
                  return Text('第 $index 行');
                },
              ),
              overlay: const ColoredBox(
                key: ValueKey<String>('initialization-overlay'),
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );

    controller.jumpTo(1200);
    await tester.pump();
    expect(controller.offset, 1200);

    show_overlay.value = false;
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('initialization-overlay')),
      findsNothing,
    );
    expect(controller.offset, 1200);
  });
}
