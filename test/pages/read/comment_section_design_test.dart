// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:app/config/color_config.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/pages/read/utils/read_models.dart';
import 'package:app/pages/read/widgets/introduction_section/index.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/comment_item/index.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/comment_section/index.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/stores/user_information.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

const _preview_dir = String.fromEnvironment('READ_HERO_PREVIEW_DIR');

class _Assets extends AssetLoader {
  const _Assets();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
            as Map,
      );
}

class _NoImageCache implements BaseCacheManager {
  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) => const Stream<FileResponse>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<ReadComment> _comments(String language) => [
  ReadComment(
    avatar_url: '',
    user_name: language == 'zh' ? '沿着河岸散步' : 'Alex Rivers',
    content: language == 'zh'
        ? '故事最后，我才读懂了开篇那场没有告别的雨。人物的选择像生活一样真实，合上书以后，仍然会想起他们。'
        : 'The quiet moments stayed with me long after the last page. Every character feels like someone I have known, and the ending makes the opening chapter read in an entirely different light.',
    star_count: 5,
    user_id: 21,
  ),
  ReadComment(
    avatar_url: '',
    user_name: language == 'zh'
        ? '一个昵称长到需要在窄屏上优雅处理的普通读者'
        : 'A reader whose exceptionally long name should remain readable',
    content: List.filled(
      9,
      language == 'zh'
          ? '最喜欢的不是宏大的世界设定，而是那些细小的生活瞬间：热茶的白雾，深夜的灯光，还有始终没有说出口的那句谢谢。'
          : 'What I loved most was the attention to small moments: the steam rising from a cup of tea, a light left on through the night, and a thank you that never quite finds its voice.',
    ).join(' '),
    star_count: 0,
    user_id: 22,
  ),
  ReadComment(
    avatar_url: '',
    user_name: language == 'zh' ? '书页里的风' : 'Morgan Lee',
    content: language == 'zh'
        ? '前半段很有吸引力，中间的节奏对我来说有点慢，还是很期待作者的下一部作品。'
        : 'An absorbing opening and a beautiful setting. The middle felt a little slow for me, but I will be looking out for this author’s next story.',
    star_count: 2,
    user_id: 23,
  ),
];

ReadDetail _detail(String language) => ReadDetail(
  story_id: 42,
  title: language == 'zh' ? '在群星闪耀之前' : 'Before the Stars Awaken',
  cover_url: '',
  author_id: 7,
  author_avatar_url: '',
  author_name: language == 'zh' ? '林间有风' : 'Elena Rivers',
  focus_on: false,
  score_major_text: '9.6',
  score_minor_text: '',
  review_count_text: language == 'zh' ? '128 人评分' : '128 ratings',
  reading_major_text: '234.1',
  reading_minor_text: 'K',
  reading_subtitle_text: language == 'zh' ? '在读' : 'Reading',
  word_count_major_text: '1.2',
  word_count_minor_text: 'M',
  word_count_subtitle_text: language == 'zh' ? '字' : 'Words',
  status_text: language == 'zh' ? '已完结' : 'Completed',
  tag_list: language == 'zh'
      ? ['奇幻', '冒险', '成长']
      : ['Fantasy', 'Adventure', 'Coming of Age'],
  intro_text: language == 'zh'
      ? '一场意外的相遇，让她走进了藏在城市深处的旧书店。每一本书都记着一个未曾抵达的明天，而最后一页，写着她自己的名字。穿过漫长的黑夜，她必须在最后一颗星辰熄灭之前，找到回家的路。'
      : 'An unexpected encounter leads her to a forgotten bookshop at the heart of the city. Every book holds a tomorrow that never arrived, and the final page bears her own name. Before the last star fades, she must find her way home.',
  chapter_title: language == 'zh' ? '第一章：旧书店' : 'Chapter One: The Bookshop',
  comment_list: _comments(language),
  comment_count: 128,
);

