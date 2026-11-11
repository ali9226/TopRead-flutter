import 'package:app/models/story_item.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/style.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/widgets/ranking_book_item.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/widgets/ranking_content.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

const _horizontal_list_key = ValueKey<String>('ranking_horizontal_list');
const _content_key = ValueKey<String>('ranking_layout_content');

/// TODO 榜单几何测试仅使用假数据，不访问网络、磁盘缓存或原生路径插件。
class _NoImageCache implements BaseCacheManager {
  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) => const Stream<FileResponse>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    CachedNetworkImageProvider.defaultCacheManager = _NoImageCache();
  });

  testWidgets('普通列保持固定宽度且末列吸附贴左撑满父容器', (tester) async {
    await _pump_content(tester);
    expect(
      tester.getSize(_book(1)).width,
      RankingSectionStyle.column_content_width,
    );

    await _drag_to_end(tester);

    _expect_end_visible(tester, 20);
    expect(tester.takeException(), isNull);
  });

  testWidgets('末列磁吸贴左后仍能反向甩动并停靠普通列', (tester) async {
    await _pump_content(tester, size: const Size(800, 600));
    await _drag_to_end(tester);
    final ScrollPosition position = _position(tester);
    expect(position.maxScrollExtent, 920);
    _expect_end_visible(tester, 20);

    await tester.fling(
      find.byKey(_horizontal_list_key),
      const Offset(260, 0),
      1500,
    );
    await _settle_scroll(tester);

    expect(position.pixels, lessThan(position.maxScrollExtent));
    expect(position.outOfRange, isFalse);
    final double column_extent =
        RankingSectionStyle.column_content_width +
        RankingSectionStyle.column_gap;
    expect(position.pixels % column_extent, closeTo(0, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('横屏、Duo 单屏与平板宽屏在日夜模式下均保持末列贴左且完整', (tester) async {
    for (final Size size in <Size>[
      const Size(844, 390),
      const Size(540, 720),
      const Size(720, 540),
      const Size(1366, 1024),
    ]) {
      for (final bool is_dark in <bool>[false, true]) {
        await _pump_content(
          tester,
          size: size,
          is_dark: is_dark,
          content_key: ValueKey<String>(
            'ranking_${size.width}_${size.height}_$is_dark',
          ),
        );
        expect(
          tester.getSize(_book(1)).width,
          RankingSectionStyle.column_content_width,
          reason: '$size, dark=$is_dark',
        );

        await _drag_to_end(tester);

        _expect_end_visible(tester, 20);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('末端在尺寸变化及重新挂载后仍恢复为合法可见位置', (tester) async {
    int saved_column_index = 0;
    void save_column(int index) => saved_column_index = index;

    await _pump_content(tester, on_column_index_changed: save_column);
    await _drag_to_end(tester);
    _expect_end_visible(tester, 20);

    await _pump_content(
      tester,
      size: const Size(800, 600),
      on_column_index_changed: save_column,
    );
    _expect_end_visible(tester, 20);
    final double resized_offset = _position(tester).pixels;

    await _pump_content(
      tester,
      size: const Size(800, 600),
      content_key: const ValueKey<String>('ranking_remounted_content'),
      initial_column_index: saved_column_index,
      on_column_index_changed: save_column,
    );

    expect(_position(tester).pixels, closeTo(resized_offset, .01));
    _expect_end_visible(tester, 20);
    expect(tester.takeException(), isNull);
  });

  testWidgets('单列在窄屏中撑满可用宽度且不产生横向溢出', (tester) async {
    await _pump_content(tester, size: const Size(320, 640), book_count: 4);

    expect(_position(tester).pixels, 0);
    expect(_position(tester).maxScrollExtent, 0);
    _expect_end_visible(tester, 4);

    await _drag_to_end(tester);

    expect(_position(tester).pixels, 0);
    _expect_end_visible(tester, 4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('数据减少时旧末端位置回到新范围且末列仍贴左撑满', (tester) async {
    await _pump_content(tester);
    await _drag_to_end(tester);

    await _pump_content(tester, book_count: 5);

    _expect_end_visible(tester, 5);
    expect(_position(tester).maxScrollExtent, 230);
    expect(tester.takeException(), isNull);

    await _pump_content(tester, book_count: 4);

    expect(_position(tester).pixels, 0);
    expect(_position(tester).maxScrollExtent, 0);
    _expect_end_visible(tester, 4);
    expect(tester.takeException(), isNull);
  });
}

/// TODO 按稳定业务编号定位唯一书籍，避免依赖懒加载列表中的组件顺序。
Finder _book(int id) => find.byWidgetPredicate(
  (Widget widget) => widget is RankingBookItem && widget.book.id == id,
);

/// TODO 从指定榜单列表取得滚动位置，用于断言真实手势后的反馈。
ScrollPosition _position(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(
        of: find.byKey(_horizontal_list_key),
        matching: find.byType(Scrollable),
      ),
    )
    .position;

/// TODO 只等待滚动物理收敛，封面假缓存保留的骨架动画不属于本次断言。
Future<void> _settle_scroll(WidgetTester tester) async {
  await tester.pump();
  for (int frame = 0; frame < 100; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (!_position(tester).isScrollingNotifier.value) {
      return;
    }
  }
  fail('榜单横向滚动未在预期时间内结束');
}

/// TODO 通过列表实际可交互区域拖至末端，并等待吸附结束。
Future<void> _drag_to_end(WidgetTester tester) async {
  final Finder horizontal_list = find.byKey(_horizontal_list_key);
  expect(horizontal_list, findsOneWidget);
  await tester.fling(horizontal_list, const Offset(-3000, 0), 3000);
  await _settle_scroll(tester);
}

/// TODO 末列左右边缘均与父容器内边距对齐，封面贴左且整列不超过父容器。
void _expect_end_visible(WidgetTester tester, int last_book_id) {
  final ScrollPosition position = _position(tester);
  final Rect list_rect = tester.getRect(find.byKey(_horizontal_list_key));
  final Rect book_rect = tester.getRect(_book(last_book_id));

  expect(position.outOfRange, isFalse);
  expect(position.pixels, closeTo(position.maxScrollExtent, .01));
  expect(
    book_rect.left,
    closeTo(
      list_rect.left + RankingSectionStyle.content_padding_horizontal,
      .01,
    ),
  );
  expect(
    book_rect.right,
    closeTo(
      list_rect.right - RankingSectionStyle.content_padding_horizontal,
      .01,
    ),
  );
  expect(
    book_rect.width,
    closeTo(
      list_rect.width - RankingSectionStyle.content_padding_horizontal * 2,
      .01,
    ),
  );
  expect(book_rect.width, lessThanOrEqualTo(list_rect.width));
}

/// TODO 用假书籍数据渲染真实榜单布局，size 模拟设备窗口、key 模拟子 Tab 挂载。
Future<void> _pump_content(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  bool is_dark = false,
  int book_count = 20,
  Key content_key = _content_key,
  int initial_column_index = 0,
  ValueChanged<int>? on_column_index_changed,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: const <Locale>[Locale('en')],
      theme: ThemeData(
        brightness: is_dark ? Brightness.dark : Brightness.light,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: RankingContent(
            key: content_key,
            books: List<StoryItem>.generate(
              book_count,
              (int index) => StoryItem(
                id: index + 1,
                title: 'A long ranking title for book ${index + 1}',
                popularity_count: '9K',
                category_text: 'Fiction',
                heat_text: '9K',
                cover_url: '',
              ),
            ),
            is_dark: is_dark,
            panel_bg: is_dark ? Colors.black : Colors.white,
            initial_column_index: initial_column_index,
            on_column_index_changed: on_column_index_changed,
          ),
        ),
      ),
    ),
  );
  await _settle_scroll(tester);
}
