import 'package:flutter/material.dart';
import 'package:app/config/layout_config.dart';

/// 推荐书籍卡片样式常量。
///
/// 统一管理今日推荐瀑布流中书籍卡片的所有视觉参数，
/// 包括卡片尺寸、动画参数、不喜欢弹窗样式等。
class RecommendBookCardStyle {
  // ==================== 卡片基础样式 ====================

  /// 卡片圆角。
  static const double card_radius = LayoutConfig.card_radius;

  /// 卡片背景色（日间模式）。
  static const Color card_light_bg = Colors.white;

  /// 卡片背景色（夜间模式）。
  static const Color card_dark_bg = Color(0xFF171C28);

  // ==================== 长按交互 ====================

  /// 长按触发时长（毫秒）。
  static const int long_press_duration_ms = 700;

  /// 长按文字缩放比例（0.96 = 缩小4%）。
  static const double long_press_text_scale = 0.96;

  /// 长按缩放动画时长（毫秒）。
  static const int scale_animation_duration_ms = 150;

  /// 手指移动取消长按的阈值（像素）。
  static const double move_cancel_threshold = 10.0;

  // ==================== 遮罩层 ====================

  /// 遮罩层颜色。
  static const Color overlay_color = Color(0x66000000);

  /// 遮罩层动画时长（毫秒）。
  static const int overlay_animation_duration_ms = 200;

  // ==================== 不喜欢按钮 ====================

  /// 不喜欢按钮背景色（日间模式）。
  static const Color dislike_button_light_bg = Color(0xFFF5F6FA);

  /// 不喜欢按钮背景色（夜间模式）。
  static const Color dislike_button_dark_bg = Color(0xFF171C28);

  /// 不喜欢按钮文字色（日间模式）。
  static const Color dislike_button_light_text = Color(0xFF222222);

  /// 不喜欢按钮文字色（夜间模式）。
  static const Color dislike_button_dark_text = Color(0xFF999AAA);

  /// 不喜欢按钮高度。
  static const double dislike_button_height = 44.0;

  /// 不喜欢按钮圆角。
  static const double dislike_button_radius = 8.0;

  /// 不喜欢按钮字号。
  static const double dislike_button_font_size = 14.0;

  /// 不喜欢按钮水平内边距。
  static const double dislike_button_horizontal_padding = 12.0;

  /// 不喜欢按钮滑入动画曲线。
  static const Curve dislike_slide_curve = Curves.easeOutCubic;

  /// 不喜欢图标尺寸。
  static const double dislike_icon_size = 16.0;

  /// 不喜欢图标与文字间距。
  static const double dislike_icon_gap = 6.0;

  // ==================== 关闭按钮 ====================

  /// 关闭按钮尺寸。
  static const double close_button_size = 22.0;

  /// 关闭按钮圆角。
  static const double close_button_radius = 11.0;

  /// 关闭图标尺寸（按钮的 50%）。
  static const double close_icon_size = close_button_size * 0.5;

  /// 关闭按钮距离顶部的间距。
  static const double close_button_top = 8.0;

  /// 关闭按钮距离右侧的间距。
  static const double close_button_right = 8.0;

  /// 关闭按钮背景色（日间模式 - 半透明黑色）。
  static const Color close_button_light_bg = Color(0x40000000);

  /// 关闭按钮背景色（夜间模式 - 半透明黑色）。
  static const Color close_button_dark_bg = Color(0x40000000);

  /// 关闭图标颜色（日间模式 - 纯白色）。
  static const Color close_icon_light_color = Colors.white;

  /// 关闭图标颜色（夜间模式）。
  static const Color close_icon_dark_color = Color(0xBFFFFFFF);

  // ==================== 删除动画 ====================

  /// 卡片删除动画时长（毫秒）。
  static const int delete_animation_duration_ms = 320;

  /// 卡片位置重排动画时长（毫秒）。
  static const int reorder_animation_duration_ms = 300;

  /// 卡片淡出动画时长（毫秒）。
  static const int fade_out_animation_duration_ms = 250;

  // ==================== 内容区域 ====================

  /// 内容区域内边距。
  static const EdgeInsets content_padding = EdgeInsets.fromLTRB(10, 10, 10, 12);

  /// 标题顶部间距。
  static const double title_top_spacing = 10;

  /// 标题字号。
  static const double title_font_size = 15;

  /// 标题行高。
  static const double title_height = 1.45;

  /// 标题最大行数。
  static const int title_max_lines = 2;

  /// 简介顶部间距。
  static const double description_top_spacing = 6;

  /// 简介字号。
  static const double description_font_size = 12;

  /// 简介行高。
  static const double description_height = 1.5;

  /// 简介最大行数。
  static const int description_max_lines = 2;

  /// 标签区域顶部间距。
  static const double tag_top_spacing = 8;

  /// 标签之间的横向间距。
  static const double tag_spacing = 6;

  /// 标签之间的纵向间距。
  static const double tag_run_spacing = 6;

  /// 标签内边距。
  static const EdgeInsets tag_padding = EdgeInsets.fromLTRB(8, 4, 8, 4);

  /// 标签圆角。
  static const double tag_radius = 999;

  /// 标签字号。
  static const double tag_font_size = 11;

  /// 标签背景透明度。
  static const double tag_background_opacity = 0.16;

  /// 标签文字透明度。
  static const double tag_text_opacity = 0.96;

  // ==================== 封面角标 ====================

  /// 封面左上角角标字号。
  static const double cover_badge_font_size = 10;

