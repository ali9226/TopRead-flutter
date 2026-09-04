// ignore_for_file: non_constant_identifier_names

import 'package:app/config/constant.dart';

/// 开屏页面样式配置
class SplashScreenStyle {
  /// 开屏图片展示时长（毫秒）。
  /// 从 Constant 统一读取，便于全局调整。
  static int get display_duration_ms => Constant.splashScreenDisplayDurationMs;

  /// 淡出动画时长（毫秒）。
  /// 从 Constant 统一读取，便于全局调整。
  static int get fade_out_duration_ms => Constant.splashScreenFadeOutDurationMs;

  /// 横屏开屏图片路径（日间模式）。
  static const String landscape_light_image = 'assets/img/splash_screen/landscape_light.jpg';

  /// 横屏开屏图片路径（夜间模式）。
  static const String landscape_dark_image = 'assets/img/splash_screen/landscape_dark.jpg';

  /// 竖屏开屏图片路径（日间模式）。
  static const String vertical_screen_light_image = 'assets/img/splash_screen/vertical_screen_light.jpg';

  /// 竖屏开屏图片路径（夜间模式）。
  static const String vertical_screen_dark_image = 'assets/img/splash_screen/vertical_screen_dark.jpg';
}
