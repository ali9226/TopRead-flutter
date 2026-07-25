import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/components/fixed_bottom_navigation/style.dart' as fixed_nav_style;
import 'package:app/components/floating_back_to_top/index.dart';
import 'package:app/components/floating_back_to_top/style.dart' as floating_back_to_top_style;
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/bookshelf/logic.dart';
import 'package:app/pages/bookshelf/style.dart';
import 'package:app/pages/bookshelf/widgets/bookshelf_book_card.dart';
import 'package:app/util/dialog/show_message.dart';
import 'package:app/util/novel_navigation/index.dart';

/// 书架网格内容类型（历史/收藏）。
enum BookshelfContentType { history, favorite }

/// 书架网格内容公共组件。
///
/// 历史和收藏 Tab 共用此组件，通过 [type] 区分行为差异：
/// - 长按弹窗：历史→删除历史记录，收藏→取消收藏
/// - 数据由外部通过 [items] 传入，组件不负责请求
/// - 删除操作为乐观模式：先移除再后台请求，带位置动画
///
/// 使用 Stack + AnimatedPositioned 实现删除动画，
/// 删除卡片后所有剩余卡片会平滑移动到新位置。
class BookshelfGridContent extends StatefulWidget {
  /// 内容类型。
  final BookshelfContentType type;

  /// 当前 Tab 的强调色。
  final Color accent_color;

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 初始数据列表。
  final List<BookshelfBookItem> items;

  /// 是否还有更多数据。
  final bool has_more;

  /// 是否处于首屏加载。
  final bool is_initial_loading;

  /// 加载更多回调（滚动到底部时触发）。
  final Future<void> Function()? on_load_more;

  /// 下拉刷新回调。
  final Future<void> Function()? on_refresh;

  /// 删除/取消收藏成功后的回调（用于从列表中移除该项）。
  final void Function(String item_id)? on_item_removed;

  /// 删除/取消收藏的API调用函数（由外部传入）。
  final Future<bool> Function(String novel_id)? on_delete;

  const BookshelfGridContent({
    super.key,
    required this.type,
    required this.accent_color,
    required this.is_dark,
    required this.items,
    this.has_more = false,
    this.is_initial_loading = false,
    this.on_load_more,
    this.on_refresh,
    this.on_item_removed,
    this.on_delete,
  });

  @override
  State<BookshelfGridContent> createState() => _BookshelfGridContentState();
}

class _BookshelfGridContentState extends State<BookshelfGridContent> {
  /// 内容滚动控制器。
  final ScrollController _scroll_controller = ScrollController();

  /// 当前是否处于加载更多。
  bool _is_loading_more = false;

  /// 返回顶部按钮是否可见。
  bool _is_back_to_top_visible = false;

  /// 正在播放删除动画的项目 ID 集合。
  final Set<String> _removing_ids = <String>{};

  /// 每个卡片的实际测量高度。
  final Map<String, double> _item_heights = <String, double>{};

  /// 删除动画时长。
  static const int _delete_animation_duration_ms = 320;

  /// 位置重排动画时长。
  static const int _reorder_animation_duration_ms = 300;

  /// 淡出动画时长。
  static const int _fade_out_animation_duration_ms = 250;

  @override
  void initState() {
    super.initState();
    _scroll_controller.addListener(_handle_scroll);
  }

  @override
  void dispose() {
    _scroll_controller.removeListener(_handle_scroll);
    _scroll_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.is_initial_loading) {
      return _build_loading_grid();
    }

