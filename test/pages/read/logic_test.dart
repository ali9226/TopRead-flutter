import 'package:app/models/novel_info.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/stores/novel_reading_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('长篇阅读导航栏滚动判断', () {
    late Logic logic;

    setUp(() {
      logic = Logic(
        story_id: 1,
        story_title: '测试小说',
        initial_body_font_size: 18,
        initial_auto_read_speed: 0.2,
      );
      logic.sync_scroll_offset(400);
    });

    tearDown(() {
      logic.onClose();
    });

    test('同方向累计超过阈值后隐藏和显示导航栏', () {
      logic.show_navigation.value = true;

      logic.on_scroll(405);
      expect(logic.show_navigation.value, isTrue);

      logic.on_scroll(409);
      expect(logic.show_navigation.value, isFalse);

      logic.on_scroll(405);
      expect(logic.show_navigation.value, isFalse);

      logic.on_scroll(400);
      expect(logic.show_navigation.value, isTrue);
    });

    test('方向变化会重置累计锚点，轻微回弹不会闪烁', () {
      logic.show_navigation.value = true;

      logic.on_scroll(407);
      logic.on_scroll(406);
      logic.on_scroll(408);

      expect(logic.show_navigation.value, isTrue);
    });

    test('程序化定位同步基准后不会被识别为大幅滚动', () {
      logic.show_navigation.value = true;
      logic.sync_scroll_offset(1200);

      logic.on_scroll(1204);

      expect(logic.show_navigation.value, isTrue);
    });
  });

  group('长篇阅读字数进度换算', () {
    late NovelReadingStore reading_store;
    late Logic logic;

    setUp(() {
      reading_store = NovelReadingStore();
      logic = Logic(
        story_id: 1,
        story_title: '测试小说',
        reading_store: reading_store,
        initial_body_font_size: 18,
        initial_auto_read_speed: 0.2,
      );
      reading_store.set_chapter_list(<NovelChapterInfo>[
        _chapter(id: '11', chapter_no: 1, word_count: 100),
        _chapter(id: '12', chapter_no: 2, word_count: 300),
      ]);
    });

    tearDown(() {
      logic.onClose();
    });

    test('全书进度按章节字数定位而不是按章节数量均分', () {
      expect(logic.find_chapter_index_by_progress(20), 0);
      expect(logic.find_chapter_index_by_progress(30), 1);
    });

    test('全书百分比和章节内百分比可以双向换算', () {
      final double chapter_progress = logic.calculate_chapter_progress_percent(
        reading_progress_percent: 50,
        chapter_index: 1,
      );
      final double total_progress = logic
          .calculate_total_progress_percent_for_chapter(
            chapter_index: 1,
            chapter_progress_percent: chapter_progress,
          );

      expect(chapter_progress, closeTo(33.333, 0.01));
      expect(total_progress, closeTo(50, 0.01));
    });
  });

  test('跳转到中间章节时上一章首次失败会重试并进入阅读窗口', () async {
    final NovelReadingStore reading_store = NovelReadingStore();
    final String cache_namespace =
        'read-window-${DateTime.now().microsecondsSinceEpoch}';
    final Map<String, int> request_counts = <String, int>{};
    final Logic logic = Logic(
      story_id: 1,
      story_title: '测试小说',
      reading_store: reading_store,
      initial_body_font_size: 18,
      initial_auto_read_speed: 0.2,
      chapter_content_loader: (String url) async {
        final int count = (request_counts[url] ?? 0) + 1;
        request_counts[url] = count;
        if (url.endsWith('/84') && count == 1) {
          return '';
        }
        return '第 $url 章正文';
      },
    );
    addTearDown(logic.onClose);

    reading_store.set_chapter_list(
      List<NovelChapterInfo>.generate(
        100,
        (int index) => _chapter(
          id: '${index + 1}',
          chapter_no: index + 1,
          word_count: 100,
          content_url: '$cache_namespace/$index',
        ),
      ),
    );
    reading_store.cache_chapter_content(83, '第 84 章正文');
    reading_store.cache_chapter_content(87, '第 88 章正文');

    final int? generation = await logic.jump_to_chapter(85);
    expect(generation, isNotNull);

    final Set<int> rendered_chapters = reading_store.reading_items
        .map((ReadingContentItem item) => item.chapter_index)
        .toSet();
    expect(rendered_chapters, containsAll(<int>[84, 85, 86]));
    expect(logic.min_loaded_chapter_index, 84);
    expect(request_counts['$cache_namespace/84'], 2);

    logic.complete_chapter_jump(generation!);
  });
}

NovelChapterInfo _chapter({
  required String id,
  required int chapter_no,
  required int word_count,
  String content_url = '',
}) {
  return NovelChapterInfo(
    id: id,
    novel_language_id: '1',
    chapter_no: chapter_no,
    title: '第 $chapter_no 章',
    sorting: chapter_no,
    content_url: content_url,
    word_count: word_count,
    is_vip: 0,
    create_time: '',
    update_time: '',
    remove_status: 0,
  );
}
