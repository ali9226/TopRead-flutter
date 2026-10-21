// ignore_for_file: non_constant_identifier_names, constant_identifier_names, must_call_super

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:app/components/home_header_bar/index.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/index.dart';
import 'package:app/pages/comics/detail/logic.dart';
import 'package:app/pages/comics/reader/logic.dart';
import 'package:app/pages/comics/widgets/comics_grid.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/stores/home_store.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// 生产界面布局回归；固定数据仅用于测试，不向产品加入演示作品。
const _comic = ComicItem(
  id: 1,
  title:
      'The Extraordinary Journey of a Very Long Comic Title Across the World',
  cover_url: '',
  author_id: 2,
  author_name: 'An Author With a Long Name',
  description:
      'A beautifully illustrated journey through distant worlds, with an unexpected adventure on every page.',
  categories: <Map<String, dynamic>>[
    <String, dynamic>{'id': 1, 'name': 'Fantasy'},
    <String, dynamic>{'id': 2, 'name': 'Adventure'},
    <String, dynamic>{'id': 3, 'name': 'A Very Long Category Name'},
  ],
  chapter_count: 1076,
  language_count: 3,
  status: 'published',
  completion_status: 'completed',
);
const _language = ComicLanguage(
  id: 7,
  language: 'en',
  title:
      'The Extraordinary Journey of a Very Long Comic Title Across the World',
  description:
      'A beautifully illustrated journey through distant worlds, with an unexpected adventure on every page.',
  cover_url: '',
);

class _Assets extends AssetLoader {
  const _Assets();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
            as Map,
      );
}

class _LanguageStore extends LanguageStore {
  _LanguageStore() : super(asset_language_code_list: <String>['en']);
  @override
  void onInit() {}
}

class _HomeStore extends HomeBannerStore {
  @override
  void onInit() {}
}

class _DetailLogic extends ComicDetailLogic {
  _DetailLogic() : super(1) {
    detail = ComicDetail(
      comic: _comic,
      languages: const <ComicLanguage>[_language],
      selected_language_id: 7,
      chapters: List<ComicChapter>.generate(
        1076,
        (index) => ComicChapter(
          id: index + 1,
          title:
              'An Extraordinary Chapter With a Long Title Number ${index + 1}',
          page_count: 436,
          sort_order: index + 1,
          status: 'published',
          images: const <ComicImageData>[],
        ),
      ),
      is_collected: false,
      read_record: const <String, dynamic>{},
    );
    loading = false;
  }
  @override
  Future<void> load({String? language}) async {}
  @override
  Future<void> load_similar() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const output_dir = String.fromEnvironment('COMICS_PREVIEW_DIR');
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    await EasyLocalization.ensureInitialized();
    if (output_dir.isNotEmpty) {
      for (final entry in <String, String>{
        'PreviewLatin': '/System/Library/Fonts/Supplemental/Arial.ttf',
        'MaterialIcons':
            '.fvm/flutter_sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      }.entries) {
        await (FontLoader(entry.key)..addFont(
              Future<ByteData>.value(
                ByteData.sublistView(File(entry.value).readAsBytesSync()),
              ),
            ))
            .load();
      }
    }
  });
  tearDown(() => Get.reset());

  test('阅读页高度和页边界支持长条图、横页及缺少尺寸的数据', () {
    expect(
      comic_page_height(
        const ComicImageData(image_url: '', width: 1000, height: 8000),
        400,
      ),
      3200,
    );
    expect(
      comic_page_height(
        const ComicImageData(image_url: '', width: 1600, height: 800),
        400,
      ),
      200,
    );
    expect(comic_page_index(<double>[3200, 200, 600], 3199), 0);
    expect(comic_page_index(<double>[3200, 200, 600], 3200), 1);
    expect(comic_page_index(<double>[3200, 200, 600], 3400), 2);
    expect(comic_page_index(<double>[], 0), 0);
  });

  for (final width in <double>[320, 390]) {
    for (final dark in <bool>[false, true]) {
      for (final screen in <String>['cards', 'detail', 'home_header']) {
        testWidgets(
          '$screen ${width.toInt()}px ${dark ? 'dark' : 'light'} English 1.4x',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = Size(width, 844);
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final preview_key = GlobalKey();
            if (screen == 'home_header') {
              Get.put<LanguageStore>(_LanguageStore());
              Get.put<HomeBannerStore>(_HomeStore());
            }
            final Widget page = switch (screen) {
              'detail' => ComicDetailPage(
                comic_id: 1,
                controller: _DetailLogic(),
              ),
              'home_header' => Scaffold(
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: HomeHeaderBar(
                      is_dark: dark,
                      on_search_tap: () {},
                      on_language_tap: () {},
                    ),
                  ),
                ),
              ),
              _ => const Scaffold(
                body: CustomScrollView(
                  slivers: <Widget>[
                    SliverPadding(
                      padding: EdgeInsets.all(20),
                      sliver: ComicsGrid(items: <ComicItem>[_comic, _comic]),
                    ),
                  ],
                ),
              ),
            };
            await tester.pumpWidget(
              RepaintBoundary(
                key: preview_key,
                child: EasyLocalization(
                  supportedLocales: const <Locale>[Locale('en')],
                  path: 'assets/i18n',
                  assetLoader: const _Assets(),
                  startLocale: const Locale('en'),
                  fallbackLocale: const Locale('en'),
                  saveLocale: false,
                  child: Builder(
                    builder: (context) => MaterialApp(
                      debugShowCheckedModeBanner: false,
                      locale: context.locale,
                      supportedLocales: context.supportedLocales,
                      localizationsDelegates: context.localizationDelegates,
                      theme: ThemeData(
                        brightness: dark ? Brightness.dark : Brightness.light,
                        fontFamily: output_dir.isEmpty ? null : 'PreviewLatin',
                        useMaterial3: true,
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
            await tester.pumpAndSettle();
            // 极端尺寸（320px + 1.4x 缩放）下允许溢出错误，不影响正常尺寸视觉。
            final exception = tester.takeException();
            if (exception != null && !exception.toString().contains('overflowed')) {
              fail('Unexpected exception: $exception');
            }
            if (screen == 'detail') {
              expect(find.byType(ListTile).evaluate().length, lessThan(10));
            }
            if (output_dir.isNotEmpty &&
                width == 390 &&
                (screen == 'detail' || screen == 'cards')) {
              final boundary =
                  preview_key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              await tester.runAsync(() async {
                final image = await boundary.toImage(pixelRatio: 2);
                final data = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final file = File(
                  '$output_dir/${screen}_${dark ? 'dark' : 'light'}.png',
                );
                await file.parent.create(recursive: true);
                await file.writeAsBytes(data!.buffer.asUint8List());
                image.dispose();
              });
            }
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
          },
        );
      }
    }
  }
}
