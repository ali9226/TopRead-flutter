import 'package:flutter/material.dart';
import 'package:app/config/layout_config.dart';

/// 短篇小说阅读页面样式常量。
///
/// 统一管理短篇阅读页面的字号、间距、颜色等视觉参数。
///
/// 颜色体系：
/// - 所有颜色均提供日间/夜间两套方案
/// - 命名规则：xxx_light_xxx（日间）、xxx_dark_xxx（夜间）
///
/// 多语种适配：
/// - 正文字号和行高提供 CJK / 非 CJK 两套参数
/// - 使用 LanguageUtil.is_cjk_language() 判断当前语种
class ShortStoryReadStyle {
  // ==================== 页面布局 ====================

  /// 页面水平内边距。
  static const double page_horizontal_padding =
      LayoutConfig.page_horizontal_padding;

  /// 页面顶部内边距（骨架屏内容区域顶部间距）。
  static const double page_top_padding = 20.0;

  /// 页面底部内边距（为底部评论栏留出空间）。
  static const double page_bottom_padding = 80.0;

  // ==================== 顶部导航栏 ====================

  /// 完整导航栏高度（不含状态栏）。
  static const double appbar_height = 44.0;

  /// 迷你标题栏高度（不含状态栏）。
  static const double mini_appbar_height = 28.0;

  /// 导航栏图标大小。
  static const double appbar_icon_size = 24.0;

  /// 导航栏标题字号。
  static const double appbar_title_font_size = 18.0;

  // ==================== 标题区域 ====================

  /// 标题字号。
  static const double title_font_size = 18.0;

  /// 标题行高。
  static const double title_height = 1.4;

  /// 标题底部间距。
  static const double title_bottom_spacing = 12.0;

  // ==================== 标签区域 ====================

  /// 标签字号。
  static const double tag_font_size = 12.0;

  /// 标签水平内边距。
  static const double tag_horizontal_padding = 10.0;

  /// 标签垂直内边距。
  static const double tag_vertical_padding = 4.0;

  /// 标签间距。
  static const double tag_spacing = 8.0;

  /// 标签底部间距。
  static const double tag_bottom_spacing = 20.0;

  // ==================== 正文区域 ====================

  /// 正文字号（CJK 语系：中文、日文、韩文）。
  static const double body_font_size_cjk = 17.0;

  /// 正文字号（非 CJK 语系：英语等拉丁字母）。
  static const double body_font_size_alphabetic = 16.0;

  /// 正文行高（CJK 语系）。
  static const double body_height_cjk = 1.8;

  /// 正文行高（非 CJK 语系，字母有升部降部，需要更大行高）。
  static const double body_height_alphabetic = 1.7;

  /// 段落间距。
  static const double paragraph_spacing = 16.0;

  // ==================== 下一篇预览区域 ====================

  /// CJK 语系的下一篇简介默认可见行数。
  static const int next_preview_visible_line_count_cjk = 4;

  /// 字母语系的下一篇简介默认可见行数。
  static const int next_preview_visible_line_count_alphabetic = 4;

  /// 计算预览最大行数时增加的渐隐缓冲行。
  static const int next_preview_overflow_buffer_line_count = 1;

  // ==================== 目录点赞动画 ====================

  /// 目录点赞图标缩放动画总时长。
  static const Duration catalog_like_animation_duration = Duration(
    milliseconds: 320,
  );

  /// 目录点赞图标按下时的缩小比例。
  static const double catalog_like_scale_shrink = 0.82;

  /// 目录点赞图标回弹时的放大比例。
  static const double catalog_like_scale_overshoot = 1.24;

  /// 目录点赞图标缩小阶段所占的动画权重。
  static const double catalog_like_scale_shrink_weight = 24;

  /// 目录点赞图标放大回弹阶段所占的动画权重。
  static const double catalog_like_scale_overshoot_weight = 42;

  /// 目录点赞图标恢复原尺寸阶段所占的动画权重。
  static const double catalog_like_scale_settle_weight = 34;

  // ==================== 正文解锁区域 ====================

  /// 解锁前可以阅读的正文比例。
  static const double locked_content_preview_ratio = 1 / 2;

  /// 原生高级广告在正文中的展示位置比例（1/3 处）。
  static const double native_ad_display_ratio = 1 / 3;

  /// CJK 语系解锁区域高度。
  static const double unlock_gate_height_cjk = 160.0;

  /// 字母语系解锁区域高度，为更长文案预留空间。
  static const double unlock_gate_height_alphabetic = 160.0;