    if (widget.items.isEmpty) {
      return _build_empty_state();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double total_width = constraints.maxWidth;
        final int grid_count = BookshelfLogic.resolve_grid_count(total_width);
        final double column_width =
            (total_width - Style.grid_cross_spacing * (grid_count - 1)) /
            grid_count;

        final positions = _calculate_grid_positions(
          widget.items,
          grid_count,
          column_width,
        );

        final double total_height = _calculate_total_height(positions);

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: <Widget>[
            RefreshIndicator(
              onRefresh: _handle_refresh,
              child: ListView(
                controller: _scroll_controller,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: <Widget>[
                  SizedBox(
                    height: total_height,
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: widget.items.map((item) {
                        final rect = positions[item.id];
                        if (rect == null) return const SizedBox.shrink();

                        final bool is_removing = _removing_ids.contains(item.id);

                        return AnimatedPositioned(
                          key: ValueKey(item.id),
                          duration: Duration(
                            milliseconds: _reorder_animation_duration_ms,
                          ),
                          curve: Curves.easeOutCubic,
                          left: rect.left,
                          top: rect.top,
                          width: rect.width,
                          height: rect.height,
                          child: AnimatedOpacity(
                            duration: Duration(
                              milliseconds: _fade_out_animation_duration_ms,
                            ),
                            curve: Curves.easeOut,
                            opacity: is_removing ? 0.0 : 1.0,
                            child: _MeasurableCard(
                              item_id: item.id,
                              on_size_changed: _on_item_size_changed,
                              child: BookshelfBookCard(
                                book_item: item,
                                is_dark: widget.is_dark,
                                on_tap: () => _navigate_to_read(item),
                                on_long_press: () =>
                                    _show_action_dialog(item),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  _build_load_more_section(),
                ],
              ),
            ),
            FloatingBackToTop(
              show: _is_back_to_top_visible,
              isDark: widget.is_dark,
              onTap: _scroll_to_top,
              right: floating_back_to_top_style.FloatingBackToTopStyle.right,
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

  /// 卡片高度回调：首次测量后存储高度并触发布局更新。
  void _on_item_size_changed(String item_id, Size size) {
    if (_item_heights[item_id] == size.height) return;
    _item_heights[item_id] = size.height;
    if (mounted) setState(() {});
  }

  /// 计算网格中每个项目的位置。
  Map<String, Rect> _calculate_grid_positions(
    List<BookshelfBookItem> items,
    int grid_count,
    double column_width,
  ) {
    final double default_height = _calculate_item_height(column_width);
    final List<double> column_heights = List<double>.filled(grid_count, 0);
    final Map<String, Rect> positions = <String, Rect>{};

    for (int i = 0; i < items.length; i++) {
      final BookshelfBookItem item = items[i];
      final bool is_removing = _removing_ids.contains(item.id);

      int shortest_column = 0;
      double min_height = column_heights[0];
      for (int c = 1; c < grid_count; c++) {
        if (column_heights[c] < min_height) {
          min_height = column_heights[c];
          shortest_column = c;
        }
      }

      final double x = shortest_column *
          (column_width + Style.grid_cross_spacing);
      final double item_height =
          _item_heights[item.id] ?? default_height;
      final double effective_height = is_removing ? 0 : item_height;

      positions[item.id] = Rect.fromLTWH(
        x,
        column_heights[shortest_column],
        column_width,
        effective_height,
      );

      if (!is_removing) {
        column_heights[shortest_column] +=
            item_height + Style.grid_main_spacing;
      }
    }

    return positions;
  }

  /// 计算网格总高度。
  double _calculate_total_height(Map<String, Rect> positions) {
    double max_bottom = 0;
    for (final rect in positions.values) {
      final double bottom = rect.top + rect.height;
      if (bottom > max_bottom) max_bottom = bottom;
    }
    return max_bottom;
  }

  /// 计算单个卡片高度（未测量时的兜底值，取最大情况避免首帧溢出）。
  double _calculate_item_height(double item_width) {
    final double cover_height = item_width / Style.cover_aspect_ratio;
    return cover_height +
        Style.book_title_top_spacing +
        Style.book_title_line_height * 2 +
        Style.book_meta_top_spacing +
        Style.book_max_meta_height;
  }

  /// 构建加载中的骨架屏网格。
  Widget _build_loading_grid() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int grid_count = BookshelfLogic.resolve_grid_count(
          constraints.maxWidth,
        );
        final double column_width =
            (constraints.maxWidth -
                (grid_count - 1) * Style.grid_cross_spacing) /
            grid_count;
        final double item_height = _calculate_item_height(column_width);

        final List<Widget> skeletons = [];
        for (int i = 0; i < Style.page_size; i++) {
          final int row = i ~/ grid_count;
          final int col = i % grid_count;
          skeletons.add(
            Positioned(
              left: col * (column_width + Style.grid_cross_spacing),
              top: row * (item_height + Style.grid_main_spacing),
              width: column_width,
              height: item_height,
              child: _BookCardSkeleton(is_dark: widget.is_dark),
            ),
          );
        }

        final int rows = (Style.page_size / grid_count).ceil();
        final double total_height =
            rows * item_height + (rows - 1) * Style.grid_main_spacing;

        return SizedBox(
          height: total_height,
          child: Stack(clipBehavior: Clip.hardEdge, children: skeletons),
        );
      },
    );
  }

  /// 处理滚动事件：控制返回顶部按钮显隐、触发加载更多。
  void _handle_scroll() {
    final bool should_show_back_to_top = _scroll_controller.hasClients &&
        _scroll_controller.offset > Style.back_to_top_visible_offset;

    if (_is_back_to_top_visible != should_show_back_to_top) {
      setState(() {
        _is_back_to_top_visible = should_show_back_to_top;
      });
    }

    if (_is_loading_more || !widget.has_more) return;

    if (_scroll_controller.position.pixels >=
        _scroll_controller.position.maxScrollExtent -
            Style.load_more_auto_trigger_distance) {
      _load_more_data();
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
    if (_is_loading_more || !widget.has_more) return;

    setState(() {
      _is_loading_more = true;
    });

    await widget.on_load_more?.call();

    if (mounted) {
      setState(() {
        _is_loading_more = false;
      });
    }
  }

  /// 下拉刷新数据。
  Future<void> _handle_refresh() async {
    await widget.on_refresh?.call();
  }

  /// 跳转到阅读页面。
  void _navigate_to_read(BookshelfBookItem book_item) {
    navigate_to_novel(
      id: int.tryParse(book_item.novel_id) ?? 0,
      title: book_item.title,
      publish_status: book_item.publish_status,
    );
  }

  /// 展示操作弹窗（历史→删除，收藏→取消收藏）。
  ///
  /// 乐观模式：确认后立即标记删除并播放动画，后台静默调用 API。
  void _show_action_dialog(BookshelfBookItem book_item) {
    final String message = widget.type == BookshelfContentType.history
        ? easy.tr(
            'bookshelf.delete_dialog.message',
            namedArgs: <String, String>{'title': book_item.title},
          )
        : easy.tr(
            'bookshelf.unfavorite_dialog.message',
            namedArgs: <String, String>{'title': book_item.title},
          );
    final String rightButtonText = widget.type == BookshelfContentType.history
        ? easy.tr('bookshelf.delete_dialog.confirm')
        : easy.tr('bookshelf.unfavorite_dialog.confirm');

    showMessage(
      message: message,
      showHelperText: false,
      iconData: widget.type == BookshelfContentType.history
          ? Icons.delete_outline_rounded
          : Icons.bookmark_remove_outlined,
      iconColor: ColorConstants.dangerColor,
      leftButtonText: easy.tr('bookshelf.delete_dialog.cancel'),
      rightButtonText: rightButtonText,
      rightButtonColor: ColorConstants.dangerColor,
      onRightPressed: () async {
        if (!mounted) return;

        // 标记为正在移除，触发位置重排动画 + 淡出动画。
        setState(() {
          _removing_ids.add(book_item.id);
        });

        // 后台静默调用 API，不等待结果。
        widget.on_delete?.call(book_item.novel_id);

        // 动画完成后从列表中真正移除。
        Future<void>.delayed(
          const Duration(milliseconds: _delete_animation_duration_ms),
        ).then((_) {
          if (mounted) {
            setState(() {
              _removing_ids.remove(book_item.id);
              widget.on_item_removed?.call(book_item.id);
            });
          }
        });
      },
    );
  }

  /// 构建空状态。
  Widget _build_empty_state() {
    final Color text_color = widget.is_dark
        ? Colors.white.withValues(alpha: 0.6)
        : const Color(0xFF9BA3B1);

    final String empty_key = widget.type == BookshelfContentType.history
        ? 'bookshelf.empty.history'
        : 'bookshelf.empty.favorite';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            widget.type == BookshelfContentType.history
                ? Icons.history_rounded
                : Icons.bookmark_outline_rounded,
            size: 64,
            color: text_color,
          ),
          const SizedBox(height: 16),
          Text(
            easy.tr(empty_key),
            style: TextStyle(
              color: text_color,
              fontSize: 16,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建加载更多区域。
  Widget _build_load_more_section() {
    final Color text_color = widget.is_dark
        ? Colors.white.withValues(alpha: 0.8)
        : const Color(0xFF616775);

    final String text_key = _is_loading_more
        ? 'bookshelf.load_more.loading'
        : (widget.has_more
            ? 'bookshelf.load_more.button'
            : 'bookshelf.load_more.no_more');

    return Padding(
      padding: const EdgeInsets.only(top: Style.load_more_top_spacing),
      child: Center(
        child: Text(
          easy.tr(text_key),
          style: TextStyle(
            color: text_color,
            fontSize: Style.load_more_font_size,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
          ),
        ),
      ),
    );
  }
}

/// 测量子组件实际尺寸的包装器。
///
/// 首次布局后将子组件的尺寸通过 [on_size_changed] 回调通知父级，
/// 用于动态计算网格位置，避免固定高度导致的溢出或间距过大。
class _MeasurableCard extends StatefulWidget {
  final String item_id;
  final void Function(String item_id, Size size) on_size_changed;
  final Widget child;

  const _MeasurableCard({
    required this.item_id,
    required this.on_size_changed,
    required this.child,
  });

  @override
  State<_MeasurableCard> createState() => _MeasurableCardState();
}

class _MeasurableCardState extends State<_MeasurableCard> {
  Size? _old_size;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final RenderObject? render_object = context.findRenderObject();
      if (render_object is! RenderBox || !render_object.hasSize) return;

      final Size new_size = render_object.size;
      if (_old_size == new_size) return;

      _old_size = new_size;
      widget.on_size_changed(widget.item_id, new_size);
    });

    return widget.child;
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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AspectRatio(
          aspectRatio: Style.cover_aspect_ratio,
          child: Container(
            decoration: BoxDecoration(
              color: block_color,
              borderRadius: BorderRadius.circular(Style.cover_radius),
            ),
          ),
        ),
        const SizedBox(height: Style.book_title_top_spacing),
        Container(
          height: 13,
          width: double.infinity,
          decoration: BoxDecoration(
            color: block_color,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 13,
          width: 72,
          decoration: BoxDecoration(
            color: block_color,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: Style.book_meta_top_spacing),
        Container(
          height: Style.book_meta_skeleton_height,
          width: 88,
          decoration: BoxDecoration(
            color: block_color,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }
}
