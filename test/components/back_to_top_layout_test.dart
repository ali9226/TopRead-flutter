import 'package:app/components/back_to_top_button/index.dart';
import 'package:app/components/back_to_top_button/style.dart';
import 'package:app/components/floating_back_to_top/index.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _content_key = ValueKey('content_edges');

Future<void> _mount(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  EdgeInsets safe_area = EdgeInsets.zero,
  bool already_inset = false,
  bool show = true,
  VoidCallback? on_tap,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final floating = FloatingBackToTop(
    show: show,
    isDark: false,
    onTap: on_tap ?? () {},
    horizontalPadding: already_inset ? 0 : LayoutConfig.page_horizontal_padding,
    visibleBottom: LayoutConfig.space_24,
    hiddenBottom: -BackToTopButtonStyle.size,
  );
  final contents = already_inset
      ? WindowContentLayout(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LayoutConfig.page_horizontal_padding,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(key: _content_key, color: ColorConstants.whiteColor),
                floating,
              ],
            ),
          ),
        )
      : Stack(
          fit: StackFit.expand,
          children: [
            WindowContentLayout(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LayoutConfig.page_horizontal_padding,
                ),
                child: const ColoredBox(key: _content_key, color: ColorConstants.whiteColor),
              ),
            ),
            floating,
          ],
        );
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: safe_area,
          viewPadding: safe_area,
        ),
        child: WindowLayoutScope(child: Scaffold(body: contents)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [390.0, 1400.0]) {
    for (final inset in [false, true]) {
      testWidgets('aligns with content at width=$width, inset=$inset', (
        tester,
      ) async {
        await _mount(
          tester,
          size: Size(width, 844),
          safe_area: const EdgeInsets.only(left: 30, right: 24),
          already_inset: inset,
        );
        expect(tester.takeException(), isNull);
        final content = tester.getRect(find.byKey(_content_key));
        final button = tester.getRect(find.byType(BackToTopButton));
        expect(button.right, closeTo(content.right, .01));
        expect(button.size, const Size.square(BackToTopButtonStyle.size));
        expect(button.left, greaterThanOrEqualTo(content.left));
      });
    }
  }

  testWidgets('hidden button is inert and visible button dispatches once', (
    tester,
  ) async {
    var taps = 0;
    await _mount(tester, show: false, on_tap: () => taps++);
    final ignore_pointer = tester.widget<IgnorePointer>(
      find
          .ancestor(
            of: find.byType(BackToTopButton),
            matching: find.byType(IgnorePointer),
          )
          .first,
    );
    expect(ignore_pointer.ignoring, isTrue);
    await _mount(tester, on_tap: () => taps++);
    await tester.tap(find.byType(BackToTopButton));
    expect(taps, 1);
  });

  test('button ink uses the shared day text color', () {
    expect(
      BackToTopButtonStyle.ink(false).toARGB32(),
      ColorConstants.lightTextColor.withValues(alpha: .88).toARGB32(),
    );
  });
}
