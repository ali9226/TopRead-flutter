import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:app/components/expandable_synopsis/index.dart';
import 'package:app/components/expandable_synopsis/style.dart';
import 'package:app/components/expandable_synopsis/toggle_button.dart';
import 'package:app/config/color_config.dart';
import 'package:app/components/content_category_tag/style.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/components/work_about_section/index.dart';
import 'package:app/components/work_genres_section/index.dart';
import 'package:app/components/work_section_card/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _mount(
  WidgetTester tester, {
  required String description,
  required List<String> tags,
  bool dark = false,
  double width = 390,
  double scale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 900),
          textScaler: TextScaler.linear(scale),
        ),
        child: Scaffold(
          backgroundColor: WorkSectionCardStyle.background(dark),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(
                WorkAboutSectionStyle.horizontal_padding,
              ),
              child: WorkAboutSection(
                description: description,
                tags: tags,
                is_dark: dark,
                title: 'About',
                key_prefix: 'detail_about',
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final dark in [false, true]) {
    testWidgets('连续正文先简介后分类，展开自然推移后续内容 dark=$dark', (tester) async {
      final description = List.filled(
        6,
        'A traveler discovers a forgotten city beneath the morning star, '
        'and begins a journey to bring its stories home.',
      ).join(' ');
      await _mount(
        tester,
        description: description,
        tags: ['Fantasy', 'Adventure'],
        dark: dark,
      );
      expect(find.byType(WorkSectionCard), findsNothing);
      final about = find.byType(ExpandableSynopsis);
      final genres = find.byType(WorkGenresSection);
      expect(
        tester.getBottomLeft(about).dy,
        lessThan(tester.getTopLeft(genres).dy),
      );
      final viewport = find.byKey(const ValueKey('detail_about_viewport'));
      final collapsed = tester.getSize(viewport).height;
      final original_genres_top = tester.getTopLeft(genres).dy;
      await tester.tap(find.byKey(const ValueKey('detail_about_header')));
      await tester.pumpAndSettle();
      final expanded = tester.getSize(viewport).height;
      expect(expanded, greaterThan(collapsed));
      expect(
        tester.getTopLeft(genres).dy - original_genres_top,
        closeTo(expanded - collapsed, 0.1),
      );
      await tester.tap(find.byKey(const ValueKey('detail_about_collapse')));
      await tester.pumpAndSettle();
      expect(tester.getSize(viewport).height, collapsed);
      expect(tester.getTopLeft(genres).dy, original_genres_top);
      expect(tester.takeException(), isNull);
    });
  }

  for (final dark in [false, true]) {
    testWidgets('简介采用居中主题色圆形箭头与昼夜截断渐变，无可见展开文字 dark=$dark', (tester) async {
      final description = List.filled(
        3,
        'A traveler follows an old promise across the forgotten world and discovers a city beneath the stars.',
      ).join(' ');
      await _mount(
        tester,
        description: description,
        tags: const [],
        dark: dark,
      );
      final synopsis = tester.widget<ExpandableSynopsis>(
        find.byType(ExpandableSynopsis),
      );
      final toggle = find.byKey(const ValueKey('detail_about_toggle'));
      final toggle_element = tester.element(toggle);
      final container = tester.widget<Container>(
        find.descendant(
          of: toggle,
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, ColorConstants.themeColor);
      final icon = tester.widget<Icon>(
        find.descendant(
          of: toggle,
          matching: find.byType(Icon),
        ),
      );
      expect(icon.color, ColorConstants.lightTextColor);
      expect(
        tester.getSize(toggle),
        const Size.square(ExpandableSynopsisStyle.toggle_extent),
      );
      expect(
        tester.getCenter(toggle).dx,
        closeTo(tester.getCenter(find.byType(WorkAboutSection)).dx, 0.01),
      );
      expect(find.text(synopsis.expand_label), findsNothing);
      expect(find.text(synopsis.collapse_label), findsNothing);
      expect(find.byTooltip(synopsis.expand_label), findsOneWidget);
      Semantics semantics() => tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(SynopsisToggleButton),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics && widget.properties.expanded != null,
              ),
            )
            .first,
      );
      expect(semantics().properties.label, synopsis.expand_label);
      expect(semantics().properties.expanded, isFalse);
      final fade = find.byKey(const ValueKey('detail_about_fade'));
      final gradient =
          (tester.widget<DecoratedBox>(fade).decoration as BoxDecoration)
                  .gradient!
              as LinearGradient;
      final surface = dark ? ColorConstants.nightBackgroundColor : ColorConstants.whiteColor;
      expect(gradient.colors.first.a, 0);
      expect(gradient.colors.last.withValues(alpha: 1), surface);
      expect(gradient.colors.last.a, ExpandableSynopsisStyle.fade_bottom_alpha);
      final viewport = find.byKey(const ValueKey('detail_about_viewport'));
      final collapsed_height = tester.getSize(viewport).height;
      expect(tester.getRect(fade).bottom, tester.getRect(viewport).bottom);
      expect(tester.getSize(fade).height, lessThan(collapsed_height));
      final header_rect = tester.getRect(
        find.byKey(const ValueKey('detail_about_header')),
      );
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(tester.element(toggle), same(toggle_element));
      expect(tester.getSize(viewport).height, greaterThan(collapsed_height));
      expect(find.byKey(const ValueKey('detail_about_fade')), findsNothing);
      expect(
        tester.getRect(find.byKey(const ValueKey('detail_about_collapse'))),
        header_rect,
      );
      expect(find.text(synopsis.collapse_label), findsNothing);
      expect(find.byTooltip(synopsis.collapse_label), findsOneWidget);
      expect(semantics().properties.label, synopsis.collapse_label);
      expect(semantics().properties.expanded, isTrue);
      final rotation = tester.widget<AnimatedRotation>(
        find.descendant(
          of: find.byType(SynopsisToggleButton),
          matching: find.byType(AnimatedRotation),
        ),
      );
      expect(rotation.turns, 0.5);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(tester.getSize(viewport).height, collapsed_height);
      expect(find.byKey(const ValueKey('detail_about_fade')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('显式深色表面用于渐变，避免不同阅读背景出现色块', (tester) async {
    const surface = ColorConstants.test_components_fullbleed_surfaces_test_tone;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: surface,
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: ExpandableSynopsis(
              description: List.filled(
                8,
                'A forgotten promise begins another journey across the stars.',
              ).join(' '),
              title: 'About',
              empty_description: '',
              expand_label: 'Expand description',
              collapse_label: 'Collapse description',
              is_dark: true,
              embedded: true,
              surface_color: surface,
              key_prefix: 'explicit_surface',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final decoration =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey('explicit_surface_fade')),
                )
                .decoration
            as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;
    expect(gradient.colors.last.withValues(alpha: 1), surface);
    expect(find.text('Expand description'), findsNothing);
    expect(find.byTooltip('Expand description'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('短简介按单行文字决定高度，不显示没有意义的展开按钮', (tester) async {
    await _mount(tester, description: 'A quiet journey home.', tags: const []);
    expect(find.byKey(const ValueKey('detail_about_toggle')), findsNothing);
    expect(find.byKey(const ValueKey('detail_about_fade')), findsNothing);
    expect(tester.getSize(find.byType(WorkAboutSection)).height, lessThan(90));
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 760.0]) {
    testWidgets('大量长分类在 $width 宽与大字号下自然换行且按既有配色顺序循环', (tester) async {
      final tags = [
        'Supernatural Adventures Across Forgotten Worlds',
        'Fantasy',
        'Action',
        'Time Travel',
        'Romance',
        'Mystery',
        'Psychology',
        'Progression',
        'Feel-good',
        'Epic Adventure',
      ];
      await _mount(
        tester,
        description: 'A quiet journey home.',
        tags: tags,
        width: width,
        scale: 1.8,
      );
      final genres = find.byType(WorkGenresSection);
      final bounds = tester.getRect(genres);
      for (var index = 0; index < tags.length; index++) {
        final tag = tags[index];
        final tag_bounds = tester.getRect(find.text(tag));
        expect(tag_bounds.left, greaterThanOrEqualTo(bounds.left));
        expect(tag_bounds.right, lessThanOrEqualTo(bounds.right));
        final decoration =
            tester
                    .widget<Container>(
                      find
                          .ancestor(
                            of: find.text(tag),
                            matching: find.byType(Container),
                          )
                          .first,
                    )
                    .decoration!
                as BoxDecoration;
        expect(
          decoration.color,
          ColorConstants.resolveTagColor(
            index,
          ).withValues(alpha: ContentCategoryTagStyle.background_alpha_light),
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Duo滚动进入局部系统区时简介标题和分类标签局部避让，正文区域保持全宽', (tester) async {
    const size = Size(466, 678);
    const obstruction = Rect.fromLTWH(382, 0, 84, 124);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: size,
            padding: EdgeInsets.only(right: 84),
            viewPadding: EdgeInsets.only(right: 84),
            displayFeatures: [
              DisplayFeature(
                bounds: obstruction,
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
                        padding: const EdgeInsets.all(
                          WorkAboutSectionStyle.horizontal_padding,
                        ),
                        child: WorkAboutSection(
                          description: List.filled(
                            8,
                            'An old promise becomes a journey across the forgotten world.',
                          ).join(' '),
                          tags: const [
                            'Supernatural Adventures Across Forgotten Worlds',
                            'Fantasy',
                            'Mystery',
                            'Adventure',
                          ],
                          is_dark: false,
                          title:
                              'About this remarkable journey through the forgotten world',
                          key_prefix: 'duo_about',
                        ),
                      ),
                      const SizedBox(
                        key: ValueKey('full_width_body'),
                        width: double.infinity,
                        height: 1200,
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
    expect(
      tester.getSize(find.byKey(const ValueKey('full_width_body'))).width,
      size.width,
    );
    scroll.jumpTo(220);
    await tester.pumpAndSettle();
    final heading = tester.getRect(
      find.byKey(const ValueKey('duo_about_header')),
    );
    expect(heading.overlaps(obstruction), isFalse);
    final tags = find.byKey(const ValueKey('work_genres_tags'));
    final initial_tag_top = tester.getTopLeft(tags).dy;
    scroll.jumpTo(scroll.offset + initial_tag_top - 20);
    await tester.pumpAndSettle();
    final tag_bounds = tester.getRect(tags);
    expect(tag_bounds.overlaps(obstruction), isFalse);
    expect(
      tester.getSize(find.byKey(const ValueKey('full_width_body'))).width,
      size.width,
    );
    expect(tester.takeException(), isNull);
  });
}
