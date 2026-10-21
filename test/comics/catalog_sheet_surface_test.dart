// ignore_for_file: non_constant_identifier_names

import 'package:app/components/catalog_card/index.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/logic.dart';
import 'package:app/pages/comics/detail/widgets/detail_sheets.dart';
import 'package:app/pages/comics/widgets/chapter_sheet/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Detail extends ComicDetailLogic {
  _Detail(int count) : super(42, progress_changes: ChangeNotifier()) {
    loading = false;
    detail = ComicDetail.from_json({
      'comic': {'id': 42, 'title': 'A comic', 'author_name': 'Author'},
      'languages': [
        {'id': 1, 'language': 'en', 'title': 'A comic'},
      ],
      'selected_language_id': 1,
      'chapters': List.generate(
        count,
        (index) => {
          'id': index + 1,
          'title': 'Chapter ${index + 1}',
          'page_count': 28,
          'status': 'published',
        },
      ),
    });
  }
}

void main() {
  Future<void> mount(
    WidgetTester tester,
    Widget Function(BuildContext) builder, {
    bool dark = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(bottom: 34),
            viewPadding: const EdgeInsets.only(bottom: 34),
          ),
          child: child!,
        ),
        home: Scaffold(body: Builder(builder: builder)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  for (final count in [4, 100]) {
    testWidgets('$count章目录自然高度或受最大高度限制，底部安全区有背景', (tester) async {
      final logic = _Detail(count);
      addTearDown(logic.dispose);
      await mount(
        tester,
        (context) => TextButton(
          onPressed: () => show_comic_chapter_sheet(
            context,
            comic_id: 42,
            controller: logic,
          ),
          child: const Text('open'),
        ),
      );
      final rect = tester.getRect(
        find.byKey(const ValueKey('comic_chapter_sheet_surface')),
      );
      expect(rect.bottom, closeTo(844, 0.1));
      if (count == 4) {
        expect(rect.height, lessThan(844 * 0.85));
      } else {
        expect(rect.height, lessThanOrEqualTo(844 * 0.9 + 0.1));
      }
      expect(find.byType(CatalogCardSurface), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('推荐查看全部使用目录卡片并正确打开作品，夜间安全区有背景', (tester) async {
    final comic = ComicItem.from_json({
      'id': 19,
      'title': 'A long comic title',
      'description': 'A complete description for this comic.',
      'author_name': 'Artist',
    });
    int? opened;
    await mount(
      tester,
      (context) => TextButton(
        onPressed: () =>
            show_comic_recommendations(context, [comic], (id) => opened = id),
        child: const Text('open'),
      ),
      dark: true,
    );
    final rect = tester.getRect(
      find.byKey(const ValueKey('comic_detail_sheet_surface')),
    );
    expect(rect.bottom, closeTo(844, 0.1));
    expect(find.byType(CatalogCardSurface), findsOneWidget);
    await tester.tap(find.text(comic.title));
    await tester.pumpAndSettle();
    expect(opened, 19);
    expect(tester.takeException(), isNull);
  });
}
