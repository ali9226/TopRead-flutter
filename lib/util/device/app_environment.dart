import 'package:flutter/foundation.dart';

/// 应用运行环境。
///
/// - [browser]: 浏览器（Web）
/// - [android]: Android 原生 App
/// - [ios]: iOS 原生 App
enum AppEnvironment {
  browser(1),
  android(2),
  ios(3);

  const AppEnvironment(this.value);

  /// 对应后端接口的数值标识。
  final int value;
}

/// 当前运行环境。
///
/// 仅在原生 App 时区分 Android / iOS，Web 统一返回 [AppEnvironment.browser]。
AppEnvironment get currentEnvironment {
  if (kIsWeb) return AppEnvironment.browser;
  if (defaultTargetPlatform == TargetPlatform.android) {
    return AppEnvironment.android;
  }
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return AppEnvironment.ios;
  }
  // 桌面端（Windows / macOS / Linux）归类为浏览器。
  return AppEnvironment.browser;
}

/// 当前是否为 Android 或 iOS 原生 App。
bool get isNativeMobileApp =>
    currentEnvironment == AppEnvironment.android ||
    currentEnvironment == AppEnvironment.ios;

/// 当前是否为 Android 平台。
bool get isAndroidApp => currentEnvironment == AppEnvironment.android;

/// 当前是否为 iOS 平台。
bool get isIOSApp => currentEnvironment == AppEnvironment.ios;

/// 当前是否为 Web 浏览器。
bool get isWebBrowser => currentEnvironment == AppEnvironment.browser;
