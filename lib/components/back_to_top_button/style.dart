import 'package:app/config/color_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';

/// 回顶按钮的独有材质；触控尺寸、图标与圆角沿用公共尺寸配置。
class BackToTopButtonStyle {
  const BackToTopButtonStyle._();

  /// 圆形按钮的可点击直径。
  static const double size = LayoutConfig.touch_target_size;
  static const double icon_size = LayoutConfig.icon_compact;
  static const BorderRadius radius = BorderRadius.all(
    Radius.circular(size / 2),
  );
  static const double border_width = 1.1;
  static const double theme_shadow_blur = LayoutConfig.space_12;
  static const double theme_shadow_offset = LayoutConfig.space_6;
  static const double ambient_shadow_blur = LayoutConfig.space_8;
  static const double ambient_shadow_offset = LayoutConfig.space_4;
  static const Alignment highlight_center = Alignment(0, -0.92);
  static const double highlight_radius = 1.08;
  static const List<double> highlight_stops = [0, 0.46, 1];

  static Color fill(bool is_dark) =>
      ColorConstants.themeColor.withValues(alpha: is_dark ? 0.88 : 1);
  static Color ink(bool is_dark) =>
      ColorConstants.lightTextColor.withValues(alpha: is_dark ? 0.92 : 0.88);
  static Color border(bool is_dark) =>
      ColorConstants.whiteColor.withValues(alpha: is_dark ? 0.26 : 0.42);
  static Color get splash => ColorConstants.whiteColor.withValues(alpha: 0.24);
  static Color get pressed => ColorConstants.whiteColor.withValues(alpha: 0.14);
  static Color get transparent =>
      ColorConstants.whiteColor.withValues(alpha: 0);

  static List<BoxShadow> shadows(bool is_dark) => [
    BoxShadow(
      color: ColorConstants.themeColor.withValues(alpha: is_dark ? 0.24 : 0.18),
      blurRadius: theme_shadow_blur,
      offset: const Offset(0, theme_shadow_offset),
    ),
    BoxShadow(
      color: ColorConstants.shadowColor.withValues(
        alpha: is_dark ? 0.14 : 0.08,
      ),
      blurRadius: ambient_shadow_blur,
      offset: const Offset(0, ambient_shadow_offset),
    ),
  ];

  static List<Color> highlights(bool is_dark) => [
    ColorConstants.whiteColor.withValues(alpha: is_dark ? 0.28 : 0.34),
    ColorConstants.whiteColor.withValues(alpha: is_dark ? 0.08 : 0.06),
    transparent,
  ];
}
