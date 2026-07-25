import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/color_config.dart';

/// 全局统一提交按钮样式配置。
///
/// 集中管理所有页面（登录、注册、修改密码、修改昵称等）
/// 共用的提交按钮视觉参数，保证按钮高度、圆角、渐变、阴影、
/// 字号、loading 指示器等完全一致。
///
/// 使用方式：
/// ```dart
/// CommonSubmitButton(
///   title: context.tr('UserInfo.login'),
///   loading: isLoading,
///   isDark: isDark,
///   onTap: handleSubmit,
/// )
/// ```
class CommonSubmitButtonStyle {
  const CommonSubmitButtonStyle._();

  // ======================== 尺寸 ========================

  /// 按钮高度。
  static const double height = 54.0;

  /// 按钮圆角。
  static const double radius = 27.0;

  /// 按钮水平内边距（用于非全宽场景）。
  static const double horizontalMargin = 0.0;

  // ======================== 文字 ========================

  /// 按钮文字字号。
  static const double fontSize = 17.0;

  /// 按钮文字字重。
  static final FontWeight fontWeight = FontConfig.adjustedWeight(FontWeight.w500);

  // ======================== Loading 指示器 ========================

  /// loading 指示器尺寸。
  static const double loadingSize = 22.0;

  /// loading 指示器线宽。
  static const double loadingStrokeWidth = 2.2;

  // ======================== 颜色方法 ========================

  /// 按钮背景（日间为金色渐变，夜间为纯主题色）。
  static Gradient? gradient({required bool isDark}) {
    if (isDark) return null;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const <Color>[Color(0xFFFFD861), Color(0xFFF4BD33)],
    );
  }

  /// 按钮纯色背景（仅夜间模式使用）。
  static Color? solidColor({required bool isDark}) {
    if (!isDark) return null;
    return ColorConstants.themeColor;
  }

  /// 按钮阴影。
  static List<BoxShadow> shadow({required bool isDark}) {
    return <BoxShadow>[
      BoxShadow(
        color: (isDark ? ColorConstants.themeColor : const Color(0xFFF4BD33))
            .withValues(alpha: 0.30),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ];
  }

  /// 按钮文字颜色（夜间模式为深色，日间模式也为深色）。
  static Color textColor({required bool isDark}) {
    return const Color(0xFF3D2E1A);
  }

  /// loading 指示器颜色。
  static Color loadingColor({required bool isDark}) {
    return const Color(0xFF3D2E1A);
  }
}
