import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/models/story_item.dart';
import 'package:app/components/empty_state/index.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/style.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/widgets/ranking_book_item.dart';

/// TODO 横向榜单按列吸附，最后一列加宽，左右两侧保留渐变遮罩。
class RankingContent extends StatefulWidget {
  /// TODO 当前分类的榜单数据。
  final List<StoryItem> books;

  /// TODO 当前是否为夜间模式。
  final bool is_dark;

  /// TODO 面板背景色，用于渐变遮罩。
  final Color panel_bg;

  /// TODO 当前分类初始吸附到的列索引。
  final int initial_column_index;

  /// TODO 当前分类的吸附列变化回调。
  final ValueChanged<int>? on_column_index_changed;

  /// TODO 空数据时点击重新加载回调。
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
  /// TODO 使用真实内容宽度的控制器，确保加宽列完整显示并响应触控。
  ScrollController? _scroll_controller;

  /// TODO 普通列的吸附步长，包含列宽和列间距。
  double? _column_extent;

  /// TODO 上次布局的视口宽度和列数，用于检测旋转、折叠及数据变化。
  double? _viewport_width;
  int? _total_columns;

  /// TODO 保存列索引而非像素偏移，宽度变化时按新布局恢复位置。
  int _current_column_index = 0;

  @override
  void initState() {
    super.initState();
    _current_column_index = widget.initial_column_index;
  }

  @override
  void dispose() {
    _scroll_controller?.dispose();
    super.dispose();
  }

  /// TODO 保存当前列，并通知父组件以独立记忆各榜单的位置。
  void _set_current_column_index(int index) {
    if (_current_column_index == index) {
      return;
    }
    _current_column_index = index;
    widget.on_column_index_changed?.call(index);
  }

  /// TODO 根据列宽、总内容宽度和视口恢复位置，防止旋转或数据减少后越界。
  void _ensure_scroll_controller({
    required int total_columns,
    required double viewport_width,
    required double column_width,
    required double content_width,
  }) {
    final double new_column_extent =
        column_width + RankingSectionStyle.column_gap;
    if (_scroll_controller != null &&
        _column_extent == new_column_extent &&
        _viewport_width == viewport_width &&
        _total_columns == total_columns) {
      return;
    }

    final int target_column_index = _current_column_index.clamp(
      0,
      total_columns - 1,
    );
    final double max_scroll_extent = (content_width - viewport_width).clamp(
      0.0,
      double.infinity,
    );
    final double target_offset = (target_column_index * new_column_extent)
        .clamp(0.0, max_scroll_extent);

    _scroll_controller?.dispose();
    _column_extent = new_column_extent;
    _viewport_width = viewport_width;
    _total_columns = total_columns;
    _set_current_column_index(target_column_index);
    _scroll_controller = ScrollController(
      initialScrollOffset: target_offset,
      keepScrollOffset: false,
    );
  }

  /// TODO 滑动结束后保存吸附列，重新挂载时恢复到相同列的左边缘。
  bool _handle_scroll_notification(ScrollNotification notification) {
    if (notification is ScrollEndNotification &&
        notification.depth == 0 &&
        _scroll_controller?.hasClients == true) {
      final ScrollPosition position = _scroll_controller!.position;
      final double column = position.pixels / _column_extent!;
      final int new_column_index = column.round().clamp(0, _total_columns! - 1);
      _set_current_column_index(new_column_index);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final double content_height = RankingSectionStyle.resolve_content_height(
      MediaQuery.textScalerOf(context),
    );
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
        /// TODO 末列填满父容器，保证其封面吸附到与首列相同的左边缘。
        final double last_column_width =
            RankingSectionStyle.resolve_last_column_width(constraints.maxWidth);
        const double column_width = RankingSectionStyle.column_content_width;
        final bool can_show_all_columns = total_columns == 1;
        final double total_content_width =
            (column_width + RankingSectionStyle.column_gap) *
                (total_columns - 1) +
            last_column_width +
            RankingSectionStyle.content_padding_horizontal * 2;

        _ensure_scroll_controller(
          total_columns: total_columns,
          viewport_width: constraints.maxWidth,
          column_width: column_width,
          content_width: total_content_width,
        );

        return SizedBox(
          height: content_height,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: <Widget>[
              NotificationListener<ScrollNotification>(
                key: const ValueKey('ranking_horizontal_list'),
                onNotification: _handle_scroll_notification,
                child: ListView.separated(
                  key: ObjectKey(_scroll_controller),
                  controller: _scroll_controller,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: RankingSectionStyle.content_padding_horizontal,
                  ),
                  physics: can_show_all_columns
                      ? const NeverScrollableScrollPhysics()
                      : _RankingColumnScrollPhysics(
                          column_extent: _column_extent!,
                        ),
                  itemCount: total_columns,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(width: RankingSectionStyle.column_gap),
                  itemBuilder: (BuildContext context, int column_index) {
                    return _build_column(
                      column_index,
                      column_width: column_index == total_columns - 1
                          ? last_column_width
                          : column_width,
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

  /// TODO 按列索引取出书籍，使用实际列宽布局并保留原有排名顺序。
  Widget _build_column(int column_index, {required double column_width}) {
    final int start_index = column_index * RankingSectionStyle.rows_per_column;
    final List<StoryItem> column_books = widget.books
        .skip(start_index)
        .take(RankingSectionStyle.rows_per_column)
        .toList();

    return SizedBox(
      width: column_width,
      child: Column(
        children: List.generate(column_books.length, (int row_index) {
          final int book_index = start_index + row_index;
          return Padding(
            padding: EdgeInsets.only(
              bottom: row_index < column_books.length - LayoutConfig.space_1
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
    );
  }

  /// TODO 构建沿指定方向淡出的遮罩，颜色跟随当前主题面板。
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

/// TODO 按普通列步长吸附，末端以真实内容边界为准，避免裁剪加宽后的最后一列。
class _RankingColumnScrollPhysics extends BouncingScrollPhysics {
  /// TODO 普通列宽加列间距，不包含最后一列额外增加的宽度。
  final double column_extent;

  const _RankingColumnScrollPhysics({
    required this.column_extent,
    super.parent,
  });

  @override
  _RankingColumnScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _RankingColumnScrollPhysics(
      column_extent: column_extent,
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final Tolerance tolerance = toleranceFor(position);
    double target_pixels;

    if (position.outOfRange) {
      /// TODO 越界拖动直接回到真实边界，保留末列增加的宽度。
      target_pixels = position.pixels.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
    } else {
      double column = position.pixels / column_extent;
      if (velocity.abs() > tolerance.velocity) {
        column += velocity.sign / 2;
      }

      /// TODO 最后一段可能短于普通列，使用该段的中点选择末端吸附点。
      final double last_snap_pixels =
          (position.maxScrollExtent / column_extent).floor() * column_extent;
      final bool snap_to_end =
          position.pixels >=
              (last_snap_pixels + position.maxScrollExtent) / 2 &&
          velocity >= -tolerance.velocity;
      target_pixels = snap_to_end
          ? position.maxScrollExtent
          : (column.round() * column_extent).clamp(
              position.minScrollExtent,
              position.maxScrollExtent,
            );
    }

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
