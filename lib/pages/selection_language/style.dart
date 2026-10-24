import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';

/// 语种选择页样式配置。
class Style {
  // ── 顶部操作栏 ──
  static const EdgeInsets headerPadding = EdgeInsets.fromLTRB(
    LayoutConfig.space_18,
    LayoutConfig.space_10,
    LayoutConfig.space_18,
    LayoutConfig.space_6,
  );
  static const double headerActionSize = 42;
  static const double headerActionRadius = LayoutConfig.radius_14;
  static const double doneButtonWidth = 86;
  static const double doneButtonHeight = 42;
  static const double doneButtonRadius = LayoutConfig.radius_14;

  // ── 页面滚动区 ──
  static const EdgeInsets pageHorizontalPadding = EdgeInsets.symmetric(
    horizontal: LayoutConfig.space_16,
  );
  static const double listTopSpacing = LayoutConfig.space_16;
  static const double listBottomSpacing = LayoutConfig.space_28;

  // ── 语言项卡片 ──
  static const double itemRadius = LayoutConfig.radius_16;
  static const double itemHeight = 68;
  static const EdgeInsets itemPadding = EdgeInsets.symmetric(
    horizontal: LayoutConfig.space_14,
    vertical: LayoutConfig.space_12,
  );
  static const double itemGap = LayoutConfig.space_10;

  // ── 国旗图标 ──
  static const double flagSize = 32;
  static const double flagWrapSize = 44;
  static const double flagWrapRadius = LayoutConfig.radius_14;

  // ── 选中指示器 ──
  static const double checkSize = 22;
  static const double checkIconSize = 14;

  // ── 文字 ──
  static final FontWeight titleWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static final FontWeight subtitleWeight = FontConfig.adjustedWeight(FontWeight.w400);
  static const double titleFontSize = 15;
  static const double subtitleFontSize = 12;
}
