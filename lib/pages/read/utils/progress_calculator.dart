import 'package:app/models/novel_info.dart';

/// 长篇小说阅读进度计算器。
///
/// 基于章节字数计算全书阅读进度、章节内进度，
/// 以及根据进度百分比定位章节索引。
class ProgressCalculator {
  /// 章节列表。
  final List<NovelChapterInfo> chapter_list;

  /// 全书总字数（缓存值，<=0 时自动重新计算）。
  final int total_word_count;

  ProgressCalculator({
    required this.chapter_list,
    required this.total_word_count,
  });

  /// 根据全书阅读百分比推算所在章节索引。
  ///
  /// 遍历章节字数累加，找到进度百分比落入的章节。
  /// 返回章节索引；章节列表为空时返回 0。
  int find_chapter_index_by_progress(double progress_percent) {
    if (chapter_list.isEmpty) return 0;

    int total_words = total_word_count;
    if (total_words <= 0) {
      for (final ch in chapter_list) {
        total_words += ch.word_count;
      }
    }
    if (total_words <= 0) return 0;

    final double target_words = total_words * progress_percent / 100;
    int cumulative = 0;
    for (int i = 0; i < chapter_list.length; i++) {
      cumulative += chapter_list[i].word_count;
      if (cumulative >= target_words) return i;
    }
    return chapter_list.length - 1;
  }

  /// 根据全书阅读进度换算指定章节内部的阅读百分比。
  ///
  /// [reading_progress_percent] 当前全书阅读百分比。
  /// [chapter_index] 需要换算的章节索引。
  /// 返回 0-100 的章节内进度百分比；章节字数缺失时返回 0。
  double calculate_chapter_progress_percent({
    required double reading_progress_percent,
    required int chapter_index,
  }) {
    if (chapter_index < 0 || chapter_index >= chapter_list.length) {
      return 0;
    }

    int total = _effective_total_word_count;
    final NovelChapterInfo chapter = chapter_list[chapter_index];
    if (total <= 0 || chapter.word_count <= 0) {
      return 0;
    }

    int words_before = _words_before_chapter(chapter_index);
    final double estimated_read =
        total * (reading_progress_percent.clamp(0.0, 100.0) / 100);
    final double read_in_chapter =
        (estimated_read - words_before).clamp(0.0, chapter.word_count.toDouble());

    return ((read_in_chapter / chapter.word_count) * 100).clamp(0.0, 100.0);
  }

  /// 根据章节索引和章节内进度换算全书阅读进度。
  ///
  /// [chapter_index] 当前章节索引。
  /// [chapter_progress_percent] 当前章节内阅读百分比，取值 0 到 100。
  double calculate_total_progress_percent_for_chapter({
    required int chapter_index,
    required double chapter_progress_percent,
  }) {
    if (chapter_index < 0 || chapter_index >= chapter_list.length) {
      return 0;
    }

    int total = _effective_total_word_count;
    if (total <= 0) {
      return 0;
    }

    int words_before = _words_before_chapter(chapter_index);
    final NovelChapterInfo chapter = chapter_list[chapter_index];
    final double chapter_read =
        chapter.word_count * (chapter_progress_percent.clamp(0.0, 100.0) / 100);
    final double read_words = words_before + chapter_read;
    return ((read_words / total) * 100).clamp(0.0, 100.0);
  }

  /// 获取有效总字数（缓存值 <=0 时重新计算）。
  int get _effective_total_word_count {
    if (total_word_count > 0) return total_word_count;
    int total = 0;
    for (final ch in chapter_list) {
      total += ch.word_count;
    }
    return total;
  }

  /// 计算指定章节之前的所有章节字数总和。
  int _words_before_chapter(int chapter_index) {
    int words = 0;
    for (int i = 0; i < chapter_index; i++) {
      words += chapter_list[i].word_count;
    }
    return words;
  }
}
