// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:app/components/window_content_layout/index.dart';
import 'package:app/pages/author_center/widgets/creator_header.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 复用仓库内真实多语种资源，统计卡片文案直接来自 i18n。
class _Assets extends AssetLoader {
  const _Assets();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
            as Map,
      );
}

Map<String, String> _zh_labels() {
  final Map<String, dynamic> json = Map<String, dynamic>.from(
    jsonDecode(File('assets/i18n/zh.json').readAsStringSync()) as Map,
  );
  return Map<String, String>.from(json['creator_center'] as Map);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    await EasyLocalization.ensureInitialized();
  });

  Future<void> pump_header(
    WidgetTester tester, {
    required bool dashboard_loaded,
    int works_count = 12,
    String favorites_count = '23',
    String comments_count = '34',
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[Locale('zh')],
        path: 'assets/i18n',
        assetLoader: const _Assets(),
        startLocale: const Locale('zh'),
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: WindowLayoutScope(
              child: Scaffold(
                body: DefaultTabController(
                  length: 4,
                  child: Builder(
                    builder: (context) => CreatorHeaderOverlay(
                      tab_controller: DefaultTabController.of(context),
                      current_height: 500,
                      is_dark: false,
                      is_cjk: true,
                      author_name: '作者',
                      works_count: works_count,
                      favorites_count: favorites_count,
                      comments_count: comments_count,
                      dashboard_loaded: dashboard_loaded,
                      on_back: () {},
                      on_create_work: () {},
                      on_continue_writing: () {},
                      on_open_guide: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // 统计数字带 300ms 入场动画，补帧让计数动画走完。
    await tester.pumpAndSettle(const Duration(milliseconds: 350));
  }

  testWidgets('数据概览未加载时三张统计卡片只显示占位', (tester) async {
    final labels = _zh_labels();
    await pump_header(tester, dashboard_loaded: false);

    expect(find.text(labels['stats_works']!), findsOneWidget);
    expect(find.text(labels['stats_favorites']!), findsOneWidget);
    expect(find.text(labels['stats_comments']!), findsOneWidget);
    // 未加载完成时数字位统一用破折号占位。
    expect(find.text('—'), findsNWidgets(3));
  });

  testWidgets('数据概览加载后统计卡片渲染作品/收藏/评论数值', (tester) async {
    final labels = _zh_labels();
    await pump_header(
      tester,
      dashboard_loaded: true,
      works_count: 12,
      favorites_count: '23',
      comments_count: '34',
    );

    expect(find.text(labels['stats_works']!), findsOneWidget);
    expect(find.text(labels['stats_favorites']!), findsOneWidget);
    expect(find.text(labels['stats_comments']!), findsOneWidget);
    // 加载完成后不再使用破折号占位。
    expect(find.text('—'), findsNothing);
    // 计数动画按 0..目标值滚动渲染，目标值本身一定出现。
    expect(find.text('34'), findsOneWidget);
    expect(find.text('23'), findsWidgets);
    expect(find.text('12'), findsWidgets);
  });

  testWidgets('数据概览数值为 0 时直接显示 0 而不是占位符', (tester) async {
    await pump_header(
      tester,
      dashboard_loaded: true,
      works_count: 0,
      favorites_count: '0',
      comments_count: '0',
    );

    expect(find.text('—'), findsNothing);
    expect(find.text('0'), findsNWidgets(3));
  });
}
