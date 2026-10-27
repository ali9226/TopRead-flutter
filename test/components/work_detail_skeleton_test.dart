import 'dart:io';
import 'dart:ui' as ui;

import 'package:app/components/work_detail_skeleton/index.dart';
import 'package:app/components/work_detail_skeleton/comic_chapters.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/widgets/chapter_preview/index.dart';
import 'package:app/pages/comics/detail/widgets/chapter_preview/chapter_card.dart';
import 'package:app/pages/comics/widgets/comic_image.dart';
import 'package:app/components/work_about_section/style.dart';
import 'package:app/components/work_introduction_hero/index.dart';
import 'package:app/components/work_introduction_hero/style.dart';
import 'package:app/pages/read/widgets/skeleton/content_skeleton.dart';
import 'package:app/pages/short_story_read/widgets/skeleton_content.dart';
import 'package:app/pages/short_story_read/widgets/story_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'
    show CupertinoLocalizations, DefaultCupertinoLocalizations;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _preview_dir = String.fromEnvironment('WORK_SKELETON_PREVIEW_DIR');
const _boundary_key = ValueKey('skeleton_preview');

Future<Color> _sample_color(WidgetTester tester, Offset position) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary_key),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final offset =
        (position.dy.floor() * image.width + position.dx.floor()) * 4;
    final color = Color.fromARGB(
      bytes!.getUint8(offset + 3),
      bytes.getUint8(offset),
      bytes.getUint8(offset + 1),
      bytes.getUint8(offset + 2),
    );
    image.dispose();
    return color;
  }))!;
}

/// 导航仅需通用Material文案，避免为几何测试引入新的本地化依赖。
class _TestMaterialDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _TestMaterialDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture(const DefaultMaterialLocalizations());
  @override
  bool shouldReload(_TestMaterialDelegate old) => false;
}

class _TestCupertinoDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _TestCupertinoDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture(const DefaultCupertinoLocalizations());
  @override
  bool shouldReload(_TestCupertinoDelegate old) => false;
}