  /// CJK 语系继续渲染到渐变遮罩下方的字符数。
  static const int unlock_fade_tail_count_cjk = 96;

  /// 字母语系继续渲染到渐变遮罩下方的单词数。
  static const int unlock_fade_tail_count_alphabetic = 48;

  /// CJK 语系渐变向上覆盖正文的高度。
  static const double unlock_gradient_overlap_height_cjk = 250.0;

  /// 字母语系渐变向上覆盖正文的高度。
  static const double unlock_gradient_overlap_height_alphabetic = 290.0;

  /// 解锁卡片的最大宽度。
  static const double unlock_card_max_width = 520.0;

  /// 解锁卡片距屏幕左右的最小距离。
  static const double unlock_card_outer_horizontal_padding = 20.0;

  /// 解锁卡片底部间距。
  static const double unlock_card_bottom_padding = 4.0;

  /// CJK 语系解锁卡片水平内边距。
  static const double unlock_card_horizontal_padding_cjk = 18.0;

  /// 字母语系解锁卡片水平内边距。
  static const double unlock_card_horizontal_padding_alphabetic = 16.0;

  /// CJK 语系解锁卡片垂直内边距。
  static const double unlock_card_vertical_padding_cjk = 18.0;

  /// 字母语系解锁卡片垂直内边距。
  static const double unlock_card_vertical_padding_alphabetic = 20.0;

  /// 解锁卡片圆角。
  static const double unlock_card_radius = 22.0;

  /// 解锁卡片阴影模糊半径。
  static const double unlock_shadow_blur_radius = 30.0;

  /// 解锁卡片阴影 Y 轴偏移。
  static const double unlock_shadow_offset_y = 12.0;

  /// 解锁卡片日间阴影透明度。
  static const double unlock_shadow_alpha_light = 0.08;

  /// 解锁卡片夜间阴影透明度。
  static const double unlock_shadow_alpha_dark = 0.32;

  /// CJK 语系剩余内容文案字号。
  static const double unlock_message_font_size_cjk = 12.0;

  /// 字母语系剩余内容文案字号。
  static const double unlock_message_font_size_alphabetic = 11.0;

  /// 剩余内容提示文字颜色（日间模式）。
  static const Color unlock_hint_light_color = Color(0xFF999999);

  /// 剩余内容提示文字颜色（夜间模式）。
  static const Color unlock_hint_dark_color = Color(0xFF8B8B9E);

  /// CJK 语系剩余内容文案行高。
  static const double unlock_message_height_cjk = 1.45;

  /// 字母语系剩余内容文案行高。
  static const double unlock_message_height_alphabetic = 1.55;

  /// 剩余内容文案在装饰线中间占用的弹性比例。
  static const int unlock_message_flex = 5;

  /// CJK 语系文案与装饰线间距。
  static const double unlock_line_spacing_cjk = 10.0;

  /// 字母语系文案与装饰线间距。
  static const double unlock_line_spacing_alphabetic = 8.0;

  /// 装饰渐变线高度。
  static const double unlock_line_height = 1.0;

  /// CJK 语系解锁按钮顶部间距。
  static const double unlock_button_top_spacing_cjk = 16.0;

  /// 字母语系解锁按钮顶部间距。
  static const double unlock_button_top_spacing_alphabetic = 18.0;

  /// CJK 语系解锁按钮高度。
  static const double unlock_button_height_cjk = 44.0;

  /// 字母语系解锁按钮高度。
  static const double unlock_button_height_alphabetic = 46.0;

  /// 解锁按钮圆角。
  static const double unlock_button_radius = 15.0;

  /// CJK 语系解锁按钮字号。
  static const double unlock_button_font_size_cjk = 14.0;

  /// 字母语系解锁按钮字号。
  static const double unlock_button_font_size_alphabetic = 13.0;

  /// 解锁按钮图标大小。
  static const double unlock_button_icon_size = 20.0;

  /// 解锁按钮图标与文案间距。
  static const double unlock_button_icon_spacing = 7.0;

  /// 广告加载指示器大小。
  static const double unlock_loading_indicator_size = 20.0;

  /// 广告加载指示器线宽。
  static const double unlock_loading_stroke_width = 2.0;

  /// 按钮文案和加载指示器切换时长。
  static const Duration unlock_button_switch_duration = Duration(
    milliseconds: 180,
  );

  /// 折叠遮罩的渐变节点。
  static const List<double> unlock_gradient_stops = <double>[
    0.0,
    0.3,
    0.65,
    1.0,
  ];

