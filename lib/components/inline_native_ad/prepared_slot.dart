import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:app/pages/short_story_read/widgets/native_ad_banner.dart';

import 'style.dart';
import 'scroll_offset_compensation.dart';

/// 将素材加载与阅读列表布局分开，业务组件仅负责创建自己的广告。
typedef PreparedNativeAdBuilder =
    Widget Function(
      BuildContext context, {
      required bool attach_ad,
      required bool reserve_space,
      required ValueChanged<NativeAdLoadStatus> on_load_status_changed,
      required ValueChanged<double> on_layout_height_changed,
      required VoidCallback on_ad_attached,
    });

/// 只在素材和尺寸都就绪、段落边界仍在屏幕下方时提交广告位。
///
/// 准备期间保留零高度锚点。读者先到达该边界时放弃本次广告，
/// 避免晚到素材突然挤动正在阅读的下一段正文。
class PreparedNativeAdSlot extends StatefulWidget {
  /// 阅读列表控制器，用于在滚动后的布局帧检查真实可见范围。
  final ScrollController scroll_controller;

  /// 创建独立广告实例；回调同时用于确认素材、尺寸和首次挂载。
  final PreparedNativeAdBuilder builder;

  /// 卡片前后的装饰间距，不参与原生平台视图的可见性判断。
  final double leading_extent;
  final double trailing_extent;

  /// 安全区下方被页面浮层遮挡的高度，首次挂载必须避开该区域。
  final double viewport_top_inset;

  /// 正文字号、预览范围等会移动段落边界的布局版本。
  ///
  /// 普通进度重建不改变它，正文重新排版时则撤销尚未完成的首次挂载。
  final Object? layout_revision;

  /// 广告业务开关；关闭时立即释放素材，已插入的高度在安全位置收回。
  final bool is_enabled;

  /// 业务关闭后收回屏内广告高度，避免免广告阅读留下可见空位。
  ///
  /// 仅补偿视口顶部之外的高度；需要补偿时等待滚动结束，防止打断手势。
  final bool collapse_when_disabled;

  /// 真正提交广告位尺寸后通知阅读页，供正文进度范围重新计算。
  final ValueChanged<double>? on_extent_changed;

  /// 缓存列表恢复时沿用已经提交的广告尺寸，避免重建时折叠排版。
  final double? initial_reserved_extent;

  /// 单列列表可补偿屏幕上方的高度差；瀑布流重排时应保持原有尺寸。
  final bool resize_above_viewport;

  /// 未能及时就绪的广告被放弃后，列表可记录边界并释放预加载素材。
  final VoidCallback? on_skipped;

  /// 短阅读窗口可保留已展示视图；无限信息流离屏后卸载以减少原生资源。
  final bool retain_attachment_offscreen;

  /// 仅在视口附近保留素材监听；无限值沿用阅读窗口的预加载行为。
  final double preload_viewport_count;

  const PreparedNativeAdSlot({
    super.key,
    required this.scroll_controller,
    required this.builder,
    this.leading_extent = InlineNativeAdStyle.spacing_top,
    this.trailing_extent = InlineNativeAdStyle.spacing_bottom,
    this.viewport_top_inset = 0,
    this.layout_revision,
    this.is_enabled = true,
    this.collapse_when_disabled = false,
    this.on_extent_changed,
    this.initial_reserved_extent,
    this.resize_above_viewport = true,
    this.on_skipped,
    this.retain_attachment_offscreen = true,
    this.preload_viewport_count = double.infinity,
  });

  @override
  State<PreparedNativeAdSlot> createState() => _PreparedNativeAdSlotState();
}