Future<void> _mount(
  WidgetTester tester, {
  required double width,
  required String language,
  required bool dark,
  required double text_scale,
  required List<ReadComment> comments,
  int? comment_count = 128,
  VoidCallback? on_view_all,
  Widget? introduction,
}) async {
  final size = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: [Locale(language)],
      startLocale: Locale(language),
      fallbackLocale: Locale(language),
      path: 'assets/i18n',
      saveLocale: false,
      assetLoader: const _Assets(),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          theme: ThemeData(
            brightness: dark ? Brightness.dark : Brightness.light,
            fontFamily: _preview_dir.isNotEmpty ? 'Roboto' : null,
          ),
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(text_scale),
            ),
            child: WindowLayoutScope(
              child: Scaffold(
                body: SingleChildScrollView(
                  child: RepaintBoundary(
                    key: const ValueKey('comments_preview'),
                    child: ColoredBox(
                      color: dark
                          ? ColorConstants.nightBackgroundColor
                          : ColorConstants.whiteColor,
                      child:
                          introduction ??
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: ReadCommentSection(
                              is_dark: dark,
                              comment_list: comments,
                              comment_count: comment_count,
                              on_view_all: on_view_all ?? () {},
                            ),
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  // 完整简介的离线封面占位持续动画，只等待局部布局观察器完成当前帧。
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_preview_dir.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('comments_preview')),
  );
  await tester.runAsync(() async {
    await Directory(_preview_dir).create(recursive: true);
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      '$_preview_dir/comments_$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void _verify_horizontal_bounds(WidgetTester tester) {
  final section = tester.getRect(find.byType(ReadCommentSection));
  for (final element
      in find
          .descendant(
            of: find.byType(ReadCommentSection),
            matching: find.byType(RichText),
          )
          .evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    final rect = paragraph.localToGlobal(Offset.zero) & paragraph.size;
    expect(rect.left, greaterThanOrEqualTo(section.left - 0.01));
    expect(rect.right, lessThanOrEqualTo(section.right + 0.01));
  }
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    CachedNetworkImageProvider.defaultCacheManager = _NoImageCache();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (_) async => <String, Object>{},
        );
    await EasyLocalization.ensureInitialized();
    if (_preview_dir.isNotEmpty) {
      for (final entry in {
        'Roboto': 'Arial Unicode',
        'Georgia': 'Times New Roman',
      }.entries) {
        final font = File(
          '/System/Library/Fonts/Supplemental/${entry.value}.ttf',
        );
        if (font.existsSync()) {
          await (FontLoader(entry.key)..addFont(
                Future.value(ByteData.sublistView(font.readAsBytesSync())),
              ))
              .load();
        }
      }
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });
  setUp(() {
    Get.testMode = true;
    Get.put<UserInformation>(UserInformation());
    Get.put<ProjectConfigStore>(ProjectConfigStore());
  });
  tearDown(Get.reset);

  for (final width in [320.0, 390.0, 900.0]) {
    for (final language in ['zh', 'en']) {
      for (final dark in [false, true]) {
        final text_scale = width == 320 ? 2.0 : 1.0;
        final name =
            '${width.toInt()}_${language}_${dark ? 'dark' : 'light'}_${text_scale}x';
        testWidgets('真实书评 $name 长名长文不溢出、0/5星级不造假', (tester) async {
          final comments = _comments(language);
          await _mount(
            tester,
            width: width,
            language: language,
            dark: dark,
            text_scale: text_scale,
            comments: comments,
          );
          expect(find.byType(ReadCommentItem), findsNWidgets(3));
          expect(
            find.byKey(const ValueKey('read_comments_count')),
            findsOneWidget,
          );
          expect(find.text('128'), findsOneWidget);
          if (width == 320 && language == 'en') {
            final heading = find.byKey(const ValueKey('read_comments_heading'));
            final heading_text = tester.widget<Text>(heading);
            final paragraph = tester.renderObject<RenderParagraph>(
              find.descendant(of: heading, matching: find.byType(RichText)),
            );
            final natural_width = paragraph.getMaxIntrinsicWidth(
              double.infinity,
            );
            final available_width = tester
                .getSize(find.byType(ReadCommentSection))
                .width;
            // 操作入口不能抢占标题宽度；Ahem 比真实字体更宽，仅真实字体检查一行。
            expect(
              tester.getSize(heading).width,
              closeTo(
                natural_width < available_width
                    ? natural_width
                    : available_width,
                0.1,
              ),
            );
            if (_preview_dir.isNotEmpty) {
              expect(
                paragraph
                    .getBoxesForSelection(
                      const TextSelection(baseOffset: 0, extentOffset: 7),
                    )
                    .length,
                1,
              );
            }
            expect(heading_text.data, 'Reviews');
          }
          for (final comment in comments) {
            expect(find.text(comment.user_name), findsOneWidget);
            expect(find.text(comment.content), findsOneWidget);
            final item = find.ancestor(
              of: find.text(comment.user_name),
              matching: find.byType(ReadCommentItem),
            );
            final stars = find.descendant(
              of: item,
              matching: find.byIcon(Icons.star_rounded),
            );
            expect(stars, findsNWidgets(comment.star_count == 0 ? 0 : 5));
            if (comment.star_count > 0) {
              final star_widgets = tester.widgetList<Icon>(stars).toList();
              expect(
                star_widgets
                    .where((star) => star.color == star_widgets.first.color)
                    .length,
                comment.star_count,
              );
              final rating_label = language == 'zh'
                  ? '评分 ${comment.star_count} 分，满分 5 分'
                  : 'Rated ${comment.star_count} out of 5';
              expect(
                find.descendant(
                  of: item,
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget is Semantics &&
                        widget.properties.label == rating_label,
                  ),
                ),
                findsOneWidget,
              );
            }
            final paragraph = tester.renderObject<RenderParagraph>(
              find.descendant(
                of: find.byKey(
                  ValueKey('read_comment_content_${comment.user_id}'),
                ),
                matching: find.byType(RichText),
              ),
            );
            expect(
              find.byKey(ValueKey('read_comment_toggle_${comment.user_id}')),
              paragraph.didExceedMaxLines ? findsOneWidget : findsNothing,
            );
          }
          _verify_horizontal_bounds(tester);
          await _capture(tester, name);
        });
      }
    }
  }

  for (final language in ['zh', 'en']) {
    for (final dark in [false, true]) {
      for (final empty in [false, true]) {
        final name =
            '${empty ? 'empty' : 'single'}_${language}_${dark ? 'dark' : 'light'}';
        testWidgets('书评 $name 真实空态与单条', (tester) async {
          final comments = empty
              ? <ReadComment>[]
              : [_comments(language).first];
          await _mount(
            tester,
            width: 390,
            language: language,
            dark: dark,
            text_scale: 1,
            comments: comments,
            comment_count: comments.length,
          );
          expect(find.byType(ReadCommentItem), findsNWidgets(comments.length));
          _verify_horizontal_bounds(tester);
          await _capture(tester, name);
        });
      }
    }
  }

  testWidgets('书评真实总数、查看全部与长文展开收起', (tester) async {
    var view_all_count = 0;
    final comments = _comments('en');
    await _mount(
      tester,
      width: 390,
      language: 'en',
      dark: false,
      text_scale: 1,
      comments: comments,
      on_view_all: () => view_all_count++,
    );
    final all = find.byKey(const ValueKey('read_comments_all'));
    await tester.tap(all);
    expect(view_all_count, 1);
    final content = find.byKey(const ValueKey('read_comment_content_22'));
    final toggle = find.byKey(const ValueKey('read_comment_toggle_22'));
    expect(toggle, findsOneWidget);
    final collapsed_height = tester.getSize(content).height;
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.getSize(content).height, greaterThan(collapsed_height));
    _verify_horizontal_bounds(tester);
    // 整段内容和后续评论都参与文档布局，完整导出长文展开态供人工检查。
    await _capture(tester, 'expanded_en_light');
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.getSize(content).height, collapsed_height);
    expect(tester.takeException(), isNull);
  });

  testWidgets('未提供总数时不能把精选条数显示成所有书评数', (tester) async {
    await _mount(
      tester,
      width: 390,
      language: 'en',
      dark: true,
      text_scale: 1,
      comments: _comments('en'),
      comment_count: null,
    );
    expect(find.byKey(const ValueKey('read_comments_count')), findsNothing);
    expect(find.byType(ReadCommentItem), findsNWidgets(3));
    _verify_horizontal_bounds(tester);
  });

  testWidgets('已有书评总数但缺少预览时保留入口，不误报无人评论', (tester) async {
    var opened = false;
    await _mount(
      tester,
      width: 320,
      language: 'en',
      dark: false,
      text_scale: 2,
      comments: const [],
      comment_count: 128,
      on_view_all: () => opened = true,
    );
    expect(
      find.text('No comments yet. Be the first to comment!'),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('read_comments_count')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('read_comments_all')));
    expect(opened, isTrue);
    _verify_horizontal_bounds(tester);
  });

  for (final scenario in [('zh', false), ('en', true)]) {
    testWidgets('完整长篇简介 ${scenario.$1} 与真实书评自然衔接', (tester) async {
      await _mount(
        tester,
        width: 390,
        language: scenario.$1,
        dark: scenario.$2,
        text_scale: 1,
        comments: _comments(scenario.$1),
        introduction: ReadIntroductionSection(
          is_dark: scenario.$2,
          detail: _detail(scenario.$1),
          on_back: () {},
          on_share: () {},
          on_read: () {},
          on_favorite: () {},
          on_comments: () {},
        ),
      );
      expect(find.byType(ReadCommentItem), findsNWidgets(3));
      _verify_horizontal_bounds(tester);
      await _capture(
        tester,
        'full_introduction_${scenario.$1}_${scenario.$2 ? 'dark' : 'light'}',
      );
    });
  }
}
