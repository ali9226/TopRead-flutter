import 'package:flutter/material.dart';
import 'package:app/config/layout_config.dart';

/// 搜索页样式常量。
class Style {
  static const double zero = 0;
  static const double one = 1;
  static const double page_top_padding = 16;
  static const double page_bottom_padding = 24;
  static const double section_spacing = 18;
  static const double card_radius = 22;
  static const double chip_radius = 999;
  static const double result_card_radius = 20;
  static const double search_bar_height = 50;
  static const double search_icon_size = 22;
  static const double search_clear_icon_size = 18;
  static const double search_clear_button_size = 28;
  static const double search_submit_button_height = 36;
  static const double search_submit_button_horizontal_padding = 14;
  /// 搜索按钮文字字号（CJK 语系）。
  static const double search_submit_button_text_size_cjk = 14;

  /// 搜索按钮文字字号（非 CJK 语系）。
  ///
  /// 英文单词更宽，缩小字号避免按钮过长。
  static const double search_submit_button_text_size_alphabetic = 13;
  static const double search_input_font_size = 15;
  static const double search_input_hint_font_size = 14;
  static const int search_clear_fade_duration_ms = 180;
  /// 页面主标题字号（CJK 语系）。
  static const double title_size_cjk = 24;

  /// 页面主标题字号（非 CJK 语系）。
  ///
  /// 英文单词更宽，缩小字号避免标题行过长。
  static const double title_size_alphabetic = 22;

  /// 搜索结果标题字号（CJK 语系）。
  static const double result_title_size_cjk = 16;

  /// 搜索结果标题字号（非 CJK 语系）。
  ///
  /// 英文单词更宽，缩小字号保持卡片内文字不溢出。
  static const double result_title_size_alphabetic = 15;

  /// 热门搜索词字号（CJK 语系）。
  static const double hot_keyword_text_size_cjk = 13;

  /// 热门搜索词字号（非 CJK 语系）。
  ///
  /// 英文单词更宽，缩小字号让 Chip 不至于过宽。
  static const double hot_keyword_text_size_alphabetic = 12;
  static const double result_vertical_gap_small = 6;
  static const double result_vertical_gap_medium = 8;
  static const double section_title_top_gap = 12;
  static const double search_bar_inner_gap = 7;
  static const double search_header_gap = 14;
  /// 热词 Chip 水平间距（CJK 语系）。
  static const double hot_keyword_spacing_cjk = 10;

  /// 热词 Chip 水平间距（非 CJK 语系）。
  ///
  /// 英文 Chip 更宽，缩减间距让整体布局更紧凑。
  static const double hot_keyword_spacing_alphabetic = 8;

  /// 热词 Chip 换行间距（CJK 语系）。
  static const double hot_keyword_run_spacing_cjk = 10;

  /// 热词 Chip 换行间距（非 CJK 语系）。
  static const double hot_keyword_run_spacing_alphabetic = 8;
  static const double result_card_bottom_margin = 12;
  /// 区块标题字号（CJK 语系）。
  static const double section_title_size_cjk = 17;

  /// 区块标题字号（非 CJK 语系）。
  ///
  /// 英文标题更宽，适当缩小字号保持视觉平衡。
  static const double section_title_size_alphabetic = 16;
  static const double body_size = 13;
  static const double body_line_height = 1.5;

  /// 顶部状态栏区域高度由系统决定，额外的顶部标题栏高度统一在此管理。
  static const double top_bar_height = 58;

  /// 顶部渐变遮罩参数（与首页保持一致）。
  static const double header_gradient_start_opacity = 0.90;
  static const double header_gradient_middle_opacity = 0.34;
  static const double header_gradient_height = 96;

  /// 搜索结果封面尺寸。
  static const double result_cover_width = 72;
  static const double result_cover_height = 98;
  static const double result_cover_radius = 12;
  static const double result_cover_gap = 12;
  static const double result_cover_icon_size = 24;

  /// 页面点缀光斑参数（与首页风格保持一致）。
  static const double top_glow_one_top = -34;
  static const double top_glow_one_right = -22;
  static const double top_glow_one_size = 196;

  static const double top_glow_two_top = 170;
  static const double top_glow_two_left = -46;
  static const double top_glow_two_size = 170;

  /// 主题与装饰颜色。
  static const Color light_page_background = Color(0xFFF6F7FB);
  static const Color dark_card_background = Color(0xFF171C28);
  static const Color top_glow_one_dark_color = Color(0xFFFFD45A);
  static const Color top_glow_two_dark_color = Color(0xFF8DB7FF);
  static const Color hot_keyword_light_background = Color(0xFFF2E8D8);
  static const Color cover_placeholder_dark_start = Color(0xFF2A3244);
  static const Color cover_placeholder_dark_end = Color(0xFF1A1F2B);
  static const Color cover_placeholder_light_start = Color(0xFFE5D2B6);
  static const Color cover_placeholder_light_end = Color(0xFFDABF9A);
  static const Color cover_placeholder_light_icon = Color(0xFF7C664A);
  static const double secondary_text_dark_alpha = 0.62;
  static const double top_glow_one_dark_alpha = 0.13;
  static const double top_glow_one_light_alpha = 0.10;
  static const double top_glow_two_dark_alpha = 0.12;
  static const double top_glow_two_light_alpha = 0.06;
  static const double hot_keyword_dark_background_alpha = 0.06;
  static const double cover_placeholder_dark_icon_alpha = 0.78;
  /// 搜索结果简介行高（CJK 语系）。
  static const double result_description_line_height_cjk = 1.5;

  /// 搜索结果简介行高（非 CJK 语系）。
  ///
  /// 英文字母有升部降部，增大行高提升可读性。
  static const double result_description_line_height_alphabetic = 1.6;

  static const EdgeInsets search_bar_padding = EdgeInsets.fromLTRB(
    18,
    0,
    12,
    0,
  );
  static const EdgeInsets result_card_padding = EdgeInsets.fromLTRB(
    12,
    12,
    12,
    12,
  );
  /// 热词 Chip 内边距（CJK 语系）。
  ///
  /// 中文字符方正紧凑，使用较大水平内边距保持视觉饱满。
  static const EdgeInsets chip_padding_cjk = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 9,
  );

  /// 热词 Chip 内边距（非 CJK 语系）。
  ///
  /// 英文单词更宽，缩减水平内边距避免 Chip 过宽。
  static const EdgeInsets chip_padding_alphabetic = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 9,
  );
  static const EdgeInsets page_padding = EdgeInsets.fromLTRB(
    LayoutConfig.page_horizontal_padding,
    page_top_padding,
    LayoutConfig.page_horizontal_padding,
    page_bottom_padding,
  );
}
