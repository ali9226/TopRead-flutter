import 'package:flutter/material.dart';
import 'package:app/common_style/input_bar/style.dart';

/// 评论区统一视觉常量。
///
/// 布局参考微信视频号评论面板：中性纯色面板、紧凑标题栏、留白式评论列表，
/// 以及固定在面板底部的轻量输入栏。所有键盘相关尺寸只用于独立编辑层，
/// 不参与评论面板本身的布局。
///
/// 底部输入栏样式来自 [InputBarStyle]，与在线客服页面保持一致。
class CommentListStyle {
  // ==================== 面板 ====================

  /// 面板占屏幕高度比例。
  static const double max_height_ratio = 0.78;

  /// 面板顶部圆角。
  static const double sheet_radius = 14;

  /// 面板弹出/收起动画时长（毫秒）。
  static const int sheet_transition_duration_ms = 260;

  /// 面板遮罩层透明度。
  static const double sheet_barrier_alpha = 0.48;

  /// 面板阴影透明度（日间模式）。
  static const double sheet_shadow_alpha_light = 0.14;

  /// 面板阴影透明度（夜间模式）。
  static const double sheet_shadow_alpha_dark = 0.36;

  /// 面板阴影模糊半径。
  static const double sheet_shadow_blur = 28;

  /// 阴影 Y 轴偏移。
  static const double sheet_shadow_offset_y = -8;

  // ==================== 标题栏 ====================

  /// 标题栏水平内边距。
  static const double header_horizontal_padding = 16;

  /// 标题栏右侧内边距。
  static const double header_right_padding = 8;

  /// 标题栏行高。
  static const double header_row_height = 48;

  /// 标题字号（CJK 语系）。
  static const double header_title_font_size_cjk = 16;

  /// 标题字号（字母语系）。
  static const double header_title_font_size_alphabetic = 15;

  /// 标题字号（当前使用 CJK）。
  static const double header_title_font_size = header_title_font_size_cjk;

  /// 关闭按钮点击区域尺寸。
  static const double close_button_size = 36;

  /// 关闭图标尺寸。
  static const double close_icon_size = 15;

  // ==================== 评论列表 ====================

  /// 列表水平内边距。
  static const double list_horizontal_padding = 16;

  /// 列表垂直内边距。
  static const double list_vertical_padding = 6;

  /// 列表滚动缓存范围（像素）。
  static const double list_cache_extent = 360;

  /// 触底加载更多的距离阈值（像素）。
  static const double load_more_trigger_distance = 100;

  /// 定位评论时的滚动动画时长（毫秒）。
  static const int scroll_to_comment_animation_duration_ms = 400;

  /// 回复目标与键盘、列表视口边缘之间的安全距离。
  static const double reply_visibility_margin = 12;

  /// 发送评论后滚动到顶部的动画时长（毫秒）。
  static const int scroll_to_top_animation_duration_ms = 300;

  /// 评论项顶部内边距。
  static const double item_top_padding = 16;

  /// 评论项底部内边距。
  static const double item_bottom_padding = 14;

  /// 头像尺寸。
  static const double avatar_size = 38;

  /// 头像圆角半径。
  static const double avatar_radius = avatar_size / 2;

  /// 头像与内容区间距。
  static const double avatar_content_gap = 12;

  /// 昵称字号（CJK 语系）。
  static const double nickname_font_size_cjk = 14;

  /// 昵称字号（字母语系）。
  static const double nickname_font_size_alphabetic = 13;

  /// 评论内容字号（CJK 语系）。
  static const double content_font_size_cjk = 16;

  /// 评论内容字号（字母语系）。
  static const double content_font_size_alphabetic = 15;

  /// 评论内容行高（CJK 语系）。
  static const double content_line_height_cjk = 1.5;

  /// 评论内容行高（字母语系）。
  static const double content_line_height_alphabetic = 1.55;

  /// 评论内容顶部间距。
  static const double content_top_spacing = 5;

