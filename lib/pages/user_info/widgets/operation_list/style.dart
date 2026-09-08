import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/layout_config.dart';

/// 样式配置（类似 CSS）
class Style {
  /// 单个列表项高度
  static const double liHeight = 62;

  /// 分组卡片圆角
  static const double groupRadius = LayoutConfig.section_radius;

  /// 分组内部列表圆角
  static const double innerRadius = LayoutConfig.section_radius;

  /// 分组上下间距
  static const double groupSpacing = 16;

  /// 图标容器尺寸
  static const double iconWrapSize = 38;

  /// 图标容器圆角
  static const double iconWrapRadius = 12;

  /// 标题文字粗细
  static final FontWeight titleFontWeight = FontConfig.adjustedWeight(FontWeight.w500);

  /// 列表项左右内边距
  static const EdgeInsets itemPadding = EdgeInsets.symmetric(horizontal: 16);

  /// 日间模式下列表项左右内边距。
  /// 日间模式分组卡片无外边距，内容边距需与其他页面统一（LayoutConfig.page_horizontal_padding = 12）。
  static const EdgeInsets lightItemPadding = EdgeInsets.symmetric(horizontal: 12);

  /// 夜间模式下列表项左右内边距
  static const EdgeInsets darkItemPadding = itemPadding;

  /// 分组卡片左右边距
  static const EdgeInsets sectionPadding = EdgeInsets.fromLTRB(0, 0, 0, 16);

  /// 日间模式下分组卡片左右外边距
  static const double lightHorizontalInset = 0;

  /// 夜间模式下分组卡片左右外边距。
  static const double darkHorizontalInset = 10;

  /// 分组内容内边距。
  /// 横向改为 0，让内部列表项自己控制内容留白，从而让波纹覆盖到两侧。
  static const EdgeInsets groupInnerPadding = EdgeInsets.fromLTRB(0, 18, 0, 10);

  /// 分组内部装饰圆半径
  static const double innerDecorSize = 88;
}
