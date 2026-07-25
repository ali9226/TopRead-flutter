// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/web_view/logic.dart';
import 'package:app/pages/web_view/style.dart';
import 'package:app/config/font_config.dart';

/// WebView 全屏页面组件。
///
/// 用于展示外部网址，页面严格遵守 SafeArea 限制，
/// 顶部不超出状态栏。左上角有关闭按钮，可以返回上一页。
/// 页面包含加载中、加载进度条、加载失败等状态展示，
/// 并适配日间和夜间主题。
///
/// 参数 [url]:
/// 要加载的网址。
class WebViewPage extends StatefulWidget {
  /// 要加载的网址。
  final String url;

  /// WebView 全屏页面构造函数。
  ///
  /// 参数 [url]:
  /// 要加载的网址。
  const WebViewPage({
    super.key,
    required this.url,
  });

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  /// WebView 控制器。
  late final WebViewController _controller;

  /// 页面逻辑交互处理器。
  late final WebViewLogic _logic;

  /// 页面加载进度，0.0 - 1.0。
  double _loading_progress = 0;

  /// 页面是否正在加载。
  bool _is_loading = true;

  /// 页面是否加载失败。
  bool _has_error = false;

  @override
  void initState() {
    super.initState();
    // 创建 WebView 控制器并开启 JavaScript。
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    // 初始化逻辑层并绑定状态回调。
    _logic = WebViewLogic(
      controller: _controller,
      onProgressChanged: _on_progress_changed,
      onLoadingChanged: _on_loading_changed,
      onErrorChanged: _on_error_changed,
    );
    // 注册导航代理并开始加载目标链接。
    _logic.init_navigation_delegate();
    _logic.load_url(widget.url);
  }

  /// 处理加载进度变化。
  ///
  /// 参数 [progress]:
  /// 加载进度，范围 0.0 - 1.0。
  void _on_progress_changed(double progress) {
    if (mounted) {
      setState(() {
        _loading_progress = progress;
      });
    }
  }

  /// 处理加载状态变化。
  ///
  /// 参数 [is_loading]:
  /// true 表示正在加载，false 表示加载完成或停止。
  void _on_loading_changed(bool is_loading) {
    if (mounted) {
      setState(() {
        _is_loading = is_loading;
      });
    }
  }

  /// 处理错误状态变化。
  ///
  /// 参数 [has_error]:
  /// true 表示加载失败，false 表示正常。
  void _on_error_changed(bool has_error) {
    if (mounted) {
      setState(() {
        _has_error = has_error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 从主题亮度推导当前日夜间模式。
    final bool is_dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          children: <Widget>[
            /// WebView 内容区域。
            WebViewWidget(controller: _controller),

            /// 加载进度条，仅在加载进行中且未完成时显示。
            if (_is_loading && _loading_progress > 0 && _loading_progress < 1)
              _build_progress_bar(),

            /// 加载中遮罩层，包含转圈图标和“正在加载中”文案。
            if (_is_loading)
              _build_loading_overlay(is_dark: is_dark),

            /// 加载失败提示层，包含错误图标、提示文字和重试按钮。
            if (_has_error)
              _build_error_overlay(is_dark: is_dark),

            /// 左上角关闭按钮。
            _build_close_button(is_dark: is_dark),
          ],
        ),
      ),
    );
  }

