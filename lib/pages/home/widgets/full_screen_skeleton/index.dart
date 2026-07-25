import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:app/components/home_header_bar/index.dart';
import 'package:app/components/top_decoration/index.dart';
import 'package:app/pages/home/widgets/full_screen_skeleton/style.dart';

/// 首页全屏骨架屏组件。
///
/// 当首页分类数据正在加载时，展示全屏骨架屏，
/// 模拟首页完整的布局结构（头部、Tab栏、内容区域），
/// 让用户在数据加载期间看到页面整体框架，减少等待焦虑。
///
/// 骨架屏包含三个主要区域：
/// 1. 头部栏 - 使用真实的 HomeHeaderBar（搜索框和语言切换可正常交互）
/// 2. Tab栏骨架 - 模拟分类标签
/// 3. 内容区域骨架 - 模拟推荐页面的榜单和瀑布流卡片
class FullScreenSkeleton extends StatefulWidget {
  /// 当前是否为夜间主题。
  final bool is_dark;

  /// 搜索点击回调。
  final VoidCallback on_search_tap;

  /// 语种切换点击回调。
  final VoidCallback on_language_tap;

  const FullScreenSkeleton({
    super.key,
    required this.is_dark,
    required this.on_search_tap,
    required this.on_language_tap,
  });

  @override
  State<FullScreenSkeleton> createState() => _FullScreenSkeletonState();
}