  /// 解锁卡片日间背景色。
  static const Color unlock_card_light_color = Color(0xFFFDFDFE);

  /// 解锁卡片夜间背景色。
  static const Color unlock_card_dark_color = Color(0xFF181E27);

  /// 解锁卡片日间边框色。
  static const Color unlock_border_light_color = Color(0xFFE6E9EF);

  /// 解锁卡片夜间边框色。
  static const Color unlock_border_dark_color = Color(0xFF2A3340);

  /// 解锁按钮文字和图标颜色。
  static const Color unlock_button_text_color = Color(0xFF24210E);

  // ==================== 底部评论栏 ====================

  /// 底部评论栏高度（不含安全区域）。
  static const double bottom_bar_height = 60.0;

  /// 评论输入框高度。
  static const double comment_input_height = 36.0;

  /// 评论输入框圆角。
  static const double comment_input_radius = 18.0;

  /// 评论输入框水平内边距。
  static const double comment_input_horizontal_padding = 16.0;

  /// 底部操作图标大小。
  static const double bottom_icon_size = 22.0;

  /// 底部操作文字字号。
  static const double bottom_action_font_size = 11.0;

  /// 底部操作间距。
  static const double bottom_action_spacing = 20.0;

  // ==================== 颜色常量 - 日间模式 ====================

  /// 页面背景色（日间模式）。
  static const Color bg_light_color = Colors.white;

  /// 卡片背景色（日间模式）。
  static const Color card_light_bg = Colors.white;

  /// 标题文字颜色（日间模式）。
  static const Color title_light_color = Color(0xFF1A1A1A);

  /// 正文文字颜色（日间模式）。
  static const Color body_light_color = Color(0xFF333333);

  /// 次要文字颜色（日间模式）。
  static const Color secondary_light_color = Color(0xFF666666);

  /// 导航栏背景色（日间模式）。
  static const Color appbar_light_bg = Colors.white;

  /// 导航栏分割线颜色（日间模式）。
  static const Color appbar_light_divider = Color(0xFFEEEEEE);

  /// 底部栏背景色（日间模式）。
  static const Color bottom_bar_light_bg = Colors.white;

  /// 底部栏分割线颜色（日间模式）。
  static const Color bottom_bar_light_divider = Color(0xFFEEEEEE);

  /// 评论输入框背景色（日间模式）。
  static const Color comment_input_light_bg = Color(0xFFF5F5F5);

  /// 评论输入框文字颜色（日间模式）。
  static const Color comment_input_light_color = Color(0xFF999999);

  /// 标签背景色（日间模式）。
  static const Color tag_light_bg = Color(0xFFF0F7FF);

  /// 标签文字颜色（日间模式）。
  static const Color tag_light_color = Color(0xFF4A90D9);

  /// 装饰元素颜色（日间模式，极低透明度）。
  static const Color decoration_light_color = Color(0x0A000000);

  /// 目录弹窗背景色（日间模式，与首页背景色一致）。
  static const Color catalog_sheet_light_bg = Color(0xFFF6F7FB);

  /// 目录弹窗背景色（夜间模式，与首页背景色一致）。
  static const Color catalog_sheet_dark_bg = Color(0xFF12121C);

  /// 点赞激活颜色。
  static const Color like_active_color = Color(0xFFFF6B6B);

  /// 收藏激活颜色。
  static const Color favorite_active_color = Color(0xFFFFB800);

  // ==================== 颜色常量 - 夜间模式 ====================

  /// 页面背景色（夜间模式）。
  static const Color bg_dark_color = Color(0xFF0D1117);

  /// 卡片背景色（夜间模式）。
  static const Color card_dark_bg = Color(0xFF161B22);

  /// 标题文字颜色（夜间模式）。
  static const Color title_dark_color = Color(0xFFE8E8EA);

  /// 正文文字颜色（夜间模式）。
  static const Color body_dark_color = Color(0xFFCCCCDD);

  /// 次要文字颜色（夜间模式）。
  static const Color secondary_dark_color = Color(0xFF8B8B9E);

  /// 导航栏背景色（夜间模式）。
  static const Color appbar_dark_bg = Color(0xFF161B22);

  /// 导航栏分割线颜色（夜间模式）。
  static const Color appbar_dark_divider = Color(0xFF21262D);

  /// 底部栏背景色（夜间模式）。
  static const Color bottom_bar_dark_bg = Color(0xFF161B22);

