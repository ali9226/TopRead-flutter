import 'package:flutter/material.dart';

/// 页面顶部渐变过渡公共样式常量。
class PageTopGradientOverlayStyle {
  /// 顶部渐变遮罩高度。
  static const double height = 90;

  /// 顶部渐变起始透明度。
  static const double start_opacity = 0.82;

  /// 顶部渐变中段透明度。
  static const double middle_opacity = 0.24;

  /// 正文与封面之间切换时，保持遮罩原位并轻柔交接背景。
  static const Duration visibility_duration = Duration(milliseconds: 240);
  static const Curve visibility_curve = Curves.easeInOutCubic;
}
