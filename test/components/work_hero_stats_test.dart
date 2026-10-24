import 'dart:ui' as ui;

import 'package:app/components/work_hero_stats/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/config/color_config.dart';

Future<void> _mount(
  WidgetTester tester, {
  required List<WorkHeroStat> items,
  double width = 280,
  double text_scale = 1,
  bool dark = false,
  bool on_hero = true,
}) => tester.pumpWidget(
  MaterialApp(
    theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(text_scale)),
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            child: WorkHeroStatsRow(
              items: items,
              on_hero: on_hero,
              is_dark: dark,
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  for (final dark in [false, true]) {
    for (final on_hero in [false, true]) {
      testWidgets('统计栏 $dark/$on_hero 两项数据均分可见磨砂面板并保留原数值', (tester) async {
        await _mount(
          tester,
          dark: dark,
          on_hero: on_hero,
          items: const [
            WorkHeroStat(
              icon: Icons.people_outline,
              value: '234.1K',
              label: 'Readers',
            ),
            WorkHeroStat(
              icon: Icons.text_fields,
              value: '1.2M',
              label: 'Words',
            ),
          ],
        );
        expect(find.text('234.1K'), findsOneWidget);
        expect(find.text('1.2M'), findsOneWidget);
        final stats = find.byType(WorkHeroStatsRow);
        expect(tester.getSize(stats).height, inInclusiveRange(40, 70));
        expect(find.byType(BackdropFilter), findsOneWidget);
        final surface_finder = find.byKey(
          const ValueKey('work_hero_stats_glass_surface'),
        );
        final surface = tester.widget<DecoratedBox>(surface_finder);
        final decoration = surface.decoration as BoxDecoration;
        expect(decoration.gradient, isNotNull);
        expect(decoration.border, isNotNull);
        expect(
          decoration.gradient!.colors.every(
            (color) => color.a > 0 && color.a <= 0.22,
          ),
          isTrue,
        );
        expect(tester.getSize(surface_finder).width, 280);
        expect(
          find.byKey(const ValueKey('work_hero_stats_top_highlight')),
          findsOneWidget,
        );
        final readers = tester.getRect(find.text('Readers'));
        final words = tester.getRect(find.text('Words'));
        expect(readers.top, words.top);
        expect(readers.right, lessThan(words.left));
        final readers_row = tester.getRect(
          find.ancestor(
            of: find.text('Readers'),
            matching: find.byType(Row),
          ),
        );
        final words_row = tester.getRect(
          find.ancestor(
            of: find.text('Words'),
            matching: find.byType(Row),
          ),
        );
        expect(
          tester.getCenter(find.text('234.1K')).dx,
          closeTo(readers_row.center.dx, 0.1),
        );
        expect(
          tester.getCenter(find.text('1.2M')).dx,
          closeTo(words_row.center.dx, 0.1),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('窄屏大字统计自然换列，完整标签和点击语义均保留', (tester) async {
    final semantics = tester.ensureSemantics();
    var comments = 0;
    const label = 'Readers across the entire world';
    await _mount(
      tester,
      width: 120,
      text_scale: 2,
      items: [
        const WorkHeroStat(
          icon: Icons.people_outline,
          value: '234.1K',
          label: label,
        ),
        WorkHeroStat(
          icon: Icons.chat_bubble_outline,
          value: '12.4K',
          label: 'Comments',
          on_tap: () => comments++,
        ),
      ],
    );
    final readers = tester.getRect(find.text(label));
    final comments_bounds = tester.getRect(find.text('Comments'));
    expect(comments_bounds.top, greaterThanOrEqualTo(readers.bottom));
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text(label), matching: find.byType(RichText)),
    );
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(find.bySemanticsLabel('Comments 12.4K'), findsOneWidget);
    await tester.tap(find.text('12.4K'));
    expect(comments, 1);
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('没有业务数据时不预留统计高度', (tester) async {
    await _mount(tester, items: const []);
    expect(tester.getSize(find.byType(WorkHeroStatsRow)).height, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('磨砂表面实际透出背景色彩，不能被深色填充盖成不透明卡片', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: ValueKey('transparent_glass_capture'),
              child: SizedBox(
                width: 280,
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ColorConstants.components_work_hero_stats_test_tone_ff306ead,
                            ColorConstants.components_work_hero_stats_test_tone_ff306ead,
                            ColorConstants.components_work_hero_stats_test_tone_ffad713b,
                            ColorConstants.components_work_hero_stats_test_tone_ffad713b,
                          ],
                          stops: [0, 0.5, 0.5, 1],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: WorkHeroStatsRow(
                        on_hero: true,
                        is_dark: true,
                        items: [
                          WorkHeroStat(
                            icon: Icons.people_outline,
                            value: '234.1K',
                            label: 'Readers',
                          ),
                          WorkHeroStat(
                            icon: Icons.text_fields,
                            value: '1.2M',
                            label: 'Words',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final capture = find.byKey(const ValueKey('transparent_glass_capture'));
    final boundary = tester.renderObject<RenderRepaintBoundary>(capture);
    final surface = tester.getRect(
      find.byKey(const ValueKey('work_hero_stats_glass_surface')),
    );
    final y = (surface.top - tester.getTopLeft(capture).dy + 66).round();
    final pixels = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return bytes!;
    });
    // 采样远离文字、图标和分隔线的位置，检查两个区域仍保留各自的底图颜色。
    for (final sample in [
      (16, [48, 110, 173]),
      (264, [173, 113, 59]),
    ]) {
      final offset = (y * 280 + sample.$1) * 4;
      for (var channel = 0; channel < 3; channel++) {
        expect(
          (pixels!.getUint8(offset + channel) - sample.$2[channel]).abs(),
          lessThanOrEqualTo(55),
        );
      }
    }
    expect(tester.takeException(), isNull);
  });
}
