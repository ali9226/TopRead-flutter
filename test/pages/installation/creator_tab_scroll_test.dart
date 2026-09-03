// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:app/components/back_to_top_button/index.dart';
import 'package:app/components/floating_back_to_top/index.dart';
import 'package:app/pages/installation/widgets/creator_work_tab.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const MethodChannel preferences_channel = MethodChannel(
      'plugins.flutter.io/shared_preferences',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(preferences_channel, (
          MethodCall method_call,
        ) async {
          if (method_call.method == 'getAll') {
            return <String, Object>{};
          }
          return true;
        });
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('Creator tabs keep completely independent scroll positions', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final PageController page_controller = PageController();
    final ScrollController first_scroll_controller = ScrollController();
    final ScrollController second_scroll_controller = ScrollController();
    addTearDown(page_controller.dispose);
    addTearDown(first_scroll_controller.dispose);
    addTearDown(second_scroll_controller.dispose);

    await tester.pumpWidget(
      _build_test_app(
        PageView(
          controller: page_controller,
          children: <Widget>[
            _build_tab(0, first_scroll_controller),
            _build_tab(1, second_scroll_controller),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      first_scroll_controller.position.maxScrollExtent,
      greaterThanOrEqualTo(200),
    );
    first_scroll_controller.jumpTo(160);
    await tester.pump();
    expect(first_scroll_controller.offset, 160);

    page_controller.jumpToPage(1);
    await tester.pumpAndSettle();
    expect(second_scroll_controller.offset, 0);

    second_scroll_controller.jumpTo(60);
    await tester.pump();
    expect(second_scroll_controller.offset, 60);

    page_controller.jumpToPage(0);
    await tester.pumpAndSettle();
    expect(first_scroll_controller.offset, 160);
    expect(second_scroll_controller.offset, 60);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Short tab supports pinned content on its first layout', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final ScrollController scroll_controller = ScrollController(
      initialScrollOffset: 200,
    );
    addTearDown(scroll_controller.dispose);

    await tester.pumpWidget(_build_test_app(_build_tab(0, scroll_controller)));
    await tester.pump();

    expect(scroll_controller.hasClients, isTrue);
    expect(
      scroll_controller.position.maxScrollExtent,
      greaterThanOrEqualTo(200),
    );
    expect(scroll_controller.offset, closeTo(200, 1));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Creator header follows drag and snaps at halfway threshold', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final ScrollController scroll_controller = ScrollController();
    addTearDown(scroll_controller.dispose);

    await tester.pumpWidget(_build_test_app(_build_tab(0, scroll_controller)));
    await tester.pumpAndSettle();

    final TestGesture expand_gesture = await tester.startGesture(
      const Offset(195, 520),
    );
    await expand_gesture.moveBy(const Offset(0, -80));
    await tester.pump(const Duration(milliseconds: 16));
    expect(scroll_controller.offset, closeTo(80, 1));
    await expand_gesture.up();
    await tester.pumpAndSettle();
    expect(scroll_controller.offset, closeTo(0, 1));

    final TestGesture pin_gesture = await tester.startGesture(
      const Offset(195, 520),
    );
    await pin_gesture.moveBy(const Offset(0, -120));
    await tester.pump(const Duration(milliseconds: 16));
    expect(scroll_controller.offset, closeTo(120, 1));
    await pin_gesture.up();
    await tester.pumpAndSettle();
    expect(scroll_controller.offset, closeTo(200, 1));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Horizontal release never triggers vertical header snapping', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final PageController page_controller = PageController();
    final ScrollController first_scroll_controller = ScrollController();
    final ScrollController second_scroll_controller = ScrollController();
    addTearDown(page_controller.dispose);
    addTearDown(first_scroll_controller.dispose);
    addTearDown(second_scroll_controller.dispose);

    await tester.pumpWidget(
      _build_test_app(
        PageView(
          controller: page_controller,
          children: <Widget>[
            _build_tab(0, first_scroll_controller),
            _build_tab(1, second_scroll_controller),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    first_scroll_controller.jumpTo(80);
    await tester.pump();

    final TestGesture horizontal_gesture = await tester.startGesture(
      const Offset(330, 520),
    );
    await horizontal_gesture.moveBy(const Offset(-260, 4));
    await tester.pump(const Duration(milliseconds: 16));
    await horizontal_gesture.up();
    await tester.pumpAndSettle();

    expect(first_scroll_controller.offset, closeTo(80, 1));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Back to top controls only its owning creator tab', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final PageController page_controller = PageController();
    final ScrollController first_scroll_controller = ScrollController();
    final ScrollController second_scroll_controller = ScrollController();
    addTearDown(page_controller.dispose);
    addTearDown(first_scroll_controller.dispose);
    addTearDown(second_scroll_controller.dispose);

    await tester.pumpWidget(
      _build_test_app(
        PageView(
          controller: page_controller,
          children: <Widget>[
            _build_tab(0, first_scroll_controller),
            _build_tab(1, second_scroll_controller),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    first_scroll_controller.jumpTo(80);
    await tester.pump();
    expect(
      tester
          .widget<FloatingBackToTop>(
            find.byKey(const ValueKey<String>('creator_back_to_top_tab_0')),
          )
          .show,
      isTrue,
    );

    page_controller.jumpToPage(1);
    await tester.pumpAndSettle();
    second_scroll_controller.jumpTo(120);
    await tester.pumpAndSettle();

    final Finder second_back_to_top = find.byKey(
      const ValueKey<String>('creator_back_to_top_tab_1'),
    );
    expect(tester.widget<FloatingBackToTop>(second_back_to_top).show, isTrue);
    await tester.tap(
      find.descendant(
        of: second_back_to_top,
        matching: find.byType(BackToTopButton),
      ),
    );
    await tester.pumpAndSettle();

    expect(second_scroll_controller.offset, closeTo(0, 1));
    expect(first_scroll_controller.offset, closeTo(80, 1));
    expect(tester.widget<FloatingBackToTop>(second_back_to_top).show, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Widget _build_tab(int tab_index, ScrollController scroll_controller) {
  return CreatorWorkTab(
    tab_index: tab_index,
    works: const [],
    is_dark: false,
    is_cjk: true,
    scroll_controller: scroll_controller,
    header_spacer_height: 300,
    minimum_header_height: 100,
    minimum_scroll_extent: 200,
    on_create_work: () {},
    on_edit_work: (_) {},
    on_primary_action: (_) {},
  );
}

Widget _build_test_app(Widget child) {
  return EasyLocalization(
    supportedLocales: const <Locale>[Locale('zh')],
    path: 'assets/i18n',
    assetLoader: const _CreatorTabTestAssetLoader(),
    startLocale: const Locale('zh'),
    fallbackLocale: const Locale('zh'),
    child: Builder(
      builder: (BuildContext context) {
        return MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(body: child),
        );
      },
    ),
  );
}

class _CreatorTabTestAssetLoader extends AssetLoader {
  const _CreatorTabTestAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return <String, dynamic>{
      'creator_center': <String, dynamic>{
        'empty_title': '暂无作品',
        'empty_subtitle': '从创建第一部作品开始',
        'create_first_work': '创建作品',
      },
    };
  }
}
