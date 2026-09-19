// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:app/api/paragraph_comment.dart';
import 'package:app/models/paragraph_anchor.dart';
import 'package:app/models/story_paragraph.dart';
import 'package:app/util/split_story_paragraphs.dart';
import 'package:crypto/crypto.dart';
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

  /// 章节数据库 ID，与目录序号及窗口内索引分开保存。
  final String chapter_id;

  /// 完整章节正文中的 UTF-16 闭开区间；标题没有段落偏移。
  final int start_offset;
  final int end_offset;

  /// 创建该段落时完整正文的摘要，用于拒绝旧阅读窗口的回调。
  final String body_content_hash;

  /// 与当前完整正文及段落摘要匹配的公开版本锚点。
  final ParagraphAnchor? anchor;

  /// 提供给长短篇共用的文本选择与段评组件。
  StoryParagraph get paragraph => StoryParagraph(
    text: text,
    start_offset: start_offset,
    end_offset: end_offset,
    anchor: anchor,
  );

  ReadingContentItem({
    required this.text,
    this.is_title = false,
    required this.chapter_no,
    required this.chapter_index,
    required this.words_before_this_chapter,
    required this.chapter_total_words,
    this.chapter_id = '',
    this.start_offset = -1,
    this.end_offset = -1,
    this.body_content_hash = '',
    this.anchor,
  });

  /// 仅替换元数据，保留阅读进度与原始正文坐标。
  ReadingContentItem with_anchor(ParagraphAnchor? value) => ReadingContentItem(
    text: text,
    is_title: is_title,
    chapter_no: chapter_no,
    chapter_index: chapter_index,
    words_before_this_chapter: words_before_this_chapter,
    chapter_total_words: chapter_total_words,
    chapter_id: chapter_id,
    start_offset: start_offset,
    end_offset: end_offset,
    body_content_hash: body_content_hash,
    anchor: value,
  );
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

  /// 缓存正文实际公开版本，优先使用正文接口返回的版本而非旧目录版本。
  final Map<int, String?> _chapter_content_revisions = {};

  /// 只保存与完整正文摘要及版本匹配的段落元数据。
  final Map<int, ParagraphMetadata> _chapter_paragraph_metadata = {};

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
  void cache_chapter_content(
    int chapter_index,
    String content, {
    String? published_revision_id,
  }) {
    if (_chapter_content_cache[chapter_index] != content ||
        (published_revision_id != null &&
            _chapter_content_revisions[chapter_index] !=
                published_revision_id)) {
      _chapter_paragraph_metadata.remove(chapter_index);
    }
    _chapter_content_cache[chapter_index] = content;
    _chapter_content_revisions[chapter_index] =
        published_revision_id ??
        _chapter_content_revisions[chapter_index] ??
        (chapter_index >= 0 && chapter_index < chapter_list.length
            ? chapter_list[chapter_index].published_revision_id
            : null);
  }

  /// 返回缓存正文对应的实际公开版本。
  String? get_cached_chapter_revision(int chapter_index) =>
      _chapter_content_revisions[chapter_index];

  /// 返回已完成正文校验的元数据；未成功加载时允许交互时重试。
  ParagraphMetadata? get_chapter_paragraph_metadata(int chapter_index) =>
      _chapter_paragraph_metadata[chapter_index];

  /// 验证完整正文身份后更新段落气泡，不按段落序号跨版本绑定。
  bool set_chapter_paragraph_metadata(
    int chapter_index,
    ParagraphMetadata metadata,
  ) {
    final content = _chapter_content_cache[chapter_index];
    final revision = _chapter_content_revisions[chapter_index];
    if (content == null ||
        metadata.content_hash.isEmpty ||
        sha256.convert(utf8.encode(content)).toString() !=
            metadata.content_hash ||
        (revision != null &&
            revision.isNotEmpty &&
            metadata.published_revision_id != revision)) {
      return false;
    }
    _chapter_paragraph_metadata[chapter_index] = metadata;
    final anchors = {
      for (final paragraph in split_story_paragraphs(
        content,
        anchors: metadata.paragraphs,
      ))
        paragraph.start_offset: paragraph.anchor,
    };
    for (int index = 0; index < reading_items.length; index++) {
      final item = reading_items[index];
      if (!item.is_title &&
          item.chapter_index == chapter_index &&
          item.body_content_hash == metadata.content_hash) {
        reading_items[index] = item.with_anchor(anchors[item.start_offset]);
      }
    }
    return true;
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
    _chapter_content_revisions.clear();
    _chapter_paragraph_metadata.clear();
  }

  /// 设置当前阅读的小说详情。
  void set_novel_info(NovelInfo info) {
    novel_info.value = info;
  }

  /// 设置目录列表。
  void set_chapter_list(List<NovelChapterInfo> list) {
    // 目录刷新后同一索引可能已指向另一个章节或修订，不能沿用原缓存。
    for (final index in _chapter_content_cache.keys.toList()) {
      if (index >= list.length ||
          index >= chapter_list.length ||
          chapter_list[index].id != list[index].id ||
          chapter_list[index].published_revision_id !=
              list[index].published_revision_id) {
        _chapter_content_cache.remove(index);
        _chapter_content_revisions.remove(index);
        _chapter_paragraph_metadata.remove(index);
      }
    }
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
    newItems.addAll(
      _build_content_items(
        chapter_no,
        chapter_index,
        words_before,
        chapter_total,
        content,
      ),
    );

    // 插入到列表头部
    reading_items.insertAll(0, newItems);
  }

  /// 将原始文本分割并转换为 ReadingContentItem 列表追加。
  void _append_content_items(
    int chapter_no,
    int chapter_index,
    int words_before,
    int chapter_total,
    String content,
  ) {
    reading_items.addAll(
      _build_content_items(
        chapter_no,
        chapter_index,
        words_before,
        chapter_total,
        content,
      ),
    );
  }

  /// 初始、追加、前插和窗口重建都使用同一拆段规则，保留缩进和原始偏移。
  List<ReadingContentItem> _build_content_items(
    int chapter_no,
    int chapter_index,
    int words_before,
    int chapter_total,
    String content,
  ) {
    final body_hash = sha256.convert(utf8.encode(content)).toString();
    final metadata = _chapter_paragraph_metadata[chapter_index];
    final chapter_id = chapter_index >= 0 && chapter_index < chapter_list.length
        ? chapter_list[chapter_index].id
        : '';
    return split_story_paragraphs(
          content,
          anchors: metadata?.content_hash == body_hash
              ? metadata!.paragraphs
              : const [],
        )
        .map(
          (paragraph) => ReadingContentItem(
            text: paragraph.text,
            chapter_no: chapter_no,
            chapter_index: chapter_index,
            words_before_this_chapter: words_before,
            chapter_total_words: chapter_total,
            chapter_id: chapter_id,
            start_offset: paragraph.start_offset,
            end_offset: paragraph.end_offset,
            body_content_hash: body_hash,
            anchor: paragraph.anchor,
          ),
        )
        .toList(growable: false);
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
    clear_chapter_content_cache();
    last_reading_progress_ratio = 0.0;
    last_scroll_offset = 0.0;
    needs_restore_scroll_position = false;
  }
}
