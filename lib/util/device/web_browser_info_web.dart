// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'package:flutter/foundation.dart';

/// 判断当前是否为苹果移动设备上的 Web Chrome 或 Safari 浏览器。
bool isMobileWebChromeOrSafari() {
  if (!kIsWeb) {
    return false;
  }

  final String userAgent = _browserUserAgent();
  final bool isAppleMobileDevice = _isAppleMobileDevice(userAgent);
  final bool isMobileWeb = _isMobileWeb(userAgent);
  final bool isChrome = userAgent.contains('CriOS');
  final bool isSafari = userAgent.contains('Safari') &&
      !userAgent.contains('CriOS') &&
      !userAgent.contains('FxiOS') &&
      !userAgent.contains('EdgiOS') &&
      !userAgent.contains('OPiOS');

  return isAppleMobileDevice && isMobileWeb && (isChrome || isSafari);
}

/// 判断 Web 当前是否属于桌面端宽屏。
bool _isDesktopWeb() {
  return (html.window.innerWidth ?? 0) >= 1100;
}

/// 判断当前是否为苹果移动设备（兼容 iPadOS 桌面级 UA）。
bool _isAppleMobileDevice(String userAgent) {
  final String platform = html.window.navigator.platform ?? '';
  final bool isIPhoneIPadOrIPod = userAgent.contains('iPhone') ||
      userAgent.contains('iPad') ||
      userAgent.contains('iPod');
  final bool isIPadOsDesktopUa =
      platform == 'MacIntel' && (html.window.navigator.maxTouchPoints ?? 0) > 1;

  return isIPhoneIPadOrIPod || isIPadOsDesktopUa;
}

/// 判断当前 Web 是否为移动端环境。
bool _isMobileWeb(String userAgent) {
  return userAgent.contains('Mobile') || !_isDesktopWeb();
}

/// 读取浏览器 userAgent。
String _browserUserAgent() {
  return html.window.navigator.userAgent;
}

/// 在浏览器中以新页面方式打开目标地址。
void openWebPageInNewTab(String url) {
  html.window.open(url, '_blank');
}
