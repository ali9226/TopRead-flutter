import 'dart:io';
import 'dart:ui' as ui;

import 'package:app/components/window_content_layout/index.dart';
import 'package:app/components/work_introduction_hero/index.dart';
import 'package:app/components/work_introduction_hero/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/config/color_config.dart';

const _preview_dir = String.fromEnvironment('WORK_HERO_PREVIEW_DIR');
const _reference_title =
    'Dandelion, A Mageknight Reincarnation (LitRPG, Progression)';

/// 模拟作者组件的本地关注状态，用真实交互检查跨布局迁移后的State身份。
class _StatefulMetadata extends StatefulWidget {
  const _StatefulMetadata();

  @override
  State<_StatefulMetadata> createState() => _StatefulMetadataState();
}

class _StatefulMetadataState extends State<_StatefulMetadata> {
  bool following = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => following = !following),
    child: SizedBox(
      height: 44,
      child: Text(following ? 'Following' : 'Follow'),
    ),
  );
}

/// 使用随Flutter安装的字体验证真实拉丁文字排版；预览时优先使用系统衬线字体。
Future<void> _load_fonts() async {
  final fonts_path =
      '${Platform.environment['FLUTTER_ROOT'] ?? '.fvm/flutter_sdk'}'
      '/bin/cache/artifacts/material_fonts';
  for (final family in ['Roboto', 'Georgia']) {
    final preview_font = File(
      '/System/Library/Fonts/Supplemental/'
      '${family == 'Georgia' ? 'Times New Roman' : 'Arial'}.ttf',
    );
    final font = _preview_dir.isNotEmpty && preview_font.existsSync()
        ? preview_font
        : File('$fonts_path/Roboto-Regular.ttf');
    if (font.existsSync()) {
      await (FontLoader(family)..addFont(
            Future.value(ByteData.sublistView(font.readAsBytesSync())),
          ))
          .load();
    }
  }
  if (_preview_dir.isNotEmpty) {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  }
}

