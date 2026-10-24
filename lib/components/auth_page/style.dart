import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 认证页公共样式。
class AuthPageStyle {
  const AuthPageStyle._();

  static const double logoSize = 90;
  static const double logoHeightSize = 90;
  static const double fieldIconSize = LayoutConfig.icon_compact;
  static const double passwordIconSize = 26;
  static const double rememberSize = 16;
  static const double sloganWidth = 50;
  static const double sloganHeight = 2;
  static const EdgeInsets contentPadding = EdgeInsets.zero;
  static const double fieldHorizontalPadding = LayoutConfig.space_20;
  static const double topHeaderHeight = 92;
  static const double brandTopSpacing = LayoutConfig.space_10;
  static const double brandTranslateY = -80;

  static final Color passwordIconColor = ColorConstants.auth_page_style_password_icon_color;

  static final List<AuthBackgroundBubble> loginBubbles = [
    AuthBackgroundBubble(
      width: 210,
      height: 210,
      top: -60,
      right: -30,
      lightOpacity: 0.14,
      darkOpacity: 0.10,
      color: ColorConstants.themeColor,
    ),
    AuthBackgroundBubble(
      width: 140,
      height: 140,
      top: 180,
      left: -45,
      lightOpacity: 0.10,
      darkOpacity: 0.08,
      color: ColorConstants.successColor,
    ),
    AuthBackgroundBubble(
      width: 120,
      height: 120,
      bottom: 90,
      right: -25,
      lightOpacity: 0.04,
      darkOpacity: 0.10,
      color: ColorConstants.lightTextColor,
    ),
  ];

  static final List<AuthBackgroundBubble> registerBubbles = [
    AuthBackgroundBubble(
      width: 200,
      height: 200,
      top: -56,
      left: -26,
      lightOpacity: 0.14,
      darkOpacity: 0.10,
      color: ColorConstants.themeColor,
    ),
    AuthBackgroundBubble(
      width: 150,
      height: 150,
      top: 230,
      right: -38,
      lightOpacity: 0.10,
      darkOpacity: 0.08,
      color: ColorConstants.successColor,
    ),
    AuthBackgroundBubble(
      width: 96,
      height: 96,
      bottom: 110,
      left: -18,
      lightOpacity: 0.04,
      darkOpacity: 0.10,
      color: ColorConstants.lightTextColor,
    ),
  ];

  static List<Color> backgroundGradient(bool isDark) {
    if (isDark) {
      return const [ColorConstants.night_gradient_start, ColorConstants.nightBackgroundColor, ColorConstants.night_gradient_end];
    }

    return const [ColorConstants.password_icon_color_fffff6d6, ColorConstants.password_icon_color_fff8f6ef, ColorConstants.whiteColor];
  }

  static Color primaryTextColor(bool isDark) {
    return isDark ? ColorConstants.whiteColor : ColorConstants.nightBackgroundColor;
  }

  static Color hintColor(bool isDark) {
    return isDark ? ColorConstants.components_auth_page_style_tone : ColorConstants.components_auth_page_style_tone_ff757575;
  }

  static Color inputBorderColor(bool isDark) {
    return isDark
        ? ColorConstants.nightTextColor
        : ColorConstants.components_cute_mascot_index_tone_33222222;
  }

  static BoxDecoration sloganGradientBar({
    required bool isDark,
    required bool reverse,
  }) {
    final Color startColor = ColorConstants.themeColor.withValues(alpha: 0);

    return BoxDecoration(
      gradient: LinearGradient(
        colors: [startColor, ColorConstants.themeColor],
        begin: reverse ? Alignment.centerRight : Alignment.centerLeft,
        end: reverse ? Alignment.centerLeft : Alignment.centerRight,
      ),
    );
  }
}

/// 认证页背景装饰圆形。
class AuthBackgroundBubble {
  final double width;
  final double height;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final double lightOpacity;
  final double darkOpacity;
  final Color color;

  const AuthBackgroundBubble({
    required this.width,
    required this.height,
    required this.lightOpacity,
    required this.darkOpacity,
    required this.color,
    this.top,
    this.right,
    this.bottom,
    this.left,
  });
}
