import 'package:app/config/layout_config.dart';

/// 样式配置（类似 CSS）
class Style {
  /// 统计卡片圆角。
  static const double cardRadius = LayoutConfig.section_radius;

  /// 统计卡片高度（CJK 语系）。
  ///
  /// 中文标签"关注"、"粉丝"、"点赞"短小紧凑，96px 高度足够。
  static const double cardHeightCjk = 96;

  /// 统计卡片高度（非 CJK 语系）。
  ///
  /// 英文标签"Follow"、"Fans"、"Likes"更宽，增加高度避免拥挤。
  static const double cardHeightAlphabetic = 100;

  /// 统计卡片标签字号（CJK 语系）。
  static const double cardLabelFontSizeCjk = 12;

  /// 统计卡片标签字号（非 CJK 语系）。
  ///
  /// 英文标签更长，缩小 1px 避免溢出。
  static const double cardLabelFontSizeAlphabetic = 11;
}
