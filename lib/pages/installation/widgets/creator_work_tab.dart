// ignore_for_file: non_constant_identifier_names

import 'package:app/components/floating_back_to_top/index.dart';
import 'package:app/components/floating_back_to_top/style.dart'
    as floating_back_to_top_style;
import 'package:app/pages/installation/author_style.dart';
import 'package:app/pages/installation/models/creator_work.dart';
import 'package:app/pages/installation/widgets/author_work_card.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SliverConstraints;

/// 单个作品状态 Tab 的独立滚动内容。
///
/// 组件通过 [AutomaticKeepAliveClientMixin] 保留自己的 ScrollPosition，
/// 并使用唯一 [PageStorageKey] 进行二次保护，避免 Tab 间复用滚动位置。
class CreatorWorkTab extends StatefulWidget {
  /// Tab 索引，用于生成唯一滚动存储键。
  final int tab_index;

  /// 当前筛选后的作品列表。
  final List<CreatorWorkDraft> works;

  /// 当前是否为夜间主题。
  final bool is_dark;

  /// 当前是否为 CJK 语系。
  final bool is_cjk;

  /// 当前 Tab 独占的滚动控制器。
  final ScrollController scroll_controller;

  /// 页面顶部为可折叠头部预留的完整高度。
  final double header_spacer_height;

  /// 头部完全折叠后的最小高度。
  final double minimum_header_height;

  /// 为保证头部可完全吸顶所需的最小滚动范围。
  final double minimum_scroll_extent;

  /// 创建作品回调。
  final VoidCallback on_create_work;

  /// 编辑作品回调。
  final ValueChanged<CreatorWorkDraft> on_edit_work;

  /// 作品主操作回调。
  final ValueChanged<CreatorWorkDraft> on_primary_action;

  const CreatorWorkTab({
    super.key,
    required this.tab_index,
    required this.works,
    required this.is_dark,
    required this.is_cjk,
    required this.scroll_controller,
    required this.header_spacer_height,
    required this.minimum_header_height,
    required this.minimum_scroll_extent,
    required this.on_create_work,
    required this.on_edit_work,
    required this.on_primary_action,
  });

  @override
  State<CreatorWorkTab> createState() => _CreatorWorkTabState();
}

