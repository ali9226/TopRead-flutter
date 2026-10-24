import 'package:app/config/color_config.dart';
import 'package:flutter/material.dart';

/// 页面背景装饰层共享样式。
///
/// 提供两类整页渐变配方与渐变方向：
/// - 设置类页面（修改密码/修改昵称/账单）：冷暖过渡较柔和。
/// - 钱包类页面（充值/提现/记录）：夜间更深、日间偏金。
class PageBackdropStyle {
  const PageBackdropStyle._();

  /// 渐变起点：页面顶部。
  static const Alignment gradient_begin = Alignment.topCenter;

  /// 渐变终点：页面底部。
  static const Alignment gradient_end = Alignment.bottomCenter;

  /// 设置类页面夜间背景渐变（深蓝黑三段）。
  static const List<Color> night_setting_colors = <Color>[
    ColorConstants.night_gradient_start,
    ColorConstants.nightBackgroundColor,
    ColorConstants.night_gradient_end,
  ];

  /// 钱包类页面夜间背景渐变（更深的蓝黑三段）。
  static const List<Color> night_wallet_colors = <Color>[
    ColorConstants.night_hero_gradient_start,
    ColorConstants.night_gradient_deep,
    ColorConstants.night_gradient_deepest,
  ];

  /// 装饰光斑默认形状。
  static const BoxShape glow_shape = BoxShape.circle;
}
