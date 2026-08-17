import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/color_config.dart';

/// 认证页（登录、注册）公共样式。
///
/// 覆盖以下位置：
/// - Logo 图标
/// - 口号文字及两侧渐变条
/// - 左上角关闭图标
/// - 输入框上方标题（账号、密码、邀请码）
/// - "注册即代表同意"协议文字
/// - "已经有账号?"/"还没有账号?"底部跳转文字
/// - "记住密码"文字
/// - "忘记密码"文字
/// - "快捷登录"标题
/// - 操作链接文字（立即登录、立即注册、用户协议）
///
/// 修改此文件会同时影响以上所有位置的视觉表现。
class AuthTextStyle {
  const AuthTextStyle._();

  // ======================== Logo ========================

  /// Logo 宽度。
  static const double logoWidth = 90;

  /// Logo 高度
  static const double logoHeight = 90;

  /// Logo 与口号之间的间距。
  static const double logoToSloganSpacing = 0;

  // ======================== 口号 ========================

  /// 口号文字字号。
  static const double sloganFontSize = 14;

  /// 口号文字字重。
  static final FontWeight sloganFontWeight = FontConfig.adjustedWeight(FontWeight.w400);

  /// 口号两侧渐变条宽度。
  static const double sloganBarWidth = 50;

  /// 口号两侧渐变条高度。
  static const double sloganBarHeight = 2;

  // ======================== 关闭图标 ========================

  /// 关闭图标尺寸。
  static const double closeIconSize = 26;

  // ======================== 主文字颜色（Logo、口号、输入框标题等） ========================

  /// 主文字颜色（根据日间/夜间模式）。
  ///
  /// 用于 Logo、口号、输入框标题等需要高对比度的元素。
  static Color primaryTextColor({required bool isDark}) {
    return isDark
        ? Colors.white
        : ColorConstants.nightBackgroundColor;
  }

  // ======================== 输入框标题（账号、密码等） ========================

  /// 输入框标题字号。
  static const double labelFontSize = 14;

  /// 输入框标题字重。
  static final FontWeight labelFontWeight = FontConfig.adjustedWeight(FontWeight.w400);

  /// 输入框标题颜色（根据日间/夜间模式）。
  static Color labelTextColor({required bool isDark}) {
    return primaryTextColor(isDark: isDark);
  }

  // ======================== 辅助文字（灰色描述性文字） ========================

  /// 辅助文字字号。
  static const double fontSize = 12;

  /// 辅助文字字重。
  static final FontWeight fontWeight = FontConfig.adjustedWeight(FontWeight.w400);

  /// 辅助文字颜色（根据日间/夜间模式）。
  static Color textColor({required bool isDark}) {
    return isDark
        ? ColorConstants.nightTextColor
        : ColorConstants.lightTextColor;
  }

  // ======================== 操作链接文字（立即登录、立即注册、用户协议） ========================

  /// 操作链接字重。
  static final FontWeight actionFontWeight = FontConfig.adjustedWeight(FontWeight.w500);
}
