import 'package:flutter/material.dart';
import 'package:app/common_style/selection_chip/style.dart';

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
  static const double arrow_right_margin = 16.0;

  /// 分类标签水平内边距（CJK）。
  static const double tag_horizontal_padding_cjk = 14.0;

  /// 分类标签水平内边距（非 CJK）。
  static const double tag_horizontal_padding_alphabetic = 16.0;

  /// 分类标签垂直内边距（CJK）。
  static const double tag_vertical_padding_cjk = 5.0;

  /// 分类标签垂直内边距（非 CJK）。
  static const double tag_vertical_padding_alphabetic = 5.0;

  /// 分类标签之间间距。
  static const double tag_spacing = 8.0;

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
  static const double filter_bar_bottom_padding = 7.0;

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
  static const double popup_title_icon_size = 20.0;

  /// 弹窗分类标签圆角（委托 SelectionChipStyle 统一管理）。
  static double get popup_tag_border_radius => SelectionChipStyle.borderRadius;

  /// 弹窗分类标签字号（CJK）。
  static const double popup_tag_font_size_cjk = 13.0;

  /// 弹窗分类标签字号（非 CJK）。
  static const double popup_tag_font_size_alphabetic = 12.0;

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

  /// 弹窗底部按钮字号（CJK）。
  static const double popup_button_font_size_cjk = 15.0;

  /// 弹窗底部按钮字号（非 CJK）。
  static const double popup_button_font_size_alphabetic = 14.0;

  /// 弹窗底部按钮区域顶部间距。
  static const double popup_button_top_spacing = 12.0;

  /// 弹窗底部按钮区域底部安全距离。
  static const double popup_button_bottom_safe = 16.0;

  /// 弹窗底部按钮之间间距。
  static const double popup_button_spacing = 12.0;

  /// 单个分类标签的目标宽度 - CJK（用于计算列数）。
  static const double target_tag_width_cjk = 90.0;

  /// 单个分类标签的目标宽度 - 非 CJK（用于计算列数）。
  static const double target_tag_width_alphabetic = 100.0;

  // ==================== 颜色常量 ====================

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
}
