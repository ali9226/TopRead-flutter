import 'package:flutter/foundation.dart';

/// 应用运行环境。
///
/// - [desktopBrowser]: 桌面浏览器（1）
/// - [android]: Android 原生 App（2）
/// - [ios]: iOS 原生 App（3）
/// - [androidBrowser]: Android 浏览器（4）
/// - [iosBrowser]: iOS 浏览器（5）
enum AppEnvironment {
  desktopBrowser(1),
  android(2),
  ios(3),
  androidBrowser(4),
  iosBrowser(5);

  const AppEnvironment(this.value);

  /// 对应后端接口的数值标识。
  final int value;
}

/// 当前运行环境。
AppEnvironment get currentEnvironment {
  if (kIsWeb) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AppEnvironment.androidBrowser;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppEnvironment.iosBrowser;
    }
    return AppEnvironment.desktopBrowser;
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return AppEnvironment.android;
  }
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return AppEnvironment.ios;
  }
  // 桌面端（Windows / macOS / Linux）归类为桌面浏览器。
  return AppEnvironment.desktopBrowser;
}

/// 当前是否为原生 App（Android 或 iOS）。
bool get isNativeMobileApp =>
    currentEnvironment == AppEnvironment.android ||
    currentEnvironment == AppEnvironment.ios;

/// 当前是否为 Android 原生 App。
bool get isAndroidApp => currentEnvironment == AppEnvironment.android;

/// 当前是否为 iOS 原生 App。
bool get isIOSApp => currentEnvironment == AppEnvironment.ios;

/// 当前是否为任意浏览器环境（桌面 / Android / iOS）。
bool get isWebBrowser =>
    currentEnvironment == AppEnvironment.desktopBrowser ||
    currentEnvironment == AppEnvironment.androidBrowser ||
    currentEnvironment == AppEnvironment.iosBrowser;

/// 当前是否为移动端浏览器（Android 或 iOS）。
bool get isMobileBrowser =>
    currentEnvironment == AppEnvironment.androidBrowser ||
    currentEnvironment == AppEnvironment.iosBrowser;
