import 'package:flutter/material.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/common_style/selection_chip/style.dart';

/// 短篇 Tab 页面样式常量。
///
/// 统一管理短篇分类筛选、弹窗、列表卡片等所有视觉参数，
/// 避免在 UI 代码中散落魔法数字。
class ShortStoryTabStyle {
  // ==================== 分类筛选栏 ====================

  /// 分类筛选栏高度（仅内容高度，无额外内边距）。
  static const double filter_bar_height = 34.0;

  /// 分类筛选栏右侧箭头图标尺寸（缩小三分之一）。
  static const double arrow_icon_size = 14.0;

  /// 分类筛选栏右侧箭头距离右边的边距。
  static const double arrow_right_margin = 16.0;

  /// 分类标签水平内边距。
  static const double tag_horizontal_padding = 14.0;

  /// 分类标签垂直内边距。
  static const double tag_vertical_padding = 5.0;

  /// 分类标签之间间距。
  static const double tag_spacing = 8.0;

  /// 分类标签圆角（委托 SelectionChipStyle 统一管理）。
  static double get tag_border_radius => SelectionChipStyle.borderRadius;

  /// 分类标签字号。
  static const double tag_font_size = 12.0;

  /// 分类标签左侧渐变遮罩宽度。
  static const double left_gradient_width = 24.0;

  /// 分类标签右侧渐变遮罩宽度。
  static const double right_gradient_width = 36.0;

  // ==================== 筛选弹窗 ====================

  /// 弹窗顶部拖拽指示条宽度。
  static const double drag_handle_width = 36.0;

  /// 弹窗顶部拖拽指示条高度。
  static const double drag_handle_height = 4.0;

  /// 弹窗标题字号。
  static const double popup_title_font_size = 17.0;

  /// 弹窗标题左侧图标尺寸。
  static const double popup_title_icon_size = 20.0;

  /// 弹窗分类标签圆角（委托 SelectionChipStyle 统一管理）。
  static double get popup_tag_border_radius => SelectionChipStyle.borderRadius;

  /// 弹窗分类标签字号。
  static const double popup_tag_font_size = 13.0;

  /// 弹窗分类标签高度。
  static const double popup_tag_height = 38.0;

  /// 弹窗分类标签水平内边距。
  static const double popup_tag_horizontal_padding = 12.0;

  /// 弹窗分类标签垂直内边距。
  static const double popup_tag_vertical_padding = 10.0;

  /// 弹窗分类标签列间距。
  static const double popup_tag_column_spacing = 10.0;

  /// 弹窗分类标签行间距。
  static const double popup_tag_row_spacing = 10.0;

  /// 弹窗内边距。
  static const EdgeInsets popup_content_padding = EdgeInsets.fromLTRB(16, 0, 16, 0);

  /// 弹窗底部按钮高度。
  static const double popup_button_height = 46.0;

  /// 弹窗底部按钮圆角。
  static const double popup_button_border_radius = 23.0;

  /// 弹窗底部按钮字号。
  static const double popup_button_font_size = 15.0;

  /// 弹窗底部按钮区域顶部间距。
  static const double popup_button_top_spacing = 12.0;

  /// 弹窗底部按钮区域底部安全距离。
  static const double popup_button_bottom_safe = 16.0;

  /// 弹窗底部按钮之间间距。
  static const double popup_button_spacing = 12.0;

  // ==================== 小说列表卡片 ====================

  /// 卡片圆角。
  static const double card_border_radius = LayoutConfig.card_radius;

  /// 卡片水平内边距。
  static const double card_horizontal_padding = 14.0;

  /// 卡片垂直内边距（CJK）。
  static const double card_vertical_padding_cjk = 14.0;

  /// 卡片垂直内边距（非 CJK）。
  static const double card_vertical_padding_alphabetic = 12.0;

  /// 卡片之间间距。
  static const double card_spacing = 10.0;

  /// 卡片列表顶部间距。
  static const double list_top_spacing = 8.0;

  /// 卡片列表底部间距。
  static const double list_bottom_spacing = 20.0;

  /// 卡片列表水平内边距（与全局页面水平内边距一致）。
  static const double list_horizontal_padding =
      LayoutConfig.page_horizontal_padding;

  /// 卡片标题字号（CJK）。
  static const double card_title_font_size_cjk = 17.0;

