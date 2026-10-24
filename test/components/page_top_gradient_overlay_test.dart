import 'package:app/components/page_top_gradient_overlay/index.dart';
import 'package:app/components/top_header_gradient/index.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Visibility = ({bool visible, bool disable_animations});

double _opacity(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find.descendant(
        of: find.byType(PageTopGradientOverlay),
        matching: find.byType(FadeTransition),
      ),
    )
    .opacity
    .value;

Future<void> _mount(
  WidgetTester tester,
  ValueNotifier<_Visibility> visibility, {
  VoidCallback? on_tap,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(951, 669);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      home: ValueListenableBuilder<_Visibility>(
        valueListenable: visibility,
        builder: (_, value, _) => MediaQuery(
          data: MediaQueryData(
            size: const Size(951, 669),
            padding: const EdgeInsets.only(top: 32, right: 84, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 32, right: 84, bottom: 34),
            disableAnimations: value.disable_animations,
          ),
          child: WindowLayoutScope(
            max_width: 760,
            child: Scaffold(
              body: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: on_tap,
                    child: const SizedBox.expand(),
                  ),
                  PageTopGradientOverlay(
                    background_color: Colors.white,
                    visible: value.visible,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('顶部渐变保留全窗口几何与子树，淡入淡出及中途反转均穿透点击', (tester) async {
    final visibility = ValueNotifier<_Visibility>((
      visible: false,
      disable_animations: false,
    ));
    addTearDown(visibility.dispose);
    var taps = 0;
    await _mount(tester, visibility, on_tap: () => taps++);
    final gradient = find.byType(TopHeaderGradient);
    final original_element = tester.element(gradient);
    expect(_opacity(tester), 0);
    expect(tester.getRect(gradient), const Rect.fromLTWH(0, 0, 951, 90));
    await tester.tapAt(const Offset(900, 20));
    expect(taps, 1);

    visibility.value = (visible: true, disable_animations: false);
    await tester.pump();
    expect(_opacity(tester), 0);
    await tester.pump(const Duration(milliseconds: 80));
    final entering = _opacity(tester);
    expect(entering, inExclusiveRange(0, 1));
    await tester.tapAt(const Offset(900, 20));
    expect(taps, 2);
    visibility.value = (visible: false, disable_animations: false);
    await tester.pump();
    expect(_opacity(tester), closeTo(entering, 0.0001));
    await tester.pump(const Duration(milliseconds: 80));
    expect(_opacity(tester), inExclusiveRange(0, entering));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_opacity(tester), 0);
    expect(tester.element(gradient), same(original_element));

    visibility.value = (visible: true, disable_animations: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(_opacity(tester), 1);
    visibility.value = (visible: false, disable_animations: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(_opacity(tester), inExclusiveRange(0, 1));
    await tester.tapAt(const Offset(900, 20));
    expect(taps, 3);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_opacity(tester), 0);
    expect(tester.element(gradient), same(original_element));
    expect(tester.takeException(), isNull);
  });

  testWidgets('系统禁用动画时直接跟随可见状态，不保留过渡或拦截触控', (tester) async {
    final visibility = ValueNotifier<_Visibility>((
      visible: false,
      disable_animations: true,
    ));
    addTearDown(visibility.dispose);
    await _mount(tester, visibility);
    expect(_opacity(tester), 0);
    visibility.value = (visible: true, disable_animations: true);
    await tester.pump();
    expect(_opacity(tester), 1);
    visibility.value = (visible: false, disable_animations: true);
    await tester.pump();
    expect(_opacity(tester), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('淡入途中开启系统减少动画时立即显现目标状态', (tester) async {
    final visibility = ValueNotifier<_Visibility>((
      visible: false,
      disable_animations: false,
    ));
    addTearDown(visibility.dispose);
    await _mount(tester, visibility);
    visibility.value = (visible: true, disable_animations: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(_opacity(tester), inExclusiveRange(0, 1));
    visibility.value = (visible: true, disable_animations: true);
    await tester.pump();
    expect(_opacity(tester), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('已有常显调用初次构建仍完全可见，不新增入场动画', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [PageTopGradientOverlay(background_color: Colors.white)],
          ),
        ),
      ),
    );
    expect(_opacity(tester), 1);
    expect(tester.takeException(), isNull);
  });
}
