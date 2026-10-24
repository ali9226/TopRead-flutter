// ignore_for_file: non_constant_identifier_names

import 'dart:ui' show DisplayFeature, DisplayFeatureType, DisplayFeatureState;
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/widgets/about_story/index.dart';
import 'package:app/pages/comics/detail/widgets/similar_comics/index.dart';
import 'package:app/pages/comics/detail/widgets/similar_comics/comic_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _description =
    'A heartwarming action love story about Lily and a boy who carries a mysterious past. '
    'When their peaceful town is threatened by dark forces, they must stand together. '
    'The full description remains available while the card animates. '
    'Each journey brings another discovery and another reason to keep reading. '
    'The full description remains available while the card animates. '
    'Each journey brings another discovery and another reason to keep reading.';

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  double scale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          textScaler: TextScaler.linear(scale),
        ),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('简介多次展开收起保持可点击，并呈现中间动画高度', (tester) async {
    await _mount(tester, const ComicAboutStory(description: _description));
    final collapsed = tester.getSize(find.byType(ComicAboutStory)).height;
    final toggle = find.byKey(const ValueKey('comic_about_toggle'));
    expect(tester.getSize(toggle).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(toggle).height, greaterThanOrEqualTo(44));

    for (var index = 0; index < 2; index++) {
      final header_rect = tester.getRect(
        find.byKey(const ValueKey('comic_about_header')),
      );
      await tester.tap(toggle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      final intermediate = tester.getSize(find.byType(ComicAboutStory)).height;
      await tester.pumpAndSettle();
      final expanded = tester.getSize(find.byType(ComicAboutStory)).height;
      expect(intermediate, greaterThan(collapsed));
      expect(intermediate, lessThan(expanded));
      final collapse = find.byKey(const ValueKey('comic_about_collapse'));
      expect(collapse.hitTestable(), findsOneWidget);
      expect(tester.getRect(collapse), header_rect);
      expect(find.text('comics.show_less'), findsNothing);
      final full_text_height = tester.getSize(find.text(_description)).height;
      await tester.tap(toggle);
      await tester.pump();
      expect(tester.widget<Text>(find.text(_description)).maxLines, isNull);
      expect(tester.getSize(find.text(_description)).height, full_text_height);
      await tester.pump(const Duration(milliseconds: 80));
      final collapsing = tester.getSize(find.byType(ComicAboutStory)).height;
      expect(collapsing, greaterThan(collapsed));
      expect(collapsing, lessThan(expanded));
      expect(tester.getSize(find.text(_description)).height, full_text_height);
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(ComicAboutStory)).height, collapsed);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('切换简介文本重置展开状态', (tester) async {
    final description = ValueNotifier(_description);
    addTearDown(description.dispose);
    await _mount(
      tester,
      ValueListenableBuilder<String>(
        valueListenable: description,
        builder: (context, text, _) => ComicAboutStory(description: text),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('comic_about_toggle')));
    await tester.pumpAndSettle();
    description.value = 'Another language version.';
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('comic_about_collapse')), findsNothing);
    expect(find.text('Another language version.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('简介展开时字体缩放会重新计算完整高度', (tester) async {
    final scale = ValueNotifier(1.0);
    addTearDown(scale.dispose);
    await _mount(
      tester,
      ValueListenableBuilder<double>(
        valueListenable: scale,
        builder: (context, value, _) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(value)),
          child: const ComicAboutStory(description: _description),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('comic_about_toggle')));
    await tester.pumpAndSettle();
    final before = tester
        .getSize(find.byKey(const ValueKey('comic_about_viewport')))
        .height;
    scale.value = 1.5;
    await tester.pumpAndSettle();
    final viewport = tester
        .getSize(find.byKey(const ValueKey('comic_about_viewport')))
        .height;
    expect(viewport, greaterThan(before));
    expect(
      viewport,
      closeTo(tester.getSize(find.text(_description)).height, 0.01),
    );
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 1.5, 2.5]) {
    testWidgets('推荐统一卡片高度，长标题和 $scale 倍字体不溢出', (tester) async {
      final comics = List.generate(
        5,
        (index) => ComicItem(
          id: index + 1,
          title: index.isEven
              ? 'The very long adventures beyond tomorrow'
              : '在遥远世界中寻找晨光的漫长旅途',
          cover_url: '',
          author_id: 1,
          author_name: 'Author',
          categories: const [],
          chapter_count: 1,
          language_count: 1,
          status: 'published',
        ),
      );
      int? opened;
      await _mount(
        tester,
        ComicSimilarComicsRow(comics: comics, on_tap: (id) => opened = id),
        scale: scale,
      );
      expect(tester.takeException(), isNull);
      final heights = tester
          .widgetList<ComicSimilarComicCard>(find.byType(ComicSimilarComicCard))
          .map((card) => tester.getSize(find.byWidget(card)).height)
          .toSet();
      expect(heights, hasLength(1));
      await tester.drag(
        find.byType(ComicSimilarComicsRow),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(comics.last.title).last);
      expect(opened, 5);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Duo 简介与推荐随折叠横屏展开切换可操作且无溢出', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in const [Size(466, 678), Size(951, 669), Size(669, 951)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              padding: const EdgeInsets.only(right: 84, bottom: 34),
              viewPadding: const EdgeInsets.only(right: 84, bottom: 34),
              textScaler: const TextScaler.linear(1.5),
              displayFeatures: [
                DisplayFeature(
                  bounds: Rect.fromLTWH(size.width - 84, 0, 84, size.height),
                  type: DisplayFeatureType.cutout,
                  state: DisplayFeatureState.unknown,
                ),
              ],
            ),
            child: Scaffold(
              body: WindowContentLayout(
                max_width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const ComicAboutStory(description: _description),
                      ComicSimilarComicsRow(
                        comics: List.generate(
                          5,
                          (index) => ComicItem(
                            id: index + 1,
                            title: 'The long journey beyond tomorrow',
                            cover_url: '',
                            author_id: 1,
                            author_name: 'Author',
                            categories: const [],
                            chapter_count: 1,
                            language_count: 1,
                            status: 'published',
                          ),
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
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('comic_about_toggle')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('comic_about_toggle')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('comic_about_toggle')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('comic_about_collapse')), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
}
