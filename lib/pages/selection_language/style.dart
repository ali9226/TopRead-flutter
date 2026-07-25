import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';

/// 语种选择页样式配置。
class Style {
  // ── 顶部操作栏 ──
  static const EdgeInsets headerPadding = EdgeInsets.fromLTRB(18, 10, 18, 6);
  static const double headerActionSize = 42;
  static const double headerActionRadius = 14;
  static const double doneButtonWidth = 86;
  static const double doneButtonHeight = 42;
  static const double doneButtonRadius = 14;

  // ── 页面滚动区 ──
  static const EdgeInsets pageHorizontalPadding = EdgeInsets.symmetric(horizontal: 16);
  static const double listTopSpacing = 16;
  static const double listBottomSpacing = 28;

  // ── 语言项卡片 ──
  static const double itemRadius = 16;
  static const double itemHeight = 68;
  static const EdgeInsets itemPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 12);
  static const double itemGap = 10;

  // ── 国旗图标 ──
  static const double flagSize = 32;
  static const double flagWrapSize = 44;
  static const double flagWrapRadius = 14;

  // ── 选中指示器 ──
  static const double checkSize = 22;
  static const double checkIconSize = 14;

  // ── 文字 ──
  static final FontWeight titleWeight = FontConfig.adjustedWeight(FontWeight.w500);
  static final FontWeight subtitleWeight = FontConfig.adjustedWeight(FontWeight.w400);
  static const double titleFontSize = 15;
  static const double subtitleFontSize = 12;
}
