import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:app/models/story_item.dart';
import 'package:app/components/empty_state/index.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/style.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/widgets/ranking_book_item.dart';

/// 榜单内容区域组件。
///
/// 展示横向分页滚动的书籍列表，按列排列，每列作为一页。
/// 支持分页对齐：滑动距离不足时自动回弹，超过时切换到下一列。
/// 左右两侧有渐变遮罩。
class RankingContent extends StatefulWidget {
  /// 当前分类的榜单数据。
  final List<StoryItem> books;

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 面板背景色（用于渐变遮罩）。
  final Color panel_bg;

  /// 当前分类初始吸附到的列索引。
  ///
  /// 不同榜单分类之间需要互相独立，父组件会为每个分类单独保存这个值。
  final int initial_column_index;

  /// 当前分类的吸附列变化回调。
  final ValueChanged<int>? on_column_index_changed;

  /// 空数据时点击重新加载回调。
  final VoidCallback? on_reload;

  const RankingContent({
    super.key,
    required this.books,
    required this.is_dark,
    required this.panel_bg,
    this.initial_column_index = 0,
    this.on_column_index_changed,
    this.on_reload,
  });

  @override
  State<RankingContent> createState() => _RankingContentState();
}

class _RankingContentState extends State<RankingContent> {
  /// PageView 控制器，用于控制分页滚动。
  PageController? _page_controller;

  /// 当前使用的 viewportFraction，用于检测屏幕变化时是否需要重建控制器。
  double? _viewport_fraction;

  /// 当前每一页的实际像素宽度：固定列宽 + 固定列间距。
  double? _page_extent;

  /// 当前吸附到的列索引。
  ///
  /// 横竖屏切换或宽度变化时，PageController 的 pixels 不能直接复用，
  /// 否则旧宽度下的像素偏移会导致新宽度下吸附点错位。
  /// 所以这里保存“列索引”，宽度变化后按新宽度重新定位。
  int _current_column_index = 0;

  @override
  void initState() {
    super.initState();
    _current_column_index = widget.initial_column_index;
  }

  @override
  void dispose() {
    _page_controller?.dispose();
    super.dispose();
  }

  void _set_current_column_index(int index) {
    if (_current_column_index == index) {
      return;
    }

    _current_column_index = index;
    widget.on_column_index_changed?.call(index);
  }

