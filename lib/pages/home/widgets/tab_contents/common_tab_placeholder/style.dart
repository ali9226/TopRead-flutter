import 'package:flutter/material.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/config/color_config.dart';

/// Tab 占位块样式常量。
///
/// 统一管理所有 Tab 临时占位块的尺寸、间距、颜色等样式数值，
/// 方便后续替换为真实内容时统一清理。
class TabPlaceholderStyle {
  TabPlaceholderStyle._();

  // ==================== 列表样式 ====================

  /// 列表水平内边距。
  static const double list_horizontal_padding = LayoutConfig.space_12;

  /// 列表顶部内边距。
  static const double list_top_padding = LayoutConfig.space_10;

  /// 列表底部内边距。
  static const double list_bottom_padding = LayoutConfig.space_20;

  /// 卡片间距。
  static const double card_spacing = LayoutConfig.space_10;

  // ==================== 卡片样式 ====================

  /// 卡片圆角。
  static const double card_radius = LayoutConfig.card_radius;

  /// 卡片水平内边距。
  static const double card_horizontal_padding = LayoutConfig.space_16;

  /// 卡片垂直内边距。
  static const double card_vertical_padding = LayoutConfig.space_14;

  // ==================== 序号样式 ====================

  /// 序号区域宽度。
  static const double number_width = 28;

  /// 序号文字字号。
  static const double number_font_size = 18;

  /// 序号与内容间距。
  static const double number_content_gap = LayoutConfig.space_14;

  // ==================== 骨架条样式 ====================

  /// 标题骨架条高度。
  static const double title_bar_height = 15;

  /// 标题骨架条最小宽度。
  static const double title_bar_min_width = 120;

  /// 标题骨架条最大宽度。
  static const double title_bar_max_width = 260;

  /// 副标题骨架条高度。
  static const double subtitle_bar_height = 12;

  /// 副标题骨架条宽度。
  static const double subtitle_bar_width = 100;

  /// 标题与副标题间距。
  static const double title_subtitle_gap = LayoutConfig.space_10;

  /// 骨架条圆角。
  static const double bar_radius = LayoutConfig.radius_pill;

  // ==================== 颜色（日间） ====================

  /// 卡片背景色（日间）。
  static const Color card_bg_light = ColorConstants.whiteColor;

  /// 卡片背景色（夜间）。
  static const Color card_bg_dark = ColorConstants.pages_home_widgets_tab_contents_recommend_tab_index_tone;

  /// 骨架条颜色（日间）。
  static const Color skeleton_light = ColorConstants.skeleton_light_base;

  /// 骨架条颜色（夜间）。
  static const Color skeleton_dark = ColorConstants.skeleton_dark_base;

  /// 序号文字颜色（日间）。
  static const Color number_light = ColorConstants.native_overlay_caption;

  /// 序号文字颜色（夜间）。
  static const Color number_dark = ColorConstants.number_dark_ff555566;

  /// 分隔线颜色（日间）。
  static const Color divider_light = ColorConstants.components_comment_list_widgets_comment_avatar_tone_fff0f0f0;

  /// 分隔线颜色（夜间）。
  static const Color divider_dark = ColorConstants.divider_dark_ff2a2f3d;
}
