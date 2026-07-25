import 'package:flutter/material.dart';

/// 书评区块样式常量。
class CommentStyle {
  /// 区块标题字号。
  static const double section_title_font_size = 16;

  /// 书评列表顶部间距。
  static const double comment_list_top_spacing = 14;

  /// 空状态顶部间距。
  static const double empty_top_spacing = 8;

  /// 空状态字号。
  static const double empty_font_size = 13;

  /// 空状态行高。
  static const double empty_line_height = 1.5;

  /// 夜间模式下空状态文字透明度。
  static const double empty_text_dark_alpha = 0.48;

  /// 日间模式下空状态文字颜色。
  static const Color empty_text_color_light = Color(0xFF8D7D68);

  /// 夜间模式下的标题颜色。
  static const Color title_color_dark = Colors.white;

  /// 日间模式下的标题颜色。
  static const Color title_color_light = Color(0xFF1F1A12);
}
