import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/config/color_config.dart';

import 'package:app/components/svg_icon/index.dart';
import 'package:app/common_style/selection_chip/style.dart';
import 'package:app/models/preference.dart';
import 'package:app/components/category_filter/style.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/config/font_config.dart';

/// 筛选弹窗组件。
///
/// 通过 [showGeneralDialog] 以独立路由方式显示，
/// 弹窗面板从底部滑入/滑下，遮罩层淡入淡出，包含：
/// - 遮罩层
/// - 标题栏（标题居中 + 左侧向下收起图标）
/// - 中间可滚动的分类网格（等宽列，支持单选，带颜色过渡动画）
/// - 底部固定按钮（清空 + 确定）
/// - 支持手势拖拽下拉关闭
///
/// 弹窗中的选择为临时状态，只有点击"确定"按钮后才会提交到正式选中状态。
/// 通过外部传入 [scroll_controller] 控制网格滚动位置。
class CategoryFilterPopup extends StatefulWidget {
  /// 当前弹窗中临时选中的分类项 id（单选，null 表示未选中）。
  final Rxn<int> temp_selected_id;

  /// 所有可选分类项列表（来源于 preference_list id=2 的 data_list）。
  final List<PreferenceItem> category_list;

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 切换分类选中状态回调，参数为分类项的 id。
  final ValueChanged<int> on_toggle_category;

  /// 清空选中回调。
  final VoidCallback on_clear;

  /// 确认选择回调。
  final VoidCallback on_confirm;

  /// 关闭弹窗回调。
  final VoidCallback on_close;

  /// 网格区域的滚动控制器，由外部传入以支持自动滚动到选中项。
  final ScrollController scroll_controller;

  /// 当前语言代码，用于 CJK/非 CJK 样式适配。
  final String language_code;

  const CategoryFilterPopup({
    super.key,
    required this.temp_selected_id,
    required this.category_list,
    required this.is_dark,
    required this.on_toggle_category,
    required this.on_clear,
    required this.on_confirm,
    required this.on_close,
    required this.scroll_controller,
    required this.language_code,
  });

  @override
  State<CategoryFilterPopup> createState() => _CategoryFilterPopupState();
}