Future<void> _mount(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  String title = 'Dawn',
  double metadata_height = 40,
  Widget? metadata_content,
  double text_scale = 1,
  bool dark = false,
  bool cutout = false,
  bool supporting_content = false,
  Color backdrop_color = ColorConstants.whiteColor,
  VoidCallback? on_back,
  VoidCallback? on_share,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final obstruction = Rect.fromLTWH(size.width - 84, 0, 84, 124);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(text_scale),
          padding: cutout ? const EdgeInsets.only(right: 84) : EdgeInsets.zero,
          viewPadding: cutout
              ? const EdgeInsets.only(right: 84)
              : EdgeInsets.zero,
          displayFeatures: cutout
              ? [
                  ui.DisplayFeature(
                    bounds: obstruction,
                    type: ui.DisplayFeatureType.cutout,
                    state: ui.DisplayFeatureState.unknown,
                  ),
                ]
              : const [],
        ),
        child: WindowLayoutScope(
          child: Scaffold(
            body: WindowContentLayout(
              child: SingleChildScrollView(
                child: RepaintBoundary(
                  key: const ValueKey('work_hero_capture'),
                  child: WorkIntroductionHero(
                    key: const ValueKey('responsive_work_hero'),
                    is_dark: dark,
                    title: title,
                    cover: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [ColorConstants.components_work_introduction_hero_test_tone_ff537894, ColorConstants.components_work_introduction_hero_test_tone_ff172b3d],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 44,
                          color: ColorConstants.components_work_introduction_hero_test_tone_ffedd39b,
                        ),
                      ),
                    ),
                    backdrop: ColoredBox(color: backdrop_color),
                    metadata_builder: (_, on_hero) =>
                        metadata_content ??
                        SizedBox(
                          key: const ValueKey('test_author'),
                          height: metadata_height,
                          child: Text(
                            'Optimystic',
                            style: TextStyle(
                              color: on_hero || dark
                                  ? ColorConstants.whiteColor
                                  : ColorConstants.lightTextColor,
                            ),
                          ),
                        ),
                    overflow_builder: supporting_content
                        ? (_, on_hero) => Container(
                            key: const ValueKey('test_stats'),
                            height: 70,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: on_hero
                                  ? ColorConstants.test_components_work_introduction_hero_test_tone
                                  : ColorConstants.test_components_work_introduction_hero_test_tone_ff252a36,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Text(
                              '9.9K Readers  ·  4.8 Rating  ·  320 Chapters',
                              style: TextStyle(color: ColorConstants.whiteColor),
                            ),
                          )
                        : null,
                    actions_builder: supporting_content
                        ? (_, _, compact) => Container(
                            key: const ValueKey('test_actions'),
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: ColorConstants.test_components_work_introduction_hero_test_tone_ffffd84c,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Text(
                              'Start Reading',
                              style: TextStyle(color: ColorConstants.lightTextColor),
                            ),
                          )
                        : null,
                    on_back: on_back ?? () {},
                    on_share: on_share ?? () {},
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
}

Rect _bounds(WidgetTester tester, String key) =>
    tester.getRect(find.byKey(ValueKey(key)));

Future<void> _capture(WidgetTester tester, String name) async {
  if (_preview_dir.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('work_hero_capture')),
  );
  await tester.runAsync(() async {
    await Directory(_preview_dir).create(recursive: true);
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      '$_preview_dir/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_load_fonts);

  for (final title in [
    'Dawn',
    'Between the Stars\nand the Sea',
    'A Journey\nBeyond the Stars\nAcross the Sea\nAnd Home Again',
  ]) {
    testWidgets('一、二、四行标题紧接作者且封面保持2:3: $title', (tester) async {
      await _mount(tester, title: title, metadata_height: 24);
      final cover = _bounds(tester, 'work_introduction_cover');
      final metadata = _bounds(tester, 'work_introduction_metadata');
      final heading = tester.getRect(find.text(title));
      final author = _bounds(tester, 'test_author');
      expect(cover.width / cover.height, closeTo(2 / 3, 0.001));
      expect(cover.left, WorkIntroductionHeroStyle.horizontal_padding);
      expect(metadata.bottom, closeTo(cover.bottom, 0.01));
      expect(
        author.top - heading.bottom,
        closeTo(WorkIntroductionHeroStyle.title_gap, 0.01),
      );
      expect(_bounds(tester, 'work_introduction_poster').height, lessThan(350));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('超过100字标题自然长高且完整显示，不由背景约束高度', (tester) async {
    await _mount(tester);
    final short_height = _bounds(tester, 'work_introduction_poster').height;
    final title = List.filled(5, _reference_title).join(' ');
    await _mount(tester, title: title, supporting_content: true);
    final poster = _bounds(tester, 'work_introduction_poster');
    final heading = tester.getRect(find.text(title));
    final author = _bounds(tester, 'test_author');
    final stats = _bounds(tester, 'test_stats');
    final actions = _bounds(tester, 'test_actions');
    expect(poster.height, greaterThan(short_height));
    expect(author.top, greaterThanOrEqualTo(heading.bottom));
    expect(stats.top, greaterThan(author.bottom));
    expect(actions.top, greaterThan(stats.bottom));
    expect(stats.width, 390 - WorkIntroductionHeroStyle.horizontal_padding * 2);
    expect(actions.bottom, lessThan(poster.bottom));
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text(title), matching: find.byType(RichText)),
    );
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets('白色封面背景日夜对比、导航回调与紧凑前景 dark=$dark', (tester) async {
      var backs = 0;
      var shares = 0;
      await _mount(
        tester,
        title: _reference_title,
        dark: dark,
        supporting_content: true,
        on_back: () => backs++,
        on_share: () => shares++,
      );
      final scrim = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('work_introduction_scrim')),
      );
      final gradient = (scrim.decoration as BoxDecoration).gradient!;
      // 底部黑色渐变区承载白色文字，需满足 WCAG AA 对比度。
      for (final color in gradient.colors.skip(gradient.colors.length - 2)) {
        final background = Color.alphaBlend(color, ColorConstants.whiteColor);
        expect(
          1.05 / (background.computeLuminance() + 0.05),
          greaterThanOrEqualTo(4.5),
        );
      }
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.tap(find.byIcon(Icons.share_outlined));
      expect(backs, 1);
      expect(shares, 1);
      expect(tester.takeException(), isNull);
      await _capture(tester, 'redesign_white_${dark ? 'dark' : 'light'}');
    });
  }

  testWidgets('Duo同组件折叠展开无文字溢出且导航避开局部系统区域', (tester) async {
    for (final size in [
      const Size(466, 678),
      const Size(951, 669),
      const Size(466, 678),
    ]) {
      await _mount(
        tester,
        size: size,
        title: _reference_title,
        supporting_content: true,
        cutout: true,
      );
      final share = tester.getRect(find.byIcon(Icons.share_outlined));
      final obstruction = Rect.fromLTWH(size.width - 84, 0, 84, 124);
      expect(_bounds(tester, 'work_introduction_poster').width, size.width);
      expect(share.overlaps(obstruction), isFalse);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('大字与长标题始终保持同一左右布局并保留关注状态', (tester) async {
    await _mount(
      tester,
      title: _reference_title,
      metadata_content: const _StatefulMetadata(),
    );
    final state = tester.state<_StatefulMetadataState>(
      find.byType(_StatefulMetadata),
    );
    await tester.tap(find.text('Follow'));
    await tester.pump();
    expect(find.text('Following'), findsOneWidget);
    for (final scale in [2.0, 1.0]) {
      await _mount(
        tester,
        title: _reference_title,
        text_scale: scale,
        metadata_content: const _StatefulMetadata(),
      );
      expect(
        tester.state<_StatefulMetadataState>(find.byType(_StatefulMetadata)),
        same(state),
      );
      expect(find.text('Following'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('work_introduction_panel')),
        findsNothing,
      );
      expect(
        _bounds(tester, 'work_introduction_metadata').left,
        greaterThan(_bounds(tester, 'work_introduction_cover').right),
      );
      expect(tester.takeException(), isNull);
    }
  });
}
