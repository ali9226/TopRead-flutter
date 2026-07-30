import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/models/story_item.dart';
import 'package:app/pages/bookshelf/style.dart' as bookshelf_style;
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/style.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/widgets/ranking_book_item.dart';
import 'package:app/pages/ranking_full_list/style.dart'
    as ranking_full_list_style;
import 'package:app/util/text/text_layout_measure.dart';

void main() {
  test('系统文字放大时首页榜单和完整榜单卡片高度同步扩展', () {
    const TextScaler default_text_scaler = TextScaler.noScaling;
    const TextScaler large_text_scaler = TextScaler.linear(1.5);

    expect(
      RankingSectionStyle.resolve_item_height(default_text_scaler),
      RankingSectionStyle.item_height,
    );
    expect(
      RankingSectionStyle.resolve_item_height(large_text_scaler),
      greaterThan(RankingSectionStyle.item_height),
    );
    expect(
      ranking_full_list_style.Style.resolve_book_content_area_height(
        large_text_scaler,
      ),
      greaterThan(
        ranking_full_list_style.Style.resolve_book_content_area_height(
          default_text_scaler,
        ),
      ),
    );
    expect(
      bookshelf_style.Style.resolve_book_content_area_height(large_text_scaler),
      greaterThan(
        bookshelf_style.Style.resolve_book_content_area_height(
          default_text_scaler,
        ),
      ),
    );
  });

  testWidgets('iPad 宽度下按真实语种和文字缩放稳定判断标题行数', (WidgetTester tester) async {
    final List<_LayoutTestCase> test_case_list = <_LayoutTestCase>[
      const _LayoutTestCase(
        locale: Locale('zh'),
        text_direction: TextDirection.ltr,
        text_scaler: TextScaler.linear(1),
        single_line_title: '短标题',
        multi_line_title: '这是一个需要在榜单卡片中完整显示为两行的中文长标题',
        category_text: '都市',
        heat_text: '9万热度',
      ),
      const _LayoutTestCase(
        locale: Locale('en'),
        text_direction: TextDirection.ltr,
        text_scaler: TextScaler.linear(1.2),
        single_line_title: 'Short',
        multi_line_title:
            'A multilingual ranking title that must wrap correctly on iPad',
        category_text: 'F',
        heat_text: '9K',
      ),
      const _LayoutTestCase(
        locale: Locale('ar'),
        text_direction: TextDirection.rtl,
        text_scaler: TextScaler.linear(1.3),
        single_line_title: 'قصير',
        multi_line_title:
            'عنوان رواية طويل متعدد اللغات يجب أن يلتف بشكل صحيح على الجهاز',
        category_text: 'خيال',
        heat_text: '9K',
      ),
    ];

    for (final _LayoutTestCase test_case in test_case_list) {
      await _pump_ranking_item(
        tester: tester,
        test_case: test_case,
        title: test_case.single_line_title,
      );

      final Offset single_category_position = tester.getTopLeft(
        find.text(test_case.category_text),
      );
      final Offset single_heat_position = tester.getTopLeft(
        find.text(test_case.heat_text),
      );

      expect(
        single_heat_position.dy,
        greaterThan(single_category_position.dy),
        reason: test_case.locale.toLanguageTag(),
      );
      expect(tester.takeException(), isNull);

      await _pump_ranking_item(
        tester: tester,
        test_case: test_case,
        title: test_case.multi_line_title,
      );

      final Offset multi_category_position = tester.getTopLeft(
        find.text(test_case.category_text),
      );
      final Offset multi_heat_position = tester.getTopLeft(
        find.text(test_case.heat_text),
      );
      final Rect title_rect = tester.getRect(
        find.text(test_case.multi_line_title),
      );
      final Rect item_rect = tester.getRect(find.byType(RankingBookItem));
      final double scaled_single_line_height =
          test_case.text_scaler.scale(RankingSectionStyle.title_font_size) *
          RankingSectionStyle.title_line_height;

      expect(
        (multi_category_position.dy - multi_heat_position.dy).abs(),
        lessThan(0.5),
      );
      expect(title_rect.height, greaterThan(scaled_single_line_height));
      expect(title_rect.bottom, lessThanOrEqualTo(item_rect.bottom));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('文字测量使用实际宽度边界且支持 CJK、拉丁和 RTL 语种', (WidgetTester tester) async {
    final List<_LayoutTestCase> test_case_list = <_LayoutTestCase>[
      const _LayoutTestCase(
        locale: Locale('zh'),
        text_direction: TextDirection.ltr,
        text_scaler: TextScaler.linear(1),
        single_line_title: '中英文混排 Title 123',
        multi_line_title: '',
        category_text: '',
        heat_text: '',
      ),
      const _LayoutTestCase(
        locale: Locale('en'),
        text_direction: TextDirection.ltr,
        text_scaler: TextScaler.linear(1.25),
        single_line_title: 'Adaptive multilingual title',
        multi_line_title: '',
        category_text: '',
        heat_text: '',
      ),
      const _LayoutTestCase(
        locale: Locale('ar'),
        text_direction: TextDirection.rtl,
        text_scaler: TextScaler.linear(1.4),
        single_line_title: 'عنوان متعدد اللغات',
        multi_line_title: '',
        category_text: '',
        heat_text: '',
      ),
    ];

    for (final _LayoutTestCase test_case in test_case_list) {
      bool? fits_exact_width;
      bool? exceeds_narrow_width;

      await tester.pumpWidget(
        MaterialApp(
          locale: test_case.locale,
          supportedLocales: <Locale>[test_case.locale],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(1024, 1366),
              textScaler: test_case.text_scaler,
            ),
            child: Directionality(
              textDirection: test_case.text_direction,
              child: Builder(
                builder: (BuildContext context) {
                  final TextStyle text_style = TextStyle(
                    fontSize: RankingSectionStyle.title_font_size,
                    height: RankingSectionStyle.title_line_height,
                  );
                  final double measured_width = measure_single_line_text_width(
                    context: context,
                    text: test_case.single_line_title,
                    text_style: text_style,
                  );

                  fits_exact_width = !text_requires_multiple_lines(
                    context: context,
                    text: test_case.single_line_title,
                    text_style: text_style,
                    max_width: measured_width + 0.5,
                  );
                  exceeds_narrow_width = text_requires_multiple_lines(
                    context: context,
                    text: test_case.single_line_title,
                    text_style: text_style,
                    max_width: measured_width - 0.5,
                  );

                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      expect(fits_exact_width, isTrue);
      expect(exceeds_narrow_width, isTrue);
      expect(tester.takeException(), isNull);
    }
  });
}

/// 在 iPad 媒体尺寸中渲染一个首页榜单书籍项。
Future<void> _pump_ranking_item({
  required WidgetTester tester,
  required _LayoutTestCase test_case,
  required String title,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: test_case.locale,
      supportedLocales: <Locale>[test_case.locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(1024, 1366),
          textScaler: test_case.text_scaler,
        ),
        child: Directionality(
          textDirection: test_case.text_direction,
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: RankingSectionStyle.column_content_width,
                child: RankingBookItem(
                  book: StoryItem(
                    id: 1,
                    title: title,
                    popularity_count: test_case.heat_text,
                    cover_url: '',
                    category_text: test_case.category_text,
                    heat_text: test_case.heat_text,
                  ),
                  ranking_index: 1,
                  is_dark: false,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// 单组设备语种与文字缩放测试参数。
class _LayoutTestCase {
  final Locale locale;
  final TextDirection text_direction;
  final TextScaler text_scaler;
  final String single_line_title;
  final String multi_line_title;
  final String category_text;
  final String heat_text;

  const _LayoutTestCase({
    required this.locale,
    required this.text_direction,
    required this.text_scaler,
    required this.single_line_title,
    required this.multi_line_title,
    required this.category_text,
    required this.heat_text,
  });
}