  /// 卡片标题字号（非 CJK）。
  static const double card_title_font_size_alphabetic = 15.0;

  /// 卡片简介字号（CJK）。
  static const double card_description_font_size_cjk = 15.0;

  /// 卡片简介字号（非 CJK）。
  static const double card_description_font_size_alphabetic = 13.5;

  /// 卡片简介最大行数。
  static const int card_description_max_lines = 3;

  /// 卡片标题行高（CJK）。
  static const double card_title_height_cjk = 1.4;

  /// 卡片标题行高（非 CJK，有升降部需要更大行高）。
  static const double card_title_height_alphabetic = 1.35;

  /// 卡片简介行高（CJK）。
  static const double card_desc_height_cjk = 1.5;

  /// 卡片简介行高（非 CJK）。
  static const double card_desc_height_alphabetic = 1.5;

  /// 卡片标题与简介间距（CJK）。
  static const double card_title_desc_gap_cjk = 6.0;

  /// 卡片标题与简介间距（非 CJK）。
  static const double card_title_desc_gap_alphabetic = 5.0;

  /// 卡片简介与底部标签栏间距（CJK）。
  static const double card_desc_bottom_gap_cjk = 10.0;

  /// 卡片简介与底部标签栏间距（非 CJK，英文字母需要更多呼吸感）。
  static const double card_desc_bottom_gap_alphabetic = 12.0;

  /// 英文标题字间距（略微加宽，提升可读性）。
  static const double card_title_letter_spacing_alphabetic = 0.2;

  /// 英文简介字间距。
  static const double card_desc_letter_spacing_alphabetic = 0.15;

  /// 简介"更多"按钮文字字号（与简介一致，CJK）。
  static double get card_more_font_size_cjk => card_description_font_size_cjk;

  /// 简介"更多"按钮文字字号（与简介一致，非 CJK）。
  static double get card_more_font_size_alphabetic => card_description_font_size_alphabetic;

  /// 简介"更多"按钮渐变遮罩宽度。
  static const double card_more_gradient_width = 100.0;

  /// 简介"更多"按钮文字颜色（日间模式）。
  static const Color card_more_light_text = Color(0xFF5F8BFF);

  /// 简介"更多"按钮文字颜色（夜间模式）。
  static const Color card_more_dark_text = Color(0xFF7AA3FF);

  /// 卡片标签圆角。
  static const double card_tag_border_radius = LayoutConfig.tag_radius;

  /// 卡片标签字号（CJK）。
  static const double card_tag_font_size_cjk = 11.0;

  /// 卡片标签字号（非 CJK）。
  static const double card_tag_font_size_alphabetic = 10.0;

  /// 卡片标签水平内边距（CJK）。
  static const double card_tag_horizontal_padding_cjk = 6.0;

  /// 卡片标签水平内边距（非 CJK）。
  static const double card_tag_horizontal_padding_alphabetic = 8.0;

  /// 卡片标签垂直内边距。
  static const double card_tag_vertical_padding = 2.0;

  /// 卡片标签之间间距。
  static const double card_tag_spacing = 6.0;

  /// 卡片点赞数字号。
  static const double card_like_font_size = 12.0;

  /// 卡片点赞图标尺寸。
  static const double card_like_icon_size = 14.0;

  /// 卡片点赞图标与文字间距。
  static const double card_like_gap = 3.0;

  // ==================== 返回顶部 ====================

  /// 返回顶部按钮显示的滚动阈值。
  static const double back_to_top_visible_offset = 320;

  // ==================== 颜色常量（委托 SelectionChipStyle 统一管理） ====================

  /// 未选中标签背景色（日间模式）。
  static Color get tag_unselected_light_bg => SelectionChipStyle.unselectedLightBg;

  /// 未选中标签文字色（日间模式）。
  static Color get tag_unselected_light_text => SelectionChipStyle.unselectedLightText;

  /// 选中标签背景色（日间模式）。
  static Color get tag_selected_light_bg => SelectionChipStyle.selectedLightBg;

  /// 选中标签文字色（日间模式）。
  static Color get tag_selected_light_text => SelectionChipStyle.selectedLightText;

  /// 未选中标签背景色（夜间模式）。
  static Color get tag_unselected_dark_bg => SelectionChipStyle.unselectedDarkBg;

  /// 未选中标签文字色（夜间模式）。
  static Color get tag_unselected_dark_text => SelectionChipStyle.unselectedDarkText;

