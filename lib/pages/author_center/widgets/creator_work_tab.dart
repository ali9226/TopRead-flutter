// ignore_for_file: non_constant_identifier_names

import 'package:app/components/floating_back_to_top/index.dart';
import 'package:app/components/floating_back_to_top/style.dart'
    as floating_back_to_top_style;
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/author_center/models/creator_backend_models.dart';
import 'package:app/pages/author_center/widgets/backend_work_card.dart';
import 'package:app/pages/author_center/widgets/creator_empty_state.dart';
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
  final List<CreatorWorkModel> works;

  /// 首屏或刷新请求状态；刷新期间继续保留已有列表。
  final bool is_loading;
  final bool is_loading_more;
  final String? error_message;
  final String? load_more_error;
  final bool has_more;
  final int? total_count;
  final Future<void> Function()? on_refresh;
  final Future<void> Function()? on_load_more;

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
  final ValueChanged<CreatorWorkModel> on_edit_work;

  /// 长按作品回调（弹出操作菜单）。
  final ValueChanged<CreatorWorkModel> on_long_press_work;

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
    required this.on_long_press_work,
    this.is_loading = false,
    this.is_loading_more = false,
    this.error_message,
    this.load_more_error,
    this.has_more = false,
    this.total_count,
    this.on_refresh,
    this.on_load_more,
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

  bool _load_more_in_flight = false;
  String? _local_load_more_error;
  String? _local_refresh_error;

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
                child: NotificationListener<ScrollNotification>(
                  onNotification: _on_scroll_notification,
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    color: Theme.of(context).primaryColor,
                    backgroundColor: AuthorStyle.surface(widget.is_dark),
                    edgeOffset: widget.header_spacer_height,
                    displacement: 24,
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

  Future<void> _refresh() async {
    if (widget.on_refresh == null) return;
    setState(() {
      _local_refresh_error = null;
      _local_load_more_error = null;
    });
    try {
      await widget.on_refresh!();
    } catch (_) {
      if (mounted) setState(() => _local_refresh_error = easy.tr('creator_center.works_load_failed'));
    }
  }

  /// 只响应向下滚动列表的动作，首帧和 rebuild 不触发网络请求。
  bool _on_scroll_notification(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final bool toward_end =
        (notification is ScrollUpdateNotification &&
            (notification.scrollDelta ?? 0) > 0) ||
        (notification is OverscrollNotification && notification.overscroll > 0);
    if (toward_end && notification.metrics.extentAfter < 280) {
      _load_more();
    }
    return false;
  }

  Future<void> _load_more({bool retry = false}) async {
    if (!mounted ||
        widget.on_load_more == null ||
        !widget.has_more ||
        widget.is_loading ||
        widget.is_loading_more ||
        _load_more_in_flight ||
        (!retry &&
            (widget.load_more_error != null ||
                _local_load_more_error != null))) {
      return;
    }

    // 先锁住本次手势，再退出滚动通知的布局阶段后更新状态和请求。
    _load_more_in_flight = true;
    await Future<void>.value();
    if (!mounted) return;
    setState(() => _local_load_more_error = null);
    try {
      await widget.on_load_more!();
    } catch (_) {
      if (mounted) _local_load_more_error = easy.tr('creator_center.load_more_failed');
    } finally {
      if (mounted) setState(() => _load_more_in_flight = false);
    }
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

  /// 根据作品数据构建列表、加载状态或空状态。
  List<Widget> _build_slivers(
    BuildContext context, {
    required double viewport_height,
  }) {
    final Widget header_spacer = SliverToBoxAdapter(
      child: SizedBox(height: widget.header_spacer_height),
    );
    final String? refresh_error = widget.error_message ?? _local_refresh_error;

    if (widget.works.isEmpty) {
      return <Widget>[
        header_spacer,
        SliverToBoxAdapter(
          child: _constrain_content(
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                    top: AuthorStyle.list_header_top_spacing,
                    bottom: 30,
                  ),
                  child: _build_list_header(),
                ),
                widget.is_loading
                    ? _build_initial_loading()
                    : refresh_error != null
                    ? _build_initial_error(refresh_error)
                    : CreatorEmptyState(
                        tab_index: widget.tab_index,
                        is_dark: widget.is_dark,
                        is_cjk: widget.is_cjk,
                        on_create_work: widget.on_create_work,
                      ),
              ],
            ),
          ),
        ),
        _build_minimum_scroll_extent_filler(),
      ];
    }

    return <Widget>[
      header_spacer,
      if (refresh_error != null)
        SliverToBoxAdapter(
          child: _constrain_content(
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _build_error_notice(refresh_error, on_retry: _refresh),
            ),
          ),
        ),
      SliverToBoxAdapter(
        child: _constrain_content(
          Padding(
            padding: const EdgeInsets.only(
              top: AuthorStyle.list_header_top_spacing,
              bottom: AuthorStyle.list_header_bottom_spacing,
            ),
            child: _build_list_header(),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(
          horizontal: AuthorStyle.page_padding,
        ),
        sliver: _AnimatedWorkList(
          works: widget.works,
          is_dark: widget.is_dark,
          is_cjk: widget.is_cjk,
          on_edit_work: widget.on_edit_work,
          on_long_press_work: widget.on_long_press_work,
        ),
      ),
      SliverToBoxAdapter(
        child: _constrain_content(
          Padding(
            padding: EdgeInsets.only(
              top: 16,
              bottom:
                  AuthorStyle.list_bottom_spacing +
                  MediaQuery.paddingOf(context).bottom,
            ),
            child: _build_load_more_footer(),
          ),
        ),
      ),
      _build_minimum_scroll_extent_filler(),
    ];
  }

  Widget _constrain_content(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AuthorStyle.page_padding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AuthorStyle.content_max_width,
          ),
          child: child,
        ),
      ),
    );
  }

  /// 在首次布局中即补齐短内容的最小滚动范围。
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

  String get _list_title_key {
    switch (widget.tab_index) {
      case 0:
        return 'creator_center.list_title_published';
      case 1:
        return 'creator_center.filter_long_unpublished';
      case 2:
        return 'creator_center.filter_short_unpublished';
      default:
        return 'creator_center.filter_off_shelf';
    }
  }

  Widget _build_list_header() {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                easy.tr(_list_title_key),
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
                easy.tr('creator_center.sort_by_recent'),
                maxLines: 2,
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
        Builder(
          builder: (context) {
            final Color tag_color = ColorConstants.tagColorList[widget.tab_index % ColorConstants.tagColorList.length];
            final Color tag_bg = tag_color.withValues(alpha: 0.12);
            return Container(
              constraints: const BoxConstraints(minWidth: 34),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: tag_bg,
                borderRadius: BorderRadius.circular(AuthorStyle.pill_radius),
              ),
              alignment: Alignment.center,
              child: Text(
                '${widget.total_count ?? widget.works.length}',
                style: TextStyle(
                  color: tag_color,
                  fontSize: 12,
                  fontWeight: AuthorStyle.title_weight,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _build_initial_loading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 72),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _build_progress(),
            const SizedBox(height: 15),
            Text(
              easy.tr('creator_center.loading_works'),
              style: TextStyle(
                color: AuthorStyle.secondary_text(widget.is_dark),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build_initial_error(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 72),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AuthorStyle.secondary_surface(widget.is_dark),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: SvgIcon(
                  name: 'offline',
                  width: 32,
                  height: 32,
                  color: AuthorStyle.secondary_text(widget.is_dark),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              easy.tr('creator_center.works_load_failed'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AuthorStyle.primary_text(widget.is_dark),
                fontSize: 17,
                fontWeight: AuthorStyle.title_weight,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AuthorStyle.secondary_text(widget.is_dark),
                fontSize: 12.5,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 18),
            widget.is_dark
                ? OutlinedButton.icon(
                    onPressed: widget.on_refresh == null ? null : _refresh,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(easy.tr('creator_center.reload')),
                    style: _retry_button_style(),
                  )
                : ElevatedButton.icon(
                    onPressed: widget.on_refresh == null ? null : _refresh,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(easy.tr('creator_center.reload')),
                    style: _retry_button_style(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _build_load_more_footer() {
    if (widget.is_loading_more || _load_more_in_flight) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(child: _build_progress()),
      );
    }
    final String? message = widget.load_more_error ?? _local_load_more_error;
    if (message != null) {
      return _build_error_notice(
        message,
        on_retry: () => _load_more(retry: true),
      );
    }
    if (widget.has_more) {
      // 同时保留按钮，短列表、辅助功能和桌面设备也能继续翻页。
      return Center(
        child: TextButton(
          onPressed: widget.on_load_more == null ? null : _load_more,
          style: TextButton.styleFrom(
            foregroundColor: AuthorStyle.selected_tab_text(widget.is_dark),
          ),
          child: Text(easy.tr('creator_center.load_more')),
        ),
      );
    }
    final bool is_published_tab = widget.tab_index == 0;
    final bool is_off_shelf_tab = widget.tab_index == 3;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        easy.tr(is_off_shelf_tab
            ? 'creator_center.status_off_shelf'
            : is_published_tab
                ? 'creator_center.all_works_shown'
                : 'creator_center.all_unpublished_shown'),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AuthorStyle.secondary_text(widget.is_dark),
          fontSize: 11.5,
        ),
      ),
    );
  }

  Widget _build_error_notice(String message, {required VoidCallback on_retry}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AuthorStyle.secondary_surface(widget.is_dark),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AuthorStyle.secondary_text(widget.is_dark),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          TextButton.icon(
            onPressed: on_retry,
            style: TextButton.styleFrom(
              foregroundColor: AuthorStyle.selected_tab_text(widget.is_dark),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: Text(easy.tr('creator_center.reload')),
          ),
        ],
      ),
    );
  }

  ButtonStyle _retry_button_style() => widget.is_dark
      ? OutlinedButton.styleFrom(
          foregroundColor: ColorConstants.themeColor,
          side: BorderSide(color: AuthorStyle.border(widget.is_dark)),
          minimumSize: const Size(120, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        )
      : ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.themeColor,
          foregroundColor: Colors.black,
          elevation: 0,
          minimumSize: const Size(120, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        );

  Widget _build_progress() {
    return SizedBox.square(
      dimension: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: ColorConstants.themeColor,
      ),
    );
  }
}

/// 作品列表。
///
/// 支持乐观删除动画：使用 [GlobalKey] 追踪每个卡片的高度，
/// 删除时先测量高度，再通过 [SizeTransition] 播放收起动画。
class _AnimatedWorkList extends StatefulWidget {
  final List<CreatorWorkModel> works;
  final bool is_dark;
  final bool is_cjk;
  final ValueChanged<CreatorWorkModel> on_edit_work;
  final ValueChanged<CreatorWorkModel> on_long_press_work;

  const _AnimatedWorkList({
    required this.works,
    required this.is_dark,
    required this.is_cjk,
    required this.on_edit_work,
    required this.on_long_press_work,
  });

  @override
  State<_AnimatedWorkList> createState() => _AnimatedWorkListState();
}

class _AnimatedWorkListState extends State<_AnimatedWorkList>
    with TickerProviderStateMixin {
  final Map<int, AnimationController> _removing = {};
  final Map<int, double> _item_heights = {};

  @override
  void dispose() {
    for (final c in _removing.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// 触发删除动画（由外部确认后调用）。
  void animate_remove(CreatorWorkModel work) {
    if (_removing.containsKey(work.id)) return;
    _animate_remove_impl(work);
  }

  void _animate_remove_impl(CreatorWorkModel work) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _removing[work.id] = controller;

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
        _removing.remove(work.id);
        _item_heights.remove(work.id);
      }
    });

    controller.forward();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<CreatorWorkModel> visible = widget.works
        .where((w) => !_removing.containsKey(w.id) || _removing[w.id]!.isAnimating)
        .toList();

    if (visible.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverList.builder(
      itemCount: visible.length,
      itemBuilder: (BuildContext context, int index) {
        final CreatorWorkModel work = visible[index];
        final AnimationController? controller = _removing[work.id];

        Widget card = Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AuthorStyle.content_max_width,
            ),
            child: BackendWorkCard(
              key: ValueKey<int>(work.id),
              work: work,
              is_dark: widget.is_dark,
              is_cjk: widget.is_cjk,
              on_tap: () => widget.on_edit_work(work),
              on_long_press: () => widget.on_long_press_work(work),
            ),
          ),
        );

        if (controller != null) {
          // 阶段1 (0~0.4): 淡出 + 向上微移
          // 阶段2 (0.3~1.0): 高度收缩
          final fade = Tween<double>(begin: 1, end: 0).animate(
            CurvedAnimation(
              parent: controller,
              curve: const Interval(0, 0.4, curve: Curves.easeOut),
            ),
          );
          final slide = Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(0, -0.15),
          ).animate(
            CurvedAnimation(
              parent: controller,
              curve: const Interval(0, 0.4, curve: Curves.easeOut),
            ),
          );
          final size = CurvedAnimation(
            parent: controller,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
          );

          return SizeTransition(
            sizeFactor: size,
            child: FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: slide,
                child: card,
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: index < visible.length - 1
                ? AuthorStyle.work_card_spacing
                : 0,
          ),
          child: _MeasureSize(
            on_size: (size) => _item_heights[work.id] = size.height,
            child: card,
          ),
        );
      },
    );
  }
}

/// 测量子组件实际高度的包装组件。
class _MeasureSize extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> on_size;

  const _MeasureSize({required this.child, required this.on_size});

  @override
  State<_MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<_MeasureSize> {
  Size? _last_size;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final Size size = box.size;
      if (_last_size != size) {
        _last_size = size;
        widget.on_size(size);
      }
    });
    return widget.child;
  }
}
