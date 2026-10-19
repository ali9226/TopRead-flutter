// ignore_for_file: non_constant_identifier_names

import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:app/components/window_content_layout/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 使用原生回传的局部区域形状，不把整列安全区伪装成刘海。
MediaQueryData _window(Size size, {bool left = false}) => MediaQueryData(
  size: size,
  padding: EdgeInsets.only(
    left: left ? 84 : 0,
    right: left ? 0 : 84,
    bottom: 34,
  ),
  viewPadding: EdgeInsets.only(
    left: left ? 84 : 0,
    right: left ? 0 : 84,
    bottom: 34,
  ),
  displayFeatures: [
    DisplayFeature(
      bounds: Rect.fromLTWH(left ? 0 : size.width - 84, 0, 84, 124),
      type: DisplayFeatureType.cutout,
      state: DisplayFeatureState.unknown,
    ),
  ],
);

Future<void> _mount(
  WidgetTester tester, {
  required MediaQueryData media,
  required Widget child,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = media.size;
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: media,
        child: WindowLayoutScope(max_width: 560, child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final size in const [Size(466, 678), Size(951, 669), Size(669, 951)]) {
    for (final left in [false, true]) {
      testWidgets('局部边缘区域 $size left=$left：仅导航行避让，正文底栏保持满宽', (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        late MediaQueryData body_media;
        await _mount(
          tester,
          media: _window(size, left: left),
          child: Scaffold(
            body: Column(
              children: [
                const WindowContentLayout(
                  expand_height: false,
                  child: SizedBox(key: ValueKey('header'), height: 48),
                ),
                Expanded(
                  child: WindowContentLayout(
                    child: Builder(
                      builder: (context) {
                        body_media = MediaQuery.of(context);
                        return const SizedBox.expand(key: ValueKey('body'));
                      },
                    ),
                  ),
                ),
                const WindowContentLayout(
                  expand_height: false,
                  child: SizedBox(key: ValueKey('footer'), height: 60),
                ),
              ],
            ),
          ),
        );
        expect(
          tester.getRect(find.byKey(const ValueKey('header'))),
          Rect.fromLTWH(left ? 84 : 0, 0, size.width - 84, 48),
        );
        expect(
          tester.getRect(find.byKey(const ValueKey('body'))),
          Rect.fromLTWH(0, 48, size.width, size.height - 108),
        );
        expect(
          tester.getRect(find.byKey(const ValueKey('footer'))),
          Rect.fromLTWH(0, size.height - 60, size.width, 60),
        );
        expect(body_media.size.width, size.width);
        expect(body_media.padding, const EdgeInsets.only(bottom: 34));
        expect(body_media.viewPadding, const EdgeInsets.only(bottom: 34));
        expect(
          body_media.displayFeatures.single.bounds,
          _window(size, left: left).displayFeatures.single.bounds,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('嵌套scope和局部导航避让不会重复84，底部控件不保留整列空白', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _mount(
      tester,
      media: _window(const Size(951, 669)),
      child: const WindowLayoutScope(
        child: Scaffold(
          body: Column(
            children: [
              WindowContentLayout(
                expand_height: false,
                child: WindowReservedRegionPadding(
                  child: SizedBox(key: ValueKey('nested_header'), height: 48),
                ),
              ),
              Expanded(
                child: WindowContentLayout(
                  child: SizedBox.expand(key: ValueKey('nested_body')),
                ),
              ),
              WindowReservedRegionPadding(
                child: SizedBox(
                  key: ValueKey('nested_bottom'),
                  width: double.infinity,
                  height: 48,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('nested_header'))),
      const Size(867, 48),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('nested_body'))).width,
      951,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('nested_bottom'))),
      const Size(951, 48),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('高hero只有短导航行避让，滚动离开状态区后释放局部留白', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final position = ValueNotifier<double>(0);
    addTearDown(position.dispose);
    const header = WindowContentLayout(
      expand_height: false,
      child: Column(
        children: [
          WindowReservedRegionPadding(
            child: SizedBox(
              key: ValueKey('moving_header'),
              width: double.infinity,
              height: 44,
            ),
          ),
          SizedBox(
            key: ValueKey('hero_body'),
            width: double.infinity,
            height: 240,
          ),
        ],
      ),
    );
    await _mount(
      tester,
      media: _window(const Size(951, 669)),
      child: Scaffold(
        body: ValueListenableBuilder<double>(
          valueListenable: position,
          child: header,
          builder: (context, top, child) => Stack(
            children: [Positioned(top: top, left: 0, right: 0, child: child!)],
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('moving_header'))).width,
      867,
    );
    expect(tester.getSize(find.byKey(const ValueKey('hero_body'))).width, 951);
    position.value = 160;
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('moving_header'))),
      const Rect.fromLTWH(0, 160, 951, 44),
    );
    position.value = 0;
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('moving_header'))).width,
      867,
    );
    expect(tester.takeException(), isNull);
  });

  for (final actions in [false, true]) {
    testWidgets('内置AppBar actions=$actions：仅工具栏内部避让，背景和正文满宽', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _mount(
        tester,
        media: _window(const Size(951, 669)),
        child: Scaffold(
          appBar: WindowAppBar(
            child: AppBar(
              title: const SizedBox(
                key: ValueKey('appbar_title'),
                height: 32,
                width: 2000,
              ),
              leading: const SizedBox(key: ValueKey('appbar_leading')),
              actions: actions
                  ? [
                      const SizedBox(
                        key: ValueKey('appbar_action'),
                        width: 48,
                        height: 48,
                      ),
                    ]
                  : null,
            ),
          ),
          body: const WindowContentLayout(
            child: SizedBox.expand(key: ValueKey('appbar_body')),
          ),
        ),
      );
      expect(tester.getSize(find.byType(AppBar)).width, 951);
      expect(
        tester.getRect(find.byKey(const ValueKey('appbar_title'))).right,
        lessThanOrEqualTo(867),
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('appbar_leading'))).left,
        0,
      );
      if (actions)
        expect(
          tester.getRect(find.byKey(const ValueKey('appbar_action'))).right,
          867,
        );
      expect(
        tester.getSize(find.byKey(const ValueKey('appbar_body'))).width,
        951,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('普通横屏刘海和贯穿窗口遮挡保留安全区，局部规则不误伤其他设备', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const size = Size(951, 669);
    for (final bounds in const [
      Rect.fromLTWH(0, 269, 59, 131),
      Rect.fromLTWH(867, 0, 84, 669),
    ]) {
      final left = bounds.left == 0;
      await _mount(
        tester,
        media: MediaQueryData(
          size: size,
          padding: EdgeInsets.only(left: left ? 59 : 0, right: left ? 0 : 84),
          viewPadding: EdgeInsets.only(
            left: left ? 59 : 0,
            right: left ? 0 : 84,
          ),
          displayFeatures: [
            DisplayFeature(
              bounds: bounds,
              type: DisplayFeatureType.cutout,
              state: DisplayFeatureState.unknown,
            ),
          ],
        ),
        child: const Scaffold(
          body: WindowContentLayout(
            child: SizedBox.expand(key: ValueKey('ordinary')),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const ValueKey('ordinary'))).width, 560);
      expect(tester.takeException(), isNull);
    }
  });
}