/// 全屏骨架屏状态类。
///
/// 使用 AnimationController 驱动流动闪光动画，
/// 让骨架屏的各个元素产生渐变流动效果，提升视觉体验。
class _FullScreenSkeletonState extends State<FullScreenSkeleton>
    with SingleTickerProviderStateMixin {
  /// 骨架屏动画控制器。
  late AnimationController _animation_controller;

  @override
  void initState() {
    super.initState();
    _animation_controller = AnimationController(
      vsync: this,
      duration: FullScreenSkeletonStyle.animation_duration,
    )..repeat();
  }

  @override
  void dispose() {
    _animation_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool is_dark = widget.is_dark;
    final double status_bar_height = MediaQuery.paddingOf(context).top;
    final bool has_status_bar_spacing = !kIsWeb && status_bar_height > 0;

    /// 当前主题下的背景色。
    final Color background_color = is_dark
        ? FullScreenSkeletonStyle.dark_background_color
        : FullScreenSkeletonStyle.light_background_color;

    /// 当前主题下的面板背景色。
    final Color panel_color = is_dark
        ? FullScreenSkeletonStyle.dark_panel_color
        : FullScreenSkeletonStyle.light_panel_color;

    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        color: background_color,
        child: Stack(
          children: <Widget>[
            // 顶部装饰（与真实首页保持一致）
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: TopDecoration(is_dark: is_dark),
            ),

            // 主要内容区域
            Column(
              children: <Widget>[
                // 状态栏间距
                if (has_status_bar_spacing)
                  SizedBox(height: status_bar_height),

                // 头部栏（使用真实的 HomeHeaderBar，搜索和语言切换可正常交互）
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: HomeHeaderBar(
                    is_dark: is_dark,
                    on_search_tap: widget.on_search_tap,
                    on_language_tap: widget.on_language_tap,
                  ),
                ),

                // Tab栏骨架（使用 Transform.translate 模拟真实首页的偏移效果）
                Transform.translate(
                  offset: const Offset(0, FullScreenSkeletonStyle.tab_bar_top_offset),
                  child: SizedBox(
                    width: double.infinity,
                    height: FullScreenSkeletonStyle.tab_bar_height,
                    child: _build_tab_bar_skeleton(is_dark: is_dark),
                  ),
                ),

                // 内容区域骨架
                Expanded(
                  child: _build_content_skeleton(
                    is_dark: is_dark,
                    panel_color: panel_color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建 Tab 栏骨架。
  ///
  /// 模拟 HomeTabBar 的布局，展示多个 Tab 项骨架。
  Widget _build_tab_bar_skeleton({required bool is_dark}) {
    /// 当前主题下的骨架底色。
    final Color base_color = is_dark
        ? FullScreenSkeletonStyle.dark_base_color
        : FullScreenSkeletonStyle.light_base_color;

    /// 当前主题下的骨架高亮色。
    final Color highlight_color = is_dark
        ? FullScreenSkeletonStyle.dark_highlight_color
        : FullScreenSkeletonStyle.light_highlight_color;

    return AnimatedBuilder(
      animation: _animation_controller,
      builder: (BuildContext context, Widget? child) {
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 16),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: FullScreenSkeletonStyle.tab_item_count,
          itemBuilder: (BuildContext context, int index) {
            final double item_width = FullScreenSkeletonStyle.tab_item_width_list[
                index % FullScreenSkeletonStyle.tab_item_width_list.length];

            final double shimmer_offset = _animation_controller.value;
            final double item_delay = index * 0.1;
            final double adjusted_offset = (shimmer_offset + item_delay) % 1.0;

            final double t = adjusted_offset < 0.5
                ? adjusted_offset * 2
                : (1.0 - adjusted_offset) * 2;

            final Color item_color = Color.lerp(
              base_color,
              highlight_color,
              t,
            )!;

            return Container(
              margin: const EdgeInsets.only(
                right: FullScreenSkeletonStyle.tab_item_spacing,
              ),
              width: item_width,
              height: FullScreenSkeletonStyle.tab_item_height,
              decoration: BoxDecoration(
                color: item_color,
                borderRadius: BorderRadius.circular(
                  FullScreenSkeletonStyle.tab_item_radius,
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 构建内容区域骨架。
  ///
  /// 模拟推荐页面的布局，包含榜单区域和瀑布流卡片区域。
  Widget _build_content_skeleton({
    required bool is_dark,
    required Color panel_color,
  }) {
    /// 当前主题下的骨架底色。
    final Color base_color = is_dark
        ? FullScreenSkeletonStyle.dark_base_color
        : FullScreenSkeletonStyle.light_base_color;

    /// 当前主题下的骨架高亮色。
    final Color highlight_color = is_dark
        ? FullScreenSkeletonStyle.dark_highlight_color
        : FullScreenSkeletonStyle.light_highlight_color;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FullScreenSkeletonStyle.content_horizontal_padding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 榜单区域骨架
            _build_ranking_section_skeleton(
              is_dark: is_dark,
              panel_color: panel_color,
              base_color: base_color,
              highlight_color: highlight_color,
            ),

            const SizedBox(height: FullScreenSkeletonStyle.section_spacing),

            // 推荐卡片瀑布流骨架
            _build_waterfall_skeleton(
              is_dark: is_dark,
              base_color: base_color,
              highlight_color: highlight_color,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 构建榜单区域骨架。
  ///
  /// 模拟推荐页面的榜单区域，包含 Tab 栏和列表项。
  Widget _build_ranking_section_skeleton({
    required bool is_dark,
    required Color panel_color,
    required Color base_color,
    required Color highlight_color,
  }) {
    return AnimatedBuilder(
      animation: _animation_controller,
      builder: (BuildContext context, Widget? child) {
        return Container(
          width: double.infinity,
          height: FullScreenSkeletonStyle.ranking_section_height,
          decoration: BoxDecoration(
            color: panel_color,
            borderRadius: BorderRadius.circular(
              FullScreenSkeletonStyle.ranking_section_radius,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: <Widget>[
              // Tab 栏骨架（模拟榜单分类 Tab）
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                child: Container(
                  height: FullScreenSkeletonStyle.ranking_tab_bar_height,
                  padding: const EdgeInsets.only(top: 20),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    itemBuilder: (BuildContext context, int index) {
                      final List<double> tab_widths = [40.0, 52.0, 48.0, 44.0];
                      final double shimmer_offset = _animation_controller.value;
                      final double item_delay = index * 0.1;
                      final double adjusted_offset = (shimmer_offset + item_delay) % 1.0;
                      final double t = adjusted_offset < 0.5
                          ? adjusted_offset * 2
                          : (1.0 - adjusted_offset) * 2;

                      final Color item_color = Color.lerp(
                        base_color,
                        highlight_color,
                        t,
                      )!;

                      return Container(
                        margin: const EdgeInsets.only(right: 20),
                        width: tab_widths[index],
                        height: 20,
                        decoration: BoxDecoration(
                          color: item_color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 列表项骨架（模拟榜单书籍列表，双列布局）
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
                  child: Column(
                    children: List<Widget>.generate(2, (int row_index) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: row_index < 1
                                ? FullScreenSkeletonStyle.ranking_item_spacing
                                : 0,
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: _build_ranking_item_skeleton(
                                  base_color: base_color,
                                  highlight_color: highlight_color,
                                  delay: 0.2 + row_index * 2 * 0.1,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _build_ranking_item_skeleton(
                                  base_color: base_color,
                                  highlight_color: highlight_color,
                                  delay: 0.2 + (row_index * 2 + 1) * 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建单个榜单列表项骨架。
  ///
  /// 模拟榜单书籍项的布局，包含封面、排名序号和书籍信息。
  Widget _build_ranking_item_skeleton({
    required Color base_color,
    required Color highlight_color,
    double delay = 0,
  }) {
    return AnimatedBuilder(
      animation: _animation_controller,
      builder: (BuildContext context, Widget? child) {
        return SizedBox(
          height: FullScreenSkeletonStyle.ranking_item_height,
          child: Row(
            children: <Widget>[
              // 封面骨架
              _build_skeleton_bar(
                width: 48,
                height: 60,
                radius: 4,
                base_color: base_color,
                highlight_color: highlight_color,
                animation_value: _animation_controller.value,
                delay: delay,
              ),

              const SizedBox(width: 4),

              // 排名序号骨架
              _build_skeleton_bar(
                width: 18,
                height: 14,
                radius: 2,
                base_color: base_color,
                highlight_color: highlight_color,
                animation_value: _animation_controller.value,
                delay: delay + 0.05,
              ),

              const SizedBox(width: 4),

              // 书籍信息骨架
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // 书名骨架
                    _build_skeleton_bar(
                      width: double.infinity,
                      height: 14,
                      radius: 3,
                      base_color: base_color,
                      highlight_color: highlight_color,
                      animation_value: _animation_controller.value,
                      delay: delay + 0.1,
                    ),

                    const SizedBox(height: 8),

                    // 分类/热度骨架
                    _build_skeleton_bar(
                      width: 80,
                      height: 11,
                      radius: 2,
                      base_color: base_color,
                      highlight_color: highlight_color,
                      animation_value: _animation_controller.value,
                      delay: delay + 0.15,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建瀑布流卡片骨架。
  ///
  /// 模拟推荐页面的瀑布流布局，展示多张不同高度的卡片骨架。
  Widget _build_waterfall_skeleton({
    required bool is_dark,
    required Color base_color,
    required Color highlight_color,
  }) {
    return AnimatedBuilder(
      animation: _animation_controller,
      builder: (BuildContext context, Widget? child) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 左列
            Expanded(
              child: Column(
                children: List<Widget>.generate(3, (int index) {
                  final int card_index = index * 2;
                  final double card_height = FullScreenSkeletonStyle.card_height_list[
                      card_index % FullScreenSkeletonStyle.card_height_list.length];

                  return Padding(
                    padding: EdgeInsets.only(
                      right: FullScreenSkeletonStyle.card_spacing / 2,
                      bottom: FullScreenSkeletonStyle.card_spacing,
                    ),
                    child: _build_card_skeleton(
                      height: card_height,
                      base_color: base_color,
                      highlight_color: highlight_color,
                      animation_value: _animation_controller.value,
                      delay: 0.3 + index * 0.15,
                    ),
                  );
                }),
              ),
            ),

            // 右列
            Expanded(
              child: Column(
                children: List<Widget>.generate(3, (int index) {
                  final int card_index = index * 2 + 1;
                  final double card_height = FullScreenSkeletonStyle.card_height_list[
                      card_index % FullScreenSkeletonStyle.card_height_list.length];

                  return Padding(
                    padding: EdgeInsets.only(
                      left: FullScreenSkeletonStyle.card_spacing / 2,
                      bottom: FullScreenSkeletonStyle.card_spacing,
                    ),
                    child: _build_card_skeleton(
                      height: card_height,
                      base_color: base_color,
                      highlight_color: highlight_color,
                      animation_value: _animation_controller.value,
                      delay: 0.35 + index * 0.15,
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建单张卡片骨架。
  ///
  /// 模拟推荐卡片的布局，包含封面区域和文字区域。
  Widget _build_card_skeleton({
    required double height,
    required Color base_color,
    required Color highlight_color,
    required double animation_value,
    double delay = 0,
  }) {
    /// 卡片封面区域高度（占卡片总高度的70%）。
    final double cover_height = height * 0.7;

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          FullScreenSkeletonStyle.card_radius,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          // 封面区域骨架
          _build_skeleton_bar(
            width: double.infinity,
            height: cover_height,
            radius: 0,
            base_color: base_color,
            highlight_color: highlight_color,
            animation_value: animation_value,
            delay: delay,
          ),

          // 文字区域骨架
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(FullScreenSkeletonStyle.card_bottom_padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // 标题骨架
                  _build_skeleton_bar(
                    width: double.infinity,
                    height: FullScreenSkeletonStyle.card_title_height,
                    radius: FullScreenSkeletonStyle.card_title_radius,
                    base_color: base_color,
                    highlight_color: highlight_color,
                    animation_value: animation_value,
                    delay: delay + 0.05,
                  ),

                  const SizedBox(height: 6),

                  // 副标题骨架
                  _build_skeleton_bar(
                    width: 60,
                    height: FullScreenSkeletonStyle.card_subtitle_height,
                    radius: FullScreenSkeletonStyle.card_subtitle_radius,
                    base_color: base_color,
                    highlight_color: highlight_color,
                    animation_value: animation_value,
                    delay: delay + 0.1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建骨架条。
  ///
  /// 通用方法，用于创建带有流动闪光效果的骨架条。
  ///
  /// 参数：
  /// - [width] 骨架条宽度
  /// - [height] 骨架条高度
  /// - [radius] 骨架条圆角
  /// - [base_color] 骨架条底色
  /// - [highlight_color] 骨架条高亮色
  /// - [animation_value] 动画当前值
  /// - [delay] 动画延迟（0-1之间，用于错开不同元素的动画）
  Widget _build_skeleton_bar({
    required double width,
    required double height,
    required double radius,
    required Color base_color,
    required Color highlight_color,
    required double animation_value,
    double delay = 0,
  }) {
    /// 调整后的动画值，考虑延迟。
    final double adjusted_value = (animation_value + delay) % 1.0;

    /// 计算当前高亮强度（0-1之间）。
    final double t = adjusted_value < 0.5
        ? adjusted_value * 2
        : (1.0 - adjusted_value) * 2;

    /// 当前骨架条颜色。
    final Color color = Color.lerp(base_color, highlight_color, t)!;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
