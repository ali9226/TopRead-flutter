import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app/components/bottom_sheet_drag_handle/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/components/positioning/index.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/models/novel_info.dart';
import 'package:app/pages/read/widgets/read_directory_sheet/style.dart';
import 'package:app/util/language_util/index.dart';
import 'widgets/book_detail_header.dart';
import 'widgets/book_introduction.dart';

/// 阅读页目录底部弹窗。
class ReadDirectorySheet extends StatefulWidget {
  /// 阅读页逻辑层，提供目录数据和当前章节索引。
  final Logic logic;

  /// 当前是否为夜间主题。
  final bool is_dark;

  /// 当前章节内的阅读进度百分比。
  final double current_chapter_progress_percent;

  /// 点击章节后的回调，交给阅读页执行真正的跳章逻辑。
  final Function(int)? on_chapter_tap;

  const ReadDirectorySheet({
    super.key,
    required this.logic,
    required this.is_dark,
    required this.current_chapter_progress_percent,
    this.on_chapter_tap,
  });

  static Future<void> show({
    required BuildContext context,
    required Logic logic,
    required bool is_dark,
    required double current_chapter_progress_percent,
    Function(int)? on_chapter_tap,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (context) => ReadDirectorySheet(
        logic: logic,
        is_dark: is_dark,
        current_chapter_progress_percent: current_chapter_progress_percent,
        on_chapter_tap: on_chapter_tap,
      ),
    );
  }

  @override
  State<ReadDirectorySheet> createState() => _ReadDirectorySheetState();
}

