// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:app/pages/comics/reader/index.dart';
import 'package:app/pages/comics/reader/logic.dart';
import 'package:app/pages/comics/reader/style.dart';
import 'package:app/pages/comics/reader/widgets/bottom_scrim.dart';
import 'package:app/pages/comics/reader/widgets/control_button.dart';
import 'package:app/pages/comics/reader/widgets/chapter_end.dart';
import 'package:app/pages/comics/reader/widgets/top_scrim.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _Assets extends AssetLoader {
  const _Assets();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
            as Map,
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const output_dir = String.fromEnvironment('COMICS_READER_PREVIEW_DIR');
  const sample_path =
      '/Users/ali/work/小说/后端/test/mangaberri漫画/数据/漫画/1092_Ken to Mahou no Zeikin Taisaku/章节/001_Chapter 1/001.webp';
  final sample_images = <ui.Image>[];
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    await EasyLocalization.ensureInitialized();
    if (output_dir.isNotEmpty) {
      for (final path in <String>[
        sample_path,
        sample_path.replaceFirst('001.webp', '002.webp'),
      ]) {
        if (File(path).existsSync()) {
          final codec = await ui.instantiateImageCodec(
            File(path).readAsBytesSync(),
          );
          sample_images.add((await codec.getNextFrame()).image);
          codec.dispose();
        }
      }
      for (final entry in <String, String>{
        'PreviewLatin': '/System/Library/Fonts/Supplemental/Arial Unicode.ttf',
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
  testWidgets('日间主题的阅读错误重试按钮在近黑画布可见且能重试', (tester) async {
    var requests = 0;
    final logic = ComicReaderLogic(
      read_chapter: (_) async {
        requests++;
        throw StateError('Network unavailable');
      },
    );
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[Locale('en')],
        path: 'assets/i18n',
        assetLoader: const _Assets(),
        startLocale: const Locale('en'),
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            theme: ThemeData(brightness: Brightness.light),
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: ComicReaderPage(chapter_id: 91, controller: logic),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final retry = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    final color = retry.style!.foregroundColor!.resolve(<WidgetState>{})!;
    final rendered = Color.alphaBlend(
      color,
      ComicReaderStyle.canvas_background,
    );
    final contrast =
        (rendered.computeLuminance() + 0.05) /
        (ComicReaderStyle.canvas_background.computeLuminance() + 0.05);
    expect(contrast, greaterThanOrEqualTo(4.5));
    expect(requests, 1);
    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();
    expect(requests, 2);
    for (final animation in tester.widgetList<AnimatedSlide>(
      find.byType(AnimatedSlide),
    )) {
      expect(animation.duration, Duration.zero);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
  testWidgets('章节结束操作在320px和2倍字号自然换行且不裁切', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[Locale('en')],
        path: 'assets/i18n',
        assetLoader: const _Assets(),
        startLocale: const Locale('en'),
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: ComicReaderChapterEnd(
                    has_next_chapter: true,
                    on_next_chapter: () {},
                    on_comments: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(FilledButton)).height,
      greaterThanOrEqualTo(52),
    );
    expect(
      tester.getSize(find.byType(TextButton)).height,
      greaterThanOrEqualTo(48),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
  for (final width in <double>[320, 390]) {
    for (final dark in <bool>[false, true]) {
      for (final scale in <double>[1.0, 1.4, 2]) {
        for (final locale in <String>['en', 'zh']) {
          testWidgets(
            'reader controls ${width.toInt()}px ${dark ? 'dark' : 'light'} ${scale}x $locale',
            (tester) async {
              tester.view.devicePixelRatio = 1;
              tester.view.physicalSize = Size(width, 844);
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              final key = GlobalKey();
              var previous = 0, next = 0, comments = 0;
              await tester.pumpWidget(
                RepaintBoundary(
                  key: key,
                  child: EasyLocalization(
                    supportedLocales: <Locale>[Locale(locale)],
                    path: 'assets/i18n',
                    assetLoader: const _Assets(),
                    startLocale: Locale(locale),
                    fallbackLocale: Locale(locale),
                    saveLocale: false,
                    child: Builder(
                      builder: (context) => MaterialApp(
                        debugShowCheckedModeBanner: false,
                        locale: context.locale,
                        supportedLocales: context.supportedLocales,
                        localizationsDelegates: context.localizationDelegates,
                        theme: ThemeData(
                          brightness: dark ? Brightness.dark : Brightness.light,
                          fontFamily: output_dir.isEmpty
                              ? null
                              : 'PreviewLatin',
                        ),
                        home: MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            textScaler: TextScaler.linear(scale),
                            padding: const EdgeInsets.only(top: 36, bottom: 28),
                          ),
                          child: Scaffold(
                            body: Stack(
                              children: <Widget>[
                                Positioned.fill(
                                  child: ColoredBox(
                                    color: ComicReaderStyle.canvas_background,
                                    child: sample_images.isNotEmpty
                                        ? SingleChildScrollView(
                                            child: Column(
                                              children: sample_images
                                                  .map(
                                                    (image) => RawImage(
                                                      image: image,
                                                      fit: BoxFit.fitWidth,
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          )
                                        : const Center(
                                            child: Icon(
                                              Icons.landscape_outlined,
                                              size: 150,
                                              color: Colors.black38,
                                            ),
                                          ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: ComicReaderTopScrim(
                                    title:
                                        'Chapter 32 — A very long journey into the unknown',
                                    comic_title:
                                        'The Extraordinary Adventure of the Wandering Artist',
                                    on_back: () {},
                                    on_open_catalog: () {},
                                    on_comments: () {},
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: ComicReaderBottomScrim(
                                    page_index: 5,
                                    page_count: 436,
                                    has_previous_chapter: true,
                                    has_next_chapter: true,
                                    on_previous_chapter: () => previous++,
                                    on_next_chapter: () => next++,
                                    on_open_catalog: () {},
                                    on_comments: () => comments++,
                                  ),
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
              expect(tester.takeException(), isNull);
              for (final element
                  in find.byType(ComicReaderControlButton).evaluate()) {
                final size = tester.getSize(find.byWidget(element.widget));
                expect(size.height, greaterThanOrEqualTo(48));
                expect(size.width, greaterThanOrEqualTo(48));
              }
              await tester.tap(
                find.text(locale == 'zh' ? '上一章' : 'Previous chapter'),
              );
              await tester.tap(
                find.text(locale == 'zh' ? '下一章' : 'Next chapter'),
              );
              await tester.tap(
                find.text(locale == 'zh' ? '章节评论' : 'Chapter comments'),
              );
              expect(previous, 1);
              expect(next, 1);
              expect(comments, 1);
              final top = tester.widget<DecoratedBox>(
                find
                    .descendant(
                      of: find.byType(ComicReaderTopScrim),
                      matching: find.byType(DecoratedBox),
                    )
                    .first,
              );
              expect((top.decoration as BoxDecoration).color!.a, 1);
              expect(ComicReaderStyle.control_target, greaterThanOrEqualTo(48));
              if (scale == 1.0) {
                expect(
                  tester.getSize(find.byType(ComicReaderTopScrim)).height,
                  lessThanOrEqualTo(100),
                );
                expect(
                  tester.getSize(find.byType(ComicReaderBottomScrim)).height,
                  lessThanOrEqualTo(145),
                );
              }
              if (output_dir.isNotEmpty && width == 390 && scale <= 1.4) {
                final boundary =
                    key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary;
                await tester.runAsync(() async {
                  final image = await boundary.toImage(pixelRatio: 2);
                  final data = await image.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  final file = File(
                    '$output_dir/reader_${dark ? 'dark' : 'light'}_${locale}_${scale}x.png',
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
}