  /// 构建加载进度条。
  ///
  /// 使用主题色作为进度指示器颜色，背景透明。
  Widget _build_progress_bar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: LinearProgressIndicator(
        value: _loading_progress,
        minHeight: Style.progress_bar_height,
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(
          ColorConstants.themeColor,
        ),
      ),
    );
  }

  /// 构建加载中遮罩层。
  ///
  /// 包含居中的转圈图标和下方的"正在加载中..."文字。
  /// 背景色根据主题自适应。
  ///
  /// 参数 [is_dark]:
  /// 当前是否为夜间主题。
  Widget _build_loading_overlay({required bool is_dark}) {
    return Positioned.fill(
      child: Container(
        color: is_dark
            ? Style.loading_overlay_dark_color
            : Style.loading_overlay_light_color,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              /// 加载转圈图标。
              SizedBox(
                width: Style.loading_area_size,
                height: Style.loading_area_size,
                child: CircularProgressIndicator(
                  color: ColorConstants.themeColor,
                ),
              ),
              const SizedBox(height: Style.loading_text_spacing),
              /// 加载中提示文字，使用多语种。
              Text(
                easy.tr('web_view.loading_text'),
                style: TextStyle(
                  fontSize: Style.loading_text_font_size,
                  color: is_dark
                      ? ColorConstants.nightTextColor
                      : ColorConstants.lightTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建加载失败提示层。
  ///
  /// 包含错误图标、错误标题、错误描述和重试按钮。
  /// 背景色和文字颜色根据主题自适应。
  ///
  /// 参数 [is_dark]:
  /// 当前是否为夜间主题。
  Widget _build_error_overlay({required bool is_dark}) {
    return Positioned.fill(
      child: Container(
        color: is_dark
            ? Style.error_page_dark_background
            : Style.error_page_light_background,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              /// 错误图标。
              Icon(
                Icons.error_outline,
                size: Style.error_icon_size,
                color: is_dark
                    ? Style.error_icon_dark_color
                    : Style.error_icon_light_color,
              ),
              const SizedBox(height: Style.error_title_spacing),
              /// 错误标题，使用多语种。
              Text(
                easy.tr('web_view.error_title'),
                style: TextStyle(
                  fontSize: Style.error_title_font_size,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
                  color: is_dark
                      ? Style.error_title_dark_color
                      : Style.error_title_light_color,
                ),
              ),
              const SizedBox(height: Style.error_description_spacing),
              /// 错误描述，使用多语种。
              Text(
                easy.tr('web_view.error_description'),
                style: TextStyle(
                  fontSize: Style.error_description_font_size,
                  color: is_dark
                      ? Style.error_description_dark_color
                      : Style.error_description_light_color,
                ),
              ),
              const SizedBox(height: Style.retry_button_spacing),
              /// 重试按钮，点击后重新加载网址。
              ElevatedButton.icon(
                onPressed: _on_retry_tap,
                icon: const Icon(Icons.refresh),
                label: Text(easy.tr('web_view.retry_button')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Style.retry_button_horizontal_padding,
                    vertical: Style.retry_button_vertical_padding,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建左上角关闭按钮。
  ///
  /// 按钮位置贯穿顶部状态栏，使用半透明黑色背景。
  ///
  /// 参数 [is_dark]:
  /// 当前是否为夜间主题（预留，当前固定黑色半透明）。
  Widget _build_close_button({required bool is_dark}) {
    return Positioned(
      top: Style.close_button_top_margin,
      left: Style.close_button_left_margin,
      child: Material(
        color: Colors.black.withValues(alpha: Style.close_button_background_alpha),
        borderRadius: BorderRadius.circular(Style.close_button_radius),
        child: InkWell(
          onTap: _on_close_tap,
          borderRadius: BorderRadius.circular(Style.close_button_radius),
          child: SizedBox(
            width: Style.close_button_size,
            height: Style.close_button_size,
            child: Icon(
              Icons.close,
              color: Colors.white,
              size: Style.close_icon_size,
            ),
          ),
        ),
      ),
    );
  }

  /// 处理关闭按钮点击。
  ///
  /// 执行路由后退操作，返回上一页。
  void _on_close_tap() {
    AppRouter.pop();
  }

  /// 处理重试按钮点击。
  ///
  /// 重置错误状态，重新加载当前网址。
  void _on_retry_tap() {
    if (mounted) {
      setState(() {
        _has_error = false;
        _is_loading = true;
      });
      _logic.reload(widget.url);
    }
  }
}
