import 'package:flutter/material.dart';
import 'package:app/pages/read/logic.dart';
import 'style.dart';

/// TODO 目录搜索、排序及真实布局定位；与弹窗的视觉构建分开维护。
mixin ReadDirectoryInteractions<T extends StatefulWidget>
    on State<T>, TickerProvider {
  Logic get reader_logic;
  late TabController tab_controller;
  int active_tab_index = 0;
  final ScrollController catalog_scroll_controller = ScrollController();
  final GlobalKey catalog_viewport_key = GlobalKey();
  final Map<int, GlobalKey> _chapter_item_keys = <int, GlobalKey>{};
  final Map<int, double> _chapter_item_heights = <int, double>{};
  bool show_position_button = false;
  bool _did_initial_scroll = false;
  int _reveal_attempt_count = 0;
  bool _visibility_check_scheduled = false;

  @override
  void initState() {
    super.initState();
    tab_controller = TabController(length: 3, vsync: this, initialIndex: 0);
    tab_controller.addListener(_handle_tab_change);
    catalog_scroll_controller.addListener(on_catalog_scroll);
  }

  @override
  void dispose() {
    query_controller.dispose();
    tab_controller.removeListener(_handle_tab_change);
    tab_controller.dispose();
    catalog_scroll_controller.removeListener(on_catalog_scroll);
    catalog_scroll_controller.dispose();
    super.dispose();
  }

  /// TODO 分页激活状态同时控制评论加载和独立输入层，返回目录只恢复列表位置。
  void _handle_tab_change() {
    final next_index = tab_controller.index;
    if (active_tab_index != next_index) {
      FocusScope.of(context).unfocus();
      setState(() => active_tab_index = next_index);
    }
    if (next_index == 0) {
      on_catalog_scroll();
    }
  }

  /// 首帧构建完成后尝试滚动到当前章节。
  void try_initial_scroll() {
    if (_did_initial_scroll) return;
    if (!catalog_scroll_controller.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) try_initial_scroll();
      });
      return;
    }
    _did_initial_scroll = true;

    final int current_index = reader_logic.current_chapter_index.value;
    if (current_index > 0) {
      scroll_to_current_chapter(animate: false);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      update_position_button();
    });
  }

  void on_catalog_scroll() {
    if (_visibility_check_scheduled) return;
    _visibility_check_scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibility_check_scheduled = false;
      update_position_button();
    });
  }

  /// 基于真实渲染位置判断当前章节是否在目录列表可视区域内。
  ///
  /// 章节标题允许多行以后，列表项高度不再固定，不能再用 index * itemHeight 判断。
  /// 这里直接读取当前章节 RenderBox 和 ListView 视口 RenderBox 的全局坐标。
  void update_position_button() {
    if (!mounted ||
        reader_logic.chapter_list.isEmpty ||
        !catalog_scroll_controller.hasClients ||
        !catalog_scroll_controller.position.hasContentDimensions) {
      return;
    }

    final bool should_show = !_is_current_chapter_visible();
    if (show_position_button != should_show) {
      setState(() {
        show_position_button = should_show;
      });
    }
  }

  bool _is_current_chapter_visible() {
    final int current_index = reader_logic.current_chapter_index.value;
    final BuildContext? item_context =
        _chapter_item_keys[current_index]?.currentContext;
    final BuildContext? viewport_context = catalog_viewport_key.currentContext;

    if (item_context == null || viewport_context == null) {
      return false;
    }

    final RenderObject? item_render_object = item_context.findRenderObject();
    final RenderObject? viewport_render_object = viewport_context
        .findRenderObject();

    if (item_render_object is! RenderBox ||
        viewport_render_object is! RenderBox ||
        !item_render_object.attached ||
        !viewport_render_object.attached ||
        !item_render_object.hasSize ||
        !viewport_render_object.hasSize) {
      return false;
    }

    final Offset item_top_left = item_render_object.localToGlobal(Offset.zero);
    final Offset viewport_top_left = viewport_render_object.localToGlobal(
      Offset.zero,
    );

    // 与短篇目录保持相同语义：条目仍能看见时不显示返回入口，首章的
    // 列表内边距也不应被额外安全边距误判为离屏。
    return (item_top_left & item_render_object.size).overlaps(
      viewport_top_left & viewport_render_object.size,
    );
  }

  /// 滚动到当前章节。
  ///
  /// 如果当前章节已经被 ListView 构建，直接用 Scrollable.ensureVisible 精确滚动。
  /// 如果当前章节距离当前视口很远、还没有被构建，则先根据已测量高度 + 平均高度
  /// 粗略 jump/animate 到附近，下一帧章节被构建后再执行精确 reveal。
  void scroll_to_current_chapter({bool animate = true}) {
    _reveal_attempt_count = 0;
    if (_query.isNotEmpty) {
      query_controller.clear();
      setState(() => _query = '');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) scroll_to_current_chapter(animate: animate);
      });
      return;
    }

    if (!catalog_scroll_controller.hasClients) return;

    final int current_index = reader_logic.current_chapter_index.value;
    final BuildContext? item_context =
        _chapter_item_keys[current_index]?.currentContext;

    if (item_context != null) {
      _reveal_current_chapter(animate: animate);
      return;
    }

    final double estimated_offset = _estimate_current_chapter_offset();
    final double max_extent =
        catalog_scroll_controller.position.maxScrollExtent;
    final double target_offset = estimated_offset.clamp(0.0, max_extent);

    if (animate) {
      catalog_scroll_controller
          .animateTo(
            target_offset,
            duration: const Duration(
              milliseconds:
                  ReadDirectorySheetStyle.scroll_animation_duration_ms,
            ),
            curve: Curves.easeOutCubic,
          )
          .whenComplete(_schedule_reveal_current_chapter);
    } else {
      catalog_scroll_controller.jumpTo(target_offset);
      _schedule_reveal_current_chapter();
    }
  }

  void _schedule_reveal_current_chapter() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bool revealed = _reveal_current_chapter(animate: true);
      if (!revealed &&
          _reveal_attempt_count <
              ReadDirectorySheetStyle.position_max_refine_attempts) {
        _reveal_attempt_count++;
        _refine_current_chapter_offset();
        _schedule_reveal_current_chapter();
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          update_position_button();
        }
      });
    });
  }

  bool _reveal_current_chapter({required bool animate}) {
    final int current_index = reader_logic.current_chapter_index.value;
    final BuildContext? item_context =
        _chapter_item_keys[current_index]?.currentContext;

    if (item_context == null) {
      update_position_button();
      return false;
    }

    Scrollable.ensureVisible(
      item_context,
      alignment: ReadDirectorySheetStyle.current_chapter_reveal_alignment,
      duration: animate
          ? const Duration(
              milliseconds:
                  ReadDirectorySheetStyle.scroll_animation_duration_ms,
            )
          : Duration.zero,
      curve: Curves.easeOutCubic,
    ).whenComplete(() {
      if (mounted) {
        update_position_button();
      }
    });
    return true;
  }

  /// 目标项尚未构建时，按目录整体比例继续逼近目标区域。
  void _refine_current_chapter_offset() {
    if (!catalog_scroll_controller.hasClients ||
        reader_logic.chapter_list.length <= 1) {
      return;
    }

    final int current_index = visible_chapter_indices.indexOf(
      reader_logic.current_chapter_index.value,
    );
    if (current_index < 0 || visible_chapter_indices.length <= 1) return;
    final double ratio = current_index / (visible_chapter_indices.length - 1);
    final ScrollPosition position = catalog_scroll_controller.position;
    final double proportional_offset = ratio * position.maxScrollExtent;
    final double measured_offset = _estimate_current_chapter_offset();
    final double target_offset = ((proportional_offset + measured_offset) / 2)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    position.jumpTo(target_offset);
  }

  double _estimate_current_chapter_offset() {
    final int current_index = reader_logic.current_chapter_index.value;
    final double average_height = _average_measured_chapter_height();
    double offset = ReadDirectorySheetStyle.catalog_list_padding.top;

    for (final index in visible_chapter_indices) {
      if (index == current_index) break;
      offset += _chapter_item_heights[index] ?? average_height;
      offset += ReadDirectorySheetStyle.chapter_separator_height;
    }

    return offset;
  }

  double _average_measured_chapter_height() {
    if (_chapter_item_heights.isEmpty) {
      return ReadDirectorySheetStyle.chapter_item_estimated_height;
    }

    final double total_height = _chapter_item_heights.values.fold<double>(
      0,
      (double total, double height) => total + height,
    );
    return total_height / _chapter_item_heights.length;
  }

  GlobalKey chapter_item_key(int index) {
    return _chapter_item_keys.putIfAbsent(index, () => GlobalKey());
  }

  /// TODO 目录查询与排序始终保留章节在原目录中的索引，跳章不受显示顺序影响。
  final TextEditingController query_controller = TextEditingController();
  String _query = '';
  bool is_search_visible = false;
  bool sort_descending = false;

  List<int> get visible_chapter_indices {
    final query = _query.toLowerCase().trim();
    final indices = <int>[
      for (var i = 0; i < reader_logic.chapter_list.length; i++)
        if (query.isEmpty ||
            reader_logic.chapter_list[i].title.toLowerCase().contains(query) ||
            reader_logic.chapter_list[i].chapter_no.toString().contains(query))
          i,
    ];
    return sort_descending ? indices.reversed.toList() : indices;
  }

  void toggle_search() {
    setState(() {
      is_search_visible = !is_search_visible;
      if (!is_search_visible) {
        _query = '';
        query_controller.clear();
      }
    });
    on_catalog_scroll();
  }

  void change_query(String value) {
    setState(() => _query = value);
    if (catalog_scroll_controller.hasClients) {
      catalog_scroll_controller.jumpTo(0);
    }
    on_catalog_scroll();
  }

  void change_sort(bool descending) {
    if (sort_descending == descending) return;
    setState(() {
      sort_descending = descending;
      // TODO 排序保留正在输入的筛选，仅完整目录需要重新定位当前章节。
      _did_initial_scroll = _query.isNotEmpty;
    });
  }

  void record_chapter_size(int index, Size size) {
    _chapter_item_heights[index] = size.height;
    on_catalog_scroll();
  }
}
