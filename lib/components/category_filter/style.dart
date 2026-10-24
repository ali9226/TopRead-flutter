import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/common_style/selection_chip/style.dart';
import 'package:app/config/color_config.dart';

/// 分类筛选组件样式常量。
///
/// 统一管理横向分类筛选栏和筛选弹窗的所有视觉参数。
class CategoryFilterStyle {
  const CategoryFilterStyle._();

  // ==================== 横向分类筛选栏 ====================

  /// 分类筛选栏高度（CJK）。
  static const double filter_bar_height_cjk = 28.0;

  /// 分类筛选栏高度（非 CJK）。
  static const double filter_bar_height_alphabetic = 30.0;

  /// 右侧箭头图标尺寸。
  static const double arrow_icon_size = 14.0;

  /// 右侧箭头距离右边的边距。
  static const double arrow_right_margin = LayoutConfig.space_16;

  /// 分类标签水平内边距（CJK）。
  static const double tag_horizontal_padding_cjk = LayoutConfig.space_14;

  /// 分类标签水平内边距（非 CJK）。
  static const double tag_horizontal_padding_alphabetic = 16.0;

  /// 分类标签垂直内边距（CJK）。
  static const double tag_vertical_padding_cjk = LayoutConfig.space_5;

  /// 分类标签垂直内边距（非 CJK）。
  static const double tag_vertical_padding_alphabetic = 5.0;

  /// 分类标签之间间距。
  static const double tag_spacing = LayoutConfig.space_8;

  /// 分类标签圆角（委托 SelectionChipStyle 统一管理）。
  static double get tag_border_radius => SelectionChipStyle.borderRadius;

  /// 分类标签字号（CJK）。
  static const double tag_font_size_cjk = 12.0;

  /// 分类标签字号（非 CJK）。
  static const double tag_font_size_alphabetic = 11.0;

  /// 分类标签左侧渐变遮罩宽度。
  static const double left_gradient_width = 24.0;

  /// 分类标签右侧渐变遮罩宽度。
  static const double right_gradient_width = 36.0;

  /// 筛选栏底部内边距。
  static const double filter_bar_bottom_padding = LayoutConfig.space_7;

  // ==================== 筛选弹窗 ====================

  /// 弹窗顶部拖拽指示条宽度。
  static const double drag_handle_width = 36.0;

  /// 弹窗顶部拖拽指示条高度。
  static const double drag_handle_height = 4.0;

  /// 弹窗标题字号（CJK）。
  static const double popup_title_font_size_cjk = 17.0;

  /// 弹窗标题字号（非 CJK）。
  static const double popup_title_font_size_alphabetic = 16.0;

  /// 弹窗标题左侧图标尺寸。
  static const double popup_title_icon_size = LayoutConfig.icon_medium;

  /// 弹窗分类标签圆角（委托 SelectionChipStyle 统一管理）。
  static double get popup_tag_border_radius => SelectionChipStyle.borderRadius;

  /// 弹窗分类标签字号（CJK）。
  static const double popup_tag_font_size_cjk = 13.0;

  /// 弹窗分类标签字号（非 CJK）。
  static const double popup_tag_font_size_alphabetic = 12.0;

  /// 弹窗分类标签水平内边距。
  static const double popup_tag_horizontal_padding = LayoutConfig.space_12;

  /// 弹窗分类标签垂直内边距。
  static const double popup_tag_vertical_padding = LayoutConfig.space_10;

  /// 弹窗分类标签列间距。
  static const double popup_tag_column_spacing = LayoutConfig.space_10;

  /// 弹窗分类标签行间距。
  static const double popup_tag_row_spacing = LayoutConfig.space_10;

  /// 弹窗内边距。
  static const EdgeInsets popup_content_padding = EdgeInsets.fromLTRB(
    LayoutConfig.space_16,
    0,
    LayoutConfig.space_16,
    0,
  );

  /// 弹窗底部按钮高度。
  static const double popup_button_height = 46.0;

  /// 弹窗底部按钮圆角。
  static const double popup_button_border_radius = LayoutConfig.radius_23;

  /// 弹窗底部按钮字号（CJK）。
  static const double popup_button_font_size_cjk = 15.0;

  /// 弹窗底部按钮字号（非 CJK）。
  static const double popup_button_font_size_alphabetic = 14.0;