class _PreparedNativeAdSlotState extends State<PreparedNativeAdSlot>
    with WidgetsBindingObserver {
  /// 零高度预加载锚点与提交后的广告位共用一个定位 key。
  final GlobalKey _slot_key = GlobalKey();

  /// 素材和原生测量分别到达，二者同时就绪才可安排广告。
  bool _is_loaded = false;
  double? _card_height;

  /// 布局一经提交便保持稳定，不随异步重载暂时折叠。
  double? _reserved_extent;

  /// 区分帧末批准的高度与已完成布局的高度，避免插位批准后读者已越过。
  bool _has_laid_out_reservation = false;

  /// 上一帧真实位置；同一布局内可用滚动差值判断卡片是否仍然可见。
  ({
    double slot_top,
    double scroll_offset,
    double viewport_top,
    double viewport_bottom,
  })?
  _last_layout_geometry;

  /// 屏幕和字体缩放的布局依赖，变化后不能复用上一帧的可见性批准。
  Object? _layout_environment;

  /// 重载后的不同尺寸必须在安全位置应用，不能挤动当前可见正文。
  double? _pending_card_height;

  /// 等待滚动结束后补偿屏幕上方广告尺寸的变化。
  ScrollPosition? _observed_position;

  /// 首页横向 Tab 的位置会改变广告的屏幕坐标，必须独立于内层竖向滚动监听。
  final Set<ScrollPosition> _horizontal_positions = <ScrollPosition>{};

  /// 被其他路由覆盖、横向移出屏幕或 Offstage 时暂停首次挂载与跳过判定。
  bool _is_route_current = true;
  bool _is_surface_active = true;
  bool _is_app_active = true;

  /// 已错过的段落边界不会因广告后到或反向滚动而重新插入。
  bool _is_skipped = false;

  /// 重载失败时等待广告位完全离开视口，再安全收回高度。
  bool _is_failed = false;

  /// 当前广告实例的首次挂载门禁，不复用上一次素材的可见性。
  bool _can_attach_ad = false;
  bool _has_attached_ad = false;

  /// 远处卡片仍保留排版决策，但不创建广告子组件或占用素材池监听。
  bool _is_near_viewport = true;

  /// 同一帧的滚动、素材和测量回调合并为一次布局检查。
  bool _visibility_update_scheduled = false;

  /// 布局阶段发生滚动时，将门禁撤销同步到下一次安全重建。
  bool _attachment_gate_dirty = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final AppLifecycleState? lifecycle_state =
        WidgetsBinding.instance.lifecycleState;
    _is_app_active =
        lifecycle_state == null || lifecycle_state == AppLifecycleState.resumed;
    _is_near_viewport = widget.preload_viewport_count.isInfinite;
    final double? initial_extent = widget.initial_reserved_extent;
    if (initial_extent != null &&
        initial_extent.isFinite &&
        initial_extent > 0) {
      _reserved_extent = initial_extent;
    }
    _is_skipped = !widget.is_enabled && _reserved_extent == null;
    _is_failed = !widget.is_enabled;
    widget.scroll_controller.addListener(_on_scroll_changed);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool route_is_current = ModalRoute.of(context)?.isCurrent ?? true;
    if (_is_route_current != route_is_current) {
      _is_route_current = route_is_current;
      _last_layout_geometry = null;
      _can_attach_ad = false;
      _has_attached_ad = false;
      _attachment_gate_dirty = true;
    }
    // ShellTabPane 保留同一个 Home 子组件，仅切换 Offstage 与 TickerMode。
    // 依赖 TickerMode 的继承通知，隐藏和恢复时都需复验，不能等待新的滚动。
    final bool ticker_mode_enabled = TickerMode.of(context);
    if (!ticker_mode_enabled && _has_offstage_ancestor()) {
      // 关闭 ticker 本身只表示动画暂停；实际 Offstage 才撤销已展示视图。
      _last_layout_geometry = null;
      _is_surface_active = false;
      _can_attach_ad = false;
      _has_attached_ad = false;
      _attachment_gate_dirty = true;
    }
    _observe_horizontal_positions();
    final MediaQueryData media_query = MediaQuery.of(context);
    final Object environment = (
      media_query.size,
      media_query.viewPadding,
      media_query.textScaler,
    );
    if (_layout_environment != environment) {
      final bool had_environment = _layout_environment != null;
      _layout_environment = environment;
      if (had_environment) _invalidate_layout_approval();
    }
    _schedule_visibility_update();
  }

  @override
  void didUpdateWidget(PreparedNativeAdSlot old_widget) {
    super.didUpdateWidget(old_widget);
    if (old_widget.is_enabled != widget.is_enabled) {
      _is_loaded = false;
      _is_failed = !widget.is_enabled;
      _card_height = null;
      _pending_card_height = null;
      _can_attach_ad = false;
      _has_attached_ad = false;
      if (!widget.is_enabled && !_reservation_has_layout()) {
        final bool had_pending_extent = _reserved_extent != null;
        _reserved_extent = null;
        _mark_skipped();
        if (had_pending_extent) widget.on_extent_changed?.call(0);
      }
    }
    if (old_widget.layout_revision != widget.layout_revision ||
        old_widget.viewport_top_inset != widget.viewport_top_inset ||
        old_widget.leading_extent != widget.leading_extent ||
        old_widget.trailing_extent != widget.trailing_extent ||
        old_widget.scroll_controller != widget.scroll_controller) {
      _invalidate_layout_approval();
    }
    if (old_widget.scroll_controller != widget.scroll_controller) {
      old_widget.scroll_controller.removeListener(_on_scroll_changed);
      widget.scroll_controller.addListener(_on_scroll_changed);
      _observe_scroll_position();
    }
    _observe_horizontal_positions();
    _schedule_visibility_update();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.scroll_controller.removeListener(_on_scroll_changed);
    for (final ScrollPosition position in _horizontal_positions) {
      position.removeListener(_on_horizontal_scroll_changed);
    }
    _observed_position?.isScrollingNotifier.removeListener(
      _schedule_visibility_update,
    );
    super.dispose();
  }

  /// 正文重新排版后等新布局确认位置；已实际插入的尺寸继续保持稳定。
  void _invalidate_layout_approval() {
    _last_layout_geometry = null;
    if (_can_retain_without_recheck) return;
    _can_attach_ad = false;
    _attachment_gate_dirty = true;
    if (_reserved_extent != null && !_reservation_has_layout()) {
      _reserved_extent = null;
      widget.on_extent_changed?.call(0);
    }
  }

  /// 检查首个广告高度是否已经真正写入渲染树。
  bool _reservation_has_layout() {
    if (_has_laid_out_reservation) return true;
    final RenderObject? render_object = _slot_key.currentContext
        ?.findRenderObject();
    if (_reserved_extent != null &&
        render_object is RenderBox &&
        render_object.hasSize &&
        render_object.size.height == _reserved_extent) {
      _has_laid_out_reservation = true;
    }
    return _has_laid_out_reservation;
  }

  /// 连续滚动仍可见时保留批准，真正离屏或尚未落地的插位已错过才撤销。
  void _on_scroll_changed() {
    final geometry = _last_layout_geometry;
    if (_is_skipped || _can_retain_without_recheck || geometry == null) return;
    if (!widget.scroll_controller.hasClients ||
        !identical(widget.scroll_controller.position, _observed_position)) {
      return;
    }
    final double current_slot_top =
        geometry.slot_top -
        (widget.scroll_controller.offset - geometry.scroll_offset);
    bool needs_rebuild = false;
    if (_reserved_extent != null &&
        !_reservation_has_layout() &&
        current_slot_top <
            geometry.viewport_bottom +
                InlineNativeAdStyle.insertion_safety_spacing) {
      _reserved_extent = null;
      _mark_skipped();
      _can_attach_ad = false;
      needs_rebuild = true;
      widget.on_extent_changed?.call(0);
    } else if (_can_attach_ad &&
        (_card_height == null ||
            !_is_card_visible(
              slot_top: current_slot_top,
              card_height: _card_height!,
              viewport_top: geometry.viewport_top,
              viewport_bottom: geometry.viewport_bottom,
            ))) {
      _can_attach_ad = false;
      needs_rebuild = true;
    }
    if (needs_rebuild) {
      _attachment_gate_dirty = true;
      if (SchedulerBinding.instance.schedulerPhase !=
          SchedulerPhase.persistentCallbacks) {
        setState(() {});
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
    }
    _schedule_visibility_update();
  }

  /// 首次挂载必须使用当前帧的位置；预加载成功本身不开放平台视图。
  void _schedule_visibility_update() {
    if (_visibility_update_scheduled ||
        _is_skipped ||
        _can_retain_without_recheck)
      return;
    _visibility_update_scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibility_update_scheduled = false;
      if (!mounted || _is_skipped || _can_retain_without_recheck) return;
      _update_visibility();
    });
  }

  /// 提交发生在可视区下方；首次挂载检查真正的卡片而非顶部空白。
  void _update_visibility() {
    _observe_scroll_position();
    final RenderObject? render_object = _slot_key.currentContext
        ?.findRenderObject();
    if (render_object is! RenderBox || !render_object.hasSize) return;

    if (!_is_route_current ||
        (!_is_app_active && !_can_retain_without_recheck)) {
      _hide_surface();
      return;
    }
    final MediaQueryData media_query = MediaQuery.of(context);
    Rect visible_bounds = Rect.fromLTRB(
      media_query.viewPadding.left,
      media_query.viewPadding.top + widget.viewport_top_inset,
      media_query.size.width - media_query.viewPadding.right,
      media_query.size.height - media_query.viewPadding.bottom,
    );
    bool has_viewport = false;
    RenderObject? ancestor = render_object;
    while (ancestor != null) {
      if (ancestor is RenderOffstage && ancestor.offstage) {
        _hide_surface();
        return;
      }
      final RenderBox? viewport_box = ancestor is RenderBox ? ancestor : null;
      if (ancestor is RenderAbstractViewport &&
          viewport_box != null &&
          viewport_box.hasSize) {
        has_viewport = true;
        // 内层纵向 viewport 可能仍在窗口坐标内，但已被外层 Tab viewport 裁掉。
        final Offset origin = viewport_box.localToGlobal(Offset.zero);
        final Rect bounds = origin & viewport_box.size;
        if (!bounds.isFinite) return;
        visible_bounds = visible_bounds.intersect(bounds);
      }
      ancestor = ancestor.parent;
    }
    if (!has_viewport) return;
    final Offset slot_origin = render_object.localToGlobal(Offset.zero);
    final double slot_top = slot_origin.dy;
    final double visible_width =
        math.min(
          slot_origin.dx + render_object.size.width,
          visible_bounds.right,
        ) -
        math.max(slot_origin.dx, visible_bounds.left);
    if (!slot_top.isFinite || !slot_origin.dx.isFinite) return;
    if (visible_bounds.isEmpty ||
        visible_width < InlineNativeAdStyle.minimum_visible_extent) {
      _hide_surface();
      return;
    }
    final double viewport_top = visible_bounds.top;
    final double viewport_bottom = visible_bounds.bottom;
    if (!_is_surface_active) setState(() => _is_surface_active = true);
    _last_layout_geometry = (
      slot_top: slot_top,
      scroll_offset: _observed_position?.pixels ?? 0,
      viewport_top: viewport_top,
      viewport_bottom: viewport_bottom,
    );
    _reservation_has_layout();
    final double preload_extent =
        (viewport_bottom - viewport_top) * widget.preload_viewport_count;
    final bool is_near_viewport =
        widget.preload_viewport_count.isInfinite ||
        (slot_top <= viewport_bottom + preload_extent &&
            slot_top + (_reserved_extent ?? 0) >=
                viewport_top - preload_extent);
    if (_is_near_viewport != is_near_viewport) {
      setState(() {
        _is_near_viewport = is_near_viewport;
        if (!is_near_viewport) {
          _is_loaded = false;
          _card_height = null;
          _pending_card_height = null;
          _can_attach_ad = false;
          _has_attached_ad = false;
        }
      });
    }

    if (_is_failed && _reserved_extent != null) {
      final bool is_below_viewport = slot_top >= viewport_bottom;
      final bool is_above_viewport =
          slot_top + _reserved_extent! <= viewport_top;
      final ScrollPosition? position = _observed_position;
      // 业务关闭与加载失败分开处理：免广告生效后无需等空位滚出屏幕。
      // 跨顶部的广告只补偿已滚过去的部分，让剩余可见空位由正文填满。
      final double removed_extent_above_viewport = (viewport_top - slot_top)
          .clamp(0.0, _reserved_extent!);
      final bool can_collapse_disabled_slot =
          !widget.is_enabled &&
          widget.collapse_when_disabled &&
          (removed_extent_above_viewport == 0 ||
              (widget.resize_above_viewport &&
                  position != null &&
                  !position.isScrollingNotifier.value));
      if (can_collapse_disabled_slot ||
          is_below_viewport ||
          (widget.resize_above_viewport &&
              is_above_viewport &&
              position != null &&
              !position.isScrollingNotifier.value)) {
        setState(() {
          _reserved_extent = null;
          _pending_card_height = null;
          _card_height = null;
          _mark_skipped();
        });
        widget.on_extent_changed?.call(0);
        if (removed_extent_above_viewport > 0 && position != null) {
          queue_native_ad_scroll_compensation(
            position: position,
            extent_delta: -removed_extent_above_viewport,
            is_valid: () => mounted && identical(_observed_position, position),
          );
        }
      }
      return;
    }

    if (_is_loaded &&
        _pending_card_height != null &&
        _reserved_extent != null) {
      final bool is_below_viewport = slot_top >= viewport_bottom;
      final bool is_above_viewport =
          slot_top + _reserved_extent! <= viewport_top;
      final ScrollPosition? position = _observed_position;
      if (is_below_viewport ||
          (widget.resize_above_viewport &&
              is_above_viewport &&
              position != null &&
              !position.isScrollingNotifier.value)) {
        final double next_extent =
            widget.leading_extent +
            _pending_card_height! +
            widget.trailing_extent;
        final double extent_delta = next_extent - _reserved_extent!;
        setState(() {
          _card_height = _pending_card_height;
          _pending_card_height = null;
          _reserved_extent = next_extent;
        });
        widget.on_extent_changed?.call(next_extent);
        if (is_above_viewport && position != null && extent_delta != 0) {
          queue_native_ad_scroll_compensation(
            position: position,
            extent_delta: extent_delta,
            is_valid: () => mounted && identical(_observed_position, position),
          );
        }
        _schedule_visibility_update();
        return;
      }
    }

    if (_reserved_extent == null) {
      if (slot_top <
          viewport_bottom + InlineNativeAdStyle.insertion_safety_spacing) {
        setState(_mark_skipped);
        return;
      }
      if (!_is_loaded || _card_height == null) return;
      setState(() {
        _reserved_extent =
            widget.leading_extent + _card_height! + widget.trailing_extent;
      });
      widget.on_extent_changed?.call(_reserved_extent!);
      // 预留高度后的布局帧才能测量真实卡片，当前帧不能挂载。
      _schedule_visibility_update();
      return;
    }

    if (!_is_loaded || _card_height == null) return;
    final bool is_visible = _is_card_visible(
      slot_top: slot_top,
      card_height: _card_height!,
      viewport_top: viewport_top,
      viewport_bottom: viewport_bottom,
    );
    if (_can_attach_ad == is_visible && !_attachment_gate_dirty) return;
    setState(() {
      _can_attach_ad = is_visible;
      _attachment_gate_dirty = false;
    });
  }

  /// 真实测量与同一布局中的滚动预测共用卡片边界，装饰留白不算曝光。
  bool _is_card_visible({
    required double slot_top,
    required double card_height,
    required double viewport_top,
    required double viewport_bottom,
  }) {
    final double card_top = slot_top + widget.leading_extent;
    final double card_bottom = card_top + card_height;
    return card_top <=
            viewport_bottom - InlineNativeAdStyle.minimum_visible_extent &&
        card_bottom >=
            viewport_top + InlineNativeAdStyle.minimum_visible_extent;
  }

  /// 普通阅读页已经展示的视图可保留；嵌套横向 Tab 必须继续观察外层位置。
  bool get _can_retain_without_recheck =>
      _has_attached_ad &&
      widget.retain_attachment_offscreen &&
      widget.preload_viewport_count.isInfinite &&
      _horizontal_positions.isEmpty &&
      _is_route_current &&
      _is_surface_active;

  /// 只观察影响横向可见性的祖先，避免复制内层竖向滚动的进度监听。
  void _observe_horizontal_positions() {
    // 同一 PageView 更换 controller 时依赖其 ScrollableScope，及时解绑旧位置。
    Scrollable.maybeOf(context, axis: Axis.horizontal);
    final Set<ScrollPosition> positions = <ScrollPosition>{};
    context.visitAncestorElements((element) {
      if (element is StatefulElement && element.state is ScrollableState) {
        final ScrollPosition position =
            (element.state as ScrollableState).position;
        if (axisDirectionToAxis(position.axisDirection) == Axis.horizontal) {
          positions.add(position);
        }
      }
      return true;
    });
    for (final ScrollPosition old_position in _horizontal_positions) {
      if (!positions.contains(old_position)) {
        old_position.removeListener(_on_horizontal_scroll_changed);
      }
    }
    for (final ScrollPosition position in positions) {
      if (!_horizontal_positions.contains(position)) {
        position.addListener(_on_horizontal_scroll_changed);
      }
    }
    _horizontal_positions
      ..clear()
      ..addAll(positions);
  }

  /// 横向移动发生后不能沿用上一帧挂载批准；已挂载素材等待真实离屏再撤下。
  void _on_horizontal_scroll_changed() {
    if (!mounted || _is_skipped) return;
    _last_layout_geometry = null;
    if (!_has_attached_ad && _can_attach_ad) {
      _can_attach_ad = false;
      _attachment_gate_dirty = true;
      _request_safe_rebuild();
    }
    _schedule_visibility_update();
  }

  /// 应用不在前台时只允许保留已展示的阅读视图，不首次创建平台广告。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bool is_active = state == AppLifecycleState.resumed;
    if (!mounted || _is_app_active == is_active) return;
    _is_app_active = is_active;
    _last_layout_geometry = null;
    if (!is_active && !_can_retain_without_recheck) {
      _can_attach_ad = false;
      _has_attached_ad = false;
      _attachment_gate_dirty = true;
      _request_safe_rebuild();
    }
    _schedule_visibility_update();
  }

  /// 被隐藏的 Tab 保留阅读几何与概率决策，不能误当成读者已经越过边界。
  void _hide_surface() {
    _last_layout_geometry = null;
    final bool drop_preload = widget.preload_viewport_count.isFinite;
    if (!_is_surface_active &&
        !_can_attach_ad &&
        !_has_attached_ad &&
        (!drop_preload || !_is_near_viewport)) {
      return;
    }
    setState(() {
      _is_surface_active = false;
      _can_attach_ad = false;
      _has_attached_ad = false;
      _attachment_gate_dirty = true;
      if (drop_preload) {
        _is_near_viewport = false;
        _is_loaded = false;
        _card_height = null;
        _pending_card_height = null;
      }
    });
  }

  /// 来自父 viewport 的滚动可发生在布局阶段，下一帧才安全重建广告子组件。
  void _request_safe_rebuild() {
    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      setState(() {});
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  /// 构建阶段也检查 Offstage，避免上一帧已批准的请求在隐藏后才首次挂载。
  bool _has_offstage_ancestor() {
    RenderObject? ancestor = _slot_key.currentContext?.findRenderObject();
    while (ancestor != null) {
      if (ancestor is RenderOffstage && ancestor.offstage) return true;
      ancestor = ancestor.parent;
    }
    return false;
  }

  /// 绑定当前列表位置，惯性滚动结束后重试尚未安全应用的尺寸。
  void _observe_scroll_position() {
    final ScrollPosition? position = widget.scroll_controller.hasClients
        ? widget.scroll_controller.position
        : null;
    if (identical(position, _observed_position)) return;
    _observed_position?.isScrollingNotifier.removeListener(
      _schedule_visibility_update,
    );
    _observed_position = position;
    position?.isScrollingNotifier.addListener(_schedule_visibility_update);
  }

  /// 重载清除旧素材的门禁，但保留已提交的正文几何尺寸。
  void _on_load_status_changed(NativeAdLoadStatus status) {
    if (!mounted || _is_skipped || !widget.is_enabled) return;
    setState(() {
      _is_loaded = status == NativeAdLoadStatus.loaded;
      _is_failed = status == NativeAdLoadStatus.failed;
      if (status == NativeAdLoadStatus.loading ||
          status == NativeAdLoadStatus.idle) {
        _card_height = null;
        _pending_card_height = null;
        _can_attach_ad = false;
        _has_attached_ad = false;
      }
      if (status == NativeAdLoadStatus.failed) {
        _can_attach_ad = false;
        _has_attached_ad = false;
        // 尚未提交布局时，失败广告直接释放，不留下任何空位。
        if (_reserved_extent == null) _mark_skipped();
      }
    });
    _schedule_visibility_update();
  }

  /// 只通知一次，回调安排在帧末，避免父列表在构建阶段被修改。
  void _mark_skipped() {
    if (_is_skipped) return;
    _is_skipped = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.on_skipped?.call();
    });
  }

  /// 接收本次素材的实际尺寸，支持测量与 loaded 回调的任意先后顺序。
  void _on_layout_height_changed(double height) {
    if (!mounted ||
        _is_skipped ||
        !widget.is_enabled ||
        !height.isFinite ||
        height <= 0) {
      return;
    }
    setState(() {
      final double next_extent =
          widget.leading_extent + height + widget.trailing_extent;
      if (_reserved_extent != null && next_extent != _reserved_extent) {
        _pending_card_height = height;
        _card_height = null;
        _can_attach_ad = false;
        _has_attached_ad = false;
      } else {
        _card_height = height;
        _pending_card_height = null;
      }
    });
    _schedule_visibility_update();
  }

  /// 已挂载实例可随列表正常滚动；新实例仍需重新通过可见性门禁。
  void _on_ad_attached() {
    if (!mounted ||
        _is_skipped ||
        !widget.is_enabled ||
        !_is_loaded ||
        !_can_attach_ad) {
      return;
    }
    // 平台首帧回调可能晚于同一帧的快速滚动，不能锁定上一帧的可见性。
    _update_visibility();
    if (!_can_attach_ad) return;
    _has_attached_ad = true;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: _slot_key,
      // 预加载子组件可能是零尺寸；锚点仍沿用卡片的实际可用宽度。
      width: double.infinity,
      height: _reserved_extent ?? 0,
      child: _is_skipped || !widget.is_enabled || !_is_near_viewport
          ? null
          : widget.builder(
              context,
              attach_ad:
                  _is_loaded &&
                  _can_attach_ad &&
                  _is_route_current &&
                  (_is_app_active || _can_retain_without_recheck) &&
                  !_has_offstage_ancestor(),
              reserve_space: _reserved_extent != null,
              on_load_status_changed: _on_load_status_changed,
              on_layout_height_changed: _on_layout_height_changed,
              on_ad_attached: _on_ad_attached,
            ),
    );
  }
}
