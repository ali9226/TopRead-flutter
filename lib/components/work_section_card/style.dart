import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';

/// 三类作品详情共用的纸面层级；日间保持纯白，以轻阴影区分卡片。
class WorkSectionCardStyle {
  const WorkSectionCardStyle._();

  static const double radius = LayoutConfig.card_radius;
  static const double padding = LayoutConfig.space_16;
  static const double gap = LayoutConfig.space_12;
  static const double title_gap = LayoutConfig.space_12;
  static const double title_size_cjk = 15;
  static const double title_size_alphabetic = 14.5;
  static const double title_height_cjk = 1.4;
  static const double title_height_alphabetic = 1.35;
  static const double accent_width = 4;
  static const double accent_height = 16;
  static const double accent_radius = LayoutConfig.radius_2;
  static const double accent_gap = LayoutConfig.space_8;

  /// 零偏移环境光投影包住四边，避免只在卡片底部形成一条灰带。
  static const double ambient_shadow_blur = 20;
  static const double ambient_shadow_spread = 1;

  /// 低强度向下投影只补充离纸高度，相邻卡片重叠时不会积成黑边。
  static const double elevation_shadow_blur = 14;
  static const double elevation_shadow_offset = 5;
  static const double border_width = 0.5;
  static final FontWeight title_weight = FontConfig.adjustedWeight(FontWeight.w500);

  static Color background(bool dark) =>
      dark ? ColorConstants.nightBackgroundColor : ColorConstants.whiteColor;

  static Color card_background(bool dark) =>
      dark ? ColorConstants.nightHighlightColor : ColorConstants.whiteColor;

  static Color foreground(bool dark) =>
      dark ? ColorConstants.whiteColor : ColorConstants.lightTextColor;

  /// 深色底上的细亮边补足顶部轮廓；日间保留柔和的纸面边缘。
  static Border border(bool dark) => Border.all(
    color: (dark ? ColorConstants.whiteColor : ColorConstants.lightTextColor).withValues(
      alpha: dark ? 0.06 : 0.025,
    ),
    width: border_width,
  );

  static List<BoxShadow> shadows(bool dark) => [
    BoxShadow(
      color: ColorConstants.shadowColor.withValues(alpha: dark ? 0.24 : 0.065),
      blurRadius: ambient_shadow_blur,
      spreadRadius: ambient_shadow_spread,
    ),
    BoxShadow(
      color: ColorConstants.shadowColor.withValues(alpha: dark ? 0.12 : 0.035),
      blurRadius: elevation_shadow_blur,
      offset: const Offset(0, elevation_shadow_offset),
    ),
  ];
}