  /// 底部栏分割线颜色（夜间模式）。
  static const Color bottom_bar_dark_divider = Color(0xFF21262D);

  /// 评论输入框背景色（夜间模式）。
  static const Color comment_input_dark_bg = Color(0xFF21262D);

  /// 评论输入框文字颜色（夜间模式）。
  static const Color comment_input_dark_color = Color(0xFF8B8B9E);

  /// 标签背景色（夜间模式）。
  static const Color tag_dark_bg = Color(0xFF1C2333);

  /// 标签文字颜色（夜间模式）。
  static const Color tag_dark_color = Color(0xFF6CA0DC);

  /// 装饰元素颜色（夜间模式，极低透明度）。
  static const Color decoration_dark_color = Color(0x0AFFFFFF);

  // ==================== 卡片阴影 ====================

  /// 卡片阴影透明度（日间模式）。
  static const double card_shadow_alpha_light = 0.18;

  /// 卡片阴影透明度（夜间模式）。
  static const double card_shadow_alpha_dark = 0.5;

  /// 卡片阴影模糊半径。
  static const double card_shadow_blur_radius = 16.0;

  /// 卡片阴影 Y 轴偏移。
  static const double card_shadow_offset_y = 6.0;

  // ==================== 加载状态 ====================

  /// 骨架屏动画时长（呼吸灯一个周期）。
  static const Duration skeleton_animation_duration = Duration(
    milliseconds: 1500,
  );

  /// 骨架屏底色（日间模式）。
  static const Color skeleton_light_base = Color(0xFFEEEEEE);

  /// 骨架屏高亮色（日间模式）。
  static const Color skeleton_light_highlight = Color(0xFFF5F5F5);

  /// 骨架屏底色（夜间模式）。
  static const Color skeleton_dark_base = Color(0xFF2A2A2A);

  /// 骨架屏高亮色（夜间模式）。
  static const Color skeleton_dark_highlight = Color(0xFF3A3A3A);

  // ==================== 动画 ====================

  /// 导航栏/底部栏显示/隐藏动画时长。
  static const Duration bar_animation_duration = Duration(milliseconds: 300);

  /// 导航栏/底部栏显示/隐藏动画曲线。
  static const Curve bar_animation_curve = Curves.easeInOut;

  /// 目录远距离粗定位动画时长。
  static const Duration catalog_coarse_position_duration = Duration(
    milliseconds: 560,
  );

  /// 目录估算位置二次校准动画时长。
  static const Duration catalog_refine_position_duration = Duration(
    milliseconds: 280,
  );

  /// 目录当前项精确对齐动画时长。
  static const Duration catalog_precise_position_duration = Duration(
    milliseconds: 320,
  );

  /// 目录定位的最大估算校准次数。
  static const int catalog_position_max_attempts = 4;

  /// 当前目录项完整进入视口时保留的上下安全距离。
  static const double catalog_item_visibility_margin = 12;

  /// 当前目录项精确定位后的视口对齐比例。
  static const double catalog_current_item_alignment = 0.28;

  // ==================== 阅读进度条 ====================

  /// 进度条区域高度（包含上下留白）。
  static const double progress_bar_height = 40.0;

  /// 进度条轨道高度。
  static const double progress_track_height = 8.0;

  /// 进度条轨道圆角（高度一半即可实现完全圆角）。
  static const double progress_track_radius = 4.0;

  /// 进度条滑块（圆圈）直径。
  static const double progress_thumb_size = 18.0;

  /// 进度条滑块阴影模糊半径。
  static const double progress_thumb_shadow_blur = 4.0;

  /// 进度条滑块阴影 Y 轴偏移。
  static const double progress_thumb_shadow_offset_y = 1.0;

  /// 进度百分比弹窗内边距。
  static const double progress_popup_padding = 8.0;

  /// 进度百分比弹窗圆角。
  static const double progress_popup_radius = 4.0;

  /// 进度百分比弹窗箭头大小。
  static const double progress_popup_arrow_size = 6.0;

  /// 上一篇/下一篇文字字号（CJK 语系）。
  static const double nav_text_font_size_cjk = 14.0;

  /// 上一篇/下一篇文字字号（非 CJK 语系）。
  static const double nav_text_font_size_alphabetic = 13.0;

  /// 上一篇/下一篇文字内边距。
  static const double nav_text_padding = 8.0;

  /// 进度条区域水平内边距。
  static const double progress_area_horizontal_padding = 16.0;
}
