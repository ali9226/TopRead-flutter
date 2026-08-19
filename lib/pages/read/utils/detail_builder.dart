import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/models/novel_info.dart';
import 'package:app/stores/novel_reading_store.dart';
import 'package:app/pages/read/utils/read_models.dart';

/// 长篇阅读页详情构建器。
///
/// 将 [NovelInfo] 和 [NovelReadingStore] 中的数据
/// 转换为页面展示所需的 [ReadDetail] 模型。
class DetailBuilder {
  DetailBuilder._();

  /// 从 Store 数据构建详情。
  ///
  /// [store] 阅读状态仓库。
  /// [story_id] 小说 ID（路由传入）。
  /// [story_title] 小说标题（路由传入，兜底用）。
  static ReadDetail build({
    required NovelReadingStore store,
    required int story_id,
    required String story_title,
  }) {
    final NovelInfo? info = store.novel_info.value;

    if (info == null) {
      return _build_placeholder(
        story_id: story_id,
        story_title: story_title,
      );
    }

    String word_count_subtitle = '';
    if (info.publish_status == 1) {
      word_count_subtitle = easy.tr('read.status_serializing');
    } else if (info.publish_status == 2) {
      word_count_subtitle = easy.tr('read.status_completed');
    } else if (info.publish_status == 3) {
      word_count_subtitle = easy.tr('read.status_removed');
    }

    return ReadDetail(
      story_id: int.tryParse(info.id) ?? story_id,
      title: info.language_info.title,
      cover_url: info.language_info.cover_url,
      author_id: int.tryParse(info.author_id) ?? 0,
      author_avatar_url: info.author_avatar,
      author_name: info.author_name,
      focus_on: info.focus_on,
      score_major_text: info.score.toStringAsFixed(1),
      score_minor_text: easy.tr('read.score_unit'),
      review_count_text: easy.tr(
        'read.review_count',
        args: [info.comment_count],
      ),
      reading_major_text: info.read_count,
      reading_minor_text: easy.tr('read.reading_unit'),
      reading_subtitle_text: easy.tr('read.reading_status'),
      word_count_major_text: (info.language_info.word_count / 10000)
          .toStringAsFixed(1),
      word_count_minor_text: easy.tr('read.word_count_unit'),
      word_count_subtitle_text: word_count_subtitle,
      tag_list: info.category_list,
      intro_text: info.language_info.introduction,
      chapter_title:
          info.chapter_info?.title ??
          (store.chapter_list.isNotEmpty
              ? store.chapter_list.first.title
              : ''),
      comment_list: info.comment_list
          .map(
            (c) => ReadComment(
              avatar_url: c.avatar_url,
              user_name: c.name,
              content: c.comment_content,
              star_count: c.score,
              user_id: int.tryParse(c.user_id) ?? 0,
            ),
          )
          .toList(),
    );
  }

  /// 构建占位详情（Store 为空时使用）。
  static ReadDetail _build_placeholder({
    required int story_id,
    required String story_title,
  }) {
    final String resolved_title = story_title.trim().isEmpty
        ? '未命名小说 $story_id'
        : story_title.trim();

    return ReadDetail(
      story_id: story_id,
      title: resolved_title,
      cover_url: '',
      author_id: 0,
      author_avatar_url: '',
      author_name: '',
      focus_on: false,
      score_major_text: '0.0',
      score_minor_text: easy.tr('read.score_unit'),
      review_count_text: easy.tr('read.review_count', args: ['0']),
      reading_major_text: '0',
      reading_minor_text: easy.tr('read.reading_unit'),
      reading_subtitle_text: easy.tr('read.reading_status'),
      word_count_major_text: '0',
      word_count_minor_text: easy.tr('read.word_count_unit'),
      word_count_subtitle_text: easy.tr('image_text.loading'),
      tag_list: const <String>[],
      intro_text: easy.tr('image_text.loading'),
      chapter_title: '',
      comment_list: const <ReadComment>[],
    );
  }
}
