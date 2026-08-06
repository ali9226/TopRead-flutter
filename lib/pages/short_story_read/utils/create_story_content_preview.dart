/// 短篇正文折叠预览的计算结果。
class StoryContentPreviewData {
  const StoryContentPreviewData({
    required this.preview_content,
    required this.remaining_count,
  });

  /// 解锁前可以阅读的正文。
  final String preview_content;

  /// 被折叠的字符数或单词数。
  final int remaining_count;
}

/// 按指定比例创建短篇正文的折叠预览。
///
/// CJK 语系按非空白字符计数，字母语系按由空白分隔的单词计数。
/// [preview_ratio] 表示解锁前可见内容占完整正文的比例。
/// [fade_tail_count] 是继续渲染到渐变遮罩下方的内容单位数，
/// 不会从 [StoryContentPreviewData.remaining_count] 中扣除。
StoryContentPreviewData create_story_content_preview({
  required String content,
  required bool is_cjk,
  required double preview_ratio,
  int fade_tail_count = 0,
}) {
  final String normalized_content = content.trim();
  if (normalized_content.isEmpty) {
    return const StoryContentPreviewData(
      preview_content: '',
      remaining_count: 0,
    );
  }

  final double safe_ratio = preview_ratio.clamp(0.0, 1.0);
  if (safe_ratio >= 1.0) {
    return StoryContentPreviewData(
      preview_content: normalized_content,
      remaining_count: 0,
    );
  }

  return is_cjk
      ? _create_cjk_preview(
          normalized_content,
          safe_ratio,
          fade_tail_count.clamp(0, normalized_content.runes.length),
        )
      : _create_alphabetic_preview(
          normalized_content,
          safe_ratio,
          fade_tail_count.clamp(0, normalized_content.length),
        );
}

/// 按非空白 Unicode 字符计算 CJK 正文预览。
StoryContentPreviewData _create_cjk_preview(
  String content,
  double preview_ratio,
  int fade_tail_count,
) {
  final List<int> runes = content.runes.toList(growable: false);
  final int total_count = runes.where(_is_non_whitespace_rune).length;
  if (total_count <= 1) {
    return StoryContentPreviewData(
      preview_content: content,
      remaining_count: 0,
    );
  }

  final int target_visible_count = (total_count * preview_ratio).ceil().clamp(
    1,
    total_count - 1,
  );
  final int rendered_visible_count = (target_visible_count + fade_tail_count)
      .clamp(1, total_count - 1);
  int visible_count = 0;
  int cut_rune_index = 0;
  for (int index = 0; index < runes.length; index++) {
    if (_is_non_whitespace_rune(runes[index])) {
      visible_count++;
    }
    if (visible_count >= rendered_visible_count) {
      cut_rune_index = index + 1;
      break;
    }
  }

  final String preview_content = String.fromCharCodes(
    runes.take(cut_rune_index),
  ).trimRight();

  return StoryContentPreviewData(
    preview_content: preview_content,
    remaining_count: total_count - target_visible_count,
  );
}

/// 按空白分隔的文本块计算字母语系正文预览。
StoryContentPreviewData _create_alphabetic_preview(
  String content,
  double preview_ratio,
  int fade_tail_count,
) {
  final List<RegExpMatch> word_matches = RegExp(
    r'\S+',
  ).allMatches(content).where(_contains_word_character).toList(growable: false);
  final int total_count = word_matches.length;
  if (total_count <= 1) {
    return StoryContentPreviewData(
      preview_content: content,
      remaining_count: 0,
    );
  }

  final int visible_count = (total_count * preview_ratio).ceil().clamp(
    1,
    total_count - 1,
  );
  final int rendered_visible_count = (visible_count + fade_tail_count).clamp(
    1,
    total_count - 1,
  );
  final int cut_code_unit_index = word_matches[rendered_visible_count - 1].end;

  return StoryContentPreviewData(
    preview_content: content.substring(0, cut_code_unit_index).trimRight(),
    remaining_count: total_count - visible_count,
  );
}

/// 判断字符是否需要计入 CJK 正文字数。
bool _is_non_whitespace_rune(int rune) {
  return String.fromCharCode(rune).trim().isNotEmpty;
}

/// 判断非空白文本块是否包含可计数的字母或数字。
bool _contains_word_character(RegExpMatch match) {
  final String token = match.group(0) ?? '';
  for (final int rune in token.runes) {
    final bool is_ascii_number = rune >= 0x30 && rune <= 0x39;
    final bool is_ascii_uppercase = rune >= 0x41 && rune <= 0x5A;
    final bool is_ascii_lowercase = rune >= 0x61 && rune <= 0x7A;
    final bool is_extended_letter =
        (rune >= 0x00C0 && rune <= 0x02AF) ||
        (rune >= 0x0370 && rune <= 0x1FFF);
    if (is_ascii_number ||
        is_ascii_uppercase ||
        is_ascii_lowercase ||
        is_extended_letter) {
      return true;
    }
  }
  return false;
}
