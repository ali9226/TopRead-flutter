import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/models/short_story_item.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/short_story_catalog_store.dart';
import 'package:app/pages/short_story_read/style.dart';
import 'package:app/pages/short_story_read/widgets/catalog/catalog_header.dart';
import 'package:app/pages/short_story_read/widgets/catalog/catalog_item.dart';
import 'package:app/pages/home/widgets/tab_contents/short_story_tab/style.dart';
import 'package:app/components/load_more_footer/index.dart';
import 'package:app/components/no_internet/index.dart';
import 'package:app/components/positioning/index.dart';

/// 目录弹窗组件。
///
/// 从屏幕底部滑出的半屏弹窗，展示短篇小说目录列表。
/// 接收外部逻辑层的响应式数据，自身仅管理分页和滚动。
///
/// 功能：
/// - 通过 [is_catalog_loading] 响应式切换骨架屏/数据列表
/// - 通过 [is_catalog_error] 响应式切换错误状态
/// - 支持下拉加载更多（使用 [no_ids] 排除已加载数据）
/// - 当前阅读中的小说高亮显示（主题色边框 + "阅读中"标记）
/// - 点击列表项跳转到对应小说
class CatalogSheet extends StatefulWidget {
  /// 当前阅读中的小说 ID（用于排除和高亮标记）。
  final int current_story_id;

  /// 外部逻辑层的目录列表数据（响应式）。
  final RxList<ShortStoryItem> catalog_list;

  /// 目录列表是否正在加载中（响应式，控制骨架屏显示）。
  final RxBool is_catalog_loading;

  /// 目录列表是否加载失败（响应式，控制无网络状态显示）。
  final RxBool is_catalog_error;

  /// 列表项点击回调（参数为小说 ID）。
  final void Function(int story_id) on_item_tap;

  /// 列表项点赞回调（参数为小说 ID）。
  final Future<void> Function(int story_id) on_like_tap;

  /// 关闭弹窗回调。
  final VoidCallback on_close;

  /// 重新加载目录回调。
  final VoidCallback on_reload;

  /// 当前阅读进度（0.0 ~ 1.0），用于在"阅读中"标记后显示百分比。
  final double reading_progress;

  const CatalogSheet({
    super.key,
    required this.current_story_id,
    required this.catalog_list,
    required this.is_catalog_loading,
    required this.is_catalog_error,
    required this.on_item_tap,
    required this.on_like_tap,
    required this.on_close,
    required this.on_reload,
    this.reading_progress = 0.0,
  });

  @override
  State<CatalogSheet> createState() => _CatalogSheetState();
}

class _CatalogSheetState extends State<CatalogSheet> {
  /// 滚动控制器（用于检测加载更多触发位置）。
  final ScrollController _scroll_controller = ScrollController();

  /// 是否正在加载更多数据。
  bool _is_loading_more = false;

  /// 短篇小说目录列表 Store。
  final ShortStoryCatalogStore _catalog_store =
      Get.find<ShortStoryCatalogStore>();

  /// 加载更多触发距离（距离底部多少像素时触发）。
  static const double _load_more_trigger_distance = 200;

  /// 页面水平内边距（与其他页面保持一致）。
  static const double _horizontal_padding =
      LayoutConfig.page_horizontal_padding;

  /// 目录列表真实可视区域。
  final GlobalKey _list_view_key = GlobalKey();

  /// 已构建目录项的布局锚点。
  final Map<int, GlobalKey> _item_keys = <int, GlobalKey>{};

  /// 目录列表中正在点赞的小说 ID 集合（控制转圈动画，本地管理）。
  final Set<int> _like_loading_ids = <int>{};

  /// 是否已自动滚动到当前阅读位置（仅首次数据加载时触发一次）。
  bool _has_scrolled_to_current = false;

  /// 防止同一时间重复执行定位。
  bool _is_locating_current = false;

  /// 防止响应式重建重复注册首次定位回调。
  bool _initial_positioning_scheduled = false;

  /// 当前阅读小说是否在可视区域内。
  bool _is_current_visible = true;

  @override
  void initState() {
    super.initState();
    _scroll_controller.addListener(_on_scroll);
  }

  @override
  void dispose() {
    _scroll_controller.removeListener(_on_scroll);
    _scroll_controller.dispose();
    super.dispose();
  }

