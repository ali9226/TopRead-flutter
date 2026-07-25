import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/util/color_util.dart';

/// 认证页公共样式。
class AuthPageStyle {
  const AuthPageStyle._();

  static const double logoSize = 90;
  static const double logoHeightSize = 90;
  static const double fieldIconSize = 22;
  static const double passwordIconSize = 26;
  static const double rememberSize = 16;
  static const double footerPromptFontSize = 13;
  static const double sloganWidth = 50;
  static const double sloganHeight = 2;
  static const EdgeInsets contentPadding = EdgeInsets.zero;
  static const double fieldHorizontalPadding = 20;
  static const double topHeaderHeight = 92;
  static const double brandTopSpacing = 10;
  static const double brandTranslateY = -80;

  static final Color passwordIconColor = hexToColor('#c8c9cc');

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
      color: Colors.black,
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
      color: Colors.black,
    ),
  ];

  static List<Color> backgroundGradient(bool isDark) {
    if (isDark) {
      return const [Color(0xFF1A1D2C), Color(0xFF12121C), Color(0xFF0D0E14)];
    }

    return const [Color(0xFFFFF6D6), Color(0xFFF8F6EF), Color(0xFFFFFFFF)];
  }

  static Color primaryTextColor(bool isDark) {
    return isDark
        ? Colors.white
        : ColorConstants.nightBackgroundColor;
  }

  static Color hintColor(bool isDark) {
    return isDark ? Colors.grey.shade400 : Colors.grey.shade600;
  }

  static Color inputBorderColor(bool isDark) {
    return isDark
        ? ColorConstants.nightTextColor
        : Colors.black.withValues(alpha: 0.2);
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
