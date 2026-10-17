// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
// ignore: depend_on_referenced_packages
import 'package:file/memory.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:app/components/comment_list/models/comment_data.dart';
import 'package:app/pages/bookshelf/widgets/bookshelf_grid_content.dart';
import 'package:app/pages/comics/comments/index.dart';
import 'package:app/pages/comics/comments/logic.dart';
import 'package:app/stores/bookshelf_store.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Assets extends AssetLoader {
  const _Assets();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
            as Map,
      );
}

/// TODO 版式回归使用确定的内存图片，避免网络占位动画使 pumpAndSettle 永不结束。
class _Images extends BaseCacheManager {
  _Images(this.image);
  final FileInfo image;
  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) => Stream<FileResponse>.value(image);
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('测试只允许读取固定图片');
}

/// TODO 只注入已加载状态，截图仍渲染实际生产评论页和公共小说评论组件。
class _Comments extends ComicCommentsLogic {
  _Comments() : super(comic_id: 1, chapter_id: 91) {
    final time = DateTime.now()
        .toUtc()
        .subtract(const Duration(minutes: 8))
        .toIso8601String();
    items.addAll(<CommentData>[
      CommentData(
        id: 1,
        user_id: 8,
        avatar: '',
        nickname: 'Alex · A Reader With a Long Name',
        content:
            'The quiet moment before the next chapter is what makes this story special. The art says so much without a single word.',
        time: time,
        like_count: 128,
      ),
      CommentData(
        id: 2,
        user_id: 9,
        avatar: '',
        nickname: 'Jamie',
        content:
            'I keep coming back to this chapter. The little details in every panel are wonderful.',
        time: time,
        like_count: 7,
        is_liked: true,
      ),
    ]);
    threads[1] = ComicReplyThread()
      ..expanded = true
      ..page = 1
      ..total = 2
      ..items.addAll(<CommentData>[
        CommentData(
          id: 3,
          user_id: 10,
          avatar: '',
          nickname: 'Rina',
          content: 'Exactly. Every page feels like a small discovery.',
          time: time,
          parent_id: 1,
          reply_to_nickname: 'Alex',
        ),
        CommentData(
          id: 4,
          user_id: 11,
          avatar: '',
          nickname: 'Sam',
          content: 'That final panel stays with you.',
          time: time,
          parent_id: 3,
          reply_to_nickname: 'Rina',
        ),
      ]);
    reply_counts[1] = 2;
    total = 2;
    loading = false;
  }
  @override
  Future<void> load({bool more = false, bool preserve_threads = false}) async {}
}