  /// 选中标签背景色（夜间模式）。
  static Color get tag_selected_dark_bg => SelectionChipStyle.selectedDarkBg;

  /// 选中标签文字色（夜间模式）。
  static Color get tag_selected_dark_text => SelectionChipStyle.selectedDarkText;

  /// 选中标签背景色（弹窗 - 与筛选栏一致）。
  static Color get popup_selected_light_bg => SelectionChipStyle.selectedLightBg;

  /// 选中标签文字色（弹窗 - 与筛选栏一致）。
  static Color get popup_selected_light_text => SelectionChipStyle.selectedLightText;

  /// 选中标签背景色（夜间模式 - 弹窗）。
  static Color get popup_selected_dark_bg => SelectionChipStyle.selectedDarkBg;

  /// 选中标签文字色（夜间模式 - 弹窗）。
  static Color get popup_selected_dark_text => SelectionChipStyle.selectedDarkText;

  /// 弹窗遮罩层颜色。
  static const Color overlay_color = Color(0x66000000);

  /// 弹窗背景色（日间模式）。
  static const Color popup_light_bg = Colors.white;

  /// 弹窗背景色（夜间模式）。
  static const Color popup_dark_bg = Color(0xFF1E2130);

  /// 弹窗标题左侧图标颜色（日间模式）。
  static const Color popup_title_light_icon = Color(0xFF333333);

  /// 弹窗标题左侧图标颜色（夜间模式）。
  static const Color popup_title_dark_icon = Color(0xFFBBBBC0);

  /// 确定按钮背景色（日间模式）。
  static const Color confirm_light_bg = Color(0xFFFFF3D6);

  /// 确定按钮文字色（日间模式）。
  static const Color confirm_light_text = Color(0xFFD4920A);

  /// 确定按钮背景色（夜间模式）。
  static const Color confirm_dark_bg = Color(0xFF3D3520);

  /// 确定按钮文字色（夜间模式）。
  static const Color confirm_dark_text = Color(0xFFFFD45A);

  /// 清空按钮背景色（日间模式）。
  static const Color clear_light_bg = Color(0xFFF0F1F5);

  /// 清空按钮文字色（日间模式）。
  static const Color clear_light_text = Color(0xFF666666);

  /// 清空按钮背景色（夜间模式）。
  static const Color clear_dark_bg = Color(0xFF252836);

  /// 清空按钮文字色（夜间模式）。
  static const Color clear_dark_text = Color(0xFFBBBBC0);

  /// 列表卡片背景色（日间模式）。
  static const Color card_light_bg = Colors.white;

  /// 列表卡片背景色（夜间模式）。
  static const Color card_dark_bg = Color(0xFF1E2130);

  /// 卡片标题文字色（日间模式）。
  static const Color card_title_light_text = Color(0xFF1A1A1A);

  /// 卡片标题文字色（夜间模式）。
  static const Color card_title_dark_text = Color(0xFFE8E8EA);

  /// 卡片简介文字色（日间模式）。
  static const Color card_desc_light_text = Color(0xFF888888);

  /// 卡片简介文字色（夜间模式）。
  static const Color card_desc_dark_text = Color(0xFF777788);

  /// 卡片标签背景色（日间模式）。
  static const Color card_tag_light_bg = Color(0xFFF5F6FA);

  /// 卡片标签背景色（夜间模式）。
  static const Color card_tag_dark_bg = Color(0xFF282B3A);

  /// 卡片标签文字色（日间模式）。
  static const Color card_tag_light_text = Color(0xFF666666);

  /// 卡片标签文字色（夜间模式）。
  static const Color card_tag_dark_text = Color(0xFF999AAA);

  /// 卡片点赞文字色（日间模式）。
  static const Color card_like_light_text = Color(0xFFAAAAAA);

  /// 卡片点赞文字色（夜间模式）。
  static const Color card_like_dark_text = Color(0xFF777788);

  /// 波纹点击效果颜色（日间模式 - 主题色极浅色系）。
  static const Color ripple_light = Color(0x12F8D02D);

  /// 波纹点击效果颜色（夜间模式 - 主题色极浅色系）。
  static const Color ripple_dark = Color(0x18F8D02D);

  // ==================== 卡片长按 ====================

  /// 卡片长按触发时长（毫秒）。
  static const int long_press_duration_ms = 700;

