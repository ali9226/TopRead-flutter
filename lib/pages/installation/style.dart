import 'package:flutter/material.dart';
import 'package:app/components/auth_page/style.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';

/// 申请成为作家页面样式常量。
///
/// 复用认证页设计体系，与登录、注册页面保持视觉一致。
class Style {
  const Style._();

  // ==================== 背景装饰气泡 ====================

  /// 页面背景装饰气泡配置。
  static final List<AuthBackgroundBubble> pageBubbles = [
    AuthBackgroundBubble(
      width: 200,
      height: 200,
      top: -56,
      right: -30,
      lightOpacity: 0.14,
      darkOpacity: 0.10,
      color: ColorConstants.themeColor,
    ),
    AuthBackgroundBubble(
      width: 140,
      height: 140,
      top: 200,
      left: -45,
      lightOpacity: 0.10,
      darkOpacity: 0.08,
      color: ColorConstants.successColor,
    ),
    AuthBackgroundBubble(
      width: 100,
      height: 100,
      bottom: 120,
      right: -20,
      lightOpacity: 0.04,
      darkOpacity: 0.10,
      color: Colors.black,
    ),
  ];

  // ==================== 标题 ====================

  /// 页面主标题字号。
  static const double titleSize = 24;

  /// 页面主标题字重。
  static final FontWeight titleWeight =
      FontConfig.adjustedWeight(FontWeight.w600);

  // ==================== 输入框 ====================

  /// 输入框文字字号。
  static const double inputFontSize = 16;

  /// 发送验证码按钮字号。
  static const double sendCodeFontSize = 14;

  // ==================== 间距 ====================

  /// 字段区块间距。
  static const double sectionSpacing = 8;

  /// 大间距（提交按钮前）。
  static const double largeSpacing = 28;

  /// 按钮水平外边距。
  static const double buttonHorizontalMargin = 20.0;

  // ==================== 协议 ====================

  /// 协议文字字号。
  static const double agreementFontSize = 12;

  /// 协议文字行高。
  static const double agreementHeight = 1.5;
}
