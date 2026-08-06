import 'dart:ui';
import 'package:app/config/font_config.dart';

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/page_background_decor/index.dart';
import 'package:app/components/login_required_content/index.dart';
import 'package:app/components/page_top_gradient_overlay/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/bookshelf/logic.dart';
import 'package:app/pages/bookshelf/style.dart';
import 'package:app/pages/bookshelf/widgets/focus_tab_content.dart';
import 'package:app/pages/bookshelf/widgets/favorite_tab_content.dart';
import 'package:app/pages/bookshelf/widgets/history_tab_content.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/user_information.dart';

/// 书架页面。
///
/// 当前先作为底部导航承载页存在，
/// 后续可以在这里继续补充最近阅读、收藏和分组等内容。
class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key});

  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage>
    with SingleTickerProviderStateMixin {
  /// 设备信息仓库。
  final DeviceInfo device_info = Get.find<DeviceInfo>();

  /// 用户信息仓库。
  final UserInformation user_information = Get.find<UserInformation>();

  /// 书架页 Tab 控制器。
  late final TabController _tab_controller;

  @override
  void initState() {
    super.initState();
    _tab_controller = BookshelfLogic.create_tab_controller(vsync: this)
      ..addListener(_on_tab_change);
  }

  @override
  void dispose() {
    _tab_controller.removeListener(_on_tab_change);
    _tab_controller.dispose();
    super.dispose();
  }

  /// 监听 Tab 切换并刷新标题样式与内容区域。
  void _on_tab_change() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      /// 当前是否为夜间主题。
      final bool is_dark = device_info.theme.value == ThemeMode.dark;

      /// 当前用户是否已登录。
      final bool is_logged_in = user_information.isLoggedIn.value;

      /// 页面背景颜色。
      final Color background_color = is_dark
          ? ColorConstants.nightBackgroundColor
          : const Color(0xFFF6F7FB);

      /// 主标题颜色。
      final Color title_color = is_dark
          ? ColorConstants.whiteColor
          : ColorConstants.lightTextColor;

      /// 辅助文本颜色。
      final Color subtitle_color = is_dark
          ? ColorConstants.whiteColor.withValues(alpha: 0.62)
          : ColorConstants.hintColor;

      /// 页面顶部内边距。
      final double page_top_padding = is_logged_in ? 0 : Style.page_top_spacing;

      final bool is_landscape =
          MediaQuery.of(context).orientation == Orientation.landscape;

      return Scaffold(
        backgroundColor: background_color,
        body: Stack(
          children: <Widget>[
            PageBackgroundDecor(is_dark: is_dark),
            SafeArea(
              bottom: false,
              left: !(is_logged_in && is_landscape),
              right: !(is_logged_in && is_landscape),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (!is_logged_in)
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          Style.page_horizontal_padding,
                          0,
                          Style.page_horizontal_padding,
                          0,
                        ).copyWith(top: page_top_padding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              easy.tr('bookshelf.title'),
                              style: TextStyle(
                                color: title_color,
                                fontSize: Style.title_font_size,
                                fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                              ),
                            ),
                            const SizedBox(height: Style.no_login_top_spacing),
                            LoginRequiredContent(
                              title: easy.tr('bookshelf.no_login.title'),
                              subtitle: easy.tr('bookshelf.no_login.desc'),
                              primary_text_color: title_color,
                              secondary_text_color: subtitle_color,
                              action_key: 'bookshelf_no_login_to_login',
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...<Widget>[
                    SizedBox(
                      height: page_top_padding + Style.logged_in_top_spacing,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Style.page_horizontal_padding,
                      ),
                      child: SizedBox(
                        height: Style.tab_bar_height,
                        child: TabBar(
                          controller: _tab_controller,
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          dividerColor: Colors.transparent,
                          indicatorSize: TabBarIndicatorSize.label,
                          labelPadding: Style.tab_label_padding,
                          indicator: UnderlineTabIndicator(
                            borderRadius: BorderRadius.circular(
                              Style.tab_indicator_height / 2,
                            ),
                            borderSide: BorderSide(
                              color: ColorConstants.themeColor,
                              width: Style.tab_indicator_height,
                            ),
                            insets: const EdgeInsets.only(
                              bottom: Style.tab_indicator_bottom_offset,
                            ),
                          ),
                          tabs: <Widget>[
                            _BookshelfTab(
                              index: 0,
                              title: easy.tr('bookshelf.tabs.history'),
                              tab_controller: _tab_controller,
                              selected_color: title_color,
                              unselected_color: subtitle_color,
                              tab_width: _measure_tab_width(
                                context: context,
                                title: easy.tr('bookshelf.tabs.history'),
                              ),
                            ),
                            _BookshelfTab(
                              index: 1,
                              title: easy.tr('bookshelf.tabs.favorite'),
                              tab_controller: _tab_controller,
                              selected_color: title_color,
                              unselected_color: subtitle_color,
                              tab_width: _measure_tab_width(
                                context: context,
                                title: easy.tr('bookshelf.tabs.favorite'),
                              ),
                            ),
                            _BookshelfTab(
                              index: 2,
                              title: easy.tr('bookshelf.tabs.focus'),
                              tab_controller: _tab_controller,
                              selected_color: title_color,
                              unselected_color: subtitle_color,
                              tab_width: _measure_tab_width(
                                context: context,
                                title: easy.tr('bookshelf.tabs.focus'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        key: ValueKey<String>(
                          'bookshelf_tab_bar_view_$is_landscape',
                        ),
                        controller: _tab_controller,
                        children: <Widget>[
                          _BookshelfTabPage(
                            child: HistoryTabContent(
                              accent_color:
                                  BookshelfLogic.resolve_tab_accent_color(0),
                              is_dark: is_dark,
                            ),
                          ),
                          _BookshelfTabPage(
                            child: FavoriteTabContent(
                              accent_color:
                                  BookshelfLogic.resolve_tab_accent_color(1),
                              is_dark: is_dark,
                            ),
                          ),
                          _BookshelfTabPage(
                            child: FocusTabContent(
                              accent_color:
                                  BookshelfLogic.resolve_tab_accent_color(2),
                              is_dark: is_dark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            PageTopGradientOverlay(background_color: background_color),
          ],
        ),
      );
    });
  }

  /// 根据文案计算 Tab 固定宽度，避免缩放时文字抖动。
  double _measure_tab_width({
    required BuildContext context,
    required String title,
  }) {
    final TextPainter text_painter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(
          fontSize: Style.tab_selected_font_size,
          fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
          height: 1,
        ),
      ),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();

    return text_painter.width + 2;
  }
}

/// 书架页 Tab 标题组件。
class _BookshelfTab extends StatelessWidget {
  /// 当前 Tab 下标。
  final int index;

  /// Tab 标题。
  final String title;

  /// Tab 控制器。
  final TabController tab_controller;

  /// 选中文字颜色。
  final Color selected_color;

  /// 未选中文字颜色。
  final Color unselected_color;

  /// Tab 固定宽度。
  final double tab_width;

  const _BookshelfTab({
    required this.index,
    required this.title,
    required this.tab_controller,
    required this.selected_color,
    required this.unselected_color,
    required this.tab_width,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: Style.tab_bar_height,
      child: SizedBox(
        width: tab_width,
        child: Center(
          child: _BookshelfTabLabel(
            index: index,
            title: title,
            tab_controller: tab_controller,
            selected_color: selected_color,
            unselected_color: unselected_color,
          ),
        ),
      ),
    );
  }
}

/// 书架页 Tab 文案组件。
class _BookshelfTabLabel extends StatelessWidget {
  /// 当前 Tab 下标。
  final int index;

  /// Tab 标题。
  final String title;

  /// Tab 控制器。
  final TabController tab_controller;

  /// 选中文字颜色。
  final Color selected_color;

  /// 未选中文字颜色。
  final Color unselected_color;

  const _BookshelfTabLabel({
    required this.index,
    required this.title,
    required this.tab_controller,
    required this.selected_color,
    required this.unselected_color,
  });

  @override
  Widget build(BuildContext context) {
    final Animation<double>? tab_animation = tab_controller.animation;
    if (tab_animation == null) {
      return Text(
        title,
        style: TextStyle(
          fontSize: Style.tab_selected_font_size,
          fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
          color: unselected_color,
          height: 1,
        ),
        strutStyle: StrutStyle(
          fontSize: Style.tab_selected_font_size,
          fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
          height: 1,
          forceStrutHeight: true,
        ),
      );
    }

    return AnimatedBuilder(
      animation: tab_animation,
      builder: (BuildContext context, Widget? child) {
        final double tab_distance = (tab_animation.value - index).abs();
        final double tab_selected_progress = (1 - tab_distance).clamp(0.0, 1.0);
        final double current_scale =
            lerpDouble(
              Style.tab_label_font_size / Style.tab_selected_font_size,
              1,
              tab_selected_progress,
            ) ??
            1;
        final Color current_text_color =
            Color.lerp(
              unselected_color,
              selected_color,
              tab_selected_progress,
            ) ??
            unselected_color;

        return Transform.scale(
          scale: current_scale,
          alignment: Alignment.center,
          child: Transform.translate(
            offset: const Offset(0, Style.tab_label_translate_y),
            child: RepaintBoundary(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontSize: Style.tab_selected_font_size,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                  color: current_text_color,
                  height: 1,
                ),
                strutStyle: StrutStyle(
                  fontSize: Style.tab_selected_font_size,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                  height: 1,
                  forceStrutHeight: true,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 书架页单个 Tab 的滚动内容容器。
class _BookshelfTabPage extends StatelessWidget {
  /// 当前 Tab 的内容。
  final Widget child;

  const _BookshelfTabPage({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Style.page_horizontal_padding,
        Style.tab_view_top_spacing,
        Style.page_horizontal_padding,
        Style.tab_view_bottom_spacing,
      ),
      child: child,
    );
  }
}