Future<void> _mount(
  WidgetTester tester, {
  WorkDetailSkeletonKind kind = WorkDetailSkeletonKind.novel,
  Size size = const Size(390, 844),
  Locale locale = const Locale('zh'),
  bool dark = false,
  double text_scale = 1,
  bool disable_animations = false,
  bool ticker_enabled = true,
  VoidCallback? on_back,
  Widget? child,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('zh'), Locale('en')],
      localizationsDelegates: const [
        _TestMaterialDelegate(),
        _TestCupertinoDelegate(),
      ],
      theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: const EdgeInsets.only(top: 44, bottom: 24),
          viewPadding: const EdgeInsets.only(top: 44, bottom: 24),
          textScaler: TextScaler.linear(text_scale),
          disableAnimations: disable_animations,
        ),
        child: TickerMode(
          enabled: ticker_enabled,
          child: Scaffold(
            body: RepaintBoundary(
              key: _boundary_key,
              child:
                  child ??
                  WorkDetailSkeleton(
                    is_dark: dark,
                    kind: kind,
                    on_back: on_back ?? () {},
                  ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _write_preview(WidgetTester tester, String filename) async {
  if (_preview_dir.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary_key),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_preview_dir/$filename.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final kind in WorkDetailSkeletonKind.values) {
    for (final dark in [false, true]) {
      testWidgets('$kind matches the real hero geometry, dark=$dark', (
        tester,
      ) async {
        await _mount(tester, kind: kind, dark: dark);
        expect(tester.takeException(), isNull);
        expect(find.byType(WorkIntroductionHero), findsOneWidget);
        final cover = tester.getRect(
          find.byKey(const ValueKey('work_introduction_cover')),
        );
        final title = tester.getRect(
          find.byKey(const ValueKey('work_detail_skeleton_title')),
        );
        final short_story = kind == WorkDetailSkeletonKind.short_story;
        final supporting = tester.getRect(
          find.byKey(
            ValueKey(
              short_story
                  ? 'work_detail_skeleton_hero_synopsis'
                  : 'work_detail_skeleton_stats',
            ),
          ),
        );
        final hero = tester.getRect(
          find.byKey(const ValueKey('work_introduction_poster')),
        );
        final body = tester.getRect(
          find.byKey(const ValueKey('work_detail_skeleton_body')),
        );
        expect(
          cover.width / cover.height,
          closeTo(WorkIntroductionHeroStyle.cover_width_to_height, .001),
        );
        expect(title.left, greaterThan(cover.right));
        expect(supporting.top, greaterThanOrEqualTo(cover.bottom));
        expect(body.top, closeTo(hero.bottom, .01));
        if (short_story) {
          expect(
            find.byKey(const ValueKey('work_detail_skeleton_stats')),
            findsNothing,
          );
          expect(
            find.descendant(
              of: find.byKey(
                const ValueKey('work_detail_skeleton_hero_synopsis_text'),
              ),
              matching: find.byType(SkeletonTextLine),
            ),
            findsNWidgets(2),
          );
        }
        expect(
          find.byKey(const ValueKey('work_detail_skeleton_synopsis')),
          short_story ? findsNothing : findsOneWidget,
        );
        // 对最终像素作检查，避免浅色主题仍被照片专用暗幕或深色占位覆盖。
        final cover_color = await _sample_color(tester, cover.center);
        expect(
          cover_color.computeLuminance(),
          dark ? lessThan(0.3) : greaterThan(0.65),
        );
        expect(
          find.byKey(const ValueKey('work_introduction_scrim')),
          dark ? findsOneWidget : findsNothing,
        );
        expect(
          find.byKey(const ValueKey('work_detail_skeleton_comments')),
          kind == WorkDetailSkeletonKind.novel ? findsOneWidget : findsNothing,
        );
        expect(
          find.byKey(
            const ValueKey('work_detail_skeleton_comic_quick_actions'),
          ),
          findsNothing,
        );
        if (kind == WorkDetailSkeletonKind.comic) {
          final synopsis = find.byKey(
            const ValueKey('work_detail_skeleton_synopsis'),
          );
          final chapters = find.byKey(
            const ValueKey('work_detail_skeleton_chapters'),
          );
          final comments = find.byKey(
            const ValueKey('work_detail_skeleton_comic_comments'),
          );
          final recommendations = find.byKey(
            const ValueKey('work_detail_skeleton_recommendations'),
          );
          expect(
            tester.getRect(chapters).top,
            greaterThan(tester.getRect(synopsis).bottom),
          );
          expect(
            tester.getRect(comments).top,
            greaterThan(tester.getRect(chapters).bottom),
          );
          expect(
            tester.getRect(recommendations).top,
            greaterThan(tester.getRect(comments).bottom),
          );
          expect(
            find.descendant(
              of: find.byKey(
                const ValueKey('work_detail_skeleton_comic_synopsis_text'),
              ),
              matching: find.byType(SkeletonTextLine),
            ),
            findsNWidgets(2),
          );
        }
        if (short_story) {
          final reading = find.byKey(
            const ValueKey('work_detail_skeleton_reading'),
          );
          expect(reading, findsOneWidget);
          expect(tester.getRect(reading).height, greaterThan(200));
          expect(
            find.descendant(
              of: reading,
              matching: find.byType(SkeletonTextLine),
            ),
            findsNWidgets(10),
          );
          expect(
            find.byType(SkeletonPulse),
            findsOneWidget,
            reason: '封面和正文共享一套动画，减少动画也必须整体停止',
          );
        }
        await _write_preview(
          tester,
          'skeleton_${kind.name}_390_${dark ? 'dark' : 'light'}',
        );
      });
    }
  }

  testWidgets('漫画章节骨架与真实章节首图和单行标题轨道保持相同几何', (tester) async {
    for (final size in [
      const Size(390, 844),
      const Size(720, 500),
      const Size(466, 678),
    ]) {
      for (final scale in [1.0, 1.5]) {
        final chapters = List.generate(
          3,
          (index) => ComicChapter(
            id: index + 1,
            title: 'Chapter ${index + 1}',
            page_count: 2,
            sort_order: index,
            status: 'published',
            images: const [],
          ),
        );
        await _mount(
          tester,
          size: size,
          text_scale: scale,
          child: SingleChildScrollView(
            child: ComicChapterPreview(
              chapters: chapters,
              completed: false,
              on_chapters: () {},
              on_open: (_) {},
              horizontal_padding: WorkAboutSectionStyle.horizontal_padding,
            ),
          ),
        );
        final real_image = tester.getRect(
          find.descendant(
            of: find.byType(ComicChapterPreviewCard).first,
            matching: find.byType(ComicImage),
          ),
        );
        final real_rail = tester.getSize(
          find.byKey(const ValueKey('comic_chapter_previews')),
        );
        await _mount(
          tester,
          size: size,
          text_scale: scale,
          child: const SingleChildScrollView(
            child: SkeletonPulse(
              is_dark: false,
              child: ComicSkeletonChapters(cjk: true, is_dark: false),
            ),
          ),
        );
        final placeholder = tester.getRect(
          find.byKey(const ValueKey('work_detail_skeleton_chapter_image_0')),
        );
        expect(placeholder.width, closeTo(real_image.width, .01));
        expect(placeholder.height, closeTo(real_image.height, .01));
        expect(placeholder.left, closeTo(real_image.left, .01));
        expect(
          tester
              .getSize(
                find.byKey(const ValueKey('work_detail_skeleton_chapter_rail')),
              )
              .height,
          closeTo(real_rail.height, .01),
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  for (final kind in WorkDetailSkeletonKind.values) {
    for (final locale in [const Locale('zh'), const Locale('en')]) {
      testWidgets(
        '$kind handles narrow and wide windows with large $locale text',
        (tester) async {
          for (final size in [const Size(280, 740), const Size(720, 900)]) {
            await _mount(
              tester,
              kind: kind,
              size: size,
              locale: locale,
              text_scale: 2,
            );
            expect(tester.takeException(), isNull);
            final cover = tester.getRect(
              find.byKey(const ValueKey('work_introduction_cover')),
            );
            expect(cover.left, greaterThanOrEqualTo(0));
            expect(cover.right, lessThanOrEqualTo(size.width));
          }
        },
      );
    }
  }

  if (_preview_dir.isNotEmpty) {
    testWidgets('export narrow large Latin skeleton previews', (tester) async {
      for (final kind in WorkDetailSkeletonKind.values) {
        await _mount(
          tester,
          kind: kind,
          size: const Size(320, 844),
          locale: const Locale('en'),
          text_scale: 2,
        );
        expect(tester.takeException(), isNull);
        await _write_preview(tester, 'skeleton_${kind.name}_320_en_2x');
      }
    });
  }

  testWidgets(
    'wide poster and paper fill the caller while hero foreground stays bounded',
    (tester) async {
      const viewport_width = 900.0;
      await _mount(tester, size: const Size(viewport_width, 900));
      expect(tester.takeException(), isNull);
      final poster = tester.getRect(
        find.byKey(const ValueKey('work_introduction_poster')),
      );
      final paper = tester.getRect(
        find.byKey(const ValueKey('work_detail_skeleton_body')),
      );
      final cover = tester.getRect(
        find.byKey(const ValueKey('work_introduction_cover')),
      );
      expect(poster.width, viewport_width);
      expect(paper.width, viewport_width);
      expect(
        cover.width,
        lessThanOrEqualTo(WorkIntroductionHeroStyle.cover_max_width),
      );
      expect(
        cover.left,
        greaterThanOrEqualTo(
          (viewport_width - WorkIntroductionHeroStyle.max_content_width) / 2,
        ),
      );
    },
  );

  testWidgets('back remains available during loading', (tester) async {
    var back_count = 0;
    await _mount(tester, on_back: () => back_count++);
    await tester.tap(find.byType(IconButton));
    expect(back_count, 1);
  });

  testWidgets('sweep repaints without rebuilding the content layout', (
    tester,
  ) async {
    var builds = 0;
    await _mount(
      tester,
      child: SkeletonPulse(
        is_dark: false,
        child: Builder(
          builder: (context) {
            builds++;
            return const SkeletonBlock(width: 120, height: 24);
          },
        ),
      ),
    );
    final initial_builds = builds;
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 450));
    expect(builds, initial_builds);
    expect(tester.binding.transientCallbackCount, greaterThan(0));
  });

  testWidgets(
    'reduced motion and disabled TickerMode stop the animation clock',
    (tester) async {
      await _mount(tester, disable_animations: true);
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      await _mount(tester, ticker_enabled: false);
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      await _mount(tester);
      await tester.pump(const Duration(milliseconds: 40));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
    },
  );

  testWidgets(
    'chapter and short story body placeholders fit a narrow large-text viewport',
    (tester) async {
      for (final content in [
        const ReadContentSkeleton(is_dark: true),
        const SingleChildScrollView(child: SkeletonContent(is_dark: true)),
      ]) {
        await _mount(
          tester,
          size: const Size(280, 740),
          text_scale: 2,
          child: content,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(WorkIntroductionHero), findsNothing);
      }
    },
  );
  testWidgets(
    'real short story loading uses the reader font size and shared motion',
    (tester) async {
      await _mount(
        tester,
        size: const Size(280, 740),
        locale: const Locale('en'),
        disable_animations: true,
        child: const SingleChildScrollView(
          child: StoryContent(
            content: '',
            is_dark: false,
            is_loading: true,
            font_size: 25,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(SkeletonContent), findsOneWidget);
      expect(find.byType(SkeletonPulse), findsOneWidget);
      final lines = tester.widgetList<SkeletonTextLine>(
        find.byType(SkeletonTextLine),
      );
      expect(lines, isNotEmpty);
      expect(lines.every((line) => line.font_size == 25), isTrue);
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
    },
  );
}