BookshelfBookItem _book({required String id, required bool comic}) =>
    BookshelfBookItem(
      id: id,
      novel_id: id,
      content_type: comic ? 'comic' : 'novel',
      title: comic
          ? 'A Journey Through Beautifully Illustrated Worlds'
          : 'A Novel With a Very Long Title',
      introduction: '',
      category_names: comic ? 'Adventure,Fantasy' : 'Fiction,Drama',
      progress_key: comic
          ? 'bookshelf.progress.comic_reading'
          : 'bookshelf.progress.read_progress',
      progress_args: comic
          ? <String, String>{'chapter': 'Chapter 7 · A New Beginning'}
          : <String, String>{'progress': '32'},
      tag_key: comic ? 'bookshelf.tags.comic' : 'bookshelf.tags.serializing',
      cover_start_color: Colors.blueGrey,
      cover_end_color: Colors.grey,
      chapter_id: comic ? '91' : null,
      chapter_title: 'Chapter 7 · A New Beginning',
      page_index: 0,
      page_count: 24,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const output = String.fromEnvironment('COMICS_LIBRARY_PREVIEW_DIR');
  const cover_path = String.fromEnvironment('COMICS_LIBRARY_COVER_FILE');
  setUpAll(() async {
    final bytes = cover_path.isEmpty
        ? base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGPIbJgJAALYAYO6bf8KAAAAAElFTkSuQmCC',
          )
        : File(cover_path).readAsBytesSync();
    final image = MemoryFileSystem().file('/cover.png')
      ..writeAsBytesSync(bytes);
    CachedNetworkImageProvider.defaultCacheManager = _Images(
      FileInfo(image, FileSource.Cache, DateTime.utc(2100), 'fixture'),
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (_) async => <String, Object>{},
        );
    await EasyLocalization.ensureInitialized();
    if (output.isNotEmpty) {
      for (final entry in <String, String>{
        'PreviewText': '/System/Library/Fonts/Supplemental/Arial Unicode.ttf',
        'Ahem': '/System/Library/Fonts/Supplemental/Arial Unicode.ttf',
        'MaterialIcons':
            '.fvm/flutter_sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      }.entries) {
        await (FontLoader(entry.key)..addFont(
              Future.value(
                ByteData.sublistView(File(entry.value).readAsBytesSync()),
              ),
            ))
            .load();
      }
    }
  });
  tearDown(() => Get.reset());

  for (final dark in <bool>[false, true]) {
    for (final screen in <String>['comments_en', 'comments_zh', 'library']) {
      testWidgets('$screen 320px ${dark ? 'dark' : 'light'} 1.4x', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 844);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final boundary_key = GlobalKey();
        final locale = screen == 'comments_zh'
            ? const Locale('zh')
            : const Locale('en');
        final controller = _Comments();
        addTearDown(controller.dispose);
        final Widget page = screen == 'library'
            ? Scaffold(
                appBar: AppBar(title: const Text('Library')),
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: BookshelfGridContent(
                      type: BookshelfContentType.history,
                      accent_color: Colors.blue,
                      is_dark: dark,
                      items: <BookshelfBookItem>[
                        _book(id: '1', comic: true),
                        _book(id: '2', comic: false),
                      ],
                    ),
                  ),
                ),
              )
            : ComicCommentsPage(
                comic_id: 1,
                chapter_id: 91,
                controller: controller,
              );
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary_key,
            child: EasyLocalization(
              supportedLocales: const <Locale>[Locale('en'), Locale('zh')],
              path: 'assets/i18n',
              assetLoader: const _Assets(),
              startLocale: locale,
              fallbackLocale: const Locale('en'),
              saveLocale: false,
              child: Builder(
                builder: (context) => MaterialApp(
                  locale: context.locale,
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                  debugShowCheckedModeBanner: false,
                  theme: ThemeData(
                    useMaterial3: true,
                    brightness: dark ? Brightness.dark : Brightness.light,
                    fontFamily: output.isEmpty ? null : 'PreviewText',
                  ),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: const TextScaler.linear(1.4)),
                    child: child!,
                  ),
                  home: page,
                ),
              ),
            ),
          ),
        );
        if (screen == 'library') {
          await tester.pump(const Duration(milliseconds: 100));
          expect(find.byType(CachedNetworkImage), findsNWidgets(2));
          // TODO 图片解码使用引擎真实异步队列，先等待固定图片完成，再检查布局动画是否收敛。
          await tester.runAsync(() async {
            for (final element in find.byType(CachedNetworkImage).evaluate()) {
              final image = element.widget as CachedNetworkImage;
              await precacheImage(
                CachedNetworkImageProvider(image.imageUrl),
                element,
              );
            }
          });
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (screen == 'library') {
          expect(find.text('Page 1/24'), findsOneWidget);
          expect(find.textContaining('Continue'), findsOneWidget);
        } else {
          expect(
            find.byKey(const ValueKey<String>('comment_item_tap_1')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey<String>('comment_reply_tap_4')),
            findsOneWidget,
          );
          final reply_text = tester.widget<RichText>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is RichText &&
                  widget.text.toPlainText().contains('Exactly. Every page'),
            ),
          );
          expect(reply_text.textScaler.scale(10), closeTo(14, 0.001));
          if (output.isNotEmpty) {
            expect(
              (reply_text.text as TextSpan).style?.fontFamily,
              'PreviewText',
            );
          }
        }
        if (output.isNotEmpty) {
          final boundary =
              boundary_key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File(
              '$output/${screen}_${dark ? 'dark' : 'light'}.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    }
  }
}
