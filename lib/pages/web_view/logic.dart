// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// TODO WebView 页面逻辑交互处理。
///
/// 负责初始化控制器、监听导航事件、管理加载状态等。
class WebViewLogic {
  /// TODO WebView 控制器。
  final WebViewController controller;

  /// TODO 页面加载进度，0.0 - 1.0。
  final ValueChanged<double> onProgressChanged;

  /// TODO 页面加载状态变化回调。
  final ValueChanged<bool> onLoadingChanged;

  /// TODO 页面错误状态变化回调。
  final ValueChanged<bool> onErrorChanged;

  /// TODO WebView 逻辑构造函数。
  ///
  /// 参数 [controller]:
  /// WebView 控制器实例。
  ///
  /// 参数 [onProgressChanged]:
  /// 加载进度变化时的回调，接收 0.0 - 1.0 的值。
  ///
  /// 参数 [onLoadingChanged]:
  /// 加载状态变化时的回调，true 表示正在加载。
  ///
  /// 参数 [onErrorChanged]:
  /// 错误状态变化时的回调，true 表示加载失败。
  WebViewLogic({
    required this.controller,
    required this.onProgressChanged,
    required this.onLoadingChanged,
    required this.onErrorChanged,
  });

  /// TODO 初始化 WebView 导航代理。
  ///
  /// 监听页面加载进度、开始、完成和错误事件，
  /// 并同步更新 UI 状态。
  void init_navigation_delegate() {
    controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: _on_progress,
        onPageStarted: _on_page_started,
        onPageFinished: _on_page_finished,
        onWebResourceError: _on_web_resource_error,
      ),
    );
  }

  /// TODO 加载指定网址。
  ///
  /// 参数 [url]:
  /// 要加载的目标网址。
  Future<void> load_url(String url) async {
    await controller.loadRequest(Uri.parse(url));
  }

  /// TODO 重新加载当前网址。
  ///
  /// 用于加载失败后用户点击重试时调用。
  Future<void> reload(String url) async {
    await controller.loadRequest(Uri.parse(url));
  }

  /// TODO 处理加载进度回调。
  ///
  /// 参数 [progress]:
  /// 加载进度百分比，范围 0 - 100。
  void _on_progress(int progress) {
    onProgressChanged(progress / 100);
  }

  /// TODO 处理页面开始加载事件。
  ///
  /// 参数 [url]:
  /// 正在加载的网址。
  void _on_page_started(String url) {
    onLoadingChanged(true);
    onErrorChanged(false);
    onProgressChanged(0);
  }

  /// TODO 处理页面加载完成事件。
  ///
  /// 参数 [url]:
  /// 已加载完成的网址。
  void _on_page_finished(String url) {
    onLoadingChanged(false);
    onProgressChanged(1);
  }

  /// TODO 处理网页资源加载错误。
  ///
  /// 参数 [error]:
  /// 错误详情对象，包含错误码、描述等信息。
  void _on_web_resource_error(WebResourceError error) {
    onLoadingChanged(false);
    onErrorChanged(true);
  }
}
