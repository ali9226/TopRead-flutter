import 'package:get/get.dart';
import 'package:app/models/novel_info.dart';

/// 阅读内容项。
class ReadingContentItem {
  /// 文本内容。
  final String text;

  /// 是否为章节标题。
  final bool is_title;

  /// 所属章节号。
  final int chapter_no;

  /// 所属章节索引（在目录中的索引）。
  final int chapter_index;

  /// 当前章节之前的总字数累计。
  final int words_before_this_chapter;

  /// 当前章节的总字数。
  final int chapter_total_words;

  ReadingContentItem({
    required this.text,
    this.is_title = false,
    required this.chapter_no,
    required this.chapter_index,
    required this.words_before_this_chapter,
    required this.chapter_total_words,
  });
}

/// 小说阅读内容全局 Store。
class NovelReadingStore extends GetxController {
  /// 当前阅读的小说详情。
  var novel_info = Rxn<NovelInfo>();

  /// 结构化的阅读内容列表。
  var reading_items = <ReadingContentItem>[].obs;

  /// 目录列表。
  var chapter_list = <NovelChapterInfo>[].obs;

  /// 章节内容缓存，key 为章节索引，value 为章节正文文本。
  /// 避免重复请求已加载过的章节，提升切换速度。
  final Map<int, String> _chapter_content_cache = {};

  /// 记录当前阅读进度比例（用于切换主题等场景恢复位置）。
  double last_reading_progress_ratio = 0.0;

  /// 记录当前滚动偏移量（用于切换主题等场景恢复位置）。
  double last_scroll_offset = 0.0;

  /// 标记是否需要恢复滚动位置。
  bool needs_restore_scroll_position = false;

  /// 获取指定章节的缓存内容，如果未缓存则返回 null。
  ///
  /// [chapter_index] 章节在目录中的索引。
  String? get_cached_chapter_content(int chapter_index) {
    return _chapter_content_cache[chapter_index];
  }

  /// 将章节内容写入缓存。
  ///
  /// [chapter_index] 章节在目录中的索引。
  /// [content] 章节正文文本。
  void cache_chapter_content(int chapter_index, String content) {
    _chapter_content_cache[chapter_index] = content;
  }

  /// 检查指定章节是否已缓存。
  ///
  /// [chapter_index] 章节在目录中的索引。
  bool is_chapter_cached(int chapter_index) {
    return _chapter_content_cache.containsKey(chapter_index);
  }

  /// 清空章节正文内存缓存。
  ///
  /// 手动刷新时使用；磁盘缓存由逻辑层按有效期管理，不在这里删除。
  void clear_chapter_content_cache() {
    _chapter_content_cache.clear();
  }

  /// 设置当前阅读的小说详情。
  void set_novel_info(NovelInfo info) {
    novel_info.value = info;
  }

  /// 设置目录列表。
  void set_chapter_list(List<NovelChapterInfo> list) {
    chapter_list.assignAll(list);
  }

  /// 清空并设置初始章节内容。
  void set_initial_content(
    String title,
    int chapter_no,
    int chapter_index,
    int words_before,
    int chapter_total,
    String content,
  ) {
    reading_items.clear();
    // 添加标题
    reading_items.add(
      ReadingContentItem(
        text: title,
        is_title: true,
        chapter_no: chapter_no,
        chapter_index: chapter_index,
        words_before_this_chapter: words_before,
        chapter_total_words: chapter_total,
      ),
    );
    _append_content_items(
      chapter_no,
      chapter_index,
      words_before,
      chapter_total,
      content,
      is_first: true,
    );
  }

  /// 追加章节内容。
  void append_chapter_content(
    String title,
    int chapter_no,
    int chapter_index,
    int words_before,
    int chapter_total,
    String content,
  ) {
    // 追加标题项
    reading_items.add(
      ReadingContentItem(
        text: title,
        is_title: true,
        chapter_no: chapter_no,
        chapter_index: chapter_index,
        words_before_this_chapter: words_before,
        chapter_total_words: chapter_total,
      ),
    );

    // 追加正文项
    _append_content_items(
      chapter_no,
      chapter_index,
      words_before,
      chapter_total,
      content,
    );
  }

  /// 在顶部插入章节内容。
  void prepend_chapter_content(
    String title,
    int chapter_no,
    int chapter_index,
    int words_before,
    int chapter_total,
    String content,
  ) {
    final List<ReadingContentItem> newItems = [];
    // 添加标题
    newItems.add(
      ReadingContentItem(
        text: title,
        is_title: true,
        chapter_no: chapter_no,
        chapter_index: chapter_index,
        words_before_this_chapter: words_before,
        chapter_total_words: chapter_total,
      ),
    );

    // 添加正文
    final List<String> lines = content
        .split(RegExp(r'\r?\n'))
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList();

    for (final String line in lines) {
      newItems.add(
        ReadingContentItem(
          text: line,
          is_title: false,
          chapter_no: chapter_no,
          chapter_index: chapter_index,
          words_before_this_chapter: words_before,
          chapter_total_words: chapter_total,
        ),
      );
    }

    // 插入到列表头部
    reading_items.insertAll(0, newItems);
  }

  /// 将原始文本分割并转换为 ReadingContentItem 列表追加。
  void _append_content_items(
    int chapter_no,
    int chapter_index,
    int words_before,
    int chapter_total,
    String content, {
    bool is_first = false,
  }) {
    final List<String> lines = content
        .split(RegExp(r'\r?\n'))
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList();

    for (final String line in lines) {
      reading_items.add(
        ReadingContentItem(
          text: line,
          is_title: false,
          chapter_no: chapter_no,
          chapter_index: chapter_index,
          words_before_this_chapter: words_before,
          chapter_total_words: chapter_total,
        ),
      );
    }
  }

  /// 根据缓存重建指定范围的章节阅读列表。
  ///
  /// 会清空现有 reading_items，然后按顺序拼接 [start_index] 到 [end_index] 的章节内容。
  /// 每个章节的正文从缓存中读取，未缓存的章节会被跳过。
  ///
  /// [start_index] 起始章节索引（含）。
  /// [end_index] 结束章节索引（含）。
  /// [chapter_list] 目录列表，用于获取章节元信息。
  void rebuild_reading_items_from_cache(
    int start_index,
    int end_index,
    List<NovelChapterInfo> chapter_list,
  ) {
    reading_items.clear();

    for (int i = start_index; i <= end_index; i++) {
      final String? content = _chapter_content_cache[i];
      if (content == null) continue;

      final NovelChapterInfo chapter = chapter_list[i];

      // 计算该章节之前的累计字数。
      int words_before = 0;
      for (int j = 0; j < i; j++) {
        words_before += chapter_list[j].word_count;
      }

      // 添加章节标题。
      reading_items.add(
        ReadingContentItem(
          text: chapter.title,
          is_title: true,
          chapter_no: chapter.chapter_no,
          chapter_index: i,
          words_before_this_chapter: words_before,
          chapter_total_words: chapter.word_count,
        ),
      );

      // 添加章节正文段落。
      _append_content_items(
        chapter.chapter_no,
        i,
        words_before,
        chapter.word_count,
        content,
      );
    }
  }

  /// 清空当前阅读的小说详情。
  void clear_novel_info() {
    novel_info.value = null;
    reading_items.clear();
    chapter_list.clear();
    _chapter_content_cache.clear();
    last_reading_progress_ratio = 0.0;
    last_scroll_offset = 0.0;
    needs_restore_scroll_position = false;
  }
}
