import 'package:app/config/color_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';

/// 通用选择标签样式常量。
///
/// 颜色与「短篇分类筛选栏」和「短篇筛选弹窗」完全一致，
/// 保证所有使用 SelectionChip 的页面视觉统一。
///
/// 使用方式：
/// ```dart
/// SelectionChip(
///   label: '小说',
///   selected: true,
///   isDark: false,
///   onTap: () {},
/// )
/// ```
class SelectionChipStyle {
  const SelectionChipStyle._();

  // ==================== 尺寸 ========================

  /// 标签圆角。
  static const double borderRadius = LayoutConfig.radius_8;

  /// 标签水平内边距（兴趣偏好页面用）。
  static const double horizontalPadding = LayoutConfig.space_16;

  /// 标签垂直内边距（兴趣偏好页面用）。
  static const double verticalPadding = LayoutConfig.space_10;

  /// 标签字号。
  static const double fontSize = 13.0;

  /// 标签固定高度（筛选弹窗使用，单行场景）。
  static const double chipHeight = 38.0;

  /// 标签之间水平间距（Wrap spacing）。
  static const double spacing = LayoutConfig.space_10;

  /// 标签之间垂直间距（Wrap runSpacing）。
  static const double runSpacing = LayoutConfig.space_12;

  /// 动画时长。
  static const Duration animationDuration = Duration(milliseconds: 200);

  // ==================== 颜色（日间模式 - 与筛选弹窗一致） ========================

  /// 未选中标签背景色（日间）。
  static const Color unselectedLightBg = ColorConstants.unselected_light_bg_ffeceef3;

  /// 未选中标签文字色（日间）。
  static const Color unselectedLightText = ColorConstants.components_paragraph_comment_sheet_style_tone_ff333333;

  /// 选中标签背景色（日间）。
  static const Color selectedLightBg = ColorConstants.warm_accent_soft_bg;

  /// 选中标签文字色（日间）。
  static const Color selectedLightText = ColorConstants.warm_accent_text;

  /// 选中标签边框色（日间），与主题色一致。
  static const Color selectedLightBorder = ColorConstants.themeColor;

  // ==================== 颜色（夜间模式 - 与筛选栏一致） ========================

  /// 未选中标签背景色（夜间）。
  static const Color unselectedDarkBg = ColorConstants.components_category_filter_index_tone;

  /// 未选中标签文字色（夜间）。
  static const Color unselectedDarkText = ColorConstants.components_category_filter_category_filter_bar_tone;

  /// 选中标签背景色（夜间）。
  static const Color selectedDarkBg = ColorConstants.warm_accent_deep_bg;

  /// 选中标签文字色（夜间）。
  static const Color selectedDarkText = ColorConstants.message_type_accent_color_list;

  /// 选中标签边框色（夜间）。
  static const Color selectedDarkBorder = ColorConstants.pages_change_password_style_tone_fff6d76a;

  // ==================== 颜色方法 ========================

  /// 未选中背景色。
  static Color unselectedBg({required bool isDark}) {
    return isDark ? unselectedDarkBg : unselectedLightBg;
  }

  /// 未选中文字色。
  static Color unselectedText({required bool isDark}) {
    return isDark ? unselectedDarkText : unselectedLightText;
  }

  /// 选中背景色。
  static Color selectedBg({required bool isDark}) {
    return isDark ? selectedDarkBg : selectedLightBg;
  }

  /// 选中文字色。
  static Color selectedText({required bool isDark}) {
    return isDark ? selectedDarkText : selectedLightText;
  }

  /// 选中边框色。
  static Color selectedBorder({required bool isDark}) {
    return isDark ? selectedDarkBorder : selectedLightBorder;
  }
}
