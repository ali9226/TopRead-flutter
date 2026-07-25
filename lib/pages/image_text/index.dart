import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' as flutter_html;
import 'package:get/get.dart';
import 'package:app/components/back_to_top_button/index.dart';
import 'package:app/components/floating_back_to_top/style.dart'
    as floating_back_to_top_style;
import 'package:app/components/language_selection/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/theme.dart';
import 'package:app/models/image_text_detail.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/layout/page_header_spacing.dart';
import 'package:app/util/router/router_util.dart';

import 'logic.dart';
import 'style.dart';

/// image_text 页面。
class ImageText extends StatefulWidget {
  /// 路由传入的业务类型。
  final String? type;

  const ImageText({super.key, this.type});

  @override
  State<ImageText> createState() => _ImageTextState();
}

class _ImageTextState extends State<ImageText> {
  /// 页面逻辑层。
  final Logic logic = const Logic();

  /// 设备信息仓库。
  final DeviceInfo device_info = Get.find<DeviceInfo>();

  /// 页面滚动控制器。
  final ScrollController scroll_controller = ScrollController();

  /// 接口返回详情。
  ImageTextDetail? detail;

  /// 页面加载状态。
  bool loading = true;

  /// 返回顶部按钮显示状态。
  bool show_back_to_top = false;

  /// 当前路由 type 参数值。
  String type_value = '';

  /// 记录上一次语言代码，语种切换后用于触发重新请求。
  String _last_language_code = '';

  @override
  void initState() {
    super.initState();

    scroll_controller.addListener(_handle_scroll);

    /// 首帧后开始执行参数校验与请求，避免在 initState 直接导航。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init_page();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final String current_language_code = Localizations.localeOf(
      context,
    ).languageCode;

    /// 首次进入仅记录语言，不重复触发请求。
    if (_last_language_code.isEmpty) {
      _last_language_code = current_language_code;
      return;
    }