  /// 弹窗底部按钮区域顶部间距。
  static const double popup_button_top_spacing = LayoutConfig.space_12;

  /// 弹窗底部按钮区域底部安全距离。
  static const double popup_button_bottom_safe = 16.0;

  /// 弹窗底部按钮之间间距。
  static const double popup_button_spacing = LayoutConfig.space_12;

  /// 单个分类标签的目标宽度 - CJK（用于计算列数）。
  static const double target_tag_width_cjk = 90.0;

  /// 单个分类标签的目标宽度 - 非 CJK（用于计算列数）。
  static const double target_tag_width_alphabetic = 100.0;

  // ==================== 颜色常量 ====================

  /// 未选中标签背景色（日间模式）。
  static Color get tag_unselected_light_bg =>
      SelectionChipStyle.unselectedLightBg;

  /// 未选中标签文字色（日间模式）。
  static Color get tag_unselected_light_text =>
      SelectionChipStyle.unselectedLightText;

  /// 选中标签背景色（日间模式）。
  static Color get tag_selected_light_bg => SelectionChipStyle.selectedLightBg;

  /// 选中标签文字色（日间模式）。
  static Color get tag_selected_light_text =>
      SelectionChipStyle.selectedLightText;

  /// 未选中标签背景色（夜间模式）。
  static Color get tag_unselected_dark_bg =>
      SelectionChipStyle.unselectedDarkBg;

  /// 未选中标签文字色（夜间模式）。
  static Color get tag_unselected_dark_text =>
      SelectionChipStyle.unselectedDarkText;

  /// 选中标签背景色（夜间模式）。
  static Color get tag_selected_dark_bg => SelectionChipStyle.selectedDarkBg;

  /// 选中标签文字色（夜间模式）。
  static Color get tag_selected_dark_text =>
      SelectionChipStyle.selectedDarkText;

  /// 选中标签背景色（弹窗 - 与筛选栏一致）。
  static Color get popup_selected_light_bg =>
      SelectionChipStyle.selectedLightBg;

  /// 选中标签文字色（弹窗 - 与筛选栏一致）。
  static Color get popup_selected_light_text =>
      SelectionChipStyle.selectedLightText;

  /// 选中标签背景色（夜间模式 - 弹窗）。
  static Color get popup_selected_dark_bg => SelectionChipStyle.selectedDarkBg;

  /// 选中标签文字色（夜间模式 - 弹窗）。
  static Color get popup_selected_dark_text =>
      SelectionChipStyle.selectedDarkText;

  /// 弹窗遮罩层颜色。
  static const Color overlay_color = ColorConstants.pages_short_story_read_widgets_auto_read_settings_sheet_tone;

  /// 弹窗背景色（日间模式）。
  static const Color popup_light_bg = ColorConstants.whiteColor;

  /// 弹窗背景色（夜间模式）。
  static const Color popup_dark_bg = ColorConstants.night_popup_surface;

  /// 弹窗标题左侧图标颜色（日间模式）。
  static const Color popup_title_light_icon = ColorConstants.components_paragraph_comment_sheet_style_tone_ff333333;

  /// 弹窗标题左侧图标颜色（夜间模式）。
  static const Color popup_title_dark_icon = ColorConstants.components_category_filter_category_filter_bar_tone;

  /// 确定按钮背景色（日间模式）。
  static const Color confirm_light_bg = ColorConstants.warm_accent_soft_bg;

  /// 确定按钮文字色（日间模式）。
  static const Color confirm_light_text = ColorConstants.warm_accent_text;

  /// 确定按钮背景色（夜间模式）。
  static const Color confirm_dark_bg = ColorConstants.warm_accent_deep_bg;

  /// 确定按钮文字色（夜间模式）。
  static const Color confirm_dark_text = ColorConstants.message_type_accent_color_list;

  /// 清空按钮背景色（日间模式）。
  static const Color clear_light_bg = ColorConstants.components_category_filter_index_tone_fff0f1f5;

  /// 清空按钮文字色（日间模式）。
  static const Color clear_light_text = ColorConstants.customer_service_sheet_style_time_color_dark;

  /// 清空按钮背景色（夜间模式）。
  static const Color clear_dark_bg = ColorConstants.components_category_filter_index_tone;

  /// 清空按钮文字色（夜间模式）。
  static const Color clear_dark_text = ColorConstants.components_category_filter_category_filter_bar_tone;
}
