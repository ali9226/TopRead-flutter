// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:app/components/window_content_layout/index.dart';
import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('窗口收起展开保持编辑文本、滚动位置和原始字号', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(466, 678);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TextEditingController();
    final scroll = ScrollController();
    addTearDown(controller.dispose);
    addTearDown(scroll.dispose);
    final field_key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: WindowContentLayout(
          child: Scaffold(
            body: Column(
              children: [
                const Text('Readable text', style: TextStyle(fontSize: 18)),
                Expanded(
                  child: ListView(
                    controller: scroll,
                    children: [
                      TextField(key: field_key, controller: controller),
                      const SizedBox(height: 2400),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '尚未提交的创作内容');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    scroll.jumpTo(200);
    await tester.pumpAndSettle();
    expect(scroll.offset, 200);
    final original_state = field_key.currentState;

    for (final size in const [
      Size(669, 951),
      Size(951, 669),
      Size(466, 678),
      Size(320, 568),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(field_key.currentState, same(original_state));
      expect(controller.text, '尚未提交的创作内容');
      expect(scroll.offset, 200);
      expect(
        tester.widget<Text>(find.text('Readable text')).style!.fontSize,
        18,
      );
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('路由scope不裁背景，栏位只包自身高度且仅约束前景', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    const background_key = ValueKey('full_window_background');
    const header_key = ValueKey('safe_header');
    const body_key = ValueKey('safe_body');
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(1200, 800),
            padding: EdgeInsets.only(right: 84),
            viewPadding: EdgeInsets.only(right: 84),
          ),
          child: WindowLayoutScope(
            max_width: LayoutConfig.form_max_width,
            child: Scaffold(
              body: Stack(
                children: [
                  const Positioned.fill(
                    child: ColoredBox(key: background_key, color: Colors.amber),
                  ),
                  Column(
                    children: [
                      const WindowContentLayout(
                        expand_height: false,
                        child: SizedBox(key: header_key, height: 48),
                      ),
                      Expanded(
                        child: WindowContentLayout(
                          child: SizedBox.expand(key: body_key),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getRect(find.byKey(background_key)),
      const Rect.fromLTWH(0, 0, 1200, 800),
    );
    expect(
      tester.getSize(find.byKey(header_key)),
      const Size(LayoutConfig.form_max_width, 48),
    );
    expect(
      tester.getRect(find.byKey(body_key)),
      const Rect.fromLTWH(278, 48, LayoutConfig.form_max_width, 752),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('内容避让左右独立安全区，并保留键盘和无障碍指标', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    MediaQueryData? content_media;
    const marker_key = ValueKey('content');
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(1200, 800),
            padding: EdgeInsets.fromLTRB(40, 24, 20, 0),
            viewPadding: EdgeInsets.fromLTRB(40, 24, 20, 34),
            viewInsets: EdgeInsets.only(bottom: 300),
            textScaler: TextScaler.linear(1.6),
            disableAnimations: true,
          ),
          child: WindowContentLayout(
            child: Builder(
              builder: (context) {
                content_media = MediaQuery.of(context);
                return const ColoredBox(key: marker_key, color: Colors.white);
              },
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byKey(marker_key)).width,
      LayoutConfig.page_max_width,
    );
    expect(tester.getTopLeft(find.byKey(marker_key)).dx, 160);
    expect(content_media!.size.width, LayoutConfig.page_max_width);
    expect(content_media!.viewInsets.bottom, 300);
    expect(
      content_media!.viewPadding,
      const EdgeInsets.only(top: 24, bottom: 34),
    );
    expect(content_media!.padding.top, 24);
    expect(content_media!.textScaler.scale(20), 32);
    expect(content_media!.disableAnimations, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('表单与正文按可用宽度限宽，紧凑窗口不设置最小宽度', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final max_width in [
      LayoutConfig.form_max_width,
      LayoutConfig.reader_max_width,
      LayoutConfig.page_max_width,
    ]) {
      for (final width in [320.0, 466.0, 669.0, 1200.0]) {
        tester.view.physicalSize = Size(width, 951);
        await tester.pumpWidget(
          MaterialApp(
            home: WindowContentLayout(
              max_width: max_width,
              child: const ColoredBox(
                key: ValueKey('panel'),
                color: Colors.white,
              ),
            ),
          ),
        );
        expect(
          tester.getSize(find.byKey(const ValueKey('panel'))).width,
          width < max_width ? width : max_width,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('Duo收起的右侧84状态栏独立避让，内容不被整体缩放', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(466, 678);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late MediaQueryData content_media;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(466, 678),
            padding: EdgeInsets.only(right: 84, bottom: 34),
            viewPadding: EdgeInsets.only(right: 84, bottom: 34),
            displayFeatures: [
              DisplayFeature(
                bounds: Rect.fromLTWH(382, 0, 84, 678),
                type: DisplayFeatureType.cutout,
                state: DisplayFeatureState.unknown,
              ),
            ],
          ),
          child: WindowContentLayout(
            child: Builder(
              builder: (context) {
                content_media = MediaQuery.of(context);
                return const SizedBox.expand(key: ValueKey('duo_content'));
              },
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('duo_content'))),
      const Size(382, 678),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('duo_content'))),
      Offset.zero,
    );
    expect(content_media.padding, const EdgeInsets.only(bottom: 34));
    expect(content_media.size, const Size(382, 678));
    expect(content_media.displayFeatures, isEmpty);
    expect(content_media.textScaler.scale(18), 18);
    expect(tester.takeException(), isNull);
  });

  testWidgets('居中内容将原生保留区域坐标转换并截取，屏外区域不会影响弹窗', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late MediaQueryData content_media;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(1200, 800),
            padding: EdgeInsets.only(left: 40, right: 20),
            displayFeatures: [
              DisplayFeature(
                bounds: Rect.fromLTWH(500, 0, 0, 800),
                type: DisplayFeatureType.fold,
                state: DisplayFeatureState.postureHalfOpened,
              ),
              DisplayFeature(
                bounds: Rect.fromLTWH(1050, 20, 60, 40),
                type: DisplayFeatureType.cutout,
                state: DisplayFeatureState.unknown,
              ),
              DisplayFeature(
                bounds: Rect.fromLTWH(1190, 0, 10, 800),
                type: DisplayFeatureType.cutout,
                state: DisplayFeatureState.unknown,
              ),
              DisplayFeature(
                bounds: Rect.fromLTWH(0, 300, 1200, 0),
                type: DisplayFeatureType.fold,
                state: DisplayFeatureState.postureFlat,
              ),
            ],
          ),
          child: WindowContentLayout(
            child: Builder(
              builder: (context) {
                content_media = MediaQuery.of(context);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );
    final features = content_media.displayFeatures;
    expect(features.length, 3);
    expect(features[0].bounds, const Rect.fromLTWH(340, 0, 0, 800));
    expect(features[0].state, DisplayFeatureState.postureHalfOpened);
    expect(features[1].bounds, const Rect.fromLTWH(890, 20, 10, 40));
    expect(features[1].type, DisplayFeatureType.cutout);
    expect(features[2].bounds, const Rect.fromLTWH(0, 300, 900, 0));
    expect(tester.takeException(), isNull);
  });
}
