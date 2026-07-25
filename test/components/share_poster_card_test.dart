import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app/components/share_sheet/style.dart';
import 'package:app/components/share_sheet/widgets/card_preview_sheet.dart';
import 'package:app/components/share_sheet/widgets/share_poster_card.dart';
import 'package:app/config/font_config.dart';
import 'package:app/stores/share_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const MethodChannel preferences_channel = MethodChannel(
      'plugins.flutter.io/shared_preferences',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(preferences_channel, (_) async {
          return <String, Object>{};
        });
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('海报只渲染摘录和书籍信息且固定导出尺寸', (WidgetTester tester) async {
    const String excerpt = '真正重要的不是故事有多长，而是它是否在某一页照亮过你。';
    final GlobalKey boundary_key = GlobalKey();

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[Locale('zh')],
        path: 'assets/i18n',
        assetLoader: const _SharePosterTestAssetLoader(),
        startLocale: const Locale('zh'),
        fallbackLocale: const Locale('zh'),
        child: Builder(
          builder: (BuildContext context) {
            return MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Material(
                child: Center(
                  child: RepaintBoundary(
                    key: boundary_key,
                    child: const SharePosterCard(
                      novel_id: 42,
                      novel_title: '长夜里的微光',
                      novel_author: '林川',
                      novel_cover_url: '',
                      novel_intro: excerpt,
                      user_avatar_url: '',
                      user_nickname: '小满',
                      date_text: '2026.07.13',
                      fallback_avatar_index: 3,
                      canvas_colors: <Color>[
                        Color(0xFFE7E2D8),
                        Color(0xFFD8D1C4),
                      ],
                      accent_color: Color(0xFF8A755D),
                      footer_color: Color(0xFFF3F0EA),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final Finder poster = find.byType(SharePosterCard);
    expect(poster, findsOneWidget);
    expect(
      tester.getSize(poster),
      const Size(
        ShareSheetStyle.poster_design_width,
        ShareSheetStyle.poster_design_height,
      ),
    );
    expect(find.text(excerpt), findsOneWidget);
    expect(find.text('小满 · 摘录'), findsOneWidget);
    expect(find.text('长夜里的微光'), findsNWidgets(2));
    expect(find.text('林川'), findsOneWidget);
    expect(find.text('打开TopRead · 与我共读'), findsOneWidget);
    expect(find.text('保存到相册'), findsNothing);
    final Text excerpt_widget = tester.widget<Text>(find.text(excerpt));
    expect(
      excerpt_widget.style?.fontWeight,
      FontConfig.adjustedWeight(FontWeight.w500),
    );
    expect(
      find.byWidgetPredicate((Widget widget) {
        if (widget is! SvgPicture || widget.bytesLoader is! SvgAssetLoader) {
          return false;
        }
        return (widget.bytesLoader as SvgAssetLoader).assetName ==
            'assets/svg/logo.svg';
      }),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    final RenderRepaintBoundary boundary =
        boundary_key.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage();
    expect(image.width, ShareSheetStyle.poster_design_width);
    expect(image.height, ShareSheetStyle.poster_design_height);
    image.dispose();
  });

  testWidgets('切换海报配色时预览区域不会被色板动画上下挤压', (WidgetTester tester) async {
    Get.put<ShareStore>(ShareStore());
    addTearDown(Get.reset);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[Locale('zh')],
        path: 'assets/i18n',
        assetLoader: const _SharePosterTestAssetLoader(),
        startLocale: const Locale('zh'),
        fallbackLocale: const Locale('zh'),
        child: Builder(
          builder: (BuildContext context) {
            return MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: const Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: CardPreviewSheet(
                    novel_id: 42,
                    novel_title: '长夜里的微光',
                    novel_author: '林川',
                    novel_cover_url: '',
                    novel_intro: '真正重要的不是故事有多长，而是它是否照亮过你。',
                    is_dark: false,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final Finder pager = find.byType(PageView);
    final double initial_top = tester.getTopLeft(pager).dy;
    final double initial_height = tester.getSize(pager).height;

    await tester.drag(pager, const Offset(-320, 0));
    await tester.pump(const Duration(milliseconds: 125));

    expect(tester.getTopLeft(pager).dy, closeTo(initial_top, 0.01));
    expect(tester.getSize(pager).height, closeTo(initial_height, 0.01));

    await tester.pumpAndSettle();
    final Finder dark_poster = find.byWidgetPredicate(
      (Widget widget) => widget is SharePosterCard && widget.use_dark_palette,
    );
    expect(dark_poster, findsOneWidget);
    final SharePosterCard dark_poster_widget = tester.widget<SharePosterCard>(
      dark_poster,
    );
    expect(
      dark_poster_widget.footer_color,
      ShareSheetStyle.card_footer_colors[1],
    );
    final Text dark_excerpt = tester.widget<Text>(
      find.descendant(
        of: dark_poster,
        matching: find.text('真正重要的不是故事有多长，而是它是否照亮过你。'),
      ),
    );
    expect(
      dark_excerpt.style?.color,
      ShareSheetStyle.poster_primary_text_color_dark,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('share_color_indicator_3')),
    );
    await tester.pumpAndSettle();

    final PageView page_view = tester.widget<PageView>(pager);
    expect(page_view.controller?.page, closeTo(3, 0.01));
    final AnimatedContainer selected_dot = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey<String>('share_color_indicator_dot_3')),
    );
    expect(
      selected_dot.constraints?.maxWidth,
      ShareSheetStyle.indicator_active_width,
    );
    expect(tester.takeException(), isNull);
  });
}

class _SharePosterTestAssetLoader extends AssetLoader {
  const _SharePosterTestAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return <String, dynamic>{
      'share_sheet': <String, dynamic>{
        'default_reader': '一位读者',
        'card_preview_title': '卡片预览',
        'save_to_album': '保存到相册',
        'excerpt_by': '{name} · 摘录',
        'read_together': '打开{app} · 与我共读',
        'qr_semantics': '书籍分享二维码',
        'share_text': '我正在用{app}看《{title}》，快来一起看吧！',
      },
    };
  }
}