class _CreatorWorkTabState extends State<CreatorWorkTab>
    with AutomaticKeepAliveClientMixin<CreatorWorkTab> {
  /// 用于取消新手势开始前尚未执行的吸附任务。
  int _scroll_activity_generation = 0;

  /// 当前跟踪的触点编号。
  int? _active_pointer_id;

  /// 当前触点的起始位置。
  Offset? _pointer_origin;

  /// 当前手势是否已完成方向锁定。
  bool _pointer_axis_resolved = false;

  /// 当前手势是否为纵向滚动。
  bool _pointer_is_vertical = false;

  /// 当前 Tab 的返回顶部按钮是否可见。
  bool _show_back_to_top = false;

  @override
  void initState() {
    super.initState();
    widget.scroll_controller.addListener(_on_scroll_position_changed);
    _schedule_back_to_top_visibility_sync();
  }

  @override
  void didUpdateWidget(CreatorWorkTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scroll_controller == widget.scroll_controller) return;

    oldWidget.scroll_controller.removeListener(_on_scroll_position_changed);
    widget.scroll_controller.addListener(_on_scroll_position_changed);
    _schedule_back_to_top_visibility_sync();
  }

  @override
  void dispose() {
    widget.scroll_controller.removeListener(_on_scroll_position_changed);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double bottom_safe_area = MediaQuery.paddingOf(context).bottom;
        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: _on_pointer_down,
                onPointerMove: _on_pointer_move,
                onPointerUp: _on_pointer_up,
                onPointerCancel: _on_pointer_cancel,
                child: CustomScrollView(
                  key: PageStorageKey<String>(
                    'creator_center_content_tab_${widget.tab_index}',
                  ),
                  controller: widget.scroll_controller,
                  primary: false,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: _build_slivers(
                    context,
                    viewport_height: constraints.maxHeight,
                  ),
                ),
              ),
            ),
            FloatingBackToTop(
              key: ValueKey<String>(
                'creator_back_to_top_tab_${widget.tab_index}',
              ),
              show: _show_back_to_top,
              isDark: widget.is_dark,
              onTap: _scroll_to_top,
              right: floating_back_to_top_style.FloatingBackToTopStyle.right,
              visibleBottom:
                  floating_back_to_top_style
                      .FloatingBackToTopStyle
                      .page_bottom +
                  bottom_safe_area,
              hiddenBottom:
                  floating_back_to_top_style
                      .FloatingBackToTopStyle
                      .hidden_offset +
                  bottom_safe_area,
            ),
          ],
        );
      },
    );
  }

  /// 首次挂载或更换控制器后同步返回顶部按钮状态。
  void _schedule_back_to_top_visibility_sync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _on_scroll_position_changed();
    });
  }

  /// 仅根据当前 Tab 自己的滚动位置更新按钮显隐。
  void _on_scroll_position_changed() {
    if (!mounted || !widget.scroll_controller.hasClients) return;

    final bool should_show =
        widget.scroll_controller.offset > AuthorStyle.scroll_extent_tolerance;
    if (should_show == _show_back_to_top) return;
    setState(() => _show_back_to_top = should_show);
  }

  /// 只滚动当前 Tab 的内容控制器到顶部。
  void _scroll_to_top() {
    if (!widget.scroll_controller.hasClients) return;
    widget.scroll_controller.animateTo(
      widget.scroll_controller.position.minScrollExtent,
      duration: AuthorStyle.back_to_top_scroll_duration,
      curve: Curves.easeOutCubic,
    );
  }

  /// 记录手指按下位置，并使之前未执行的吸附失效。
  void _on_pointer_down(PointerDownEvent event) {
    if (_active_pointer_id != null) return;

    _scroll_activity_generation += 1;
    _active_pointer_id = event.pointer;
    _pointer_origin = event.position;
    _pointer_axis_resolved = false;
    _pointer_is_vertical = false;
  }

  /// 超过移动阈值后只锁定一次手势方向。
  void _on_pointer_move(PointerMoveEvent event) {
    if (event.pointer != _active_pointer_id || _pointer_axis_resolved) return;

    final Offset? origin = _pointer_origin;
    if (origin == null) return;
    final Offset delta = event.position - origin;
    if (delta.distance < AuthorStyle.pointer_axis_lock_distance) return;

    _pointer_axis_resolved = true;
    _pointer_is_vertical = delta.dy.abs() > delta.dx.abs();
  }

  /// 用手指抬起瞬间的滚动位置进行吸附判定。
  void _on_pointer_up(PointerUpEvent event) {
    _finish_pointer_gesture(event.pointer);
  }

  /// 系统取消触点时使用相同的收尾逻辑。
  void _on_pointer_cancel(PointerCancelEvent event) {
    _finish_pointer_gesture(event.pointer);
  }

  /// 结束当前触点，并在事件分发完成后取消区间内的惯性。
  void _finish_pointer_gesture(int pointer_id) {
    if (pointer_id != _active_pointer_id) return;

    final bool should_snap =
        _pointer_axis_resolved &&
        _pointer_is_vertical &&
        widget.scroll_controller.hasClients;
    final double? release_offset = should_snap
        ? widget.scroll_controller.offset
        : null;
    final int completed_generation = _scroll_activity_generation;

    _active_pointer_id = null;
    _pointer_origin = null;
    _pointer_axis_resolved = false;
    _pointer_is_vertical = false;

    if (release_offset == null) return;
    Future<void>.microtask(() {
      if (!mounted ||
          completed_generation != _scroll_activity_generation ||
          !widget.scroll_controller.hasClients) {
        return;
      }
      _snap_header_scroll_position(release_offset);
    });
  }

  /// 按照手指抬起瞬间的位置执行二段头部吸附。
  void _snap_header_scroll_position(double release_offset) {
    final double collapse_range = widget.minimum_scroll_extent;
    final double tolerance = AuthorStyle.scroll_extent_tolerance;
    if (release_offset <= tolerance ||
        release_offset >= collapse_range - tolerance) {
      return;
    }

    final double target_offset = release_offset < collapse_range / 2
        ? widget.scroll_controller.position.minScrollExtent
        : collapse_range;
    widget.scroll_controller.animateTo(
      target_offset.clamp(
        widget.scroll_controller.position.minScrollExtent,
        widget.scroll_controller.position.maxScrollExtent,
      ),
      duration: AuthorStyle.header_snap_duration,
      curve: Curves.easeOutCubic,
    );
  }

  /// 根据作品数据构建列表或空状态。
  List<Widget> _build_slivers(
    BuildContext context, {
    required double viewport_height,
  }) {
    final Widget header_spacer = SliverToBoxAdapter(
      child: SizedBox(height: widget.header_spacer_height),
    );

    if (widget.works.isEmpty) {
      final double empty_content_height =
          (viewport_height - widget.minimum_header_height).clamp(
            0.0,
            double.infinity,
          );
      return <Widget>[
        header_spacer,
        SliverToBoxAdapter(
          child: SizedBox(
            height: empty_content_height,
            child: _build_empty_state(),
          ),
        ),
        _build_minimum_scroll_extent_filler(),
      ];
    }

    return <Widget>[
      header_spacer,
      SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AuthorStyle.content_max_width,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AuthorStyle.page_padding,
                AuthorStyle.list_header_top_spacing,
                AuthorStyle.page_padding,
                AuthorStyle.list_header_bottom_spacing,
              ),
              child: _build_list_header(),
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          AuthorStyle.page_padding,
          0,
          AuthorStyle.page_padding,
          AuthorStyle.list_bottom_spacing +
              MediaQuery.paddingOf(context).bottom,
        ),
        sliver: SliverList.separated(
          itemCount: widget.works.length,
          separatorBuilder: (BuildContext context, int index) =>
              const SizedBox(height: AuthorStyle.work_card_spacing),
          itemBuilder: (BuildContext context, int index) {
            final CreatorWorkDraft work = widget.works[index];
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AuthorStyle.content_max_width,
                ),
                child: AuthorWorkCard(
                  work: work,
                  is_dark: widget.is_dark,
                  is_cjk: widget.is_cjk,
                  on_tap: () => widget.on_edit_work(work),
                  on_primary_action: () => widget.on_primary_action(work),
                ),
              ),
            );
          },
        ),
      ),
      _build_minimum_scroll_extent_filler(),
    ];
  }

  /// 在首次布局中即补齐短内容的最小滚动范围。
  ///
  /// 使用 Sliver 约束直接计算剩余高度，避免首帧渲染后再 setState
  /// 导致新 Tab 先出现空白区，下一帧才将内容顶上来。
  Widget _build_minimum_scroll_extent_filler() {
    return SliverLayoutBuilder(
      builder: (BuildContext context, SliverConstraints constraints) {
        final double required_total_extent =
            constraints.viewportMainAxisExtent + widget.minimum_scroll_extent;
        final double filler_extent =
            (required_total_extent - constraints.precedingScrollExtent).clamp(
              0.0,
              double.infinity,
            );
        return SliverToBoxAdapter(child: SizedBox(height: filler_extent));
      },
    );
  }

  /// 构建作品列表标题和当前筛选结果数量。
  Widget _build_list_header() {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                easy.tr('creator_center.my_works'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AuthorStyle.primary_text(widget.is_dark),
                  fontSize: widget.is_cjk ? 18 : 16.5,
                  fontWeight: AuthorStyle.title_weight,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                easy.tr('creator_center.my_works_subtitle'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AuthorStyle.secondary_text(widget.is_dark),
                  fontSize: widget.is_cjk ? 11.5 : 10.5,
                  fontWeight: AuthorStyle.body_weight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          constraints: const BoxConstraints(minWidth: 34),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AuthorStyle.selected_tab_surface(widget.is_dark),
            borderRadius: BorderRadius.circular(AuthorStyle.pill_radius),
          ),
          alignment: Alignment.center,
          child: Text(
            '${widget.works.length}',
            style: TextStyle(
              color: AuthorStyle.selected_tab_text(widget.is_dark),
              fontSize: 12,
              fontWeight: AuthorStyle.title_weight,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建当前筛选条件下的空状态。
  Widget _build_empty_state() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 34, 24, 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AuthorStyle.selected_tab_surface(widget.is_dark),
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.auto_stories_outlined,
                size: 32,
                color: widget.is_dark
                    ? AuthorStyle.gold
                    : AuthorStyle.deep_gold,
              ),
            ),
            const SizedBox(height: 17),
            Text(
              easy.tr('creator_center.empty_title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AuthorStyle.primary_text(widget.is_dark),
                fontSize: 17,
                fontWeight: AuthorStyle.title_weight,
              ),
            ),
            const SizedBox(height: 7),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                easy.tr('creator_center.empty_subtitle'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AuthorStyle.secondary_text(widget.is_dark),
                  fontSize: 12.5,
                  height: 1.55,
                  fontWeight: AuthorStyle.body_weight,
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: widget.on_create_work,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(easy.tr('creator_center.create_first_work')),
              style: FilledButton.styleFrom(
                backgroundColor: AuthorStyle.gold,
                foregroundColor: const Color(0xFF1A1A18),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: AuthorStyle.title_weight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