  /// 元数据（时间、点赞等）顶部间距。
  static const double metadata_top_spacing = 8;

  /// 时间文字字号。
  static const double time_font_size = 12;

  /// 操作按钮字号（CJK 语系）。
  static const double action_font_size_cjk = 12.5;

  /// 操作按钮字号（字母语系）。
  static const double action_font_size_alphabetic = 12;

  /// 操作按钮间距。
  static const double action_spacing = 10;

  /// 点赞按钮最小点击区域宽度。
  static const double like_touch_width = 44;

  /// 点赞按钮最小点击区域高度。
  static const double like_touch_height = 32;

  /// 点赞按钮左侧留白，扩大触控区且不挤压图标。
  static const double like_left_padding = 10;

  /// 点赞图标尺寸。
  static const double like_icon_size = 20;

  /// 点赞数字字号。
  static const double like_count_font_size = 12;

  /// 紧凑模式点赞图标尺寸。
  static const double like_compact_icon_size = 18;

  /// 点赞图标与数字间距。
  static const double like_icon_count_spacing = 3;

  /// 点赞状态切换缩放动画时长（毫秒）。
  static const int like_animation_duration_ms = 300;

  /// 点赞动画收缩阶段的最小缩放比例。
  static const double like_scale_shrink = 0.82;

  /// 点赞动画回弹阶段的最大缩放比例。
  static const double like_scale_overshoot = 1.12;

  /// 点赞动画收缩阶段所占权重。
  static const double like_scale_shrink_weight = 28;

  /// 点赞动画回弹阶段所占权重。
  static const double like_scale_overshoot_weight = 38;

  /// 点赞动画复位阶段所占权重。
  static const double like_scale_settle_weight = 34;

  /// 分割线缩进（头像尺寸 + 内容区间距）。
  static const double divider_indent = avatar_size + avatar_content_gap;

  /// 分割线粗细。
  static const double divider_thickness = 0.5;

  // ==================== 加载更多指示器 ====================

  /// 加载更多指示器的外边距。
  static const double load_more_padding_vertical = 16;

  /// 加载更多指示器的尺寸。
  static const double load_more_indicator_size = 20;

  /// 加载更多指示器的线条宽度。
  static const double load_more_indicator_stroke_width = 2;

  // ==================== 空状态 ====================

  /// 空状态区域内边距。
  static const double empty_padding_vertical = 60;

  /// 空状态图标尺寸。
  static const double empty_icon_size = 48;

  /// 空状态图标与文字的间距。
  static const double empty_icon_text_spacing = 16;

  /// 空状态文字字号。
  static const double empty_text_font_size = 14;

  /// 空状态图标透明度。
  static const double empty_icon_opacity = 0.3;

  // ==================== 回复列表 ====================

  /// 回复区域缩进（与分割线缩进一致）。
  static const double reply_indent = divider_indent;

  /// 子回复列表底部留白。
  static const double reply_section_bottom_padding = 16;

  /// 回复项间距。
  static const double reply_item_spacing = 16;

  /// 子回复头像尺寸。
  static const double reply_avatar_size = 26;

  /// 子回复头像与内容区间距。
  static const double reply_avatar_gap = 9;

  /// 子回复昵称字号（CJK 语系）。
  static const double reply_nickname_font_size_cjk = 13.5;

  /// 子回复昵称字号（字母语系）。
  static const double reply_nickname_font_size_alphabetic = 12.5;

  /// 回复文字字号（CJK 语系）。
  static const double reply_text_font_size_cjk = 15;

  /// 回复文字字号（字母语系）。
  static const double reply_text_font_size_alphabetic = 14;

  /// 回复文字行高（CJK 语系）。
  static const double reply_line_height_cjk = 1.5;

  /// 回复文字行高（字母语系）。
  static const double reply_line_height_alphabetic = 1.55;

  /// 子回复正文顶部间距。
  static const double reply_content_top_spacing = 4;

