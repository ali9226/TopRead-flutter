import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:app/components/expandable_synopsis/style.dart';
import 'package:app/components/expandable_synopsis/toggle_button.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/components/work_section_card/index.dart';
import 'package:app/components/work_about_section/index.dart';
import 'package:app/pages/comics/detail/widgets/about_story/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

const _description =
    'A journey begins beneath the stars.\n'
    'An old promise reveals a forgotten world.\n'
    'The friends set out for another discovery.\n'
    'Their story continues beyond the horizon.';

Future<void> _mount(
  WidgetTester tester, {
  double scale = 1,
  bool disable_animations = false,
  bool dark = false,
  bool novel = false,
  Size size = const Size(390, 844),
  String description = _description,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(scale),
          disableAnimations: disable_animations,
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: novel
                  ? WorkAboutSection(
                      description: description,
                      tags: const [],
                      is_dark: dark,
                      key_prefix: 'novel_about',
                      collapsed_lines: 2,
                      compact_toggle: true,
                    )
                  : ComicAboutStory(
                      description: description,
                      embedded: true,
                      is_dark: dark,
                    ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 防止局部避让和溢出回报相互重建，稳定状态应在短时间内停止请求新帧。
Future<void> _settle_frames(WidgetTester tester) async {
  await tester.pumpAndSettle(
    const Duration(milliseconds: 20),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 2),
  );
}

void main() {
  testWidgets('漫画简介标题保持静态，点击箭头展开正文', (tester) async {
    await _mount(tester);
    final viewport = find.byKey(const ValueKey('comic_about_viewport'));
    final collapsed = tester.getSize(viewport).height;
    await tester.tap(find.byKey(const ValueKey('comic_about_header')));
    await tester.pumpAndSettle();
    expect(tester.getSize(viewport).height, collapsed);
    await tester.tap(find.byKey(const ValueKey('comic_about_toggle')));
    await tester.pumpAndSettle();
    expect(tester.getSize(viewport).height, greaterThan(collapsed));
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('漫画简介以两行自然文字高度预览，兼容 $scale 倍大字', (tester) async {
      await _mount(tester, scale: scale);
      expect(find.byType(WorkSectionCard), findsNothing);
      final text = tester.widget<Text>(find.text(_description));
      final painter = TextPainter(
        text: TextSpan(text: _description, style: text.style),
        maxLines: 2,
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.linear(scale),
      )..layout(maxWidth: tester.getSize(find.text(_description)).width);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('comic_about_viewport')))
            .height,
        closeTo(painter.height, 0.01),
      );
      painter.dispose();
      expect(tester.takeException(), isNull);
    });
  }

  for (final dark in [false, true]) {
    testWidgets('漫画双箭头无圆形背景，保留透明触控区与半圈旋转 dark=$dark', (tester) async {
      await _mount(tester, dark: dark);
      final toggle = find.byKey(const ValueKey('comic_about_toggle'));
      final toggle_element = tester.element(toggle);
      final container = tester.widget<Container>(
        find.descendant(of: toggle, matching: find.byType(Container)),
      );
      expect(container.decoration, isNull);
      expect(tester.getSize(toggle), const Size.square(44));
      final svg_finder = find.descendant(
        of: toggle,
        matching: find.byType(SvgPicture),
      );
      final svg = tester.widget<SvgPicture>(svg_finder);
      expect(
        (svg.bytesLoader as SvgAssetLoader).assetName,
        'assets/svg/up.svg',
      );
      expect(tester.getSize(svg_finder), const Size.square(12));
      expect(
        tester.getCenter(svg_finder).dy,
        lessThan(tester.getCenter(toggle).dy - 4),
      );
      expect(
        svg.colorFilter,
        ColorFilter.mode(
          dark
              ? ExpandableSynopsisStyle.embedded_text_dark
              : ExpandableSynopsisStyle.embedded_text_light,
          BlendMode.srcIn,
        ),
      );
      final rotation = find.descendant(
        of: find.byType(SynopsisToggleButton),
        matching: find.byType(RotationTransition),
      );
      double turns() => tester.widget<RotationTransition>(rotation).turns.value;
      expect(turns(), 0.5);
      final viewport = find.byKey(const ValueKey('comic_about_viewport'));
      final collapsed = tester.getSize(viewport).height;
      await tester.tap(toggle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      final middle_height = tester.getSize(viewport).height;
      expect(turns(), greaterThan(0));
      expect(turns(), lessThan(0.5));
      await tester.pumpAndSettle();
      final expanded = tester.getSize(viewport).height;
      expect(middle_height, greaterThan(collapsed));
      expect(middle_height, lessThan(expanded));
      expect(turns(), 0);
      expect(tester.element(toggle), same(toggle_element));
      await tester.tap(toggle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(turns(), greaterThan(0));
      expect(turns(), lessThan(0.5));
      expect(tester.getSize(viewport).height, greaterThan(collapsed));
      expect(tester.getSize(viewport).height, lessThan(expanded));
      await tester.pumpAndSettle();
      expect(turns(), 0.5);
      expect(tester.getSize(viewport).height, collapsed);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('漫画简介饰条标题上提，双箭头衔接末行渐变并保留完整触控区', (tester) async {
    await _mount(tester);
    final heading = tester.getRect(
      find.byKey(const ValueKey('comic_about_header')),
    );
    final accent = tester.getRect(
      find.byKey(const ValueKey('comic_about_accent')),
    );
    expect(accent.right, lessThan(heading.left));
    expect(accent.height, lessThan(heading.height));
    expect(accent.center.dy, closeTo(heading.center.dy, 0.01));
    expect(heading.top, lessThan(20));
    final viewport = tester.getRect(
      find.byKey(const ValueKey('comic_about_viewport')),
    );
    final fade = tester.getRect(find.byKey(const ValueKey('comic_about_fade')));
    expect(fade.bottom, closeTo(viewport.bottom, 0.01));
    expect(fade.height, greaterThan(viewport.height / 4));
    expect(fade.top, greaterThan(viewport.top + viewport.height / 2));
    final toggle = find.byKey(const ValueKey('comic_about_toggle'));
    final svg = find.descendant(of: toggle, matching: find.byType(SvgPicture));
    expect(tester.getRect(svg).top, lessThan(viewport.bottom));
    expect(tester.getRect(svg).bottom, greaterThan(viewport.bottom));
    expect(tester.getRect(toggle).height, 44);
    // 重叠区域全部位于父布局内，图标本身与完整透明触控区均可以点按。
    await tester.tap(svg);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('comic_about_viewport'))).height,
      greaterThan(viewport.height),
    );
    expect(
      tester.getRect(svg).top,
      greaterThan(
        tester
            .getRect(find.byKey(const ValueKey('comic_about_viewport')))
            .bottom,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  for (final novel in [false, true]) {
    for (final size in [
      const Size(390, 844),
      const Size(844, 390),
      const Size(466, 678),
    ]) {
      testWidgets('${novel ? '长篇' : '漫画'}简介正文双向切换无波纹 $size', (tester) async {
        await _mount(
          tester,
          novel: novel,
          size: size,
          dark: size.width > size.height,
          scale: size.width == 466 ? 2 : 1,
        );
        final prefix = novel ? 'novel_about' : 'comic_about';
        final viewport = find.byKey(ValueKey('${prefix}_viewport'));
        final body = tester.widget<InkWell>(
          find.byKey(ValueKey('${prefix}_text')),
        );
        expect(body.onTap, isNotNull);
        expect(body.splashFactory, NoSplash.splashFactory);
        expect(
          body.overlayColor?.resolve({WidgetState.pressed}),
          Colors.transparent,
        );
        expect(
          find.descendant(
            of: find.byKey(ValueKey('${prefix}_toggle')),
            matching: find.byType(InkWell),
          ),
          findsNothing,
        );
        final collapsed = tester.getSize(viewport).height;
        await tester.tapAt(tester.getTopLeft(viewport) + const Offset(20, 10));
        await tester.pumpAndSettle();
        expect(tester.getSize(viewport).height, greaterThan(collapsed));
        await tester.tapAt(tester.getTopLeft(viewport) + const Offset(20, 10));
        await tester.pumpAndSettle();
        expect(tester.getSize(viewport).height, closeTo(collapsed, 0.01));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('展开的超长简介正文仍可拖动页面，滚动不触发收起', (tester) async {
    await _mount(
      tester,
      novel: true,
      description: List.filled(80, _description).join('\n'),
    );
    final viewport = find.byKey(const ValueKey('novel_about_viewport'));
    final collapsed = tester.getSize(viewport).height;
    await tester.tapAt(tester.getTopLeft(viewport) + const Offset(20, 10));
    await tester.pumpAndSettle();
    final expanded = tester.getSize(viewport).height;
    expect(expanded, greaterThan(844));
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
      greaterThan(100),
    );
    expect(tester.getSize(viewport).height, expanded);
    await tester.tapAt(const Offset(40, 100));
    await tester.pumpAndSettle();
    expect(tester.getSize(viewport).height, closeTo(collapsed, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('漫画简介在局部系统区反复避让后停止调度布局帧并保持可点按', (tester) async {
    const size = Size(466, 678);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    // 在完整宽度恰好两行，进入局部系统区后超过两行，覆盖展开入口变化。
    final description = List.filled(54, 'a').join();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: size,
            padding: EdgeInsets.only(right: 84),
            viewPadding: EdgeInsets.only(right: 84),
            displayFeatures: [
              DisplayFeature(
                bounds: Rect.fromLTWH(382, 0, 84, 124),
                type: DisplayFeatureType.cutout,
                state: DisplayFeatureState.unknown,
              ),
            ],
          ),
          child: WindowLayoutScope(
            child: Scaffold(
              body: WindowContentLayout(
                child: SingleChildScrollView(
                  controller: scroll,
                  child: Column(
                    children: [
                      const SizedBox(height: 220),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: ComicAboutStory(
                          description: description,
                          embedded: true,
                        ),
                      ),
                      const SizedBox(height: 1200),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await _settle_frames(tester);
    final toggle = find.byKey(const ValueKey('comic_about_toggle'));
    expect(toggle, findsNothing);
    for (var cycle = 0; cycle < 3; cycle++) {
      scroll.jumpTo(220);
      await _settle_frames(tester);
      expect(toggle, findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.tap(toggle);
      await _settle_frames(tester);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.tap(toggle);
      await _settle_frames(tester);
      scroll.jumpTo(400);
      await _settle_frames(tester);
      expect(tester.binding.hasScheduledFrame, isFalse);
      scroll.jumpTo(0);
      await _settle_frames(tester);
      expect(toggle, findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('关闭系统动画后漫画简介和双箭头立即切换', (tester) async {
    await _mount(tester, disable_animations: true);
    final viewport = find.byKey(const ValueKey('comic_about_viewport'));
    final collapsed = tester.getSize(viewport).height;
    await tester.tap(find.byKey(const ValueKey('comic_about_toggle')));
    await tester.pump();
    final rotation = tester.widget<AnimatedRotation>(
      find.descendant(
        of: find.byType(SynopsisToggleButton),
        matching: find.byType(AnimatedRotation),
      ),
    );
    expect(rotation.duration, Duration.zero);
    expect(rotation.turns, 0);
    expect(tester.getSize(viewport).height, greaterThan(collapsed));
    expect(
      tester.getSize(viewport).height,
      tester.getSize(find.text(_description)).height,
    );
    expect(
      tester
          .widget<RotationTransition>(
            find.descendant(
              of: find.byType(SynopsisToggleButton),
              matching: find.byType(RotationTransition),
            ),
          )
          .turns
          .value,
      0,
    );
    expect(tester.takeException(), isNull);
  });
}
