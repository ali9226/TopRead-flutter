/// 计算短篇正文原生广告需要插入的段落下标。
///
/// [display_ratio] 会被限制在 0～1。正文少于四段时不插入广告，
/// 避免广告卡片挤压过短的阅读内容。
int? resolve_native_ad_insert_index({
  required int paragraph_count,
  required bool has_native_ad,
  required double display_ratio,
}) {
  if (!has_native_ad || paragraph_count < 4) return null;

  final double safe_ratio = display_ratio.clamp(0.0, 1.0);
  return (paragraph_count * safe_ratio).ceil().clamp(1, paragraph_count);
}

/// 判断完整正文是否具备插入原生广告的基础条件。
bool can_insert_native_ad(String content) {
  final int paragraph_count = content
      .split('\n')
      .where((String paragraph) => paragraph.trim().isNotEmpty)
      .length;
  return paragraph_count >= 4;
}