  /// 回复元数据顶部间距。
  static const double reply_metadata_top_spacing = 7;

  /// 评论定位高亮动画时长（毫秒）。
  static const int highlight_animation_duration_ms = 1500;

  // ==================== 底部输入栏 ====================
  //
  // 评论弹窗的输入栏需要与弹窗窄边距、键盘 Overlay 切换节奏匹配，
  // 因此在通用 InputBarStyle 基础上保留评论区专用的胶囊尺寸和色彩。

  /// 输入栏水平内边距。
  static const double input_horizontal_padding = 12;

  /// 输入栏顶部内边距。
  static const double input_top_padding = 10;

  /// 输入栏底部内边距。
  static const double input_bottom_padding = 9;

  /// 输入框高度。
  static const double input_height = 42;

  /// 输入框最大高度（多行展开）。
  static const double input_max_height = InputBarStyle.field_max_height;

  /// 输入框圆角。
  static const double input_radius = input_height / 2;

  /// 输入框内水平内边距。
  static const double input_inner_padding = 14;

  /// 输入框内垂直内边距。
  static const double input_content_vertical_padding =
      InputBarStyle.content_vertical_padding;

  /// 输入框文字行高。
  static const double input_text_line_height = InputBarStyle.text_line_height;

  /// 输入框光标宽度。
  static const double input_cursor_width = InputBarStyle.cursor_width;

  /// 输入框字号（CJK 语系）。
  static const double input_font_size_cjk = InputBarStyle.font_size_cjk;

  /// 输入框字号（字母语系）。
  static const double input_font_size_alphabetic =
      InputBarStyle.font_size_alphabetic;

  /// 输入框字号（当前使用 CJK）。
  static const double input_font_size = input_font_size_cjk;

  /// 输入区域总高度（含内边距）。
  static const double input_area_height = 56;

  /// 输入框与按钮间距。
  static const double input_action_spacing = 10;

  /// 表情按钮点击区域尺寸。
  static const double emoji_button_size = 36;

  /// 表情图标显示尺寸。
  static const double emoji_icon_size = 22;

  /// 表情按钮与输入框右边界的留白。
  static const double emoji_button_right_padding = 3;

  /// 表情按钮内部视觉高亮的圆角。
  static const double emoji_button_radius = 18;

  /// 发送按钮高度。
  static const double send_button_height = input_height;

  /// 发送按钮最小宽度（CJK 语系）。
  static const double send_button_min_width_cjk = 54;

  /// 发送按钮最小宽度（字母语系）。
  static const double send_button_min_width_alphabetic = 68;

  /// 发送按钮圆角。
  static const double send_button_radius = input_height / 2;

  /// 发送按钮水平内边距。
  static const double send_button_horizontal_padding = 14;

  /// 输入状态切换的轻量动画时长。
  static const int input_state_animation_duration_ms = 140;

  /// 发送按钮字号（CJK 语系）。
  static const double send_button_font_size_cjk =
      InputBarStyle.send_font_size_cjk;

  /// 发送按钮字号（字母语系）。
  static const double send_button_font_size_alphabetic =
      InputBarStyle.send_font_size_alphabetic;

  /// 发送按钮禁用状态背景色（日间模式）。
  static const Color send_disabled_light_bg =
      InputBarStyle.send_disabled_bg_light;

  /// 发送按钮禁用状态背景色（夜间模式）。
  static const Color send_disabled_dark_bg =
      InputBarStyle.send_disabled_bg_dark;

  /// 发送按钮禁用状态文字色（日间模式）。
  static const Color send_disabled_light_text =
      InputBarStyle.send_disabled_text_light;

  /// 发送按钮禁用状态文字色（夜间模式）。
  static const Color send_disabled_dark_text =
      InputBarStyle.send_disabled_text_dark;

  // ==================== 骨架屏 ====================

  /// 骨架块圆角。
  static const double skeleton_block_radius = 4;

