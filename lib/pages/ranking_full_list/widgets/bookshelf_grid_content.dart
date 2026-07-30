import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/api/post_request.dart';
import 'package:app/components/category_filter/index.dart';
import 'package:app/components/fixed_bottom_navigation/style.dart'
    as fixed_nav_style;
import 'package:app/components/floating_back_to_top/index.dart';
import 'package:app/components/floating_back_to_top/style.dart'
    as floating_back_to_top_style;
import 'package:app/components/load_more_footer/index.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/models/recommend_ranking_item.dart';
import 'package:app/pages/ranking_full_list/logic.dart';
import 'package:app/pages/ranking_full_list/style.dart';
import 'package:app/pages/ranking_full_list/widgets/bookshelf_book_card.dart';
import 'package:app/stores/ranking_full_list_store.dart';
import 'package:app/util/novel_navigation/index.dart';

/// 完整榜单网格内容组件。
///
/// 根据 [ranking_tab_id] 请求不同的后端接口获取真实数据，
/// 支持分类筛选和分页加载。
///
/// 缓存策略：
/// - Tab切换时保留每个Tab的选中分类和已加载数据
/// - 同Tab内切换分类时缓存每个分类的数据
/// - 使用请求版本号解决异步竞态问题
class BookshelfGridContent extends StatefulWidget {
  /// 榜单 Tab id，决定请求哪个接口。
  final int ranking_tab_id;

  /// 当前顶部 Tab 的强调色。
  final Color accent_color;

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 初始选中的分类 id（可选，用于从外部传入默认选中项）。
  final int? initial_category_id;

  const BookshelfGridContent({
    super.key,
    required this.ranking_tab_id,
    required this.accent_color,
    required this.is_dark,
    this.initial_category_id,
  });

  @override
  State<BookshelfGridContent> createState() => _BookshelfGridContentState();
}

class _BookshelfGridContentState extends State<BookshelfGridContent> {
  /// 内容滚动控制器。
  final ScrollController _scroll_controller = ScrollController();

  /// 当前可见数据列表。
  List<RecommendRankingItem> _visible_book_list = <RecommendRankingItem>[];

  /// 当前是否处于首屏加载。
  bool _is_initial_loading = true;

  /// 当前是否处于加载更多。
  bool _is_loading_more = false;

  /// 返回顶部按钮是否可见。
  bool _is_back_to_top_visible = false;

  /// 是否还有更多数据可加载。
  bool _has_more = true;

  /// 当前选中的分类 id（null 表示未筛选）。
  int? _selected_category_id;

  /// 请求版本号，用于解决异步竞态问题。
  ///
  /// 每次发起新请求时递增，请求返回时检查版本号是否匹配，
  /// 不匹配则丢弃结果，避免旧请求覆盖新数据。
  int _request_version = 0;

  /// 距离底部多少像素时触发自动加载更多。
  static const double _load_more_trigger_distance = 180;

  /// 每次加载的数据量。
  static const int _page_size = 20;

  /// 标签颜色池。
  static const List<Color> _tag_color_pool = <Color>[
    Color(0xFF2FBF9B),
    Color(0xFF5F8BFF),
    Color(0xFFF56C6C),
    Color(0xFFFF9F5A),
    Color(0xFF8B7CFF),
    Color(0xFFE6A23C),
  ];

  /// 缓存仓库。
  final RankingFullListStore _store = Get.find<RankingFullListStore>();

  @override
  void initState() {
    super.initState();
    _scroll_controller.addListener(_handle_scroll);

    // 初始化选中分类
    final int? cached_category = _store.get_selected_category_id(
      widget.ranking_tab_id,
    );
    if (cached_category != null) {
      _selected_category_id = cached_category;
    } else if (widget.initial_category_id != null &&
        widget.initial_category_id! > 0) {
      _selected_category_id = widget.initial_category_id;
      _store.set_selected_category_id(
        widget.ranking_tab_id,
        _selected_category_id,
      );
    }

    // 尝试从缓存加载数据
    _load_from_cache_or_network();
  }

  @override
  void dispose() {
    _scroll_controller.removeListener(_handle_scroll);
    _scroll_controller.dispose();
    super.dispose();
  }

  /// 从缓存加载数据，如果缓存不存在则从网络加载。
  void _load_from_cache_or_network() {
    final RankingCategoryCache? cache = _get_current_cache();
    if (cache != null) {
      // 缓存存在，直接使用
      setState(() {
        _visible_book_list = List<RecommendRankingItem>.from(cache.items);
        _has_more = cache.has_more;
        _is_initial_loading = false;
      });
    } else {
      // 缓存不存在，从网络加载
      _load_initial_data();
    }
  }