  /// 确保 PageController 已创建，且 viewportFraction 与当前布局宽度匹配。
  void _ensure_page_controller({
    required int total_columns,
    required double viewport_width,
  }) {
    final double safe_viewport_width = viewport_width <= 0 ? 1 : viewport_width;

    // 固定“一列内容宽度 + 列间距”，不要再按屏幕宽度计算一屏两列。
    // 这样横屏/平板/折叠屏会自然展示更多列，列与列之间仍保持固定间距。
    final double new_page_extent =
        RankingSectionStyle.column_content_width +
        RankingSectionStyle.column_gap;
    final double new_fraction = new_page_extent / safe_viewport_width;
    final int max_column_index = total_columns <= 0 ? 0 : total_columns - 1;

    final int target_column_index = _current_column_index
        .clamp(0, max_column_index)
        .toInt();

    final bool need_recreate_controller =
        _page_controller == null ||
        _viewport_fraction == null ||
        _page_extent == null ||
        (_viewport_fraction! - new_fraction).abs() > 0.0001 ||
        (_page_extent! - new_page_extent).abs() > 0.5;

    if (need_recreate_controller) {
      _page_controller?.dispose();
      _viewport_fraction = new_fraction;
      _page_extent = new_page_extent;
      _set_current_column_index(target_column_index);
      _page_controller = PageController(
        viewportFraction: new_fraction,
        initialPage: target_column_index,
      );
      return;
    }

    // 数据变化导致列数减少时，把当前位置拉回合法范围。
    if (_current_column_index != target_column_index) {
      _set_current_column_index(target_column_index);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _page_controller?.hasClients != true) {
          return;
        }
        _page_controller!.jumpToPage(_current_column_index);
      });
    }
  }

  bool _handle_scroll_notification(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      if (_page_controller?.hasClients == true) {
        final double? current_page = _page_controller!.page;
        if (current_page != null && current_page.isFinite) {
          final int new_column_index = current_page
              .round()
              .clamp(
                0,
                widget.books.isEmpty
                    ? 0
                    : (widget.books.length /
                                  RankingSectionStyle.rows_per_column)
                              .ceil() -
                          1,
              )
              .toInt();
          _set_current_column_index(new_column_index);
        }

        // 检查是否超出边界，如果超出则强制回弹。
        final double current_pixels = _page_controller!.offset;
        final double max_allowed = _calculate_max_allowed_pixels();
        if (current_pixels > max_allowed) {
          _page_controller!.animateTo(
            max_allowed,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      }
    }

    return false;
  }

  /// 计算最大允许的滚动位置。
  double _calculate_max_allowed_pixels() {
    if (_page_controller == null || !_page_controller!.hasClients) {
      return 0;
    }

    final int total_columns =
        (widget.books.length / RankingSectionStyle.rows_per_column).ceil();
    if (total_columns <= 1) {
      return 0;
    }

    final double column_extent = RankingSectionStyle.column_content_width +
        RankingSectionStyle.column_gap;
    final double viewport_width = _page_controller!.position.viewportDimension;
    final int visible_columns = (viewport_width / column_extent).floor();

    if (visible_columns >= total_columns) {
      return 0;
    }

    return column_extent * (total_columns - visible_columns) +
        RankingSectionStyle.content_padding_horizontal;
  }

  @override
  Widget build(BuildContext context) {
    /// 使用当前设备真实文字缩放比例计算内容高度，避免平板或辅助字号裁剪标题。
    final TextScaler text_scaler = MediaQuery.textScalerOf(context);
    final double content_height = RankingSectionStyle.resolve_content_height(
      text_scaler,
    );

    /// 总列数（向上取整）。
    final int total_columns =
        (widget.books.length / RankingSectionStyle.rows_per_column).ceil();

    if (total_columns == 0) {
      return SizedBox(
        height: content_height,
        child: EmptyState(is_dark: widget.is_dark, on_reload: widget.on_reload),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _ensure_page_controller(
          total_columns: total_columns,
          viewport_width: constraints.maxWidth,
        );

        /// 计算总内容宽度：列宽 * 列数 + 列间距 * (列数 - 1) + 左右内边距。
        final double total_content_width =
            RankingSectionStyle.column_content_width * total_columns +
            RankingSectionStyle.column_gap * (total_columns - 1) +
            RankingSectionStyle.content_padding_horizontal * 2;

        /// 屏幕宽度是否足够完整展示所有列。
        final bool can_show_all_columns =
            constraints.maxWidth >= total_content_width;

        /// 动态列宽：屏幕宽度足够时平分屏幕，否则使用固定列宽。
        final double dynamic_column_width = can_show_all_columns
            ? (constraints.maxWidth -
                    RankingSectionStyle.content_padding_horizontal * 2 -
                    RankingSectionStyle.column_gap * (total_columns - 1)) /
                total_columns
            : RankingSectionStyle.column_content_width;

        return SizedBox(
          height: content_height,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: <Widget>[
              NotificationListener<ScrollNotification>(
                onNotification: _handle_scroll_notification,
                child: PageView.builder(
                  key: ValueKey<String>(
                    '${(_viewport_fraction ?? 1.0).toStringAsFixed(6)}_${(_page_extent ?? 0).toStringAsFixed(1)}_$can_show_all_columns',
                  ),
                  controller: _page_controller,
                  padEnds: false,
                  // 屏幕宽度足够时禁用滚动，否则使用自定义物理限制过度滚动。
                  physics: can_show_all_columns
                      ? const NeverScrollableScrollPhysics()
                      : _LastColumnClampPagePhysics(
                          viewport_fraction: _viewport_fraction ?? 1.0,
                          last_page_index: total_columns - 1,
                        ),
                  // 关闭 PageView 默认分页物理，完全交给下面的自定义 physics。
                  // 否则宽屏/横屏下默认 PageScrollPhysics 的惯性吸附可能越过我们限制的最大位置。
                  pageSnapping: false,
                  // PageView 的可视区域必须占满整个内容区域，而不是放在 Padding 里面。
                  // 每一列通过 Transform 保留视觉内边距；滑动时内容可以穿过这个内边距，
                  // 并在真正的屏幕/父容器边缘被裁剪消失。
                  itemCount: total_columns,
                  itemBuilder: (BuildContext context, int column_index) {
                    return Transform.translate(
                      offset: const Offset(
                        RankingSectionStyle.content_padding_horizontal,
                        0,
                      ),
                      child: _build_column(
                        column_index,
                        column_width: dynamic_column_width,
                      ),
                    );
                  },
                ),
              ),
              if (!can_show_all_columns)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: RankingSectionStyle.content_gradient_mask_width,
                  child: IgnorePointer(
                    child: _build_gradient_mask(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              if (!can_show_all_columns)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: RankingSectionStyle.content_gradient_mask_width,
                  child: IgnorePointer(
                    child: _build_gradient_mask(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }



  Widget _build_column(
    int column_index, {
    double column_width = RankingSectionStyle.column_content_width,
  }) {
    final int start_index = column_index * RankingSectionStyle.rows_per_column;

    final List<StoryItem> column_books = widget.books
        .skip(start_index)
        .take(RankingSectionStyle.rows_per_column)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(right: RankingSectionStyle.column_gap),
      child: SizedBox(
        width: column_width,
        child: Column(
          children: List.generate(column_books.length, (int row_index) {
            final int book_index = start_index + row_index;
            return Padding(
              padding: EdgeInsets.only(
                bottom: row_index < column_books.length - 1
                    ? RankingSectionStyle.row_gap
                    : 0,
              ),
              child: RankingBookItem(
                book: column_books[row_index],
                ranking_index: book_index + 1,
                is_dark: widget.is_dark,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _build_gradient_mask({
    required Alignment begin,
    required Alignment end,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: <Color>[
            widget.panel_bg,
            widget.panel_bg.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

/// 限制榜单横向分页的最大滚动位置。
///
/// 使用场景：PageView 的 viewportFraction 小于 1 时，如果只设置真实列数，
/// 最后一列无法滑到左侧边缘；如果额外加一页占位页，最后一列可以贴左，
/// 但又会继续滑到占位空白页。
///
/// 这个 physics 同时处理两件事：
/// 1. 拖动时不能超过最后一列贴左的位置；
/// 2. 松手后的惯性/吸附动画也不能把内容推过这个位置。
class _LastColumnClampPagePhysics extends PageScrollPhysics {
  final double viewport_fraction;
  final int last_page_index;

  const _LastColumnClampPagePhysics({
    required this.viewport_fraction,
    required this.last_page_index,
    super.parent,
  });

  @override
  _LastColumnClampPagePhysics applyTo(ScrollPhysics? ancestor) {
    return _LastColumnClampPagePhysics(
      viewport_fraction: viewport_fraction,
      last_page_index: last_page_index,
      parent: buildParent(ancestor),
    );
  }

  double _page_size(ScrollMetrics position) {
    return position.viewportDimension * viewport_fraction;
  }

  double _max_allowed_pixels(ScrollMetrics position) {
    if (last_page_index <= 0) {
      return position.minScrollExtent;
    }

    /// 每列占用宽度：列宽 + 列间距。
    final double column_extent = RankingSectionStyle.column_content_width +
        RankingSectionStyle.column_gap;

    /// 屏幕能完整显示的列数。
    final int visible_columns =
        (position.viewportDimension / column_extent).floor();

    /// 总列数。
    final int total_columns = last_page_index + 1;

    /// 如果屏幕能完整显示所有列，不需要滑动。
    if (visible_columns >= total_columns) {
      return position.minScrollExtent;
    }

    /// 最大滑动距离：让最后 visible_columns 列完整显示。
    /// 第 (total_columns - visible_columns) 列左边缘对齐屏幕左边缘。
    return column_extent * (total_columns - visible_columns) +
        RankingSectionStyle.content_padding_horizontal;
  }

  double _get_page(ScrollMetrics position) {
    final double page_size = _page_size(position);
    if (page_size <= 0) {
      return 0;
    }
    return position.pixels / page_size;
  }

  double _get_pixels_from_page(ScrollMetrics position, double page) {
    return page * _page_size(position);
  }

  double _get_target_pixels(
    ScrollMetrics position,
    Tolerance tolerance,
    double velocity,
  ) {
    double page = _get_page(position);

    if (velocity < -tolerance.velocity) {
      page -= 0.5;
    } else if (velocity > tolerance.velocity) {
      page += 0.5;
    }

    final double target_pixels = _get_pixels_from_page(
      position,
      page.roundToDouble(),
    );

    return target_pixels
        .clamp(position.minScrollExtent, _max_allowed_pixels(position))
        .toDouble();
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // 允许过度拖动，松手后会回弹。
    return 0.0;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final double max_allowed_pixels = _max_allowed_pixels(position);
    final Tolerance tolerance = toleranceFor(position);

    // 如果当前位置超出最大允许范围，直接回弹到最大位置。
    if (position.pixels > max_allowed_pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        max_allowed_pixels,
        velocity,
        tolerance: tolerance,
      );
    }

    // 如果当前位置小于最小范围，直接回弹到最小位置。
    if (position.pixels < position.minScrollExtent) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        position.minScrollExtent,
        velocity,
        tolerance: tolerance,
      );
    }

    final double target_pixels = _get_target_pixels(
      position,
      tolerance,
      velocity,
    );

    if ((target_pixels - position.pixels).abs() < tolerance.distance &&
        velocity.abs() < tolerance.velocity) {
      return null;
    }

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target_pixels,
      velocity,
      tolerance: tolerance,
    );
  }
}