class _ReadDirectorySheetState extends State<ReadDirectorySheet>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scroll_controller = ScrollController();
  final GlobalKey _catalog_viewport_key = GlobalKey();
  final Map<int, GlobalKey> _chapter_item_keys = <int, GlobalKey>{};
  final Map<int, double> _chapter_item_heights = <int, double>{};
  bool _show_position_button = false;
  bool _did_initial_scroll = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _scroll_controller.addListener(_on_scroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scroll_controller.removeListener(_on_scroll);
    _scroll_controller.dispose();
    super.dispose();
  }

  /// 首帧构建完成后尝试滚动到当前章节。
  void _try_initial_scroll() {
    if (_did_initial_scroll) return;
    _did_initial_scroll = true;

    final int current_index = widget.logic.current_chapter_index.value;
    if (current_index > 0 && _scroll_controller.hasClients) {
      _scroll_to_current_chapter(animate: false);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _update_position_button();
    });
  }

  void _on_scroll() {
    _update_position_button();
  }

  /// 基于真实渲染位置判断当前章节是否在目录列表可视区域内。
  ///
  /// 章节标题允许多行以后，列表项高度不再固定，不能再用 index * itemHeight 判断。
  /// 这里直接读取当前章节 RenderBox 和 ListView 视口 RenderBox 的全局坐标。
  void _update_position_button() {
    if (!_scroll_controller.hasClients || !mounted) return;

    final bool should_show = !_is_current_chapter_visible();
    if (_show_position_button != should_show) {
      setState(() {
        _show_position_button = should_show;
      });
    }
  }

  bool _is_current_chapter_visible() {
    final int current_index = widget.logic.current_chapter_index.value;
    final BuildContext? item_context =
        _chapter_item_keys[current_index]?.currentContext;
    final BuildContext? viewport_context = _catalog_viewport_key.currentContext;

    if (item_context == null || viewport_context == null) {
      return false;
    }

    final RenderObject? item_render_object = item_context.findRenderObject();
    final RenderObject? viewport_render_object = viewport_context
        .findRenderObject();

    if (item_render_object is! RenderBox ||
        viewport_render_object is! RenderBox ||
        !item_render_object.attached ||
        !viewport_render_object.attached) {
      return false;
    }

    final Offset item_top_left = item_render_object.localToGlobal(Offset.zero);
    final Offset viewport_top_left = viewport_render_object.localToGlobal(
      Offset.zero,
    );

    final double item_top = item_top_left.dy;
    final double item_bottom = item_top + item_render_object.size.height;
    final double viewport_top = viewport_top_left.dy;
    final double viewport_bottom =
        viewport_top + viewport_render_object.size.height;

    return item_top < viewport_bottom && item_bottom > viewport_top;
  }

  /// 滚动到当前章节。
  ///
  /// 如果当前章节已经被 ListView 构建，直接用 Scrollable.ensureVisible 精确滚动。
  /// 如果当前章节距离当前视口很远、还没有被构建，则先根据已测量高度 + 平均高度
  /// 粗略 jump/animate 到附近，下一帧章节被构建后再执行精确 reveal。
  void _scroll_to_current_chapter({bool animate = true}) {
    if (!_scroll_controller.hasClients) return;

    final int current_index = widget.logic.current_chapter_index.value;
    final BuildContext? item_context =
        _chapter_item_keys[current_index]?.currentContext;

    if (item_context != null) {
      _reveal_current_chapter(animate: animate);
      return;
    }

    final double estimated_offset = _estimate_current_chapter_offset();
    final double max_extent = _scroll_controller.position.maxScrollExtent;
    final double target_offset = estimated_offset.clamp(0.0, max_extent);

    if (animate) {
      _scroll_controller
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
      _scroll_controller.jumpTo(target_offset);
      _schedule_reveal_current_chapter();
    }
  }

  void _schedule_reveal_current_chapter() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reveal_current_chapter(animate: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _update_position_button();
        }
      });
    });
  }

  void _reveal_current_chapter({required bool animate}) {
    final int current_index = widget.logic.current_chapter_index.value;
    final BuildContext? item_context =
        _chapter_item_keys[current_index]?.currentContext;

    if (item_context == null) {
      _update_position_button();
      return;
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
        _update_position_button();
      }
    });
  }

  double _estimate_current_chapter_offset() {
    final int current_index = widget.logic.current_chapter_index.value;
    final double average_height = _average_measured_chapter_height();
    double offset = ReadDirectorySheetStyle.catalog_list_padding.top;

    for (int index = 0; index < current_index; index++) {
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

  GlobalKey _get_chapter_item_key(int index) {
    return _chapter_item_keys.putIfAbsent(index, () => GlobalKey());
  }

  @override
  Widget build(BuildContext context) {
    final double screen_height = MediaQuery.sizeOf(context).height;
    final double sheet_height =
        screen_height * ReadDirectorySheetStyle.sheet_height_ratio;
    final ReadDetail detail = widget.logic.build_detail();
    final double bottom_padding = MediaQuery.viewPaddingOf(context).bottom;

    final Color bg_color = ReadDirectorySheetStyle.getSheetColor(
      widget.is_dark,
    );

    return Container(
      height: sheet_height,
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        color: bg_color,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ReadDirectorySheetStyle.sheet_border_radius),
        ),
      ),
      child: Column(
        children: <Widget>[
          BottomSheetDragHandle(is_dark: widget.is_dark),
          BookDetailHeader(
            detail: detail,
            is_dark: widget.is_dark,
            on_focus_changed: (bool new_status) {
              widget.logic.update_focus_on(new_status);
            },
          ),
          _buildTabBar(context),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: <Widget>[
                BookIntroduction(detail: detail, is_dark: widget.is_dark),
                _buildCatalogTab(bottom_padding: bottom_padding),
                Center(
                  child: Text(
                    tr('read.no_notes'),
                    style: TextStyle(
                      color: widget.is_dark ? Colors.white38 : Colors.black38,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final bool is_cjk = LanguageUtil.is_cjk_language(
      context.locale.languageCode,
    );
    final double tab_font_size = is_cjk
        ? ReadDirectorySheetStyle.tab_font_size_cjk
        : ReadDirectorySheetStyle.tab_font_size_alphabetic;
    final double tab_label_padding = is_cjk
        ? ReadDirectorySheetStyle.tab_label_padding_cjk
        : ReadDirectorySheetStyle.tab_label_padding_alphabetic;
    final Color label_color = ReadDirectorySheetStyle.getPrimaryTextColor(
      widget.is_dark,
    );
    final Color unselected_label_color =
        ReadDirectorySheetStyle.getSubTextColor(widget.is_dark);

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.none,
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
        ),
        child: Container(
          height: ReadDirectorySheetStyle.tab_bar_height,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(
            horizontal: ReadDirectorySheetStyle.tab_bar_horizontal_padding,
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: label_color,
            unselectedLabelColor: unselected_label_color,
            labelPadding: EdgeInsets.symmetric(horizontal: tab_label_padding),
            labelStyle: TextStyle(
              fontSize: tab_font_size,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: tab_font_size,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
            ),
            indicatorColor: ColorConstants.themeColor,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorPadding: ReadDirectorySheetStyle.tab_indicator_padding,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: tr('read.detail')),
              Tab(text: tr('read.catalog')),
              Tab(text: tr('read.notes')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogTab({required double bottom_padding}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _try_initial_scroll();
    });

    return Stack(
      children: <Widget>[
        ListView.separated(
          key: _catalog_viewport_key,
          controller: _scroll_controller,
          padding: EdgeInsets.fromLTRB(
            0,
            ReadDirectorySheetStyle.catalog_list_padding.top,
            0,
            bottom_padding +
                ReadDirectorySheetStyle.catalog_bottom_extra_padding,
          ),
          itemCount: widget.logic.chapter_list.length,
          separatorBuilder: (BuildContext context, int index) {
            return Divider(
              height: ReadDirectorySheetStyle.chapter_separator_height,
              indent:
                  ReadDirectorySheetStyle.chapter_item_horizontal_padding +
                  ReadDirectorySheetStyle.chapter_number_width +
                  ReadDirectorySheetStyle.chapter_number_title_spacing,
              endIndent: 16,
              color: ReadDirectorySheetStyle.getDividerColor(widget.is_dark),
            );
          },
          itemBuilder: (BuildContext context, int index) {
            return _buildChapterCard(index: index);
          },
        ),
        PositioningButton(
          show: _show_position_button,
          is_dark: widget.is_dark,
          icon_color: ColorConstants.dangerColor,
          right: ReadDirectorySheetStyle.position_button_right,
          bottom:
              bottom_padding +
              ReadDirectorySheetStyle.position_button_bottom_spacing,
          on_tap: () => _scroll_to_current_chapter(),
        ),
      ],
    );
  }

  /// 构建章节列表项。
  Widget _buildChapterCard({required int index}) {
    final NovelChapterInfo chapter = widget.logic.chapter_list[index];
    final bool is_current = index == widget.logic.current_chapter_index.value;
    final Color accent_color = ColorConstants.dangerColor;

    return _MeasureSize(
      key: _get_chapter_item_key(index),
      on_change: (Size size) {
        _chapter_item_heights[index] = size.height;
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            if (widget.on_chapter_tap != null) {
              widget.on_chapter_tap!(index);
            }
          },
          splashColor: accent_color.withValues(alpha: 0.06),
          highlightColor: accent_color.withValues(alpha: 0.03),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: ReadDirectorySheetStyle.chapter_item_vertical_padding,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width:
                      ReadDirectorySheetStyle.chapter_item_horizontal_padding,
                  child: is_current
                      ? Center(
                          child: Container(
                            width: ReadDirectorySheetStyle
                                .current_chapter_bar_width,
                            height: 20,
                            decoration: BoxDecoration(
                              color: accent_color,
                              borderRadius: BorderRadius.circular(
                                ReadDirectorySheetStyle
                                    .current_chapter_bar_radius,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
                SizedBox(
                  width: ReadDirectorySheetStyle.chapter_number_width,
                  child: Text(
                    _format_chapter_no(chapter.chapter_no),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                      color: is_current
                          ? accent_color
                          : ReadDirectorySheetStyle.getSubTextColor(
                              widget.is_dark,
                            ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: ReadDirectorySheetStyle.chapter_number_title_spacing,
                ),
                Expanded(
                  child: is_current
                      ? _buildCurrentChapterTitle(
                          chapter: chapter,
                          accent_color: accent_color,
                        )
                      : _buildRegularChapterTitle(chapter: chapter),
                ),
                if (is_current)
                  _buildCurrentChapterTrailing(accent_color: accent_color)
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: widget.is_dark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建当前章节标题（主题色 + 粗体）。
  Widget _buildCurrentChapterTitle({
    required NovelChapterInfo chapter,
    required Color accent_color,
  }) {
    return Text(
      chapter.title,
      softWrap: true,
      style: TextStyle(
        fontSize: 15,
        height: 1.3,
        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
        color: accent_color,
      ),
    );
  }

  /// 构建普通章节标题。
  Widget _buildRegularChapterTitle({required NovelChapterInfo chapter}) {
    return Text(
      chapter.title,
      softWrap: true,
      style: TextStyle(
        fontSize: 15,
        height: 1.3,
        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
        color: ReadDirectorySheetStyle.getPrimaryTextColor(widget.is_dark),
      ),
    );
  }

  /// 构建当前章节右侧尾部（百分比）。
  Widget _buildCurrentChapterTrailing({required Color accent_color}) {
    final int progress_percent = widget.current_chapter_progress_percent
        .clamp(0.0, 100.0)
        .round();

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 2),
      child: Text(
        '$progress_percent%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
          color: accent_color,
        ),
      ),
    );
  }

  /// 将章节号格式化为两位数。
  String _format_chapter_no(int chapter_no) {
    if (chapter_no <= 0) {
      return '00';
    }
    return chapter_no.toString().padLeft(2, '0');
  }
}

class _MeasureSize extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> on_change;

  const _MeasureSize({super.key, required this.child, required this.on_change});

  @override
  State<_MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<_MeasureSize> {
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
      widget.on_change(new_size);
    });

    return widget.child;
  }
}
