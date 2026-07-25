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
  static const double borderRadius = 8.0;

  /// 标签水平内边距（兴趣偏好页面用）。
  static const double horizontalPadding = 16.0;

  /// 标签垂直内边距（兴趣偏好页面用）。
  static const double verticalPadding = 10.0;

  /// 标签字号。
  static const double fontSize = 13.0;

  /// 标签固定高度（兴趣偏好页面和筛选弹窗统一使用）。
  static const double chipHeight = 38.0;

  /// 标签之间水平间距（Wrap spacing）。
  static const double spacing = 10.0;

  /// 标签之间垂直间距（Wrap runSpacing）。
  static const double runSpacing = 12.0;

  /// 动画时长。
  static const Duration animationDuration = Duration(milliseconds: 200);

  // ==================== 颜色（日间模式 - 与筛选弹窗一致） ========================

  /// 未选中标签背景色（日间）。
  static const Color unselectedLightBg = Color(0xFFECEEF3);

  /// 未选中标签文字色（日间）。
  static const Color unselectedLightText = Color(0xFF333333);

  /// 选中标签背景色（日间）。
  static const Color selectedLightBg = Color(0xFFFFF3D6);

  /// 选中标签文字色（日间）。
  static const Color selectedLightText = Color(0xFFD4920A);

  /// 选中标签边框色（日间），与主题色一致。
  static const Color selectedLightBorder = Color(0xFFF8D02D);

  // ==================== 颜色（夜间模式 - 与筛选栏一致） ========================

  /// 未选中标签背景色（夜间）。
  static const Color unselectedDarkBg = Color(0xFF252836);

  /// 未选中标签文字色（夜间）。
  static const Color unselectedDarkText = Color(0xFFBBBBC0);

  /// 选中标签背景色（夜间）。
  static const Color selectedDarkBg = Color(0xFF3D3520);

  /// 选中标签文字色（夜间）。
  static const Color selectedDarkText = Color(0xFFFFD45A);

  /// 选中标签边框色（夜间）。
  static const Color selectedDarkBorder = Color(0xFFF6D76A);

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
