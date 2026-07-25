import 'dart:ui';
import 'package:app/config/font_config.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app/config/color_config.dart';
import 'package:app/pages/home/widgets/home_tab_bar/style.dart';
import 'package:app/stores/home_store.dart';
import 'package:app/stores/redis_request.dart';
import 'package:app/models/home_classification.dart';
import 'package:app/util/language_util/index.dart';

/// 默认 Tab 标题列表（当接口数据未加载时使用）。
const List<String> kDefaultTabTitles = [
  '推荐',
  '小说',
  '听书',
  '看剧',
  '经典',
  '短篇',
  '漫剧',
  '少儿',
  '相声',
  '评书',
  '广播剧',
];

/// 获取当前 Tab 标题列表。
List<String> get_titles() {
  try {
    final HomeBannerStore home_store = Get.find<HomeBannerStore>();
    final List<HomeClassification> list = home_store.home_classification_list;
    if (list.isNotEmpty) {
      return list.map((e) => e.title).toList();
    }
  } catch (_) {}
  return kDefaultTabTitles;
}

/// 首页 Tab 标题栏组件。
///
/// 根据当前语种自动适配字号、间距和缩放比例：
/// - CJK 语系（中文/日文/韩文）使用较大的字号和宽松的间距。
/// - 非 CJK 语系（英语等拉丁字母语种）使用较小的字号和紧凑的间距，
///   避免单词过长导致 Tab 栏溢出。
class HomeTabBar extends StatefulWidget {
  /// Tab 控制器。
  final TabController tab_controller;

  /// 当前是否为夜间主题。
  final bool is_dark;

  /// 当前语种代码，用于判断是否为 CJK 语系。
  final String language_code;

  const HomeTabBar({
    super.key,
    required this.tab_controller,
    required this.is_dark,
    required this.language_code,
  });

  @override
  State<HomeTabBar> createState() => _HomeTabBarState();
}

class _HomeTabBarState extends State<HomeTabBar> {
  @override
  void initState() {
    super.initState();
    widget.tab_controller.addListener(_on_tab_changed);
  }

  @override
  void didUpdateWidget(covariant HomeTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab_controller != widget.tab_controller) {
      oldWidget.tab_controller.removeListener(_on_tab_changed);
      widget.tab_controller.addListener(_on_tab_changed);
    }
  }

  @override
  void dispose() {
    widget.tab_controller.removeListener(_on_tab_changed);
    super.dispose();
  }

  void _on_tab_changed() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<String> titles = get_titles();
    final bool is_dark = widget.is_dark;
    final TabController controller = widget.tab_controller;

    /// redis/get 请求中时禁止切换 Tab。
    final bool is_loading = Get.find<RedisRequestStore>().is_fetching;

    /// 根据语种判断是否为 CJK，选择对应的字号和间距。
    final bool is_cjk = LanguageUtil.is_cjk_language(widget.language_code);
    final double font_size = is_cjk
        ? HomeTabBarStyle.tab_title_font_size_cjk
        : HomeTabBarStyle.tab_title_font_size_alphabetic;
    final double label_padding_left = is_cjk
        ? HomeTabBarStyle.tab_label_padding_left_cjk
        : HomeTabBarStyle.tab_label_padding_left_alphabetic;
    final double padding_right = is_cjk
        ? HomeTabBarStyle.tab_padding_right_cjk
        : HomeTabBarStyle.tab_padding_right_alphabetic;

    final Color unselected_color = is_dark
        ? HomeTabBarStyle.unselected_dark_color
        : HomeTabBarStyle.unselected_light_color;

    final Color gradient_color = is_dark
        ? ColorConstants.nightBackgroundColor
        : const Color(0xFFF6F7FB);

    return IgnorePointer(
      ignoring: is_loading,
      child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerLeft,
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: TabBar(
            controller: controller,
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
              width: 3,
              color: ColorConstants.themeColor,
            ),
            insets: const EdgeInsets.only(bottom: 4),
          ),
          dividerHeight: 0,
          tabAlignment: TabAlignment.start,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: List<Widget>.generate(
            titles.length,
            (int index) => _build_tab_item(
              index: index,
              title: titles[index],
              is_cjk: is_cjk,
              font_size: font_size,
            ),
          ),
          ),
        ),

        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              width: HomeTabBarStyle.gradient_width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: <Color>[
                    gradient_color,
                    gradient_color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),

        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              width: HomeTabBarStyle.gradient_width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: <Color>[
                    gradient_color,
                    gradient_color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    );
  }

  /// 构建单个 Tab 项。
  ///
  /// [index] Tab 索引。
  /// [title] Tab 标题文字。
  /// [is_cjk] 当前语种是否为 CJK。
  /// [font_size] 当前语种对应的字号。
  Widget _build_tab_item({
    required int index,
    required String title,
    required bool is_cjk,
    required double font_size,
  }) {
    final Color selected_color =
        widget.is_dark ? Colors.white : Colors.black;

    final Color unselected_color = widget.is_dark
        ? HomeTabBarStyle.unselected_dark_color
        : HomeTabBarStyle.unselected_light_color;

    /// 根据语种选择缩放比例。
    final double selected_scale = is_cjk
        ? HomeTabBarStyle.tab_selected_scale_cjk
        : HomeTabBarStyle.tab_selected_scale_alphabetic;

    return AnimatedBuilder(
      animation: widget.tab_controller.animation!,
      builder: (BuildContext context, Widget? child) {
        final double animation_value =
            widget.tab_controller.animation!.value;

        final double distance = (animation_value - index).abs();
        final double t = distance.clamp(0.0, 1.0);

        // 缩放：直接用距离计算
        final double scale = lerpDouble(selected_scale, 1.0, t) ?? 1.0;

        // 颜色：线性插值
        final Color text_color = Color.lerp(
                selected_color, unselected_color, t) ??
            unselected_color;

        return Transform.scale(
          scale: scale,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 10,
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