  /// 骨架昵称宽度。
  static const double skeleton_nickname_width = 76;

  /// 骨架文字高度。
  static const double skeleton_text_height = 13;

  /// 骨架短行宽度。
  static const double skeleton_short_line_width = 190;

  /// 骨架时间宽度。
  static const double skeleton_time_width = 50;

  /// 骨架行间距。
  static const double skeleton_line_spacing = 7;

  /// 骨架动画时长（毫秒）。
  static const int skeleton_animation_duration_ms = 1400;

  /// 骨架最小透明度。
  static const double skeleton_min_opacity = 0.28;

  /// 骨架透明度变化范围。
  static const double skeleton_opacity_range = 0.22;

  /// Shimmer 动画时长（毫秒）。
  static const int shimmer_animation_duration_ms = 1800;

  /// Shimmer 渐变起始位置。
  static const double shimmer_gradient_start = -1.0;

  /// Shimmer 渐变中心位置。
  static const double shimmer_gradient_center = -0.3;

  /// Shimmer 渐变结束位置。
  static const double shimmer_gradient_end = 0.0;

  /// Shimmer 基础透明度。
  static const double shimmer_base_opacity = 0.15;

  /// Shimmer 峰值透明度。
  static const double shimmer_peak_opacity = 0.45;

  /// 骨架屏内容与真实列表之间切换的动画时长（毫秒）。
  static const int skeleton_switch_duration_ms = 300;

  /// 键盘下降超过此逻辑像素值时，立即隐藏真实编辑层。
  static const double keyboard_close_hide_threshold = 0.5;

  /// 操作按钮尺寸（兼容已有引用）。
  static const double action_button_size = 24;

  /// 操作按钮间距（兼容已有引用）。
  static const double action_button_spacing = 16;

  // ==================== 日间颜色 ====================

  /// 面板背景色（日间模式）。
  static const Color sheet_light_bg = Color(0xFFFFFFFF);

  /// 卡片背景色（日间模式）。
  static const Color card_light_bg = Color(0xFFFFFFFF);

  /// 输入栏背景色（日间模式），引用 InputBarStyle。
  static const Color input_bar_light_bg = InputBarStyle.bar_bg_light;

  /// 标题文字色（日间模式）。
  static const Color title_light_color = Color(0xFF191919);

  /// 次要文字色（日间模式）。
  static const Color secondary_light_color = Color(0xFF8C8C8C);

  /// 提示文字色（日间模式）。
  static const Color hint_light_color = Color(0xFFB2B2B2);

  /// 分割线颜色（日间模式）。
  static const Color divider_light_color = Color(0xFFEDEDED);

  /// 输入框背景色（日间模式）。
  static const Color input_light_bg = Color(0xFFF6F6F7);

  /// 输入框边框色（日间模式）。
  static const Color input_border_light_color = Color(0xFFECECED);

  /// 表情按钮激活背景色（日间模式）。
  static const Color emoji_active_light_bg = Color(0x1FF8D02D);

  /// 昵称文字色（日间模式）。
  static const Color nickname_light_color = Color(0xFF9A9A9A);

  /// 评论正文颜色（日间模式）。
  static const Color content_light_color = Color(0xFF3D3D3D);

  /// 时间等弱元数据颜色（日间模式）。
  static const Color metadata_light_color = Color(0xFFB5B5B5);

  /// 回复操作文字颜色（日间模式）。
  static const Color action_light_color = Color(0xFF8F8F8F);

  /// 点赞图标色（日间模式）。
  static const Color like_light_color = Color(0xFF929292);

  /// 评论定位高亮色（日间模式）。
  static const Color highlight_light_color = Color(0x24F8D02D);

  // ==================== 夜间颜色 ====================

  /// 面板背景色（夜间模式）。
  static const Color sheet_dark_bg = Color(0xFF191919);

  /// 卡片背景色（夜间模式）。
  static const Color card_dark_bg = Color(0xFF191919);

