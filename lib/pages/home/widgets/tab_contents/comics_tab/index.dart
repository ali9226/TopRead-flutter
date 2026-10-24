// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

import 'package:app/components/category_filter/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/components/fixed_bottom_navigation/style.dart'
    as fixed_nav_style;
import 'package:app/components/floating_back_to_top/index.dart';
import 'package:app/components/floating_back_to_top/style.dart'
    as floating_back_to_top_style;
import 'package:app/components/load_more_footer/index.dart';
import 'package:app/pages/comics/logic.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/pages/comics/widgets/comics_grid.dart';
import 'package:app/pages/comics/widgets/empty_state.dart';
import 'package:app/pages/comics/widgets/grid_skeleton.dart';
import 'package:app/pages/home/widgets/tab_contents/comics_tab/logic.dart';
import 'package:app/pages/home/widgets/tab_contents/comics_tab/style.dart';

/// 首页「漫画」分类 Tab 内容组件（classification id = 146）。
///
/// 与短篇 Tab 共用同一套分类筛选交互（横栏 + 弹窗，单选），
/// 列表使用瀑布流卡片展示漫画作品，支持下拉刷新与滚动加载。
class ComicsTabContent extends StatefulWidget {
  const ComicsTabContent({super.key});

  @override
  State<ComicsTabContent> createState() => _ComicsTabContentState();
}

class _ComicsTabContentState extends State<ComicsTabContent>
    with AutomaticKeepAliveClientMixin {
  /// Tab 切走后保留滚动位置与已加载数据。
  @override
  bool get wantKeepAlive => true;

  /// 漫画列表分页、分类筛选逻辑，复用漫画浏览实现。
  late final ComicsBrowseLogic _logic = ComicsBrowseLogic();

  /// 列表滚动控制器，用于触发加载更多和回到顶部。
  final ScrollController _scroll_controller = ScrollController();

  /// 分类横栏滚动控制器。
  final ScrollController _category_scroll_controller = ScrollController();

  /// 是否展示「回到顶部」浮层。
  bool _is_back_to_top_visible = false;

  @override
  void initState() {
    super.initState();
    // 拉取分类与首页漫画列表。
    _logic.load_categories();
    _logic.load();
    _scroll_controller.addListener(_handle_scroll);
  }

  @override
  void dispose() {
    _scroll_controller.removeListener(_handle_scroll);
    _scroll_controller.dispose();
    _category_scroll_controller.dispose();
    _logic.dispose();
    super.dispose();
  }

  /// 滚动事件处理：触底自动加载更多、控制回到顶部浮层显隐。
  void _handle_scroll() {
    if (!_scroll_controller.hasClients) return;

    // 距底部小于阈值时预加载下一页。
    if (_scroll_controller.position.extentAfter <
        ComicsTabStyle.load_more_trigger_distance) {
      _logic.load(more: true);
    }

    // 滑过一屏后展示回到顶部按钮。
    final bool should_show =
        _scroll_controller.position.pixels >
        _scroll_controller.position.viewportDimension;
    if (should_show != _is_back_to_top_visible) {
      setState(() => _is_back_to_top_visible = should_show);
    }
  }

  /// 滚动回到列表顶部。
  void _scroll_to_top() {
    _scroll_controller.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// 下拉刷新：同时重试分类与列表。
  Future<void> _on_refresh() => _logic.refresh();

  /// 分类筛选回调：把选中的分类 id 映射为列表过滤条件。
  ///
  /// [category_id] 筛选组件回调值，null 表示未选中。
  void _on_category_changed(int? category_id) {
    _logic.select_category(ComicsTabLogic.to_filter_category_id(category_id));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 要求调用

    return AnimatedBuilder(
      animation: _logic,
      builder: (BuildContext context, Widget? child) {
        final bool is_dark = ComicsStyle.is_dark(context);

        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: Column(
                children: <Widget>[
                  /// 分类筛选栏：与短篇 Tab 同款交互，单选。
                  CategoryFilter(
                    on_category_changed: _on_category_changed,
                    category_scroll_controller: _category_scroll_controller,
                    categories: ComicsTabLogic.to_preference_items(
                      context,
                      _logic.categories,
                    ),
                    is_loading: !_logic.categories_loaded,
                  ),

                  /// 漫画列表主体。
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _on_refresh,
                      color: ColorConstants.themeColor,
                      child: _build_body(context, is_dark),
                    ),
                  ),
                ],
              ),
            ),

            /// 回到顶部浮层。
            FloatingBackToTop(
              show: _is_back_to_top_visible,
              isDark: is_dark,
              onTap: _scroll_to_top,
              visibleBottom:
                  fixed_nav_style.Style.bar_height +
                  floating_back_to_top_style
                      .FloatingBackToTopStyle
                      .offset_from_bottom_nav +
                  MediaQuery.paddingOf(context).bottom,
              hiddenBottom:
                  fixed_nav_style.Style.bar_height +
                  floating_back_to_top_style
                      .FloatingBackToTopStyle
                      .hidden_offset +
                  MediaQuery.paddingOf(context).bottom,
            ),
          ],
        );
      },
    );
  }

  /// 列表主体：首屏骨架 / 空态 / 加载失败 / 漫画瀑布流。
  ///
  /// [context] 用于读取主题。
  /// [is_dark] 当前是否夜间模式，传递给底部加载组件。
  Widget _build_body(BuildContext context, bool is_dark) {
    // 首屏加载中展示流光骨架屏，与真实卡片结构一致，加载完成零跳动。
    if (_logic.items.isEmpty && _logic.loading) {
      return CustomScrollView(
        controller: _scroll_controller,
        physics: ComicsTabStyle.list_scroll_physics,
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: LayoutConfig.page_horizontal_padding,
            ),
            sliver: SliverToBoxAdapter(
              child: ComicsGridSkeleton(is_dark: is_dark),
            ),
          ),
        ],
      );
    }

    // 仅在列表为空时展示空态；下拉刷新和分类切换保留已有内容，避免整屏闪烁。
    if (_logic.items.isEmpty) {
      return CustomScrollView(
        controller: _scroll_controller,
        physics: ComicsTabStyle.list_scroll_physics,
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: ComicsEmptyState(
              loading: _logic.loading,
              error: _logic.error,
              message: easy.tr('comics.empty_discover'),
              on_retry: _logic.refresh,
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      controller: _scroll_controller,
      physics: ComicsTabStyle.list_scroll_physics,
      slivers: <Widget>[
        /// 漫画瀑布流网格。
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: LayoutConfig.page_horizontal_padding,
          ),
          sliver: ComicsGrid(items: _logic.items),
        ),

        /// 底部加载更多 / 没有更多。
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              top: ComicsStyle.large_gap,
              bottom:
                  ComicsTabStyle.list_bottom_base +
                  MediaQuery.paddingOf(context).bottom,
            ),
            child: LoadMoreFooter(
              is_dark: is_dark,
              is_loading: _logic.loading_more,
              has_more: _logic.has_more,
              on_load_more: () => _logic.load(more: true),
            ),
          ),
        ),
      ],
    );
  }
}
