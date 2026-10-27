// ignore_for_file: non_constant_identifier_names

import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:app/components/reader_top_bar/action_button.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/project_config.dart';
import 'package:app/pages/read/widgets/navigation_bars/top/index.dart';
import 'package:app/pages/short_story_read/widgets/full_appbar.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Assets extends AssetLoader {
  const _Assets();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'comics': {'collect': 'Save', 'collected': 'Saved', 'share': 'Share'},
    'favorite': {
      'action_add': 'Save to library',
      'action_remove': 'Remove from library',
    },
  };
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
  tearDown(Get.reset);

  testWidgets('长篇顶部显示章节标题、保留原回调及远端分享开关，加载使用主题色', (tester) async {
    final config = Get.put(ProjectConfigStore());
    config.save_config(
      ProjectConfig.from_json({'share_switch': SwitchValue.off}),
    );
    var collected = false;
    var loading = false;
    var back = 0, favorite = 0, shares = 0;
    late StateSetter update;
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'test',
        assetLoader: const _Assets(),
        startLocale: const Locale('en'),
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, state) {
                  update = state;
                  return Stack(
                    children: [
                      ReadTopBar(
                        title: 'Chapter 4',
                        is_dark: false,
                        show: true,
                        on_back: () => back++,
                        on_favorite_tap: () => favorite++,
                        on_share: () => shares++,
                        is_favorited: collected,
                        is_loading: loading,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    List<ReaderTopBarAction> actions() => tester
        .widgetList<ReaderTopBarAction>(find.byType(ReaderTopBarAction))
        .toList();
    expect(actions().first.asset, 'right');
    expect((actions()[1].icon_widget! as SvgIcon).name, 'not_favorited');
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    expect(actions()[1].label, 'Save to library');
    expect(find.text('Chapter 4'), findsOneWidget);
    await tester.tap(find.byWidget(actions()[1]));
    expect(favorite, 1);
    update(() => collected = true);
    await tester.pumpAndSettle();
    expect((actions()[1].icon_widget! as SvgIcon).name, 'user_selected');
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    expect(actions()[1].color, ColorConstants.themeColor);
    expect(actions()[1].label, 'Remove from library');
    config.save_config(
      ProjectConfig.from_json({'share_switch': SwitchValue.on}),
    );
    await tester.pumpAndSettle();
    expect(actions().last.asset, 'share');
    await tester.tap(find.byWidget(actions().last));
    expect(shares, 1);
    update(() => loading = true);
    await tester.pump();
    expect(
      tester
          .widgetList<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .map((indicator) => indicator.color),
      everyElement(ColorConstants.themeColor),
    );
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
    await tester.tap(find.byWidget(actions().first));
    expect(back, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('长短篇标题单行省略并避让导航，分享原色在竖横屏和Duo日夜主题一致', (tester) async {
    Get.put(
      ProjectConfigStore(),
    ).save_config(ProjectConfig.from_json({'share_switch': SwitchValue.on}));
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final scenario in [
      (
        size: const Size(320, 600),
        dark: false,
        locale: const Locale('en'),
        duo: false,
      ),
      (
        size: const Size(844, 390),
        dark: true,
        locale: const Locale('en'),
        duo: false,
      ),
      (
        size: const Size(466, 678),
        dark: false,
        locale: const Locale('zh'),
        duo: true,
      ),
      (
        size: const Size(678, 466),
        dark: true,
        locale: const Locale('zh'),
        duo: true,
      ),
    ]) {
      tester.view.physicalSize = scenario.size;
      final chapter =
          'Chapter ${'very long chapter title '.padRight(180, 'x')}';
      final story = '作品标题${'很长的作品标题'.padRight(180, '长')}';
      final insets = EdgeInsets.only(top: 32, right: scenario.duo ? 84 : 0);
      await tester.pumpWidget(
        EasyLocalization(
          key: ValueKey(scenario),
          supportedLocales: const [Locale('en'), Locale('zh')],
          path: 'test',
          assetLoader: const _Assets(),
          startLocale: scenario.locale,
          saveLocale: false,
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              home: MediaQuery(
                data: MediaQueryData(
                  size: scenario.size,
                  padding: insets,
                  viewPadding: insets,
                  displayFeatures: scenario.duo
                      ? [
                          DisplayFeature(
                            bounds: Rect.fromLTWH(
                              scenario.size.width - 84,
                              0,
                              84,
                              32,
                            ),
                            type: DisplayFeatureType.cutout,
                            state: DisplayFeatureState.unknown,
                          ),
                        ]
                      : const [],
                ),
                child: WindowLayoutScope(
                  child: Scaffold(
                    body: Column(
                      children: [
                        SizedBox(
                          height: 100,
                          child: Stack(
                            children: [
                              ReadTopBar(
                                title: chapter,
                                is_dark: scenario.dark,
                                show: true,
                                on_back: () {},
                                on_favorite_tap: () {},
                                on_share: () {},
                                is_favorited: false,
                              ),
                            ],
                          ),
                        ),
                        FullAppbar(
                          title: story,
                          is_dark: scenario.dark,
                          on_back: () {},
                          on_favorite_tap: () {},
                          on_share: () {},
                          is_favorited: false,
                          status_bar_height: 32,
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
      for (final (type, title) in [
        (ReadTopBar, chapter),
        (FullAppbar, story),
      ]) {
        final title_finder = find.text(title);
        final title_widget = tester.widget<Text>(title_finder);
        expect(title_widget.maxLines, 1);
        expect(title_widget.overflow, TextOverflow.ellipsis);
        expect(
          tester.renderObject<RenderParagraph>(title_finder).didExceedMaxLines,
          isTrue,
        );
        Finder icon(String name) => find.descendant(
          of: find.byType(type),
          matching: find.byWidgetPredicate(
            (widget) => widget is SvgIcon && widget.name == name,
          ),
        );
        expect(
          tester.getRect(title_finder).right,
          lessThanOrEqualTo(tester.getRect(icon('not_favorited')).left),
        );
        expect(tester.getRect(title_finder).left, greaterThan(0));
      }
      Finder share_in(Type type) => find.descendant(
        of: find.byType(type),
        matching: find.byWidgetPredicate(
          (widget) => widget is SvgIcon && widget.name == 'share',
        ),
      );
      final novel = tester.widget<SvgIcon>(share_in(ReadTopBar));
      final short = tester.widget<SvgIcon>(share_in(FullAppbar));
      expect(novel.width, short.width);
      expect(novel.height, short.height);
      expect(novel.color, short.color);
      SvgPicture picture(Type type) => tester.widget<SvgPicture>(
        find.descendant(of: share_in(type), matching: find.byType(SvgPicture)),
      );
      expect(picture(ReadTopBar).bytesLoader, picture(FullAppbar).bytesLoader);
      expect(picture(ReadTopBar).colorFilter, isNull);
      expect(tester.takeException(), isNull);
    }
  });
}
