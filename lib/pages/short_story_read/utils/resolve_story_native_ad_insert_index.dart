import 'package:app/pages/short_story_read/style.dart';
import 'package:app/util/native_ad_insert_index.dart';
import 'package:app/util/split_story_paragraphs.dart';

import 'create_story_content_preview.dart';

/// 按广告决策时实际可读的正文确定段落插位，之后解锁全文仍复用该边界。
///
/// [content] 为完整正文，[is_unlocked] 表示是否已经能够阅读全部正文，
/// [is_cjk] 与正文解锁组件使用相同语种计数规则。
int? resolve_story_native_ad_insert_index({
  required String content,
  required bool is_unlocked,
  required bool is_cjk,
}) {
  final String visible_content = is_unlocked
      ? content
      : create_story_content_preview(
          content: content,
          is_cjk: is_cjk,
          preview_ratio: ShortStoryReadStyle.locked_content_preview_ratio,
          fade_tail_count: is_cjk
              ? ShortStoryReadStyle.unlock_fade_tail_count_cjk
              : ShortStoryReadStyle.unlock_fade_tail_count_alphabetic,
        ).preview_content;
  return resolve_native_ad_insert_index(
    paragraph_count: split_story_paragraphs(visible_content).length,
    has_native_ad: true,
    display_ratio: ShortStoryReadStyle.native_ad_display_ratio,
  );
}
