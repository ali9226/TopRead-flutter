import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';

/// 兴趣偏好页面样式常量。
///
/// 统一管理页面布局、间距、字号等视觉参数，
/// 子组件通过静态方法读取，支持日间/夜间主题切换。
class InterestPreferenceStyle {
  const InterestPreferenceStyle._();

  // ==================== 页面布局 ========================

  /// 页面水平内边距。
  static const double pageHorizontalPadding = 20.0;

  /// 页面底部安全区内边距。
  static const double pageBottomPadding = 32.0;

  /// 顶部导航栏高度（含安全区）。
  static const double topBarHeight = 56.0;

  // ==================== 页面标题区 ========================

  /// 页面主标题字号。
  static const double titleFontSize = 24.0;

  /// 页面主标题字重。
  static final FontWeight titleFontWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 页面主标题底部间距。
  static const double titleBottomSpacing = 6.0;

  /// 页面副标题字号。
  static const double subtitleFontSize = 13.0;

  /// 页面副标题字重。
  static final FontWeight subtitleFontWeight = FontConfig.adjustedWeight(FontWeight.w400);

  // ==================== 分组区 ========================

  /// 分组标题字号。
  static const double sectionTitleSize = 16.0;

  /// 分组标题字重。
  static final FontWeight sectionTitleWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 分组标题右侧提示字号。
  static const double sectionHintSize = 12.0;

  /// 分组标题底部间距。
  static const double sectionTitleBottomSpacing = 14.0;

  /// 分组之间间距。
  static const double sectionSpacing = 32.0;

  /// 标签圆角。
  static const double chipBorderRadius = 10.0;

  /// 标签水平内边距（CJK 语系）。
  ///
  /// 中文标签短小紧凑，16px 内边距视觉舒适。
  static const double chipHorizontalPaddingCjk = 16.0;

  /// 标签水平内边距（非 CJK 语系）。
  ///
  /// 英文标签更长，缩减内边距避免标签被挤压。
  static const double chipHorizontalPaddingAlphabetic = 12.0;

  /// 标签字号（CJK 语系）。
  static const double chipFontSizeCjk = 14.0;

  /// 标签字号（非 CJK 语系）。
  ///
  /// 英文标签文字更宽，缩小 1px 配合 minFontSize 缩放。
  static const double chipFontSizeAlphabetic = 13.0;

  /// 标签之间水平间距。
  static const double chipSpacing = 10.0;

  /// 标签之间垂直间距。
  static const double chipRunSpacing = 12.0;

  // ==================== 自适应列数 ========================

  /// 小屏设备每行列数。
  static const int smallScreenColumns = 2;

  /// 中屏设备每行列数。
  static const int mediumScreenColumns = 3;

  /// 大屏设备每行列数。
  static const int largeScreenColumns = 4;

  /// 中屏最小可用宽度阈值（屏幕宽度 - 两侧 padding）。
  ///
  /// CJK 和非 CJK 使用相同阈值，列数一致，
  /// 文字长度差异由标签自身的 minFontSize 缩放机制处理。
  static const double mediumScreenWidth = 330.0;

  /// 大屏最小可用宽度阈值。
  static const double largeScreenWidth = 480.0;

  /// 标签文字最小缩放字号。
  static const double chipMinFontSize = 10.0;

  /// 根据可用宽度计算每行列数。
  ///
  /// 列数与语种无关，保持 CJK 和非 CJK 一致的网格布局。
  static int columnsByWidth(double availableWidth) {
    if (availableWidth >= largeScreenWidth) return largeScreenColumns;
    if (availableWidth >= mediumScreenWidth) return mediumScreenColumns;
    return smallScreenColumns;
  }

  /// 根据可用宽度和列数计算每个标签的固定宽度。
  static double chipWidthByColumns(double availableWidth, int columns) {
    if (columns <= 0) columns = 1;
    return (availableWidth - (columns - 1) * chipSpacing) / columns;
  }

  // ==================== 颜色方法 ========================

  /// 页面背景色。
  static Color backgroundColor({required bool isDark}) {
    return isDark ? const Color(0xFF12141F) : const Color(0xFFF5F6FA);
  }

  /// 页面标题文字色。
  static Color titleColor({required bool isDark}) {
    return isDark ? Colors.white : const Color(0xFF1A1A1A);
  }

  /// 页面副标题文字色。
  static Color subtitleColor({required bool isDark}) {
    return isDark
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFF999999);
  }

  /// 分组标题文字色。
  static Color sectionTitleColor({required bool isDark}) {
    return isDark ? Colors.white : const Color(0xFF1A1A1A);
  }

  /// 分组提示文字色。
  static Color sectionHintColor({required bool isDark}) {
    return isDark
        ? Colors.white.withValues(alpha: 0.4)
        : const Color(0xFFBBBBBB);
  }

  /// 顶部导航栏返回按钮颜色。
  static Color topBarIconColor({required bool isDark}) {
    return isDark ? Colors.white : const Color(0xFF1A1A1A);
  }

}