  /// 卡片长按内容缩放比例（0.95 = 缩小5%）。
  static const double long_press_scale = 0.95;

  /// 卡片长按缩放动画时长（毫秒）。
  static const int long_press_scale_duration_ms = 150;

  // ==================== 点赞动画 ====================

  /// 点赞图标弹跳最大缩放比例。
  static const double like_bounce_scale = 1.3;

  /// 点赞图标弹跳动画时长（毫秒）。
  static const int like_bounce_duration_ms = 300;

  /// 点赞防抖间隔（毫秒），防止连续快速点击重复发请求。
  static const int like_debounce_ms = 500;

  // ==================== 不喜欢理由弹窗 ====================

  /// 不喜欢理由弹窗背景色（日间模式）。
  static const Color dislike_popup_light_bg = Color(0xFFFFFFFF);

  /// 不喜欢理由弹窗背景色（夜间模式）。
  static const Color dislike_popup_dark_bg = Color(0xFF1E2130);

  /// 不喜欢理由弹窗标题字号。
  static const double dislike_popup_title_font_size = 16.0;

  /// 不喜欢理由弹窗选项字号。
  static const double dislike_popup_option_font_size = 14.0;

  /// 不喜欢理由选项圆角（委托 SelectionChipStyle 统一管理）。
  static double get dislike_popup_option_border_radius => SelectionChipStyle.borderRadius;

  /// 不喜欢理由选项高度（委托 SelectionChipStyle 统一管理）。
  static double get dislike_popup_option_height => SelectionChipStyle.chipHeight;

  /// 不喜欢理由选项水平内边距。
  static const double dislike_popup_option_horizontal_padding = 12.0;

  /// 不喜欢理由弹窗选项之间水平间距。
  static const double dislike_popup_option_column_spacing = 12.0;

  /// 不喜欢理由弹窗选项之间垂直间距。
  static const double dislike_popup_option_row_spacing = 12.0;

  /// 不喜欢理由弹窗内边距。
  static const EdgeInsets dislike_popup_content_padding = EdgeInsets.fromLTRB(20, 24, 20, 0);

  /// 不喜欢理由弹窗底部提示字号。
  static const double dislike_popup_hint_font_size = 13.0;

  /// 不喜欢理由弹窗底部提示顶部间距。
  static const double dislike_popup_hint_top_spacing = 24.0;

  /// 不喜欢理由弹窗底部安全间距。
  static const double dislike_popup_bottom_safe = 34.0;

  /// 不喜欢理由弹窗拖拽指示条宽度。
  static const double dislike_popup_drag_handle_width = 36.0;

  /// 不喜欢理由弹窗拖拽指示条高度。
  static const double dislike_popup_drag_handle_height = 4.0;

  /// 不喜欢理由弹窗顶部内边距（含拖拽条）。
  static const double dislike_popup_top_padding = 12.0;

  /// 不喜欢理由选项背景色（日间模式 - 委托 SelectionChipStyle）。
  static Color get dislike_option_light_bg => SelectionChipStyle.unselectedLightBg;

  /// 不喜欢理由选项背景色（夜间模式 - 委托 SelectionChipStyle）。
  static Color get dislike_option_dark_bg => SelectionChipStyle.unselectedDarkBg;

  /// 不喜欢理由选项文字色（日间模式 - 委托 SelectionChipStyle）。
  static Color get dislike_option_light_text => SelectionChipStyle.unselectedLightText;

  /// 不喜欢理由选项文字色（夜间模式 - 委托 SelectionChipStyle）。
  static Color get dislike_option_dark_text => SelectionChipStyle.unselectedDarkText;

  /// 不喜欢理由弹窗底部提示文字色（日间模式）。
  static const Color dislike_hint_light_text = Color(0xFFAAAAAA);

  /// 不喜欢理由弹窗底部提示文字色（夜间模式）。
  static const Color dislike_hint_dark_text = Color(0xFF666666);

  /// 不喜欢理由弹窗遮罩层颜色。
  static const Color dislike_overlay_color = Color(0x66000000);

  /// 不喜欢理由弹窗拖拽指示条颜色（日间模式）。
  static const Color dislike_drag_handle_light_color = Color(0xFFDDDDDD);

  /// 不喜欢理由弹窗拖拽指示条颜色（夜间模式）。
  static const Color dislike_drag_handle_dark_color = Color(0xFF444444);
}
