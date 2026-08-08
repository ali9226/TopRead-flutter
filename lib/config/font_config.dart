import 'package:flutter/material.dart';
import 'package:app/util/device/app_environment.dart';

/// 字体平台适配配置。
///
/// Android 默认思源黑体比 iOS 苹方视觉更粗，
///  Noto Sans CJK SC、Noto Sans SC （安卓平台支持中文的只有这两种字体）
/// 本类通过 fontFamily 选择和字重映射来统一两端视觉效果。
class FontConfig {
  /// Android 平台优选字体（视觉更接近苹方）。
  static const String _androidFontFamily = 'Noto Sans SC';


  /// 根据平台返回最优 fontFamily。
  ///
  /// - Android: 使用 Noto Sans SC（比默认 Noto Sans CJK SC 更细）
  /// - iOS/Web: 空字符串，使用平台默认字体
  static String get platformFontFamily {
    if (!isAndroidApp) return '';
    return _androidFontFamily;
  }

  /// Android 上降低一档 FontWeight 来匹配 iOS 视觉效果。
  ///
  /// 思源黑体 Regular(400) ≈ 苹方 Medium(500)，
  /// 因此在 Android 上将字重降一档以达到同等视觉粗细。
  static FontWeight adjustedWeight(FontWeight original) {
    if (!isAndroidApp) return original;
    if (original == FontWeight.w900) return FontWeight.w800;
    if (original == FontWeight.w800) return FontWeight.w700;
    if (original == FontWeight.w700) return FontWeight.w600;
    if (original == FontWeight.w600) return FontWeight.w500;
    if (original == FontWeight.w500) return FontWeight.w400;
    if (original == FontWeight.w400) return FontWeight.w300;
    if (original == FontWeight.w300) return FontWeight.w200;
    return original;
  }

  /// 返回平台适配的 TextTheme。
  ///
  /// Android 上所有 Material 默认文本样式降一档字重，
  /// 使中文字体视觉粗细与 iOS 苹方保持一致。
  static TextTheme adjustedTextTheme(TextTheme base) {
    if (!isAndroidApp) return base;
    return base.copyWith(
      displayLarge: _adjust(base.displayLarge),
      displayMedium: _adjust(base.displayMedium),
      displaySmall: _adjust(base.displaySmall),
      headlineLarge: _adjust(base.headlineLarge),
      headlineMedium: _adjust(base.headlineMedium),
      headlineSmall: _adjust(base.headlineSmall),
      titleLarge: _adjust(base.titleLarge),
      titleMedium: _adjust(base.titleMedium),
      titleSmall: _adjust(base.titleSmall),
      bodyLarge: _adjust(base.bodyLarge),
      bodyMedium: _adjust(base.bodyMedium),
      bodySmall: _adjust(base.bodySmall),
      labelLarge: _adjust(base.labelLarge),
      labelMedium: _adjust(base.labelMedium),
      labelSmall: _adjust(base.labelSmall),
    );
  }

  /// 对单个 TextStyle 降一档字重。
  static TextStyle? _adjust(TextStyle? style) {
    if (style == null) return null;
    return style.copyWith(
      fontWeight: adjustedWeight(style.fontWeight ?? FontWeight.w400),
    );
  }
}
