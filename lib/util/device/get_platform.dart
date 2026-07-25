import 'dart:ui' show FlutterView;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// 返回 true 表示电脑端（Desktop 或 Web 宽屏），false 表示手机/平板
bool isPcMobile() {
  final FlutterView view =
      WidgetsBinding.instance.platformDispatcher.views.first;
  final double width = view.physicalSize.width / view.devicePixelRatio;

  if (kIsWeb) {
    return width >= 1100;

    /// Web 宽度 >=1100 当作电脑
  }

  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    return true; // 桌面端
  }

  // 手机和平板
  return false;
}
