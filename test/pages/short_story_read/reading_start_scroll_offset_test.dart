import 'package:app/pages/short_story_read/utils/reading_start_scroll_offset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('真实正文锚点随短标题、长标题与展开简介更新，不依赖头部估算高度', (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final body_start = GlobalKey();
    for (final header_height in [150.0, 500.0, 900.0, 150.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 500,
              child: SingleChildScrollView(
                controller: scroll,
                child: Column(
                  children: [
                    SizedBox(height: header_height),
                    SizedBox(key: body_start, height: 0),
                    const SizedBox(height: 1200),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final target = reading_start_scroll_offset(
        scroll_controller: scroll,
        body_start_key: body_start,
      );
      expect(target, closeTo(header_height, 0.01));
      scroll.jumpTo(target!);
      await tester.pump();
      expect(tester.getTopLeft(find.byKey(body_start)).dy, closeTo(0, 0.01));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('短正文定位钳制到实际边界，未挂载时不返回虚构位置', (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final body_start = GlobalKey();
    expect(
      reading_start_scroll_offset(
        scroll_controller: scroll,
        body_start_key: body_start,
      ),
      isNull,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 500,
            child: SingleChildScrollView(
              controller: scroll,
              child: Column(
                children: [
                  const SizedBox(height: 600),
                  SizedBox(key: body_start, height: 0),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final target = reading_start_scroll_offset(
      scroll_controller: scroll,
      body_start_key: body_start,
    );
    expect(target, scroll.position.maxScrollExtent);
    expect(target, 200);
    expect(tester.takeException(), isNull);
  });
}
