import 'package:app/components/work_about_section/index.dart';
import 'package:app/components/work_genres_section/index.dart';
import 'package:app/components/work_genres_section/style.dart';
import 'package:app/components/work_genres_section/widgets/genre_tag.dart';
import 'package:app/components/work_section_card/index.dart';
import 'package:app/components/content_category_tag/style.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/widgets/overview_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('小说与漫画分类连续排版，长文案完整换行且不使用独立白卡 dark=$dark', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const tags = [
        'Supernatural Adventures Across Forgotten Worlds',
        'Fantasy',
        'Romance',
        'Mystery',
      ];
      final detail = ComicDetail.from_json({
        'comic': {
          'id': 42,
          'title': 'Story',
          'categories': tags.map((name) => {'name': name}).toList(),
        },
        'languages': [
          {'id': 1, 'language': 'en', 'title': 'Story', 'description': 'About'},
        ],
        'selected_language_id': 1,
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: dark ? Brightness.dark : Brightness.light,
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: WorkAboutSectionStyle.horizontal_padding,
                    ),
                    child: WorkAboutSection(
                      description: 'About',
                      tags: tags,
                      is_dark: dark,
                    ),
                  ),
                  ComicDetailOverviewTab(detail: detail, is_dark: dark),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final sections = find.byType(WorkGenresSection);
      expect(sections, findsOneWidget);
      expect(find.byType(WorkSectionCard), findsNothing);
      for (var index = 0; index < 1; index++) {
        final section = sections.at(index);
        final rect = tester.getRect(section);
        expect(rect.left, WorkAboutSectionStyle.horizontal_padding);
        expect(rect.width, 320 - WorkAboutSectionStyle.horizontal_padding * 2);
        final wrap = find.descendant(of: section, matching: find.byType(Wrap));
        expect(
          tester.renderObject<RenderBox>(wrap).constraints.maxWidth,
          rect.width,
        );
        final long_tag = find.descendant(
          of: section,
          matching: find.text(tags.first),
        );
        final text_bounds = tester.getRect(long_tag);
        expect(text_bounds.left, greaterThanOrEqualTo(rect.left));
        expect(text_bounds.right, lessThanOrEqualTo(rect.right));
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: long_tag, matching: find.byType(RichText)),
        );
        expect(paragraph.didExceedMaxLines, isFalse);
      }
      expect(tester.takeException(), isNull);
    });

    for (final embedded in [false, true]) {
      testWidgets('分类颜色按tagColorList顺序循环且共享胶囊样式 dark=$dark embedded=$embedded', (
        tester,
      ) async {
        final tags = List.generate(
          ColorConstants.tagColorList.length + 2,
          (index) => index == 1
              ? 'Supernatural Adventures Across Forgotten Worlds'
              : index == 2
              ? '穿越遥远群星寻找最后一缕晨光的奇幻冒险故事'
              : 'Genre $index',
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
            home: Scaffold(
              body: MediaQuery(
                data: const MediaQueryData(
                  textScaler: TextScaler.linear(1.6),
                ),
                child: SingleChildScrollView(
                  child: Center(
                    child: SizedBox(
                      width: 260,
                      child: WorkGenresSection(
                        title: 'Genres',
                        tags: tags,
                        content_id: 42,
                        is_dark: dark,
                        embedded: embedded,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final pills = find.byType(WorkGenreTag);
        expect(pills, findsNWidgets(tags.length));
        final wrap = tester.getRect(
          find.byKey(const ValueKey('work_genres_tags')),
        );
        for (var index = 0; index < tags.length; index++) {
          final pill = pills.at(index);
          final color = ColorConstants.tagColorList[
            index % ColorConstants.tagColorList.length
          ];
          final label = find.descendant(of: pill, matching: find.text(tags[index]));
          final text = tester.widget<Text>(label);
          expect(
            text.style!.color,
            color.withValues(alpha: ContentCategoryTagStyle.text_alpha),
          );
          final container = tester.widget<Container>(
            find.descendant(of: pill, matching: find.byType(Container)).first,
          );
          final decoration = container.decoration as BoxDecoration;
          expect(
            decoration.color,
            color.withValues(
              alpha: dark
                  ? ContentCategoryTagStyle.background_alpha_dark
                  : ContentCategoryTagStyle.background_alpha_light,
            ),
          );
          expect(
            decoration.borderRadius,
            BorderRadius.circular(WorkGenresSectionStyle.tag_radius),
          );
          final bounds = tester.getRect(pill);
          expect(bounds.left, greaterThanOrEqualTo(wrap.left));
          expect(bounds.right, lessThanOrEqualTo(wrap.right));
          expect(bounds.height, greaterThanOrEqualTo(22));
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: label, matching: find.byType(RichText)),
          );
          expect(paragraph.didExceedMaxLines, isFalse);
        }
        expect(
          tester.widget<WorkGenreTag>(pills.first).color,
          tester.widget<WorkGenreTag>(pills.at(ColorConstants.tagColorList.length)).color,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
