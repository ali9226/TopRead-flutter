import 'dart:convert';
import 'dart:io';

import 'package:app/components/work_reading_actions/index.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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

Future<void> _mount(
  WidgetTester tester, {
  bool continuing = false,
  bool loading = false,
  bool favorited = false,
  bool can_read = true,
  bool compact = false,
  bool dark = true,
  String language = 'en',
  double text_scale = 1,
  double width = 280,
  VoidCallback? on_read,
  VoidCallback? on_favorite,
}) async {
  await tester.pumpWidget(
    EasyLocalization(
      path: 'assets/i18n',
      supportedLocales: [Locale(language)],
      startLocale: Locale(language),
      fallbackLocale: Locale(language),
      saveLocale: false,
      assetLoader: const _Assets(),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(text_scale)),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: width,
                  child: WorkReadingActions(
                    on_read: on_read ?? () {},
                    on_favorite: on_favorite ?? () {},
                    continuing: continuing,
                    can_read: can_read,
                    compact: compact,
                    favorite_loading: loading,
                    favorited: favorited,
                    on_hero: dark,
                    is_dark: dark,
                    read_key: const ValueKey('read'),
                    favorite_key: const ValueKey('favorite'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  // 以有限帧验证星形和交互状态，不依赖动画是否结束。
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
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
    // 常规按钮比例使用真实字体测量，避免Ahem测试字体把短文案误判为多行。
    final font = File(
      '${Platform.environment['FLUTTER_ROOT'] ?? '.fvm/flutter_sdk'}'
      '/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
    );
    if (font.existsSync()) {
      await (FontLoader('Roboto')..addFont(
            Future.value(ByteData.sublistView(font.readAsBytesSync())),
          ))
          .load();
    }
  });

  testWidgets('无阅读历史显示开始，有历史显示续读，保留阅读和收藏回调', (tester) async {
    var reads = 0;
    var favorites = 0;
    await _mount(
      tester,
      on_read: () => reads++,
      on_favorite: () => favorites++,
    );
    expect(find.text('Start reading'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('read')));
    await tester.tap(find.byKey(const ValueKey('favorite')));
    expect(reads, 1);
    expect(favorites, 1);
    await _mount(tester, continuing: true);
    expect(find.text('Continue reading'), findsOneWidget);
    expect(find.text('Start reading'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('常规金色主操作为48dp，左阅读线索与右方向引导不挤压文案', (tester) async {
    await _mount(tester);
    final read = tester.getRect(find.byKey(const ValueKey('read')));
    final book = tester.getRect(find.byIcon(Icons.menu_book_rounded));
    final title = tester.getRect(find.text('Start reading'));
    final direction = tester.getRect(find.byIcon(Icons.chevron_right_rounded));
    final favorite = tester.getRect(find.byKey(const ValueKey('favorite')));
    expect(read.height, closeTo(48, 0.01));
    expect(book.right, lessThan(title.left));
    expect(title.right, lessThan(direction.left));
    expect(direction.right, lessThan(read.right));
    expect(read.right, lessThan(favorite.left));
    expect(favorite.height, closeTo(read.height, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('收藏明确使用同一套空实星和收藏动作语义，不再冒充点赞爱心', (tester) async {
    await _mount(tester);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is SvgIcon && widget.name == 'not_favorited',
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Save to library'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    await _mount(tester, favorited: true);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is SvgIcon && widget.name == 'user_selected',
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Remove from library'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [180.0, 150.0]) {
    testWidgets('极窄窗口分行保留完整续读文案和收藏触控区域 width=$width', (tester) async {
      await _mount(tester, width: width, text_scale: 2, continuing: true);
      final read = tester.getRect(find.byKey(const ValueKey('read')));
      final favorite = tester.getRect(find.byKey(const ValueKey('favorite')));
      expect(read.width, closeTo(width, 0.01));
      expect(favorite.top, greaterThan(read.bottom));
      expect(favorite.width, greaterThanOrEqualTo(48));
      expect(find.text('Continue reading'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('显式紧凑模式44dp并排显示完整文案与收藏，不展示尾部方向装饰', (tester) async {
    var reads = 0;
    var favorites = 0;
    await _mount(
      tester,
      width: 210,
      compact: true,
      on_read: () => reads++,
      on_favorite: () => favorites++,
    );
    final read = tester.getRect(find.byKey(const ValueKey('read')));
    final favorite = tester.getRect(find.byKey(const ValueKey('favorite')));
    expect(read.height, closeTo(44, 0.01));
    expect(favorite.size, const Size(44, 44));
    expect(read.right, lessThan(favorite.left));
    expect(find.text('Start reading'), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    await tester.tap(find.byKey(const ValueKey('read')));
    await tester.tap(find.byKey(const ValueKey('favorite')));
    expect(reads, 1);
    expect(favorites, 1);
    expect(tester.takeException(), isNull);
  });

  for (final language in ['en', 'zh']) {
    testWidgets('紧凑续读支持大字和极窄列重排 $language', (tester) async {
      for (final width in [196.0, 150.0]) {
        await _mount(
          tester,
          width: width,
          compact: true,
          continuing: true,
          text_scale: 2,
          language: language,
        );
        final read = tester.getRect(find.byKey(const ValueKey('read')));
        final favorite = tester.getRect(find.byKey(const ValueKey('favorite')));
        expect(read.height, greaterThanOrEqualTo(44));
        if (width < 164) {
          expect(favorite.top, greaterThan(read.bottom));
        } else {
          expect(read.right, lessThan(favorite.left));
        }
        expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('紧凑不可读与收藏加载状态仍禁用原业务操作', (tester) async {
    var reads = 0;
    var favorites = 0;
    await _mount(
      tester,
      width: 210,
      compact: true,
      loading: true,
      favorited: true,
      can_read: false,
      on_read: () => reads++,
      on_favorite: () => favorites++,
    );
    await tester.tap(find.byKey(const ValueKey('read')));
    await tester.tap(find.byKey(const ValueKey('favorite')));
    expect(reads, 0);
    expect(favorites, 0);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is SvgIcon && widget.name == 'user_selected',
      ),
      findsOneWidget,
    );
    final favorite = tester.widget<IconButton>(
      find.byKey(const ValueKey('favorite')),
    );
    expect(favorite.style!.splashFactory, NoSplash.splashFactory);
    expect(
      favorite.style!.overlayColor!.resolve({WidgetState.pressed}),
      Colors.transparent,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('不可阅读和收藏请求期间分别禁用原操作', (tester) async {
    var reads = 0;
    var favorites = 0;
    await _mount(
      tester,
      loading: true,
      can_read: false,
      on_read: () => reads++,
      on_favorite: () => favorites++,
    );
    await tester.tap(find.byKey(const ValueKey('read')));
    await tester.tap(find.byKey(const ValueKey('favorite')));
    expect(reads, 0);
    expect(favorites, 0);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final language in ['en', 'zh']) {
    for (final dark in [false, true]) {
      testWidgets('窄屏两倍字号操作完整换行 $language dark=$dark', (tester) async {
        await _mount(
          tester,
          language: language,
          dark: dark,
          text_scale: 2,
          continuing: true,
        );
        final read = tester.getRect(find.byKey(const ValueKey('read')));
        final favorite = tester.getRect(find.byKey(const ValueKey('favorite')));
        expect(read.height, greaterThanOrEqualTo(46));
        expect(read.right, lessThan(favorite.left));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