  // ==================== 数据加载 ====================

  /// 滚动到当前阅读的小说位置。
  ///
  /// 通过“索引粗定位 + RenderObject 精定位”兼容不同高度的目录卡片。
  Future<bool> _scroll_to_current_story() async {
    if (_is_locating_current) return false;
    final int current_index = widget.catalog_list.indexWhere(
      (ShortStoryItem item) => item.id == widget.current_story_id,
    );
    if (current_index < 0) return false;

    _is_locating_current = true;
    try {
      for (int attempt = 0; attempt < 6; attempt++) {
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted || !_scroll_controller.hasClients) return false;

        final BuildContext? current_context = _item_key_for(
          widget.current_story_id,
        ).currentContext;
        if (current_context != null) {
          await Scrollable.ensureVisible(
            current_context,
            alignment: 0.28,
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
          );
          if (!mounted) return false;
          _check_current_visibility();
          return true;
        }

        final ScrollPosition position = _scroll_controller.position;
        final double target_offset = attempt == 0
            ? position.maxScrollExtent *
                  current_index /
                  math.max(1, widget.catalog_list.length - 1)
            : _estimate_next_offset(current_index, position);
        final double clamped_offset = target_offset.clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
        if ((clamped_offset - position.pixels).abs() < 0.5) break;
        _scroll_controller.jumpTo(clamped_offset);
      }
      _check_current_visibility();
      return false;
    } finally {
      _is_locating_current = false;
    }
  }

  GlobalKey _item_key_for(int story_id) {
    return _item_keys.putIfAbsent(story_id, GlobalKey.new);
  }

  double _estimate_next_offset(int target_index, ScrollPosition position) {
    final List<({int index, double top, double height})> visible_items =
        <({int index, double top, double height})>[];

    for (int index = 0; index < widget.catalog_list.length; index++) {
      final BuildContext? item_context =
          _item_keys[widget.catalog_list[index].id]?.currentContext;
      final RenderObject? render_object = item_context?.findRenderObject();
      if (render_object is! RenderBox ||
          !render_object.attached ||
          !render_object.hasSize) {
        continue;
      }
      visible_items.add((
        index: index,
        top: render_object.localToGlobal(Offset.zero).dy,
        height: render_object.size.height,
      ));
    }

    if (visible_items.isEmpty) {
      return position.maxScrollExtent *
          target_index /
          math.max(1, widget.catalog_list.length - 1);
    }

    visible_items.sort((a, b) => a.index.compareTo(b.index));
    final double average_extent =
        visible_items.fold<double>(
          0,
          (double total, item) => total + item.height,
        ) /
        visible_items.length;
    final int nearest_index = target_index < visible_items.first.index
        ? visible_items.first.index
        : visible_items.last.index;
    return position.pixels + (target_index - nearest_index) * average_extent;
  }

  /// 加载更多数据。
  ///
  /// 使用已加载数据的 ID 列表作为 [no_ids] 参数，排除已展示的数据。
  /// 加载结果为空时标记无更多数据。
  Future<void> _load_more_data() async {
    if (_is_loading_more || !_catalog_store.has_more) return;

    setState(() {
      _is_loading_more = true;
    });

    try {
      final List<int> no_ids = <int>{
        ...widget.catalog_list.map((ShortStoryItem item) => item.id),
        widget.current_story_id,
      }.toList();

      final ResultsType<List<ShortStoryItem>> results =
          await postRequest<List<ShortStoryItem>>(
            path: 'novel/short_story',
            parameter: <String, dynamic>{'no_ids': no_ids},
            showTips: false,
            fromJsonList: (List<dynamic> json) =>
                ShortStoryItem.from_json_list(json),
          );

      if (!mounted) return;

      if (results.status && results.content != null) {
        final int previous_length = _catalog_store.catalog_list.length;
        _catalog_store.append_catalog_list(results.content!);
        _catalog_store.has_more =
            results.content!.isNotEmpty &&
            _catalog_store.catalog_list.length > previous_length;
      }
    } catch (_) {
      // 网络失败不等于没有更多；保留状态以便用户再次触底重试。
    } finally {
      if (mounted) {
        setState(() {
          _is_loading_more = false;
        });
      }
    }
  }

  // ==================== 滚动监听 ====================

  /// 处理滚动事件。
  ///
  /// 当滚动位置接近底部时触发加载更多，并检测当前阅读小说是否在可视区域内。
  void _on_scroll() {
    if (!_scroll_controller.hasClients) return;

    final double position = _scroll_controller.position.pixels;
    final double max_extent = _scroll_controller.position.maxScrollExtent;

    if (position >= max_extent - _load_more_trigger_distance) {
      _load_more_data();
    }

    // 检测当前阅读小说是否在可视区域内。
    _check_current_visibility();
  }

  /// 检测当前阅读小说是否在可视区域内。
  ///
  /// 通过 GlobalKey 获取当前阅读小说的 RenderBox，
  /// 判断其是否在 ListView 的可视范围内。
  void _check_current_visibility() {
    if (!mounted) return;
    final BuildContext? item_context = _item_key_for(
      widget.current_story_id,
    ).currentContext;
    final BuildContext? viewport_context = _list_view_key.currentContext;
    if (item_context == null) {
      if (_is_current_visible) {
        setState(() {
          _is_current_visible = false;
        });
      }
      return;
    }

    final RenderObject? render_object = item_context.findRenderObject();
    final RenderObject? viewport_object = viewport_context?.findRenderObject();
    if (render_object is! RenderBox ||
        viewport_object is! RenderBox ||
        !render_object.attached ||
        !viewport_object.attached ||
        !render_object.hasSize ||
        !viewport_object.hasSize) {
      return;
    }

    final Rect item_rect =
        render_object.localToGlobal(Offset.zero) & render_object.size;
    final Rect viewport_rect =
        viewport_object.localToGlobal(Offset.zero) & viewport_object.size;
    final bool is_visible = item_rect.overlaps(viewport_rect);

    if (_is_current_visible != is_visible) {
      setState(() {
        _is_current_visible = is_visible;
      });
    }
  }

  // ==================== 点赞处理 ====================

  /// 处理列表项点赞。
  ///
  /// 立即显示转圈，调用外部点赞回调，完成后清除 loading 状态。
  Future<void> _handle_like_tap(int story_id) async {
    if (_like_loading_ids.contains(story_id)) return;

    setState(() {
      _like_loading_ids.add(story_id);
    });

    try {
      await widget.on_like_tap(story_id);
    } finally {
      if (mounted) {
        setState(() {
          _like_loading_ids.remove(story_id);
        });
      }
    }
  }

  // ==================== UI 构建 ====================

  @override
  Widget build(BuildContext context) {
    /// 设备信息仓库（获取当前主题模式）。
    final DeviceInfo device_info = Get.find<DeviceInfo>();

    /// 是否为夜间模式。
    final bool is_dark = device_info.theme.value == ThemeMode.dark;

    /// 弹窗背景色（与首页背景色一致）。
    final Color bg_color = is_dark
        ? ShortStoryReadStyle.catalog_sheet_dark_bg
        : ShortStoryReadStyle.catalog_sheet_light_bg;

    /// 屏幕高度（用于限制弹窗最大高度）。
    final double screen_height = MediaQuery.of(context).size.height;

    /// 弹窗最大高度（屏幕高度的 90%）。
    final double max_height = screen_height * 0.9;

    return Container(
      constraints: BoxConstraints(maxHeight: max_height),
      decoration: BoxDecoration(
        color: bg_color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Stack(
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              /// 顶部标题栏。
              CatalogHeader(is_dark: is_dark, on_close: widget.on_close),

              /// 列表内容区域（响应式切换骨架屏 / 数据列表 / 错误状态 / 空状态）。
              Flexible(
                child: Obx(() {
                  if (widget.is_catalog_loading.value) {
                    return _buildLoadingSkeleton(is_dark: is_dark);
                  }
                  if (widget.is_catalog_error.value) {
                    return _buildErrorState(is_dark: is_dark);
                  }
                  if (widget.catalog_list.isEmpty) {
                    return _buildEmptyState(is_dark: is_dark);
                  }
                  return _buildStoryList(is_dark: is_dark);
                }),
              ),
            ],
          ),

          /// 定位按钮（当前阅读小说不在可视区域内时显示）。
          Obx(() {
            final bool show_button =
                !widget.is_catalog_loading.value &&
                !widget.is_catalog_error.value &&
                widget.catalog_list.isNotEmpty &&
                !_is_current_visible;

            final double safe_bottom = MediaQuery.viewPaddingOf(context).bottom;

            return PositioningButton(
              show: show_button,
              is_dark: is_dark,
              icon_color: ColorConstants.dangerColor,
              on_tap: () => unawaited(_scroll_to_current_story()),
              right: 16.0,
              bottom: safe_bottom + 24.0,
            );
          }),
        ],
      ),
    );
  }

  /// 构建小说列表。
  ///
  /// 可滚动的卡片列表，底部包含加载更多组件。
  /// 首次数据加载完成后自动滚动到当前阅读的小说。
  Widget _buildStoryList({required bool is_dark}) {
    if (!_has_scrolled_to_current && !_initial_positioning_scheduled) {
      _initial_positioning_scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(() async {
          final bool positioned = await _scroll_to_current_story();
          if (!mounted) return;
          _has_scrolled_to_current = positioned;
          _initial_positioning_scheduled = false;
        }());
      });
    }

    return ListView.builder(
      key: _list_view_key,
      controller: _scroll_controller,
      padding: const EdgeInsets.symmetric(vertical: 8),
      // 列表项数量 + 底部加载更多组件。
      itemCount: widget.catalog_list.length + 1,
      itemBuilder: (BuildContext context, int index) {
        // 最后一项：加载更多底部组件。
        if (index == widget.catalog_list.length) {
          return LoadMoreFooter(
            is_dark: is_dark,
            is_loading: _is_loading_more,
            has_more: _catalog_store.has_more,
            on_load_more: _load_more_data,
          );
        }

        final ShortStoryItem item = widget.catalog_list[index];
        final bool is_current = item.id == widget.current_story_id;

        return CatalogItem(
          key: _item_key_for(item.id),
          item: item,
          is_current: is_current,
          is_dark: is_dark,
          is_like_loading: _like_loading_ids.contains(item.id),
          reading_progress: is_current ? widget.reading_progress : 0.0,
          on_tap: is_current ? null : () => widget.on_item_tap(item.id),
          on_like_tap: () => _handle_like_tap(item.id),
        );
      },
    );
  }

  /// 构建加载中骨架屏。
  ///
  /// 模拟 5 个卡片的占位效果。
  Widget _buildLoadingSkeleton({required bool is_dark}) {
    /// 骨架屏底色。
    final Color base_color = is_dark
        ? ShortStoryReadStyle.skeleton_dark_base
        : ShortStoryReadStyle.skeleton_light_base;

    /// 卡片背景色。
    final Color card_bg = is_dark
        ? ShortStoryTabStyle.card_dark_bg
        : ShortStoryTabStyle.card_light_bg;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: _horizontal_padding,
      ),
      itemCount: 5,
      itemBuilder: (BuildContext context, int index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: card_bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// 标题骨架（宽度递减，模拟不同长度标题）。
              Container(
                width: index.isEven ? 140.0 : 180.0,
                height: 16,
                decoration: BoxDecoration(
                  color: base_color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              const SizedBox(height: 10),

              /// 简介骨架（两行）。
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: base_color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 200,
                height: 12,
                decoration: BoxDecoration(
                  color: base_color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              const SizedBox(height: 12),

              /// 底部骨架（标签 + 点赞）。
              Row(
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 20,
                    decoration: BoxDecoration(
                      color: base_color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 36,
                    height: 20,
                    decoration: BoxDecoration(
                      color: base_color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 14,
                    decoration: BoxDecoration(
                      color: base_color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建空状态提示。
  ///
  /// 列表为空时显示，提示用户暂无数据。
  Widget _buildEmptyState({required bool is_dark}) {
    /// 文字颜色。
    final Color text_color = is_dark
        ? ShortStoryReadStyle.secondary_dark_color
        : ShortStoryReadStyle.secondary_light_color;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(
          tr('short_story_read.catalog_empty'),
          style: TextStyle(fontSize: 14, color: text_color),
        ),
      ),
    );
  }

  /// 构建错误状态。
  ///
  /// 目录加载失败时显示无网络提示组件，点击触发重新加载。
  Widget _buildErrorState({required bool is_dark}) {
    return NoInternet(
      is_dark: is_dark,
      title: tr('no_internet.title'),
      description: tr('no_internet.description'),
      on_reload: widget.on_reload,
    );
  }
}