    /// 语种变化后重新请求详情，确保 language id 跟随最新语种。
    if (_last_language_code != current_language_code && type_value.isNotEmpty) {
      _last_language_code = current_language_code;
      _fetch_detail();
    }
  }

  @override
  void dispose() {
    scroll_controller.removeListener(_handle_scroll);
    scroll_controller.dispose();
    super.dispose();
  }

  /// 页面初始化流程：
  /// 1. 校验 type 参数；
  /// 2. 参数缺失时返回首页；
  /// 3. 参数有效时请求详情数据。
  Future<void> _init_page() async {
    type_value = (widget.type ?? '').trim();

    if (type_value.isEmpty) {
      if (!mounted) return;

      /// 缺少 type 参数时，按统一路由入口直接回首页。
      routerUtil(path: '/', type: 'replace');
      return;
    }

    await _fetch_detail();
  }

  /// 请求详情数据。
  Future<void> _fetch_detail() async {
    if (!mounted) return;

    setState(() {
      loading = true;
    });

    final ImageTextDetail? response = await logic.fetch_image_text_detail(
      type: type_value,
    );

    if (!mounted) return;

    setState(() {
      detail = response;
      loading = false;
    });
  }

  /// 下拉刷新入口，复用详情请求逻辑。
  Future<void> _on_refresh() async {
    if (type_value.isEmpty) {
      return;
    }
    await _fetch_detail();
  }

  /// 监听滚动位置，控制返回顶部按钮显隐。
  void _handle_scroll() {
    if (!scroll_controller.hasClients || !mounted) return;

    final double threshold =
        MediaQuery.of(context).size.height * Style.back_to_top_threshold_ratio;
    final bool should_show = scroll_controller.offset > threshold;

    if (show_back_to_top == should_show) return;

    setState(() {
      show_back_to_top = should_show;
    });
  }

  /// 平滑滚动到页面顶部。
  Future<void> _scroll_to_top() async {
    if (!scroll_controller.hasClients || loading) return;

    await scroll_controller.animateTo(
      0,
      duration: const Duration(milliseconds: Style.scroll_to_top_duration_ms),
      curve: Curves.easeInOutCubic,
    );
  }

  /// 构建文章页骨架屏。
  Widget _build_loading_skeleton({required bool is_dark}) {
    final Color bar_color = is_dark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.08);

    return Padding(
      padding: Style.article_content_padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            height: 32,
            decoration: BoxDecoration(
              color: bar_color,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 220,
            height: 32,
            decoration: BoxDecoration(
              color: bar_color,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 22),
          ...List<Widget>.generate(10, (int index) {
            final double width_factor = index % 3 == 2 ? 0.72 : 1.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FractionallySizedBox(
                widthFactor: width_factor,
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: bar_color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media_query = MediaQuery.of(context);
    final EdgeInsets safe_padding = media_query.padding;

    final double content_top_padding =
        resolvePageHeaderContentTopPadding(mediaQuery: media_query) + 8;

    return Obx(() {
      final bool is_dark = device_info.dark.value;
      final bool is_zh_language =
          Localizations.localeOf(context).languageCode.toLowerCase().startsWith(
            'zh',
          );
      final Color background_color = is_dark
          ? ColorConstants.nightBackgroundColor
          : ColorConstants.lightBackgroundColor;

      return Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: ThemeConstants.animationTime),
          curve: Curves.easeInOut,
          color: background_color,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: is_dark
                          ? const <Color>[
                              Color(0xFF191C2A),
                              Color(0xFF11131D),
                              Color(0xFF0C0D14),
                            ]
                          : const <Color>[
                              Color(0xFFF6F0D8),
                              Color(0xFFF8F8F4),
                              Color(0xFFFFFFFF),
                            ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -40,
                right: -24,
                child: IgnorePointer(
                  child: Container(
                    width: Style.decor_circle_one_size,
                    height: Style.decor_circle_one_size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Style.accent_color.withValues(
                        alpha: Style.decor_circle_opacity,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 120,
                left: -36,
                child: IgnorePointer(
                  child: Container(
                    width: Style.decor_circle_two_size,
                    height: Style.decor_circle_two_size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorConstants.successColor.withValues(
                        alpha: Style.decor_circle_opacity,
                      ),
                    ),
                  ),
                ),
              ),
              RefreshIndicator(
                onRefresh: _on_refresh,
                child: ListView(
                  controller: scroll_controller,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    Style.page_horizontal_padding + safe_padding.left,
                    content_top_padding,
                    Style.page_horizontal_padding + safe_padding.right,
                    Style.page_bottom_padding + safe_padding.bottom,
                  ),
                  children: <Widget>[
                    if (loading)
                      _build_loading_skeleton(is_dark: is_dark)
                    else ...<Widget>[
                      Padding(
                        padding: Style.article_content_padding,
                        child: Text(
                          (detail?.title ?? '').trim().isEmpty
                              ? '-'
                              : detail!.title,
                          style: TextStyle(
                            fontSize: Style.title_font_size,
                            height: Style.title_line_height,
                            fontWeight: Style.title_font_weight,
                            color: is_dark
                                ? ColorConstants.whiteColor
                                : ColorConstants.lightTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: Style.title_to_content_spacing),
                      Padding(
                        padding: Style.article_content_padding,
                        child: flutter_html.Html(
                          data: detail?.content ?? '',
                          style: <String, flutter_html.Style>{
                            'html': flutter_html.Style(
                              fontSize: flutter_html.FontSize(
                                Style.html_default_font_size,
                              ),
                              lineHeight: flutter_html.LineHeight(
                                is_zh_language
                                    ? Style.html_default_line_height
                                    : 1.85,
                              ),
                              textAlign: TextAlign.start,
                              color: is_dark
                                  ? Colors.white.withValues(alpha: 0.95)
                                  : ColorConstants.lightTextColor,
                              margin: flutter_html.Margins.zero,
                              padding: flutter_html.HtmlPaddings.zero,
                            ),
                            'body': flutter_html.Style(
                              margin: flutter_html.Margins.zero,
                              padding: flutter_html.HtmlPaddings.zero,
                            ),
                            'p': flutter_html.Style(
                              margin: flutter_html.Margins.only(
                                bottom: is_zh_language ? 12 : 16,
                              ),
                              lineHeight: flutter_html.LineHeight(
                                is_zh_language
                                    ? Style.html_default_line_height
                                    : 1.9,
                              ),
                            ),
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          background_color.withValues(alpha: 0.98),
                          background_color.withValues(alpha: 0.82),
                          background_color.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    child: LanguageSelection(
                      darkBackground: is_dark,
                    ),
                  ),
                ),
              ),
              Positioned(
                right:
                    floating_back_to_top_style.FloatingBackToTopStyle.right +
                    safe_padding.right,
                bottom:
                    floating_back_to_top_style
                        .FloatingBackToTopStyle
                        .page_bottom +
                    safe_padding.bottom,
                child: AnimatedSlide(
                  duration: const Duration(
                    milliseconds: Style.back_to_top_slide_duration_ms,
                  ),
                  curve: Curves.easeOutCubic,
                  offset: show_back_to_top
                      ? Offset.zero
                      : const Offset(0, Style.back_to_top_hidden_offset_y),
                  child: AnimatedOpacity(
                    duration: const Duration(
                      milliseconds: Style.back_to_top_opacity_duration_ms,
                    ),
                    opacity: show_back_to_top ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !show_back_to_top,
                      child: BackToTopButton(
                        isDark: is_dark,
                        onTap: _scroll_to_top,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