  /// 封面左上角角标内边距。
  static const EdgeInsets cover_badge_padding = EdgeInsets.fromLTRB(6, 4, 6, 4);

  /// 封面左上角角标位置。
  static const EdgeInsets cover_badge_margin = EdgeInsets.fromLTRB(8, 8, 0, 0);

  /// 封面左上角角标圆角。
  static const double cover_badge_radius = 999;

  /// 封面左上角角标背景透明度。
  static const double cover_badge_background_opacity = 0.56;

  // ==================== 封面附加信息 ====================

  /// 封面左下角附加信息字号。
  static const double cover_meta_font_size = 11;

  /// 封面左下角附加信息位置。
  static const EdgeInsets cover_meta_margin = EdgeInsets.fromLTRB(8, 0, 8, 8);

  /// 封面附加信息阴影透明度。
  static const double cover_meta_shadow_opacity = 0.30;

  // ==================== 点击波纹 ====================

  /// 卡片点击波纹透明度。
  static const double ripple_opacity = 0.14;

  /// 卡片点击高亮透明度。
  static const double highlight_opacity = 0.08;

  // ==================== 瀑布流布局 ====================

  /// 左右两列之间的间距。
  static const double column_spacing = 8;

  /// 同一列中卡片之间的纵向间距。
  static const double item_spacing = 10;

  /// 单个卡片允许的最小宽度。
  static const double min_item_width = 150;

  /// 允许展示的最小列数。
  static const int min_column_count = 2;

  /// 允许展示的最大列数。
  static const int max_column_count = 4;

  /// 卡片默认高度（未测量前使用）。
  static const double default_card_height = 220.0;

  /// 封面最小高度限制，避免图片过矮。
  static const double cover_min_height = 120.0;

  /// 封面最大高度限制，避免图片过高。
  static const double cover_max_height = 320.0;

  // ==================== 原生广告 ====================

  /// 原生广告尚未返回原生布局测量结果时使用的临时高度。
  ///
  /// 实际高度由广告素材宽高比和标题、简介、标签的真实内容共同决定；
  /// 宽度始终由瀑布流当前列约束。
  static const double native_ad_fallback_height = 300.0;

  /// 原生广告媒体区域最小高度。
  ///
  /// Google 要求视频 MediaView 的宽、高都不能小于 120dp/pt。
  static const double native_ad_media_min_height = 120.0;

  /// 与普通小说封面一致的媒体区域最大高度。
  static const double native_ad_media_max_height = cover_max_height;

  /// 骨架屏较短封面高度。
  static const double skeleton_cover_short_height = 190.0;

  /// 骨架屏标准封面高度。
  static const double skeleton_cover_standard_height = 210.0;

  /// 骨架屏较高封面高度。
  static const double skeleton_cover_tall_height = 230.0;

  /// 骨架屏动画时长。
  static const Duration skeleton_animation_duration = Duration(
    milliseconds: 1500,
  );

  /// 骨架屏展示行数。
  static const int skeleton_row_count = 3;

  /// 骨架屏每行错开的动画进度。
  static const double skeleton_row_delay = 0.15;

  /// 骨架屏右列相对于左列错开的动画进度。
  static const double skeleton_right_column_delay = 0.08;

  /// 标题骨架圆角。
  static const double skeleton_title_radius = 4;

  /// 标题骨架两行之间的间距。
  static const double skeleton_title_line_spacing = 4;

  /// 标题骨架第二行宽度。
  static const double skeleton_title_second_line_width = 80;

  /// 标题骨架第一行动画延迟。
  static const double skeleton_title_first_line_delay = 0.05;

  /// 标题骨架第二行动画延迟。
  static const double skeleton_title_second_line_delay = 0.08;

  /// 简介骨架圆角。
  static const double skeleton_description_radius = 3;

  /// 简介骨架两行之间的间距。
  static const double skeleton_description_line_spacing = 3;

  /// 简介骨架第二行宽度。
  static const double skeleton_description_second_line_width = 100;

  /// 简介骨架第一行动画延迟。
  static const double skeleton_description_first_line_delay = 0.11;

  /// 简介骨架第二行动画延迟。
  static const double skeleton_description_second_line_delay = 0.14;

  /// 标签骨架宽度。
  static const double skeleton_tag_width = 44;

  /// 标签骨架上下内边距总和。
  static const double skeleton_tag_vertical_padding = 8;

  /// 第一个标签骨架的动画延迟。
  static const double skeleton_tag_initial_delay = 0.17;

  /// 相邻标签骨架之间错开的动画进度。
  static const double skeleton_tag_interval_delay = 0.05;

  /// 日间主题骨架底色。
  static const Color skeleton_light_base_color = Color(0xFFF0F1F5);

  /// 日间主题骨架高亮色。
  static const Color skeleton_light_highlight_color = Color(0xFFF8F8F8);

  /// 夜间主题骨架底色。
  static const Color skeleton_dark_base_color = Color(0xFF252836);

  /// 夜间主题骨架高亮色。
  static const Color skeleton_dark_highlight_color = Color(0xFF2F3346);

  /// 加载更多指示器顶部间距。
  static const double loading_indicator_top_spacing = 20.0;

  /// 加载更多指示器底部间距。
  static const double loading_indicator_bottom_spacing = 30.0;

  /// 加载更多指示器尺寸。
  static const double loading_indicator_size = 18.0;

  /// 加载更多文字字号。
  static const double loading_text_font_size = 12.0;
}