class _CategoryFilterPopupState extends State<CategoryFilterPopup>
    with TickerProviderStateMixin {
  /// 面板动画控制器（控制滑入/滑出）。
  late AnimationController _panel_animation_controller;

  /// 面板滑入动画。
  late Animation<Offset> _panel_slide_animation;

  /// 遮罩层动画控制器（控制淡入/淡出）。
  late AnimationController _overlay_animation_controller;

  /// 遮罩层透明度动画。
  late Animation<double> _overlay_opacity_animation;

  /// 拖拽起始 Y 坐标。
  double _drag_start_y = 0;

  /// 当前拖拽偏移量。
  double _current_drag_offset = 0;

  /// 拖拽是否已开始。
  bool _is_dragging = false;

  /// 触发关闭的拖拽距离阈值。
  static const double _close_threshold = 100.0;

  @override
  void initState() {
    super.initState();
    _panel_animation_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _panel_slide_animation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _panel_animation_controller,
      curve: Curves.easeOutCubic,
    ));

    _overlay_animation_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _overlay_opacity_animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _overlay_animation_controller,
      curve: Curves.easeOut,
    ));

    _overlay_animation_controller.forward();
    _panel_animation_controller.forward();

    /// 弹窗打开后滚动到选中项位置。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scroll_to_selected();
    });
  }

  @override
  void dispose() {
    _panel_animation_controller.dispose();
    _overlay_animation_controller.dispose();
    super.dispose();
  }

  /// 将网格滚动到当前选中的分类位置。
  ///
  /// 根据选中项在列表中的索引和当前列数计算其所在行，
  /// 然后滚动到该行的位置使选中项可见。
  void _scroll_to_selected() {
    if (!mounted) return;
    if (!widget.scroll_controller.hasClients) return;
    if (widget.category_list.isEmpty) return;
    if (widget.temp_selected_id.value == null) return;

    final int index = widget.category_list.indexWhere(
      (PreferenceItem item) => item.id == widget.temp_selected_id.value,
    );
    if (index < 0) return;

    /// 计算当前屏幕下的列数。
    final bool is_cjk = LanguageUtil.is_cjk_language(widget.language_code);
    final double target_tag_width = is_cjk
        ? CategoryFilterStyle.target_tag_width_cjk
        : CategoryFilterStyle.target_tag_width_alphabetic;
    final double screen_width = MediaQuery.of(context).size.width;
    final double available_width =
        screen_width - CategoryFilterStyle.popup_content_padding.horizontal;
    final int column_count = (available_width / target_tag_width)
        .floor()
        .clamp(3, 8);

    /// 计算选中项所在行。
    final int row = index ~/ column_count;

    /// 每行高度 = 标签高度 + 行间距。
    final double row_height = SelectionChipStyle.chipHeight +
        CategoryFilterStyle.popup_tag_row_spacing;

    /// 目标滚动偏移量（上方留一点间距）。
    final double target_offset = row * row_height - 14.0;
    final double safe_offset = target_offset.clamp(
      0.0,
      widget.scroll_controller.position.maxScrollExtent,
    );

    widget.scroll_controller.animateTo(
      safe_offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  /// 关闭弹窗：遮罩淡出 + 面板滑下，动画完成后调用 on_close。
  ///
  /// 使用 [addPostFrameCallback] 将 on_close 延迟到下一帧执行，
  /// 避免在拖拽手势的 widget tree finalization 阶段调用 Navigator.pop 导致断言失败。
  void _dismiss() {
    _overlay_animation_controller.reverse();
    _panel_animation_controller.reverse().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.on_close();
        }
      });
    });
  }

  /// 处理拖拽开始。
  void _on_drag_start(DragStartDetails details) {
    _drag_start_y = details.globalPosition.dy;
    _is_dragging = true;
  }

  /// 处理拖拽更新。
  void _on_drag_update(DragUpdateDetails details) {
    if (!_is_dragging) return;
    final double delta = details.globalPosition.dy - _drag_start_y;
    if (delta > 0) {
      setState(() {
        _current_drag_offset = delta;
      });
    }
  }

  /// 处理拖拽结束。
  void _on_drag_end(DragEndDetails details) {
    _is_dragging = false;
    if (_current_drag_offset > _close_threshold) {
      _dismiss();
    } else {
      setState(() {
        _current_drag_offset = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    /// 根据语种判断是否为 CJK，选择对应的字号和目标宽度。
    final bool is_cjk = LanguageUtil.is_cjk_language(widget.language_code);
    final double popup_title_font_size = is_cjk
        ? CategoryFilterStyle.popup_title_font_size_cjk
        : CategoryFilterStyle.popup_title_font_size_alphabetic;
    final double popup_tag_font_size = is_cjk
        ? CategoryFilterStyle.popup_tag_font_size_cjk
        : CategoryFilterStyle.popup_tag_font_size_alphabetic;
    final double popup_button_font_size = is_cjk
        ? CategoryFilterStyle.popup_button_font_size_cjk
        : CategoryFilterStyle.popup_button_font_size_alphabetic;
    final double target_tag_width = is_cjk
        ? CategoryFilterStyle.target_tag_width_cjk
        : CategoryFilterStyle.target_tag_width_alphabetic;

    /// 弹窗背景色。
    final Color popup_bg = widget.is_dark
        ? CategoryFilterStyle.popup_dark_bg
        : CategoryFilterStyle.popup_light_bg;

    /// 标题文字色。
    final Color title_color = widget.is_dark
        ? const Color(0xFFE8E8EA)
        : const Color(0xFF1A1A1A);

    /// 标题左侧图标颜色。
    final Color title_icon_color = widget.is_dark
        ? CategoryFilterStyle.popup_title_dark_icon
        : CategoryFilterStyle.popup_title_light_icon;

    /// 选中标签背景色（区分日夜模式）。
    final Color selected_bg = widget.is_dark
        ? CategoryFilterStyle.popup_selected_dark_bg
        : CategoryFilterStyle.popup_selected_light_bg;

    /// 选中标签文字色（区分日夜模式）。
    final Color selected_text = widget.is_dark
        ? CategoryFilterStyle.popup_selected_dark_text
        : CategoryFilterStyle.popup_selected_light_text;

    /// 未选中标签背景色。
    final Color unselected_bg = widget.is_dark
        ? CategoryFilterStyle.tag_unselected_dark_bg
        : CategoryFilterStyle.tag_unselected_light_bg;

    /// 未选中标签文字色。
    final Color unselected_text = widget.is_dark
        ? CategoryFilterStyle.tag_unselected_dark_text
        : CategoryFilterStyle.tag_unselected_light_text;

    /// 清空按钮背景色。
    final Color clear_bg = widget.is_dark
        ? CategoryFilterStyle.clear_dark_bg
        : CategoryFilterStyle.clear_light_bg;

    /// 清空按钮文字色。
    final Color clear_text = widget.is_dark
        ? CategoryFilterStyle.clear_dark_text
        : CategoryFilterStyle.clear_light_text;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: <Widget>[
          /// 遮罩层（淡入淡出，点击触发滑下关闭）。
          GestureDetector(
            onTap: _dismiss,
            child: AnimatedBuilder(
              animation: _overlay_opacity_animation,
              builder: (BuildContext context, Widget? child) {
                return Container(
                  color: CategoryFilterStyle.overlay_color.withValues(
                    alpha: _overlay_opacity_animation.value * 0.66,
                  ),
                );
              },
            ),
          ),

          /// 弹窗面板（从底部滑入，支持拖拽下拉）。
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _panel_slide_animation,
              child: Transform.translate(
                offset: Offset(0, _current_drag_offset),
                child: GestureDetector(
                  onVerticalDragStart: _on_drag_start,
                  onVerticalDragUpdate: _on_drag_update,
                  onVerticalDragEnd: _on_drag_end,
                  child: Container(
                    height: MediaQuery.of(context).size.height *
                        (MediaQuery.of(context).size.width >
                                MediaQuery.of(context).size.height
                            ? 0.85
                            : 0.7),
                    decoration: BoxDecoration(
                      color: popup_bg,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      bottom: false,
                      child: StatefulBuilder(
                        builder:
                            (BuildContext context, StateSetter set_inner_state) {
                          /// 实时读取临时选中的分类 id。
                          final int? temp_id = widget.temp_selected_id.value;

                          /// 判断是否有选中（用于确定按钮文字）。
                          final bool has_selection = temp_id != null;
                          final String confirm_text_str = has_selection
                              ? easy.tr('filter_popup.confirm_with_count', args: ['1'])
                              : easy.tr('filter_popup.confirm');

                          return Column(
                            children: <Widget>[
                              /// 标题栏（标题居中）。
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: <Widget>[
                                    /// 左侧向下收起图标（点击触发滑下关闭）。
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: GestureDetector(
                                        onTap: _dismiss,
                                        child: Transform.rotate(
                                          angle: 90 * 3.141592653589793 / 180,
                                          child: SvgIcon(
                                            name: 'right',
                                            width: CategoryFilterStyle
                                                .popup_title_icon_size,
                                            height: CategoryFilterStyle
                                                .popup_title_icon_size,
                                            color: title_icon_color,
                                          ),
                                        ),
                                      ),
                                    ),

                                    /// 标题文字（居中）。
                                    Text(
                                      easy.tr('filter_popup.title'),
                                      style: TextStyle(
                                        fontSize: popup_title_font_size,
                                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                                        color: title_color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              /// 分割线。
                              Divider(
                                height: 1,
                                thickness: 0.5,
                                color: widget.is_dark
                                    ? const Color(0xFF2A2D3C)
                                    : const Color(0xFFF0F0F0),
                              ),

                              /// 中间可滚动的分类网格（等宽列，占据剩余空间）。
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (BuildContext context,
                                      BoxConstraints constraints) {
                                    /// 可用宽度（扣除内边距）。
                                    final double available_width =
                                        constraints.maxWidth -
                                            CategoryFilterStyle
                                                .popup_content_padding.horizontal;

                                    /// 根据可用宽度动态计算列数（等分）。
                                    final int column_count =
                                        (available_width / target_tag_width)
                                            .floor()
                                            .clamp(3, 8);

                                    /// 每列等分宽度。
                                    final double tag_width =
                                        (available_width -
                                                (column_count - 1) *
                                                    CategoryFilterStyle
                                                        .popup_tag_column_spacing) /
                                            column_count;

                                    return SingleChildScrollView(
                                      controller: widget.scroll_controller,
                                      padding: CategoryFilterStyle
                                          .popup_content_padding,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        child: Wrap(
                                          spacing: CategoryFilterStyle
                                              .popup_tag_column_spacing,
                                          runSpacing: CategoryFilterStyle
                                              .popup_tag_row_spacing,
                                          children: List<Widget>.generate(
                                            widget.category_list.length,
                                            (int index) {
                                              final PreferenceItem item =
                                                  widget.category_list[index];
                                              /// 判断当前分类是否被临时选中。
                                              final bool is_selected =
                                                  temp_id == item.id;
                                              return Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () {
                                                    widget.on_toggle_category(
                                                        item.id);
                                                    set_inner_state(() {});
                                                  },
                                                  splashColor: Colors.transparent,
                                                  highlightColor: Colors.transparent,
                                                  child: AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 250),
                                                    curve: Curves.easeInOut,
                                                    width: tag_width,
                                                    height: SelectionChipStyle
                                                        .chipHeight,
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      color: is_selected
                                                          ? selected_bg
                                                          : unselected_bg,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        CategoryFilterStyle
                                                            .popup_tag_border_radius,
                                                      ),
                                                      border: Border.all(
                                                        color: is_selected
                                                            ? ColorConstants
                                                                .themeColor
                                                            : unselected_bg,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      item.title,
                                                      style: TextStyle(
                                                        fontSize: popup_tag_font_size,
                                                        fontWeight:
                                                            FontConfig.adjustedWeight(FontWeight.w400),
                                                        color: is_selected
                                                            ? selected_text
                                                            : unselected_text,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              /// 底部固定按钮区域。
                              Container(
                                padding: EdgeInsets.fromLTRB(
                                  16,
                                  CategoryFilterStyle.popup_button_top_spacing,
                                  16,
                                  CategoryFilterStyle.popup_button_bottom_safe +
                                      MediaQuery.of(context).padding.bottom,
                                ),
                                child: Row(
                                  children: <Widget>[
                                    /// 清空按钮（点击触发滑下关闭）。
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          widget.on_clear();
                                          _dismiss();
                                        },
                                        child: Container(
                                          height: CategoryFilterStyle
                                              .popup_button_height,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: clear_bg,
                                            borderRadius: BorderRadius.circular(
                                              CategoryFilterStyle
                                                  .popup_button_border_radius,
                                            ),
                                          ),
                                          child: Text(
                                            easy.tr('filter_popup.clear'),
                                            style: TextStyle(
                                              fontSize: popup_button_font_size,
                                              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                                              color: clear_text,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(
                                        width: CategoryFilterStyle
                                            .popup_button_spacing),

                                    /// 确定按钮（主题色背景，黑色文字，点击触发滑下关闭）。
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          widget.on_confirm();
                                          _dismiss();
                                        },
                                        child: Container(
                                          height: CategoryFilterStyle
                                              .popup_button_height,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: ColorConstants.themeColor,
                                            borderRadius: BorderRadius.circular(
                                              CategoryFilterStyle
                                                  .popup_button_border_radius,
                                            ),
                                          ),
                                          child: Text(
                                            confirm_text_str,
                                            style: TextStyle(
                                              fontSize: popup_button_font_size,
                                              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
