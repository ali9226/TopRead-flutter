import 'dart:ui';
import 'package:app/config/font_config.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/page_background_decor/index.dart';
import 'package:app/components/page_top_gradient_overlay/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/home/widgets/tab_contents/short_story_tab/index.dart';
import 'package:app/pages/ranking_full_list/logic.dart';
import 'package:app/pages/ranking_full_list/style.dart';
import 'package:app/pages/ranking_full_list/widgets/bookshelf_tab_content.dart';
import 'package:app/pages/ranking_full_list/widgets/starfield_decoration.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/home_store.dart';
import 'package:app/util/language_util/index.dart';

/// 完整榜单页面。
///
/// 基于书架页面结构重构，支持 Tab 切换和书籍列表展示。
/// 接收 [initial_tab_id] 参数，用于从首页跳转时定位到对应分类。
class RankingFullListPage extends StatefulWidget {
  /// 从外部传入的初始 Tab id，用于跳转时定位到对应分类。
  /// 如果为 0 或不匹配任何分类，则默认选中第一个。
  final int initial_tab_id;

  /// 从外部传入的初始分类 id，用于筛选推荐榜等。
  final int initial_category_id;

  const RankingFullListPage({
    super.key,
    this.initial_tab_id = 0,
    this.initial_category_id = 0,
  });

  @override
  State<RankingFullListPage> createState() => _RankingFullListPageState();
}

