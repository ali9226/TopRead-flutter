import 'package:flutter/material.dart';
import 'package:app/config/layout_config.dart';

/// 榜单区域样式常量。
///
/// 集中管理榜单模块所有的尺寸、间距、圆角等样式数值，
/// 避免硬编码，方便统一调整。
class RankingSectionStyle {
  RankingSectionStyle._();

  // ---- Tab 栏样式 ----

  /// Tab 栏高度。
  static const double tab_bar_height = 36;

  /// Tab 文字字号（CJK 语系）。
  static const double tab_font_size_cjk = 12;

  /// Tab 文字字号（非 CJK 语系）。
  ///
  /// 英文单词更宽，缩小 1px 避免子 Tab 栏拥挤。
  static const double tab_font_size_alphabetic = 11;

  /// Tab 选中状态的缩放比例（CJK 语系）。
  static const double tab_selected_scale_cjk = 1.25;

  /// Tab 选中状态的缩放比例（非 CJK 语系）。
  ///
  /// 英文单词更宽，缩放过大会挤压相邻 Tab。
  static const double tab_selected_scale_alphabetic = 1.12;

  /// Tab 缩放动画时长（毫秒）。
  static const int tab_animation_duration_ms = 200;

  /// Tab 之间间距（CJK 语系）。
  static const double tab_separator_width_cjk = 20;

  /// Tab 之间间距（非 CJK 语系）。
  ///
  /// 英文单词更宽，缩减间距让子 Tab 能在一屏内完整显示。
  static const double tab_separator_width_alphabetic = 14;

  /// Tab 列表左侧内边距。
  static const double tab_left_padding = 14;

  /// Tab 列表右侧内边距（最后一个 tab 标题的右边距）。
  static const double tab_right_padding = 20;

  /// Tab 栏左侧渐变遮罩宽度。
  static const double tab_left_gradient_width = 14;

  /// Tab 栏右侧渐变遮罩宽度。
  static const double tab_right_gradient_width = 30;

  /// "完整榜单"按钮与 Tab 列表的间距。
  static const double full_ranking_gap = 5;

  /// "完整榜单"文字与图标的间距。
  static const double full_ranking_icon_gap = 2;

  /// "完整榜单"图标尺寸。
  static const double full_ranking_icon_size = 14;

  // ---- 内容区域样式 ----

  /// 每列显示的书籍数量。
  static const int rows_per_column = 4;

  /// 列与列之间的间距。
  static const double column_gap = 10;

  /// 榜单每一列的固定内容宽度。
  ///
  /// 宽屏/横屏时不要按屏幕宽度强制一屏两列，
  /// 而是保持固定列宽和固定列间距，让屏幕自然展示更多列。
  static const double column_content_width = 220;

  /// 行与行之间的间距。
  static const double row_gap = 0;

  /// 封面图片高度。
  static const double cover_height = 60;

  /// 封面图片宽度。
  static const double cover_width = 48;

  /// 封面图片圆角半径。
  static const double cover_border_radius = LayoutConfig.tag_radius;

  /// 单个书籍项的高度（封面 + 底部间距）。
  static const double item_height = cover_height + 11;

  /// 内容区域左右内边距。
  static const double content_padding_horizontal = 10;

  /// 内容区域顶部内边距。
  static const double content_padding_top = 5;

  /// 内容区域渐变遮罩宽度。
  static const double content_gradient_mask_width = 8;

  /// 榜单底部间距。
  static const double ranking_bottom_spacing = 0;

  // ---- 书籍项样式 ----

  /// 排名序号宽度。
  static const double rank_number_width = 18;

  /// 排名序号字号。
  static const double rank_number_font_size = 14;

  /// 排名序号顶部偏移。
  static const double rank_number_top_offset = 2;

  /// 书名字号。
  static const double title_font_size = 13;

  /// 书名行高。
  static const double title_line_height = 1.35;

  /// 分类/热度字号。
  static const double category_font_size = 11;

  /// 分隔点尺寸。
  static const double separator_dot_size = 3;

  /// 封面与排名序号间距。
  static const double cover_to_rank_gap = 4;

  /// 排名序号与书籍信息间距。
  static const double rank_to_info_gap = 4;

  /// 分类与分隔点间距。
  static const double category_to_dot_gap = 4;

  /// 分隔点与热度间距。
  static const double dot_to_heat_gap = 4;

  // ---- 颜色 ----

  /// 未选中 Tab 文字颜色（日间模式）。
  static const Color unselected_color_light = Color(0xFF999999);

  /// 书名文字颜色（日间模式）。
  static const Color title_color_light = Color(0xFF222222);

  /// 分类/热度文字颜色（日间模式）。
  static const Color secondary_color_light = Color(0xFF999999);

  /// 前三名排名序号对应的主题色索引映射。
  static const int top_rank_count = 3;

  // ---- 查看更多按钮样式 ----

  /// "查看更多"按钮顶部间距。
  static const double view_more_top_spacing = 2;

  /// "查看更多"按钮底部间距。
  static const double view_more_bottom_spacing = 8;

  /// "查看更多"内容区域固定高度。
  static const double view_more_content_height = 22;

  /// "查看更多"骨架条宽度。
  static const double view_more_skeleton_width = 72;

  /// "查看更多"骨架条高度。
  static const double view_more_skeleton_height = 12;

  /// "查看更多"文字字号（CJK 语系）。
  static const double view_more_font_size_cjk = 13;

  /// "查看更多"文字字号（非 CJK 语系）。
  static const double view_more_font_size_alphabetic = 12;

  /// "查看更多"图标尺寸。
  static const double view_more_icon_size = 12;

  /// "查看更多"文字与图标间距。
  static const double view_more_icon_gap = 2;

  /// "查看更多"下划线高度。
  static const double view_more_underline_height = 1;

  /// "查看更多"下划线与文字间距。
  static const double view_more_underline_gap = 2;
}
