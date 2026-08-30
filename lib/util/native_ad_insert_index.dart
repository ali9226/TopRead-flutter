/// 计算正文原生广告需要插入的段落下标。
///
/// [display_ratio] 会被限制在 0～1。正文少于 [minimum_paragraph_count]
/// 段时不插入广告，避免广告卡片挤压过短的阅读内容。
int? resolve_native_ad_insert_index({
  required int paragraph_count,
  required bool has_native_ad,
  required double display_ratio,
  int minimum_paragraph_count = 4,
}) {
  if (!has_native_ad || paragraph_count < minimum_paragraph_count) {
    return null;
  }

  final double safe_ratio = display_ratio.clamp(0.0, 1.0);
  return (paragraph_count * safe_ratio).ceil().clamp(1, paragraph_count);
}

/// 根据每个完整段落的内容长度计算原生广告插入位置。
///
/// 返回值表示广告应放在多少个完整段落之后。累计正文长度首次到达
/// [display_ratio] 时，保留当前完整段落，并将广告放在它的下方。
int? resolve_native_ad_insert_index_by_paragraph_lengths({
  required List<int> paragraph_lengths,
  required bool has_native_ad,
  required double display_ratio,
  int minimum_paragraph_count = 4,
}) {
  if (!has_native_ad || paragraph_lengths.length < minimum_paragraph_count) {
    return null;
  }

  final List<int> safe_lengths = paragraph_lengths
      .map((int length) => length > 0 ? length : 0)
      .toList(growable: false);
  final int total_length = safe_lengths.fold<int>(
    0,
    (int total, int length) => total + length,
  );
  if (total_length <= 0) {
    return resolve_native_ad_insert_index(
      paragraph_count: paragraph_lengths.length,
      has_native_ad: true,
      display_ratio: display_ratio,
      minimum_paragraph_count: minimum_paragraph_count,
    );
  }

  final double safe_ratio = display_ratio.clamp(0.0, 1.0);
  final double target_length = total_length * safe_ratio;
  int rendered_length = 0;
  for (int index = 0; index < safe_lengths.length; index++) {
    rendered_length += safe_lengths[index];
    if (rendered_length >= target_length) {
      return index + 1;
    }
  }
  return safe_lengths.length;
}

/// 判断完整正文是否具备插入原生广告的基础条件。
bool can_insert_native_ad(String content, {int minimum_paragraph_count = 4}) {
  final int paragraph_count = content
      .split('\n')
      .where((String paragraph) => paragraph.trim().isNotEmpty)
      .length;
  return paragraph_count >= minimum_paragraph_count;
}
