import 'package:flutter/material.dart';
import 'package:app/config/layout_config.dart';

/// 书架页样式常量。
class Style {
  /// 页面横向内边距。
  static const double page_horizontal_padding =
      LayoutConfig.page_horizontal_padding;

  /// 页面顶部额外留白。
  static const double page_top_spacing = 16;

  /// 页面标题字号。
  static const double title_font_size = 24;

  /// 内容卡片圆角。
  static const double card_radius = 24;

  /// 内容卡片内边距。
  static const EdgeInsets card_padding = EdgeInsets.fromLTRB(18, 20, 18, 20);

  /// 标题与副标题间距。
  static const double text_spacing = 8;

  /// 未登录占位顶部间距。
  static const double no_login_top_spacing = 36;

  /// 已登录状态顶部间距。
  static const double logged_in_top_spacing = 0;

  /// TabBar 高度。
  static const double tab_bar_height = 44;

  /// Tab 左右内边距。
  static const EdgeInsets tab_label_padding = EdgeInsets.only(right: 24);

  /// Tab 内容顶部间距。
  static const double tab_view_top_spacing = 4;

  /// Tab 内容底部间距。
  static const double tab_view_bottom_spacing = 0;

  /// Tab 选中字号。
  static const double tab_selected_font_size = 20;

  /// Tab 常规字号。
  static const double tab_label_font_size = 15;

  /// Tab 文案向上偏移量。
  static const double tab_label_translate_y = -4;

  /// Tab 指示条高度。
  static const double tab_indicator_height = 4;

  /// Tab 指示条底部偏移。
  static const double tab_indicator_bottom_offset = 6;

  /// 内容卡片标题字号。
  static const double content_title_font_size = 18;

  /// 内容卡片描述字号。
  static const double content_desc_font_size = 14;

  /// 内容卡片描述行高。
  static const double content_desc_height = 1.6;

  /// 内容卡片之间的纵向间距。
  static const double content_card_spacing = 12;

  /// 内容卡片补充信息顶部间距。
  static const double content_meta_top_spacing = 10;

  /// 内容卡片补充信息字号。
  static const double content_meta_font_size = 12;

  /// 筛选栏与网格之间的间距。
  static const double filter_bottom_spacing = 18;

  /// 筛选项圆角。
  static const double filter_radius = 14;

  /// 筛选项横向内边距。
  static const double filter_horizontal_padding = 16;

  /// 筛选项纵向内边距。
  static const double filter_vertical_padding = 8;

  /// 筛选项字号。
  static const double filter_font_size = 14;

  /// 筛选项未选中字号。
  static const double filter_unselected_font_size = 13;

  /// 筛选项未选中背景色（日间）。
  static const Color filter_idle_background_light_color = Color(0xFFE8EDF7);

  /// 筛选项未选中背景色（夜间）。
  static const Color filter_idle_background_dark_color = Color(0xFF263247);

  /// 网格横向间距。
  static const double grid_cross_spacing = 14;

  /// 网格纵向间距。
  static const double grid_main_spacing = 12;

  /// 单个书籍卡片圆角。
  static const double book_card_radius = 18;

  /// 封面圆角。
  static const double cover_radius = 16;

  /// 封面宽高比。
  static const double cover_aspect_ratio = 0.72;

  /// 书签圆角。
  static const double tag_radius = 10;

  /// 书签横向内边距。
  static const double tag_horizontal_padding = 8;

  /// 书签纵向内边距。
  static const double tag_vertical_padding = 4;

  /// 书签字号。
  static const double tag_font_size = 10;

  /// 书签距右上角的边距。
  static const double tag_offset = 6;

  /// 标题顶部间距。
  static const double book_title_top_spacing = 10;

  /// 标题字号。
  static const double book_title_font_size = 14;

  /// 标题行高。
  static const double book_title_height = 1.35;

  /// 标题区域最小高度。
  static const double book_title_min_height = 38;

  /// 标题单行时最大内容高度（3 行内容 + 间距 + 余量）。
  static const double book_max_meta_height =
      (book_meta_font_size * book_title_height) * 3 + 20;

  /// 标题单行高度。
  static const double book_title_line_height =
      book_title_font_size * book_title_height;

  /// 进度区域顶部间距。
  static const double book_meta_top_spacing = 8;

  /// 进度字号。
  static const double book_meta_font_size = 12;

  /// 详情三点的点直径。
  static const double book_meta_dot_size = 2.4;

  /// 详情三点之间的纵向间距。
  static const double book_meta_dot_spacing = 1.8;

  /// 详情三点和进度的间距。
  static const double book_meta_icon_spacing = 6;

  /// 删除弹窗圆角。
  static const double dialog_radius = 20;

  /// 删除弹窗标题字号。
  static const double dialog_title_font_size = 17;

  /// 删除弹窗内容字号。
  static const double dialog_content_font_size = 14;

  /// 弹窗按钮字号。
  static const double dialog_action_font_size = 15;

  /// 弹窗内容顶部间距。
  static const double dialog_content_top_spacing = 10;

  /// 书籍内容默认列数。
  static const int compact_grid_count = 3;

  /// 首屏初始加载条数。
  static const int initial_page_size = 6;

  /// 单次分页加载条数。
  static const int page_size = 6;

  /// 模拟请求延迟时长。
  static const Duration mock_request_duration = Duration(seconds: 1);

  /// 骨架筛选项宽度。
  static const double filter_skeleton_width = 72;

  /// 骨架筛选项高度。
  static const double filter_skeleton_height = 34;

  /// 骨架进度条高度。
  static const double book_meta_skeleton_height = 12;

  /// 骨架标题行高度。
  static const double book_title_skeleton_height = 13;

  /// 骨架标题行之间的间距。
  static const double book_title_skeleton_spacing = 8;

  /// 骨架第二行标题宽度。
  static const double book_title_skeleton_short_width = 72;

  /// 骨架进度条宽度。
  static const double book_meta_skeleton_width = 88;

  /// 骨架文本块圆角。
  static const double book_text_skeleton_radius = 10;

  /// 距离底部多少像素时触发自动加载更多。
  static const double load_more_auto_trigger_distance = 180;

  /// 没有更多数据时，推荐瀑布流和提示文案之间的顶部间距。
  static const double no_more_recommend_top_spacing = 20;

  /// 返回顶部按钮显示的滚动阈值。
  static const double back_to_top_visible_offset = 320;

  /// 宽屏时的 4 列断点。
  static const double wide_grid_breakpoint = 520;

  /// 更宽屏时的 5 列断点。
  static const double extra_wide_grid_breakpoint = 760;

  /// 超宽屏时的 6 列断点。
  static const double ultra_wide_grid_breakpoint = 1040;
}
