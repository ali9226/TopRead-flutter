// ignore_for_file: non_constant_identifier_names

import 'dart:ui' as ui;

import 'package:app/components/window_content_layout/index.dart';
import 'package:app/pages/novel_discovery/browse/style.dart';
import 'package:app/pages/novel_discovery/browse/widgets/category_tabs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _Translations extends AssetLoader {
  const _Translations();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {};
}

class _TabsHarness extends StatefulWidget {
  const _TabsHarness({required this.dark});

  final bool dark;

  @override
  State<_TabsHarness> createState() => _TabsHarnessState();
}

class _TabsHarnessState extends State<_TabsHarness>
    with SingleTickerProviderStateMixin {
  late final TabController controller = TabController(length: 18, vsync: this);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        const SizedBox(height: 84),
        NovelBrowseCategoryTabs(
          categories: List.generate(
            18,
            (index) => {
              'id': index + 1,
              'translations': {
                'zh': '分类${index + 1}',
                'en': 'Genre ${index + 1}',
              },
            },
          ),
          controller: controller,
          is_dark: widget.dark,
        ),
        const Expanded(
          child: SizedBox(
            key: ValueKey('novel_browse_content_start'),
            width: double.infinity,
          ),
        ),
      ],
    ),
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

  for (final config in [
    (
      size: const Size(390, 844),
      locale: 'zh',
      dark: false,
      scale: 1.0,
      duo: false,
    ),
    (
      size: const Size(390, 844),
      locale: 'en',
      dark: true,
      scale: 1.0,
      duo: false,
    ),
    (
      size: const Size(844, 390),
      locale: 'zh',
      dark: true,
      scale: 1.0,
      duo: false,
    ),
    (
      size: const Size(844, 390),
      locale: 'en',
      dark: false,
      scale: 1.8,
      duo: false,
    ),
    (
      size: const Size(951, 678),
      locale: 'zh',
      dark: false,
      scale: 2.0,
      duo: true,
    ),
    (
      size: const Size(466, 678),
      locale: 'en',
      dark: true,
      scale: 2.0,
      duo: true,
    ),
  ]) {
    testWidgets('分类标题和列表之间保留留白 $config', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = config.size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('zh')],
          path: 'unused',
          assetLoader: const _Translations(),
          startLocale: Locale(config.locale),
          saveLocale: false,
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              theme: ThemeData(
                brightness: config.dark ? Brightness.dark : Brightness.light,
              ),
              home: MediaQuery(
                data: MediaQueryData(
                  size: config.size,
                  textScaler: TextScaler.linear(config.scale),
                  padding: EdgeInsets.only(right: config.duo ? 84 : 0),
                  viewPadding: EdgeInsets.only(right: config.duo ? 84 : 0),
                  displayFeatures: config.duo
                      ? [
                          ui.DisplayFeature(
                            bounds: Rect.fromLTWH(
                              config.size.width - 84,
                              0,
                              84,
                              124,
                            ),
                            type: ui.DisplayFeatureType.cutout,
                            state: ui.DisplayFeatureState.unknown,
                          ),
                        ]
                      : [],
                ),
                child: WindowLayoutScope(
                  child: _TabsHarness(dark: config.dark),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      void verify_spacing(String selected_title) {
        final tabs = find.byKey(const ValueKey('novel_browse_category_tabs'));
        final tabs_rect = tester.getRect(tabs);
        final content_rect = tester.getRect(
          find.byKey(const ValueKey('novel_browse_content_start')),
        );
        final indicator =
            tester.widget<TabBar>(tabs).indicator! as UnderlineTabIndicator;
        final indicator_bottom =
            tabs_rect.bottom -
            indicator.insets.resolve(ui.TextDirection.ltr).bottom;
        final indicator_top = indicator_bottom - indicator.borderSide.width;
        final title_rect = tester.getRect(find.text(selected_title));

        // 底部留白属于固定标题栏，滚动列表不会把它带走。
        expect(
          content_rect.top - tabs_rect.bottom,
          closeTo(NovelBrowseStyle.tab_bottom_gap, 0.01),
        );
        expect(
          content_rect.top - indicator_bottom,
          closeTo(
            NovelBrowseStyle.tab_bottom_gap +
                NovelBrowseStyle.tab_indicator_bottom_offset,
            0.01,
          ),
        );
        // 选中文字经过缩放后的真实边界仍在指示线上方。
        expect(title_rect.bottom, lessThan(indicator_top));
        expect(title_rect.top, greaterThanOrEqualTo(tabs_rect.top));
      }

      verify_spacing(config.locale == 'zh' ? '分类1' : 'Genre 1');
      final state = tester.state<_TabsHarnessState>(find.byType(_TabsHarness));
      state.controller.animateTo(17);
      await tester.pumpAndSettle();
      verify_spacing(config.locale == 'zh' ? '分类18' : 'Genre 18');
      final last_tab = tester.getRect(
        find.byKey(const ValueKey('novel_browse_category_18')),
      );
      final tabs_rect = tester.getRect(find.byType(NovelBrowseCategoryTabs));
      expect(
        last_tab.center.dx,
        inInclusiveRange(tabs_rect.left, tabs_rect.right),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