class _RankingFullListPageState extends State<RankingFullListPage>
    with SingleTickerProviderStateMixin {
  /// 设备信息仓库。
  final DeviceInfo device_info = Get.find<DeviceInfo>();

  /// 首页数据仓库（获取推荐页面的榜单 tab 数据）。
  final HomeBannerStore home_store = Get.find<HomeBannerStore>();

  /// 榜单 tab 标题列表。
  late final List<String> _tab_title_list;

  /// 榜单 tab id 列表。
  late final List<int> _tab_id_list;

  /// Tab 控制器。
  late final TabController _tab_controller;

  @override
  void initState() {
    super.initState();

    // 从 HomeBannerStore 获取推荐页面的榜单 tab 标题和 id
    if (home_store.rankings_list.isNotEmpty) {
      _tab_title_list = home_store.rankings_list.map((e) => e.title).toList();
      _tab_id_list = home_store.rankings_list.map((e) => e.id).toList();
    } else {
      _tab_title_list = <String>['推荐', '畅销', '新书', '完结'];
      _tab_id_list = <int>[0, 0, 0, 0];
    }

    _tab_controller = RankingFullListLogic.create_tab_controller(
      vsync: this,
      length: _tab_title_list.length,
    )..addListener(_on_tab_change);

    // 根据传入的 initial_tab_id 定位到对应分类
    final int initial_index = _resolve_initial_tab_index();
    if (initial_index > 0 && initial_index < _tab_title_list.length) {
      _tab_controller.index = initial_index;
    }
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

  /// 根据 [initial_tab_id] 解析初始 Tab 索引。
  ///
  /// 如果 id 为 0 或不匹配任何分类，则返回 0（默认选中第一个）。
  int _resolve_initial_tab_index() {
    if (widget.initial_tab_id == 0) {
      return 0;
    }

    final int match_index = _tab_id_list.indexOf(widget.initial_tab_id);
    return match_index >= 0 ? match_index : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      /// 当前是否为夜间主题。
      final bool is_dark = device_info.theme.value == ThemeMode.dark;

      /// 主标题颜色。
      final Color title_color = is_dark
          ? ColorConstants.whiteColor
          : ColorConstants.lightTextColor;

      /// 辅助文本颜色。
      final Color subtitle_color = is_dark
          ? ColorConstants.whiteColor.withValues(alpha: 0.62)
          : ColorConstants.hintColor;

      /// 页面背景颜色。
      final Color background_color = is_dark
          ? ColorConstants.nightBackgroundColor
          : const Color(0xFFF6F7FB);

    return Scaffold(
      backgroundColor: background_color,
      body: Stack(
        children: <Widget>[
          PageBackgroundDecor(is_dark: is_dark),
          /// 顶部星星点缀装饰。
          StarfieldDecoration(is_dark: is_dark),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  height: Style.logged_in_top_spacing,
                ),
                _build_tab_bar(
                  is_dark: is_dark,
                  title_color: title_color,
                  subtitle_color: subtitle_color,
                  background_color: background_color,
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tab_controller,
                    children: List<Widget>.generate(
                      _tab_title_list.length,
                      (int index) {
                        /// 短篇榜（id=157）使用首页短篇 Tab 的子组件。
                        if (_tab_id_list[index] == 157) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              top: Style.tab_view_top_spacing,
                            ),
                            child: const ShortStoryTabContent(),
                          );
                        }

                        // 只有当前选中的 tab 才传入 initial_category_id
                        final bool is_selected_tab = index == _tab_controller.index;
                        final int? category_id = is_selected_tab && widget.initial_category_id > 0
                            ? widget.initial_category_id
                            : null;

                        return _RankingTabPage(
                          child: BookshelfTabContent(
                            ranking_tab_id: _tab_id_list[index],
                            accent_color:
                                RankingFullListLogic.resolve_tab_accent_color(index),
                            is_dark: is_dark,
                            initial_category_id: category_id,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          PageTopGradientOverlay(background_color: background_color),
        ],
      ),
    );
    });
  }

  /// 构建 Tab 栏，支持语种适配。
  Widget _build_tab_bar({
    required bool is_dark,
    required Color title_color,
    required Color subtitle_color,
    required Color background_color,
  }) {
    /// 根据语种判断是否为 CJK，选择对应的字号、间距和缩放比例。
    final bool is_cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    final double font_size = is_cjk
        ? Style.tab_title_font_size_cjk
        : Style.tab_title_font_size_alphabetic;
    final double label_padding_left = is_cjk
        ? Style.tab_label_padding_left_cjk
        : Style.tab_label_padding_left_alphabetic;
    final double padding_right = is_cjk
        ? Style.tab_padding_right_cjk
        : Style.tab_padding_right_alphabetic;
    final double selected_scale = is_cjk
        ? Style.tab_selected_scale_cjk
        : Style.tab_selected_scale_alphabetic;

    final Color unselected_color = is_dark
        ? Style.unselected_dark_color
        : Style.unselected_light_color;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerLeft,
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: TabBar(
            controller: _tab_controller,
            isScrollable: true,
            labelPadding: EdgeInsets.only(left: label_padding_left),
            padding: EdgeInsets.only(right: padding_right),
            labelStyle: TextStyle(
              fontSize: font_size,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: font_size,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
            ),
            labelColor: is_dark ? Colors.white : Colors.black,
            unselectedLabelColor: unselected_color,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                width: Style.tab_indicator_height,
                color: ColorConstants.themeColor,
              ),
              insets: const EdgeInsets.only(
                bottom: Style.tab_indicator_bottom_offset,
              ),
            ),
            dividerHeight: 0,
            tabAlignment: TabAlignment.start,
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            tabs: List<Widget>.generate(
              _tab_title_list.length,
              (int index) => _build_tab_item(
                index: index,
                title: _tab_title_list[index],
                is_cjk: is_cjk,
                font_size: font_size,
                selected_scale: selected_scale,
                is_dark: is_dark,
                unselected_color: unselected_color,
              ),
            ),
          ),
        ),
        // 左侧渐变遮罩
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              width: Style.gradient_width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: <Color>[
                    background_color,
                    background_color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        // 右侧渐变遮罩
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              width: Style.gradient_width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: <Color>[
                    background_color,
                    background_color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建单个 Tab 项。
  Widget _build_tab_item({
    required int index,
    required String title,
    required bool is_cjk,
    required double font_size,
    required double selected_scale,
    required bool is_dark,
    required Color unselected_color,
  }) {
    final Color selected_color = is_dark ? Colors.white : Colors.black;

    return AnimatedBuilder(
      animation: _tab_controller.animation!,
      builder: (BuildContext context, Widget? child) {
        final double animation_value = _tab_controller.animation!.value;
        final double distance = (animation_value - index).abs();
        final double t = distance.clamp(0.0, 1.0);

        // 缩放：直接用距离计算
        final double scale = lerpDouble(selected_scale, 1.0, t) ?? 1.0;

        // 颜色：线性插值
        final Color text_color =
            Color.lerp(selected_color, unselected_color, t) ??
                unselected_color;

        return Transform.scale(
          scale: scale,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 6,
            ),
            child: Text(
              title,
              maxLines: 1,
              style: TextStyle(
                fontSize: font_size,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                color: text_color,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 完整榜单页单个 Tab 的滚动内容容器。
class _RankingTabPage extends StatelessWidget {
  /// 当前 Tab 的内容。
  final Widget child;

  /// 是否应用内边距（短篇榜等自带内边距的组件设为 false）。
  final bool apply_padding;

  const _RankingTabPage({
    required this.child,
    this.apply_padding = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!apply_padding) {
      return child;
    }

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