  /// 输入栏背景色（夜间模式），引用 InputBarStyle。
  static const Color input_bar_dark_bg = InputBarStyle.bar_bg_dark;

  /// 标题文字色（夜间模式）。
  static const Color title_dark_color = Color(0xFFF2F2F2);

  /// 次要文字色（夜间模式）。
  static const Color secondary_dark_color = Color(0xFF8C8C8C);

  /// 提示文字色（夜间模式）。
  static const Color hint_dark_color = Color(0xFF737373);

  /// 分割线颜色（夜间模式）。
  static const Color divider_dark_color = Color(0xFF2C2C2C);

  /// 输入框背景色（夜间模式）。
  static const Color input_dark_bg = Color(0xFF242424);

  /// 输入框边框色（夜间模式）。
  static const Color input_border_dark_color = Color(0xFF343434);

  /// 表情按钮激活背景色（夜间模式）。
  static const Color emoji_active_dark_bg = Color(0x29F8D02D);

  /// 昵称文字色（夜间模式）。
  static const Color nickname_dark_color = Color(0xFF929292);

  /// 评论正文颜色（夜间模式）。
  static const Color content_dark_color = Color(0xFFE3E3E3);

  /// 时间等弱元数据颜色（夜间模式）。
  static const Color metadata_dark_color = Color(0xFF737373);

  /// 回复操作文字颜色（夜间模式）。
  static const Color action_dark_color = Color(0xFF9A9A9A);

  /// 点赞图标色（夜间模式）。
  static const Color like_dark_color = Color(0xFF8C8C8C);

  /// 评论定位高亮色（夜间模式）。
  static const Color highlight_dark_color = Color(0x24FFFFFF);

  /// 微信式点赞激活红色。
  static const Color like_active_color = Color(0xFFFA5151);

  // ==================== 表情面板 ====================

  /// 表情面板每行数量。
  static const int emoji_columns = InputBarStyle.emoji_columns;

  /// 表情面板背景色（日间模式），与评论弹窗保持一致。
  static const Color emoji_panel_light_bg = sheet_light_bg;

  /// 表情面板背景色（夜间模式），与评论弹窗保持一致。
  static const Color emoji_panel_dark_bg = sheet_dark_bg;

  /// 表情面板顶部分隔线颜色（日间模式）。
  static const Color emoji_panel_divider_light_color = Color(0xFFEFEFF0);

  /// 表情面板顶部分隔线颜色（夜间模式）。
  static const Color emoji_panel_divider_dark_color = Color(0xFF2B2B2B);

  /// 表情面板顶部分隔线粗细。
  static const double emoji_panel_divider_thickness = 0.5;

  /// 表情网格的最大内容宽度，避免桌面浏览器上单个按钮过宽。
  static const double emoji_panel_max_width = 420;

  /// 表情网格水平内边距。
  static const double emoji_panel_horizontal_padding = 14;

  /// 表情网格垂直内边距。
  static const double emoji_panel_vertical_padding = 12;

  /// 表情单元的水平间距。
  static const double emoji_item_horizontal_spacing = 6;

  /// 表情单元的垂直间距。
  static const double emoji_item_vertical_spacing = 8;

  /// 表情单元高度。
  static const double emoji_item_height = 40;

  /// 表情单元触控反馈圆角。
  static const double emoji_item_radius = 12;

  /// 表情单元触控反馈色（日间模式）。
  static const Color emoji_item_feedback_light_color = Color(0x14000000);

  /// 表情单元触控反馈色（夜间模式）。
  static const Color emoji_item_feedback_dark_color = Color(0x1FFFFFFF);

  /// 表情字号。
  static const double emoji_font_size = 25;

  /// 表情面板展开、收起动画时长。
  static const int emoji_panel_animation_duration_ms = 180;

  /// 预置表情列表。
  static const List<String> emoji_list = InputBarStyle.emoji_list;
}