  /// 获取当前分类的缓存数据。
  RankingCategoryCache? _get_current_cache() {
    return _store.get_category_cache(
      widget.ranking_tab_id,
      _selected_category_id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int grid_count = RankingFullListLogic.resolve_grid_count(
          constraints.maxWidth,
        );

        final double item_width =
            (constraints.maxWidth -
                (grid_count - 1) * Style.grid_cross_spacing) /
            grid_count;

        /// 使用当前设备真实文字缩放比例计算内容高度，避免标题或分类信息被裁剪。
        final double content_area_height =
            Style.resolve_book_content_area_height(
              MediaQuery.textScalerOf(context),
            );

        final double item_height =
            item_width / Style.cover_aspect_ratio + content_area_height;

        return Column(
          children: <Widget>[
            CategoryFilter(
              initial_category_id:
                  _selected_category_id ?? widget.initial_category_id,
              on_category_changed: _handle_category_changed,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handle_refresh,
                child: Stack(
                  children: <Widget>[
                    CustomScrollView(
                      controller: _scroll_controller,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: <Widget>[
                        if (_is_initial_loading)
                          SliverGrid(
                            delegate: SliverChildBuilderDelegate((
                              BuildContext context,
                              int index,
                            ) {
                              return _BookCardSkeleton(is_dark: widget.is_dark);
                            }, childCount: Style.page_size),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: grid_count,
                                  crossAxisSpacing: Style.grid_cross_spacing,
                                  mainAxisSpacing: Style.grid_main_spacing,
                                  mainAxisExtent: item_height,
                                ),
                          )
                        else ...<Widget>[
                          SliverGrid(
                            delegate: SliverChildBuilderDelegate((
                              BuildContext context,
                              int index,
                            ) {
                              final RecommendRankingItem book_item =
                                  _visible_book_list[index];

                              return BookshelfBookCard(
                                book_item: book_item,
                                is_dark: widget.is_dark,
                                tag_color_pool: _tag_color_pool,
                                on_tap: () {
                                  navigate_to_novel(
                                    id: book_item.id,
                                    title: book_item.title,
                                    publish_status: book_item.publish_status,
                                  );
                                },
                              );
                            }, childCount: _visible_book_list.length),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: grid_count,
                                  crossAxisSpacing: Style.grid_cross_spacing,
                                  mainAxisSpacing: Style.grid_main_spacing,
                                  mainAxisExtent: item_height,
                                ),
                          ),
                          SliverToBoxAdapter(
                            child: LoadMoreFooter(
                              is_dark: widget.is_dark,
                              is_loading: _is_loading_more,
                              has_more: _has_more,
                              on_load_more: _load_more_data,
                            ),
                          ),
                        ],
                      ],
                    ),
                    FloatingBackToTop(
                      show: _is_back_to_top_visible,
                      isDark: widget.is_dark,
                      onTap: _scroll_to_top,
                      right:
                          floating_back_to_top_style
                              .FloatingBackToTopStyle
                              .right -
                          Style.page_horizontal_padding,
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
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 加载首屏数据。
  Future<void> _load_initial_data() async {
    setState(() {
      _is_initial_loading = true;
    });

    // 保存请求发起时的状态快照
    final int request_version = ++_request_version;
    final int? request_category_id = _selected_category_id;

    final List<RecommendRankingItem> items = await _fetch_data(
      category_id: request_category_id,
    );

    // 检查版本号，如果不匹配说明有新请求发起，丢弃本次结果
    if (!mounted || request_version != _request_version) return;

    setState(() {
      _visible_book_list = items;
      _has_more = items.length >= _page_size;
      _is_initial_loading = false;
    });

    // 更新缓存（使用请求发起时的分类id）
    _store.set_category_cache(
      widget.ranking_tab_id,
      request_category_id,
      items: items,
      has_more: _has_more,
    );
  }

  /// 下拉刷新。
  Future<void> _handle_refresh() async {
    // 保存请求发起时的状态快照
    final int request_version = ++_request_version;
    final int? request_category_id = _selected_category_id;

    final List<RecommendRankingItem> items = await _fetch_data(
      category_id: request_category_id,
    );

    // 检查版本号
    if (!mounted || request_version != _request_version) return;

    setState(() {
      _visible_book_list = items;
      _has_more = items.length >= _page_size;
      _is_loading_more = false;
    });

    // 更新缓存
    _store.set_category_cache(
      widget.ranking_tab_id,
      request_category_id,
      items: items,
      has_more: _has_more,
    );
  }

  /// 分类筛选变更。
  Future<void> _handle_category_changed(int? category_id) async {
    if (_selected_category_id == category_id) return;
    _selected_category_id = category_id;

    // 保存选中的分类到Store
    _store.set_selected_category_id(widget.ranking_tab_id, category_id);

    // 检查是否有缓存数据
    final RankingCategoryCache? cache = _get_current_cache();
    if (cache != null) {
      // 缓存存在，直接使用
      setState(() {
        _visible_book_list = List<RecommendRankingItem>.from(cache.items);
        _has_more = cache.has_more;
        _is_initial_loading = false;
      });
      // 滚动到顶部
      if (_scroll_controller.hasClients) {
        _scroll_controller.jumpTo(0);
      }
    } else {
      // 缓存不存在，从网络加载
      setState(() {
        _is_initial_loading = true;
      });

      // 保存请求发起时的状态快照
      final int request_version = ++_request_version;
      final int? request_category_id = category_id;

      final List<RecommendRankingItem> items = await _fetch_data(
        category_id: request_category_id,
      );

      // 检查版本号
      if (!mounted || request_version != _request_version) return;

      setState(() {
        _visible_book_list = items;
        _has_more = items.length >= _page_size;
        _is_initial_loading = false;
      });

      // 更新缓存（使用请求发起时的分类id）
      _store.set_category_cache(
        widget.ranking_tab_id,
        request_category_id,
        items: items,
        has_more: _has_more,
      );
    }
  }

  /// 请求榜单数据。
  ///
  /// 根据 [widget.ranking_tab_id] 选择对应的 API 路径，
  /// 传入 [category_id] 进行分类筛选，传入 [no_ids] 排除已加载数据。
  Future<List<RecommendRankingItem>> _fetch_data({
    int? category_id,
    List<int>? no_ids,
  }) async {
    final String api_path = RankingFullListLogic.resolve_api_path(
      widget.ranking_tab_id,
    );

    try {
      final results = await postRequest<List<RecommendRankingItem>>(
        path: api_path,
        showTips: false,
        parameter: <String, dynamic>{
          'limit': _page_size,
          if (category_id != null) 'category_id': category_id,
          if (no_ids != null && no_ids.isNotEmpty) 'no_ids': no_ids,
        },
        fromJsonList: (List<dynamic> json) =>
            RecommendRankingItem.from_json_list(json),
      );

      if (!results.status || results.content == null) {
        return <RecommendRankingItem>[];
      }

      return results.content!;
    } catch (_) {
      return <RecommendRankingItem>[];
    }
  }

  /// 处理滚动事件。
  void _handle_scroll() {
    final bool should_show_back_to_top =
        _scroll_controller.hasClients &&
        _scroll_controller.offset > Style.back_to_top_visible_offset;

    if (_is_back_to_top_visible != should_show_back_to_top) {
      setState(() {
        _is_back_to_top_visible = should_show_back_to_top;
      });
    }

    if (_is_initial_loading || _is_loading_more) return;

    if (_scroll_controller.position.pixels >=
        _scroll_controller.position.maxScrollExtent -
            _load_more_trigger_distance) {
      if (_has_more) {
        _load_more_data();
      }
    }
  }

  /// 平滑滚动到顶部。
  void _scroll_to_top() {
    if (!_scroll_controller.hasClients) return;

    _scroll_controller.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  /// 加载更多数据。
  Future<void> _load_more_data() async {
    if (_is_loading_more || !_has_more) return;

    setState(() {
      _is_loading_more = true;
    });

    final List<int> no_ids = _visible_book_list
        .map((RecommendRankingItem item) => item.id)
        .toList();

    // 保存请求发起时的状态快照
    final int request_version = _request_version;
    final int? request_category_id = _selected_category_id;

    final List<RecommendRankingItem> new_items = await _fetch_data(
      category_id: request_category_id,
      no_ids: no_ids,
    );

    // 检查版本号
    if (!mounted || request_version != _request_version) return;

    setState(() {
      _visible_book_list.addAll(new_items);
      _has_more = new_items.length >= _page_size;
      _is_loading_more = false;
    });

    // 更新缓存
    _store.append_category_cache(
      widget.ranking_tab_id,
      request_category_id,
      new_items: new_items,
      has_more: _has_more,
    );
  }
}

/// 书籍卡片骨架屏。
class _BookCardSkeleton extends StatelessWidget {
  final bool is_dark;

  const _BookCardSkeleton({required this.is_dark});

  @override
  Widget build(BuildContext context) {
    final Color block_color = is_dark
        ? const Color(0xFF1A2130)
        : const Color(0xFFEDEFF4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: block_color,
              borderRadius: BorderRadius.circular(Style.cover_radius),
            ),
          ),
        ),
        const SizedBox(height: Style.book_title_top_spacing),
        // 标题骨架（双行）
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 13,
              width: double.infinity,
              decoration: BoxDecoration(
                color: block_color,
                borderRadius: BorderRadius.circular(LayoutConfig.tag_radius),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 13,
              width: 72,
              decoration: BoxDecoration(
                color: block_color,
                borderRadius: BorderRadius.circular(LayoutConfig.tag_radius),
              ),
            ),
          ],
        ),
        const SizedBox(height: Style.book_meta_top_spacing),
        // 底部信息骨架（单行，与双行标题时的实际内容一致）
        Container(
          height: Style.book_meta_skeleton_height,
          width: 88,
          decoration: BoxDecoration(
            color: block_color,
            borderRadius: BorderRadius.circular(LayoutConfig.tag_radius),
          ),
        ),
      ],
    );
  }
}
