// ignore_for_file: non_constant_identifier_names

import 'package:app/components/viewport_resize_observer/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 使用实际Text换行和滚动视口，检验旧锚点是在新正文排版前记录的。
class _ReadingFixture extends StatefulWidget {
  const _ReadingFixture({super.key});
  @override
  State<_ReadingFixture> createState() => _ReadingFixtureState();
}

class _ReadingFixtureState extends State<_ReadingFixture> {
  final scroll = ScrollController();
  final text_key = GlobalKey();
  double width = 466;
  int starts = 0;
  int ends = 0;
  double progress = 0;
  double captured_extent = 0;

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: width,
        height: 600,
        child: ViewportResizeObserver(
          on_resize_start: () {
            starts++;
            captured_extent = scroll.position.maxScrollExtent;
            progress = scroll.offset / captured_extent;
          },
          on_resize_end: () {
            ends++;
            scroll.jumpTo(scroll.position.maxScrollExtent * progress);
          },
          child: SingleChildScrollView(
            controller: scroll,
            child: Text(
              key: text_key,
              List.filled(
                160,
                'A readable paragraph that wraps with the window.',
              ).join(' '),
              style: const TextStyle(fontSize: 18, height: 1.5),
            ),
          ),
        ),
      ),
    ),
  );

  void resize(double next_width) => setState(() => width = next_width);
}

void main() {
  testWidgets('仅宽度变化在重新换行前取旧锚点，新布局后恢复同一进度', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture_key = GlobalKey<_ReadingFixtureState>();
    await tester.pumpWidget(_ReadingFixture(key: fixture_key));
    await tester.pumpAndSettle();
    final fixture = fixture_key.currentState!;
    expect(fixture.starts, 0);
    expect(fixture.ends, 0);
    fixture.scroll.jumpTo(fixture.scroll.position.maxScrollExtent * .42);
    await tester.pumpAndSettle();

    for (final width in [669.0, 466.0, 760.0, 320.0]) {
      final old_extent = fixture.scroll.position.maxScrollExtent;
      fixture.resize(width);
      await tester.pumpAndSettle();
      expect(fixture.captured_extent, old_extent);
      expect(
        fixture.scroll.offset / fixture.scroll.position.maxScrollExtent,
        closeTo(.42, .001),
      );
      expect(tester.takeException(), isNull);
    }
    expect(fixture.starts, 4);
    expect(fixture.ends, 4);
  });

  testWidgets('主题或键盘MediaQuery变化不改变真实视口时不重定位', (tester) async {
    var starts = 0;
    var ends = 0;
    final keyboard = ValueNotifier<double>(0);
    addTearDown(keyboard.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<double>(
          valueListenable: keyboard,
          builder: (context, height, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(viewInsets: EdgeInsets.only(bottom: height)),
            child: ViewportResizeObserver(
              on_resize_start: () => starts++,
              on_resize_end: () => ends++,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    keyboard.value = 300;
    await tester.pumpAndSettle();
    keyboard.value = 0;
    await tester.pumpAndSettle();
    expect(starts, 0);
    expect(ends, 0);
    expect(tester.takeException(), isNull);
  });
}
