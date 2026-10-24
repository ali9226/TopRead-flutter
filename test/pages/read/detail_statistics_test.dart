import 'dart:convert';
import 'dart:io';

import 'package:app/components/work_hero_stats/index.dart';
import 'package:app/models/novel_info.dart';
import 'package:app/models/project_config.dart';
import 'package:app/pages/read/utils/detail_builder.dart';
import 'package:app/pages/read/utils/read_models.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/stat_section/index.dart';
import 'package:app/stores/novel_reading_store.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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

ReadDetail _legacy_detail({String score = '9.6'}) => ReadDetail(
  story_id: 42,
  title: 'Story',
  cover_url: '',
  author_id: 1,
  author_avatar_url: '',
  author_name: 'Author',
  focus_on: false,
  score_major_text: score,
  score_minor_text: '',
  review_count_text: '12.4K ratings',
  reading_major_text: '234.1',
  reading_minor_text: 'K',
  reading_subtitle_text: 'Readers',
  word_count_major_text: '1.2',
  word_count_minor_text: 'M',
  word_count_subtitle_text: 'Words',
  tag_list: const [],
  intro_text: '',
  chapter_title: '',
  comment_list: const [],
);

Future<void> _mount(
  WidgetTester tester, {
  required Widget Function(BuildContext context) builder,
  String language = 'en',
}) async {
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
          home: Scaffold(body: Builder(builder: builder)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<WorkHeroStat> _stats(WidgetTester tester) =>
    tester.widget<WorkHeroStatsRow>(find.byType(WorkHeroStatsRow)).items;

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
    Get.put(ProjectConfigStore());
  });
  tearDown(Get.reset);

  for (final language in ['en', 'zh']) {
    testWidgets('真实阅读量和字数按$language格式化，统计标签不混入完结状态', (tester) async {
      final store = NovelReadingStore();
      store.novel_info.value = NovelInfo.from_json({
        'id': 42,
        'read_count': '9955',
        'publish_status': 2,
        'score': 0,
        'language_info': {'title': 'Story', 'word_count': 246000},
      });
      late ReadDetail detail;
      await _mount(
        tester,
        language: language,
        builder: (context) {
          detail = DetailBuilder.build(
            store: store,
            story_id: 42,
            story_title: 'Story',
            locale: context.locale.toString(),
          );
          return ReadStatSection(detail: detail, is_dark: false);
        },
      );
      final items = _stats(tester);
      expect(items, hasLength(2));
      expect(items[0].value, language == 'en' ? '9.96K' : '9955');
      expect(items[1].value, language == 'en' ? '246K' : '24.6万');
      expect(items[0].label, language == 'en' ? 'Readers' : '人');
      expect(items[1].label, language == 'en' ? 'words' : '字');
      expect(detail.status_text, language == 'en' ? 'Completed' : '已完结');
      expect(items.any((item) => item.label == detail.status_text), isFalse);
      expect(detail.reading_major_text, '9955');
      expect(detail.word_count_major_text, '24.6');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('异常阅读量不从包含单位的字符串猜数字', (tester) async {
    final store = NovelReadingStore();
    store.novel_info.value = NovelInfo.from_json({
      'read_count': '9955Readers',
      'language_info': {'word_count': 24000},
    });
    await _mount(
      tester,
      builder: (context) => ReadStatSection(
        detail: DetailBuilder.build(
          store: store,
          story_id: 42,
          story_title: 'Story',
          locale: 'en',
        ),
        is_dark: false,
      ),
    );
    expect(_stats(tester).first.value, '—');
    expect(_stats(tester).last.value, '24K');
    expect(tester.takeException(), isNull);
  });

  testWidgets('旧展示fixture保留原拆分字段，不补造不存在的统计', (tester) async {
    await _mount(
      tester,
      builder: (_) => ReadStatSection(detail: _legacy_detail(), is_dark: false),
    );
    expect(_stats(tester).map((item) => item.value), ['9.6', '234.1K', '1.2M']);
    expect(tester.takeException(), isNull);
  });

  for (final score in ['', '0', '0.0']) {
    testWidgets('评分为$score时省略评分列', (tester) async {
      await _mount(
        tester,
        builder: (_) => ReadStatSection(
          detail: _legacy_detail(score: score),
          is_dark: false,
        ),
      );
      expect(_stats(tester), hasLength(2));
      expect(
        _stats(tester).any((item) => item.icon == Icons.star_rounded),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('评分功能关闭时仍保留真实阅读和字数', (tester) async {
    Get.find<ProjectConfigStore>().save_config(
      ProjectConfig.from_json({'rating_switch': SwitchValue.off}),
    );
    await _mount(
      tester,
      builder: (_) => ReadStatSection(detail: _legacy_detail(), is_dark: false),
    );
    expect(_stats(tester).map((item) => item.value), ['234.1K', '1.2M']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('苹果审核时隐藏评分但保留阅读和字数', (tester) async {
    Get.find<ProjectConfigStore>().save_config(
      ProjectConfig.from_json({
        'rating_switch': SwitchValue.on,
        'app_review_status': 1,
      }),
    );
    await _mount(
      tester,
      builder: (_) => ReadStatSection(detail: _legacy_detail(), is_dark: false),
    );
    expect(_stats(tester), hasLength(2));
    expect(
      _stats(tester).any((item) => item.icon == Icons.star_rounded),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant({TargetPlatform.iOS}));
}
