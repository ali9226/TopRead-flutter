// ignore_for_file: non_constant_identifier_names

import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;
import 'package:app/components/window_content_layout/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MediaQueryData _media(Size size) => MediaQueryData(
  size: size,
  padding: const EdgeInsets.only(right: 84, bottom: 34),
  viewPadding: const EdgeInsets.only(right: 84, bottom: 34),
  displayFeatures: [
    DisplayFeature(
      bounds: Rect.fromLTWH(size.width - 84, 0, 84, 124),
      type: DisplayFeatureType.cutout,
      state: DisplayFeatureState.unknown,
    ),
  ],
);

Widget _title() => const WindowReservedRegionPadding(
  mode: WindowReservedRegionPaddingMode.heading,
  child: SizedBox(
    width: double.infinity,
    child: Text(
      'A very long title that wraps over many lines. A very long title that wraps over many lines. '
      'A very long title that wraps over many lines. A very long title that wraps over many lines. '
      'A very long title that wraps over many lines. A very long title that wraps over many lines.',
      key: ValueKey('title'),
      style: TextStyle(fontSize: 28, height: 1.4),
    ),
  ),
);

void main() {
  testWidgets('超过124高度的多行标题避让局部cutout，正文不损失整列宽度', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(466, 678);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: _media(const Size(466, 678)),
          child: WindowLayoutScope(
            child: Scaffold(
              body: WindowContentLayout(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _title(),
                      const SizedBox(
                        key: ValueKey('body'),
                        width: double.infinity,
                        height: 300,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final title = tester.getRect(find.byKey(const ValueKey('title')));
    expect(title.height, greaterThan(124));
    expect(title.right, closeTo(382, 0.1));
    expect(tester.getSize(find.byKey(const ValueKey('body'))).width, 466);
    expect(tester.takeException(), isNull);
  });

  testWidgets('折叠宽度变化重算标题避让，滚动离开局部区域释放并可重新进入', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(466, 678);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final media = ValueNotifier(_media(const Size(466, 678)));
    final scroll = ScrollController();
    addTearDown(media.dispose);
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<MediaQueryData>(
          valueListenable: media,
          builder: (context, data, _) => MediaQuery(
            data: data,
            child: WindowLayoutScope(
              child: Scaffold(
                body: WindowContentLayout(
                  child: SingleChildScrollView(
                    controller: scroll,
                    child: Column(
                      children: [
                        const SizedBox(height: 72),
                        _title(),
                        const SizedBox(
                          key: ValueKey('body'),
                          width: double.infinity,
                          height: 1600,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('title'))).right,
      closeTo(382, 0.1),
    );
    tester.view.physicalSize = const Size(951, 669);
    media.value = _media(const Size(951, 669));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('title'))).right,
      closeTo(867, 0.1),
    );
    scroll.jumpTo(900);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('title'))).right,
      closeTo(951, 0.1),
    );
    expect(tester.getSize(find.byKey(const ValueKey('body'))).width, 951);
    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('title'))).right,
      closeTo(867, 0.1),
    );
    expect(tester.takeException(), isNull);
  });
}
