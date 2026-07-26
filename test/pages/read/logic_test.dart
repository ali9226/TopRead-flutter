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
}

NovelChapterInfo _chapter({
  required String id,
  required int chapter_no,
  required int word_count,
}) {
  return NovelChapterInfo(
    id: id,
    novel_language_id: '1',
    chapter_no: chapter_no,
    title: '第 $chapter_no 章',
    sorting: chapter_no,
    content_url: '',
    word_count: word_count,
    is_vip: 0,
    create_time: '',
    update_time: '',
    remove_status: 0,
  );
}
