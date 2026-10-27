import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:app/components/work_detail_skeleton/pulse.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/widgets/discovery_grid/index.dart';
import 'package:app/pages/comics/widgets/discovery_grid/skeleton.dart';
import 'package:app/pages/home/widgets/tab_contents/comics_tab/skeleton.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _boundary_key = ValueKey('comic_discovery_loading_preview');

class _Assets extends AssetLoader {
  const _Assets();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
            as Map,
      );
}

Future<void> _mount(
  WidgetTester tester, {
  required Widget child,
  Size size = const Size(390, 844),
  bool dark = false,
  String language = 'en',
  double scale = 1,
  bool reduced_motion = false,
  bool ticker_enabled = true,
}) async {
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
          ),
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(scale),
              disableAnimations: reduced_motion,
            ),
            child: TickerMode(
              enabled: ticker_enabled,
              child: RepaintBoundary(
                key: _boundary_key,
                child: Scaffold(
                  backgroundColor: dark
                      ? const Color(0xff17191d)
                      : const Color(0xfffafafa),
                  body: child,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 30));
}

Future<Uint8List> _frame(WidgetTester tester, {bool png = false}) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary_key),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(
      format: png ? ui.ImageByteFormat.png : ui.ImageByteFormat.rawRgba,
    );
    image.dispose();
    return bytes!.buffer.asUint8List();
  }))!;
}

Future<void> _export(WidgetTester tester, String name) async {
  if (Platform.environment['COMICS_DISCOVERY_LOADING_PREVIEW'] != '1') return;
  final file = File('/tmp/comics-discovery-loading-review/$name.png');
  final bytes = await _frame(tester, png: true);
  await tester.runAsync(() async {
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  });
}

Widget _catalog_skeleton() => const CustomScrollView(
  slivers: [
    SliverPadding(
      padding: EdgeInsets.all(20),
      sliver: ComicDiscoverySliverSkeleton(),
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (_) async => <String, Object>{},
        );
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('列表骨架逐帧绘制光扫且全区域只有一个动画时钟', (tester) async {
    await _mount(tester, child: _catalog_skeleton());
    final first = await _frame(tester);
    await tester.pump(const Duration(milliseconds: 600));
    final second = await _frame(tester);
    expect(second, isNot(orderedEquals(first)));
    expect(find.byType(SkeletonPulse), findsOneWidget);
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    expect(tester.takeException(), isNull);
    await _export(tester, 'catalog_phone_light');
  });

  testWidgets('减少动态效果和离屏时都停止骨架时钟', (tester) async {
    for (final reduced in [true, false]) {
      await _mount(
        tester,
        child: _catalog_skeleton(),
        reduced_motion: reduced,
        ticker_enabled: reduced,
      );
      await tester.pumpAndSettle();
      final first = await _frame(tester);
      await tester.pump(const Duration(milliseconds: 600));
      expect(await _frame(tester), orderedEquals(first));
      expect(tester.binding.transientCallbackCount, 0);
    }
  });

  testWidgets('首页的分类与六本书组共享时钟，并能真正显示光扫动画', (tester) async {
    await _mount(
      tester,
      language: 'zh',
      child: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: ComicsHomeSectionsSkeleton(is_dark: false),
      ),
    );
    expect(find.byType(SkeletonPulse), findsOneWidget);
    expect(find.byType(ComicDiscoverySkeleton), findsNWidgets(2));
    final first = await _frame(tester);
    await tester.pump(const Duration(milliseconds: 600));
    expect(await _frame(tester), isNot(orderedEquals(first)));
    expect(tester.takeException(), isNull);
    await _export(tester, 'home_phone_light');
  });

  for (final size in const [Size(320, 844), Size(844, 390), Size(951, 669)]) {
    for (final language in ['zh', 'en']) {
      testWidgets('骨架与真实卡片几何一致 $size $language 2x 夜间', (tester) async {
        await _mount(
          tester,
          size: size,
          language: language,
          scale: 2,
          dark: true,
          child: _catalog_skeleton(),
        );
        final skeleton_card = tester.getRect(
          find.byKey(const ValueKey('comic_discovery_skeleton_card_0')),
        );
        final skeleton_cover = tester.getRect(
          find.byKey(const ValueKey('comic_discovery_skeleton_cover')).first,
        );
        expect(tester.takeException(), isNull);
        if (size.width == 951 && language == 'en') {
          await _export(tester, 'catalog_duo_dark_2x');
        }
        await _mount(
          tester,
          size: size,
          language: language,
          scale: 2,
          dark: true,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: ComicDiscoverySliverGrid(
                  items: [
                    ComicItem.from_json({
                      'id': 1,
                      'title': '星空之下 Journey',
                      'cover_url': '',
                    }),
                  ],
                  on_open: (_) {},
                ),
              ),
            ],
          ),
        );
        final card = find.byKey(const ValueKey('comic_discovery_card_1'));
        expect(tester.getRect(card), skeleton_card);
        final cover = find.descendant(
          of: card,
          matching: find.byType(AspectRatio),
        );
        expect(tester.getRect(cover), skeleton_cover);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('首页大字体和Duo宽屏占位不溢出且仍只有一个时钟', (tester) async {
    for (final size in const [Size(320, 844), Size(844, 390), Size(951, 669)]) {
      await _mount(
        tester,
        size: size,
        dark: true,
        scale: 2,
        child: const SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: ComicsHomeSectionsSkeleton(is_dark: true),
        ),
      );
      expect(find.byType(SkeletonPulse), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (size.width == 951) await _export(tester, 'home_duo_dark_2x');
    }
  });

  testWidgets('单独封面下载占位填满图片区域，并支持减少动态效果', (tester) async {
    await _mount(
      tester,
      child: const Center(
        child: SizedBox(
          width: 120,
          height: 180,
          child: ComicDiscoveryCoverSkeleton(),
        ),
      ),
    );
    expect(tester.getSize(find.byType(SkeletonBlock)), const Size(120, 180));
    final first = await _frame(tester);
    await tester.pump(const Duration(milliseconds: 600));
    expect(await _frame(tester), isNot(orderedEquals(first)));
    await _mount(
      tester,
      reduced_motion: true,
      child: const SizedBox(
        width: 120,
        height: 180,
        child: ComicDiscoveryCoverSkeleton(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}
