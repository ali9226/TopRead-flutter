// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:app/components/positioning/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/short_story_item.dart';
import 'package:app/models/novel_info.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/pages/read/widgets/read_directory_sheet/index.dart';
import 'package:app/pages/short_story_read/widgets/catalog/catalog_item.dart';
import 'package:app/pages/short_story_read/widgets/catalog/catalog_sheet.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/short_story_catalog_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';

class _Assets extends AssetLoader {
  const _Assets();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
            as Map,
      );
}

/// 本组只验证目录布局，不订阅设备网络状态或请求分页数据。
class _DeviceInfo extends DeviceInfo {
  @override
  // 目录布局测试刻意跳过真实网络订阅，避免启动 DeviceInfo 的插件生命周期。
  // ignore: must_call_super
  void onInit() {}
}

/// 目录仅消费本地章节和书籍摘要，不初始化阅读服务或请求网络。
class _DirectoryLogic extends Fake implements Logic {
  @override
  final current_chapter_index = 0.obs;

  @override
  final chapter_list = List.generate(
    30,
    (index) => NovelChapterInfo.from_json({
      'id': '${index + 1}',
      'chapter_no': index + 1,
      'title': 'Chapter ${index + 1}',
    }),
  );

  @override
  ReadDetail build_detail() => const ReadDetail(
    story_id: 1,
    title: 'A quiet promise',
    cover_url: '',
    author_id: 1,
    author_avatar_url: '',
    author_name: '',
    focus_on: false,
    score_major_text: '5',
    score_minor_text: '',
    review_count_text: '3',
    reading_major_text: '12',
    reading_minor_text: '',
    reading_subtitle_text: '',
    word_count_major_text: '10',
    word_count_minor_text: '',
    word_count_subtitle_text: '',
    tag_list: [],
    intro_text: 'A quiet promise.',
    chapter_title: 'Chapter 1',
    comment_list: [],
  );
}

ShortStoryItem _story(int index) => ShortStoryItem(
  id: index + 1,
  title: 'Story ${index + 1}',
  description: 'A promise changes the course of a quiet life.',
  tags: const ['Mystery'],
  like_count: 3,
);

Future<void> _mount(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  bool dark = false,
  double scale = 1,
  int current_id = 1,
  bool loading = false,
  Widget? directory,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final device = Get.find<DeviceInfo>();
  device.theme.value = dark ? ThemeMode.dark : ThemeMode.light;
  final catalog = Get.find<ShortStoryCatalogStore>();
  catalog.has_more = false;
  catalog.is_loading.value = loading;
  catalog.is_error.value = false;
  catalog.set_catalog_list(List.generate(30, _story));
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      startLocale: const Locale('en'),
      path: 'assets/i18n',
      assetLoader: const _Assets(),
      child: Builder(
        builder: (context) => MaterialApp(
          theme: dark ? ThemeData.dark() : ThemeData.light(),
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(scale),
              viewPadding: const EdgeInsets.only(bottom: 34),
            ),
            child: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child:
                    directory ??
                    CatalogSheet(
                      current_story_id: current_id,
                      catalog_list: catalog.catalog_list,
                      is_catalog_loading: catalog.is_loading,
                      is_catalog_error: catalog.is_error,
                      on_item_tap: (_) {},
                      on_like_tap: (_) {},
                      on_close: () {},
                      on_reload: () {},
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

Finder get _location => find.byType(PositioningButton);

Finder _current() => find.byWidgetPredicate(
  (widget) => widget is CatalogItem && widget.is_current,
);

ScrollController _controller(WidgetTester tester) =>
    tester.widget<ListView>(find.byType(ListView)).controller!;

void _expect_hidden(WidgetTester tester) {
  final button = tester.widget<PositioningButton>(_location);
  expect(button.show, isFalse);
  expect(button.icon_color, ColorConstants.dangerColor);
  expect(
    tester
        .widget<AnimatedOpacity>(
          find.descendant(
            of: _location,
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity,
    0,
  );
}

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
  setUp(() {
    Get.testMode = true;
    Get.put<DeviceInfo>(_DeviceInfo());
    Get.put(ShortStoryCatalogStore());
  });
  tearDown(() => Get.reset());

  for (final scenario in [
    (const Size(390, 844), false, 1.0),
    (const Size(844, 390), true, 1.0),
    (const Size(466, 678), true, 2.0),
  ]) {
    testWidgets('首项已显示时不出现定位按钮 ${scenario.$1}', (tester) async {
      await _mount(
        tester,
        size: scenario.$1,
        dark: scenario.$2,
        scale: scenario.$3,
      );
      expect(_current(), findsOneWidget);
      final item = tester.getRect(_current());
      final viewport = tester.getRect(find.byType(ListView));
      expect(item.overlaps(viewport), isTrue);
      expect(item.top - viewport.top, lessThan(12));
      _expect_hidden(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('当前项部分可见时隐藏，完全离屏后淡入，点击动画返回后淡出', (tester) async {
    await _mount(tester);
    final controller = _controller(tester);
    final first_height = tester.getSize(_current()).height;
    controller.jumpTo(first_height / 2);
    await tester.pumpAndSettle();
    expect(
      tester
          .getRect(_current())
          .overlaps(tester.getRect(find.byType(ListView))),
      isTrue,
    );
    _expect_hidden(tester);

    controller.jumpTo(first_height + 40);
    await tester.pump();
    await tester.pump();
    expect(tester.widget<PositioningButton>(_location).show, isTrue);
    await tester.pump(const Duration(milliseconds: 70));
    final fade = find.descendant(
      of: _location,
      matching: find.byType(FadeTransition),
    );
    expect(tester.widget<FadeTransition>(fade).opacity.value, greaterThan(0));
    expect(tester.widget<FadeTransition>(fade).opacity.value, lessThan(1));
    await tester.pumpAndSettle();
    final before = controller.offset;
    await tester.tap(_location);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.offset, lessThan(before));
    expect(controller.offset, greaterThan(0));
    await tester.pumpAndSettle();
    _expect_hidden(tester);
    expect(
      tester
          .getRect(_current())
          .overlaps(tester.getRect(find.byType(ListView))),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('延迟加载与远端当前作品初次定位完成后不留下定位按钮', (tester) async {
    await _mount(tester, current_id: 20, loading: true);
    _expect_hidden(tester);
    Get.find<ShortStoryCatalogStore>().is_loading.value = false;
    await tester.pumpAndSettle();
    expect(_current(), findsOneWidget);
    expect(
      tester
          .getRect(_current())
          .overlaps(tester.getRect(find.byType(ListView))),
      isTrue,
    );
    _expect_hidden(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('长篇首章与部分可见章节同样不误显示定位，离屏后可返回', (tester) async {
    await _mount(
      tester,
      directory: ReadDirectorySheet(
        logic: _DirectoryLogic(),
        is_dark: false,
        current_chapter_progress_percent: 0,
      ),
    );
    final controller = _controller(tester);
    final current = find.text('Chapter 1');
    expect(current, findsOneWidget);
    _expect_hidden(tester);
    controller.jumpTo(20);
    await tester.pumpAndSettle();
    _expect_hidden(tester);
    controller.jumpTo(180);
    await tester.pumpAndSettle();
    expect(tester.widget<PositioningButton>(_location).show, isTrue);
    await tester.tap(_location);
    await tester.pumpAndSettle();
    _expect_hidden(tester);
    expect(current.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
