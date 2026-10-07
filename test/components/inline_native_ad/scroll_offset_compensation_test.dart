import 'package:app/components/inline_native_ad/scroll_offset_compensation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 使用真实滚动位置，确认补偿标记仅覆盖同步 jumpTo 的监听调用。
Future<void> _pump_scrollable(
  WidgetTester tester,
  ScrollController scroll_controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          height: 600,
          child: SingleChildScrollView(
            controller: scroll_controller,
            child: const SizedBox(height: 4000),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('同步补偿期间标记为 true，执行前后及普通滚动均为 false', (tester) async {
    final ScrollController scroll_controller = ScrollController();
    addTearDown(scroll_controller.dispose);
    await _pump_scrollable(tester, scroll_controller);
    final ScrollPosition position = scroll_controller.position;
    final List<bool> observed_flags = <bool>[];
    scroll_controller.addListener(() {
      observed_flags.add(is_native_ad_scroll_compensating(position));
    });

    scroll_controller.jumpTo(400);
    expect(observed_flags, isNotEmpty);
    expect(observed_flags, everyElement(isFalse));
    observed_flags.clear();

    queue_native_ad_scroll_compensation(
      position: position,
      extent_delta: 100,
      is_valid: () => true,
    );
    expect(is_native_ad_scroll_compensating(position), isFalse);
    expect(observed_flags, isEmpty);
    await tester.pump();

    expect(scroll_controller.offset, 500);
    expect(observed_flags, isNotEmpty);
    expect(observed_flags, everyElement(isTrue));
    expect(is_native_ad_scroll_compensating(position), isFalse);

    observed_flags.clear();
    scroll_controller.jumpTo(600);
    expect(observed_flags, isNotEmpty);
    expect(observed_flags, everyElement(isFalse));
    expect(is_native_ad_scroll_compensating(position), isFalse);
  });

  testWidgets('同帧累计有效高度差仅触发一次补偿，已失效贡献不计入', (tester) async {
    final ScrollController scroll_controller = ScrollController();
    addTearDown(scroll_controller.dispose);
    await _pump_scrollable(tester, scroll_controller);
    scroll_controller.jumpTo(400);
    final ScrollPosition position = scroll_controller.position;
    final List<({double offset, bool is_compensating})> observed_offsets = [];
    scroll_controller.addListener(() {
      observed_offsets.add((
        offset: scroll_controller.offset,
        is_compensating: is_native_ad_scroll_compensating(position),
      ));
    });
    bool second_slot_is_valid = true;

    queue_native_ad_scroll_compensation(
      position: position,
      extent_delta: 75,
      is_valid: () => true,
    );
    queue_native_ad_scroll_compensation(
      position: position,
      extent_delta: 1000,
      is_valid: () => second_slot_is_valid,
    );
    queue_native_ad_scroll_compensation(
      position: position,
      extent_delta: -20,
      is_valid: () => true,
    );
    second_slot_is_valid = false;
    await tester.pump();

    expect(scroll_controller.offset, 455);
    expect(observed_offsets, <({double offset, bool is_compensating})>[
      (offset: 455, is_compensating: true),
    ]);
    expect(is_native_ad_scroll_compensating(position), isFalse);
  });

  testWidgets('所有广告均已失效时不改变位置且不开放补偿标记', (tester) async {
    final ScrollController scroll_controller = ScrollController();
    addTearDown(scroll_controller.dispose);
    await _pump_scrollable(tester, scroll_controller);
    scroll_controller.jumpTo(400);
    final ScrollPosition position = scroll_controller.position;
    final List<bool> observed_flags = <bool>[];
    scroll_controller.addListener(() {
      observed_flags.add(is_native_ad_scroll_compensating(position));
    });
    bool slot_is_valid = true;
    queue_native_ad_scroll_compensation(
      position: position,
      extent_delta: 100,
      is_valid: () => slot_is_valid,
    );
    slot_is_valid = false;
    await tester.pump();

    expect(scroll_controller.offset, 400);
    expect(observed_flags, isEmpty);
    expect(is_native_ad_scroll_compensating(position), isFalse);
  });

  testWidgets('等待补偿期间读者已改变位置时保留读者位置', (tester) async {
    final ScrollController scroll_controller = ScrollController();
    addTearDown(scroll_controller.dispose);
    await _pump_scrollable(tester, scroll_controller);
    scroll_controller.jumpTo(400);
    final ScrollPosition position = scroll_controller.position;
    final List<bool> observed_flags = <bool>[];
    scroll_controller.addListener(() {
      observed_flags.add(is_native_ad_scroll_compensating(position));
    });
    queue_native_ad_scroll_compensation(
      position: position,
      extent_delta: 100,
      is_valid: () => true,
    );
    scroll_controller.jumpTo(800);
    await tester.pump();

    expect(scroll_controller.offset, 800);
    expect(observed_flags, isNotEmpty);
    expect(observed_flags, everyElement(isFalse));
    expect(is_native_ad_scroll_compensating(position), isFalse);
  });
}
