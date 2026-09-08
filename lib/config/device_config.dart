import 'package:flutter/foundation.dart';

/// 设备配置。
///
/// 根据设备类型（桌面/移动）返回不同的布局约束。
class DeviceConfig {
  /// 桌面浏览器最大宽度限制。
  static const double _desktopMaxWidth = 900.0;

  /// 获取当前设备的最大宽度限制。
  ///
  /// 桌面浏览器返回 900，移动端和平板返回 0（不限制）。
  static double get maxWidth {
    // 原生 App 不限制。
    if (!kIsWeb) return 0;

    // Web 端根据平台判断。
    final TargetPlatform platform = defaultTargetPlatform;
    if (platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux) {
      return _desktopMaxWidth;
    }

    // 移动端浏览器和平板不限制。
    return 0;
  }
}
