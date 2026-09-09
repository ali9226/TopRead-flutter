// ignore_for_file: non_constant_identifier_names

import 'package:app/components/bottom_sheet_drag_handle/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'logic.dart';
import 'style.dart';

/// 自定义发布时间选择器，将日期和时间整合在一个底部弹窗中。
Future<DateTime?> show_schedule_time_picker({
  required BuildContext context,
  required bool is_dark,
  DateTime? initial_time,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ScheduleTimePickerSheet(
      is_dark: is_dark,
      initial_time: initial_time,
    ),
  );
}

class _ScheduleTimePickerSheet extends StatefulWidget {
  const _ScheduleTimePickerSheet({
    required this.is_dark,
    required this.initial_time,
  });

  final bool is_dark;
  final DateTime? initial_time;

  @override
  State<_ScheduleTimePickerSheet> createState() =>
      _ScheduleTimePickerSheetState();
}

class _ScheduleTimePickerSheetState extends State<_ScheduleTimePickerSheet> {
  late final ScheduleTimeSelection _selection;
  late int _selected_date_index;
  late int _selected_hour;
  late int _selected_minute;

  late final FixedExtentScrollController _hour_controller;
  late final FixedExtentScrollController _minute_controller;
  late final ScrollController _date_scroll_controller;

  late final List<DateTime> _dates;
  bool _is_cjk = false;

  /// 日期卡片尺寸常量
  static const double _date_card_width = 68;
  static const double _date_card_gap = 10;
  static const double _date_section_padding = ScheduleTimeStyle.sheet_padding;

  @override
  void initState() {
    super.initState();
    _selection = ScheduleTimeSelection(
      now: DateTime.now(),
      initial_time: widget.initial_time,
    );
    _dates = _build_dates();
    _selected_date_index = _find_closest_date_index();
    _selected_hour = _selection.selected_time.hour;
    _selected_minute = _selection.selected_time.minute;
    _hour_controller = FixedExtentScrollController(initialItem: _selected_hour);
    _minute_controller =
        FixedExtentScrollController(initialItem: _selected_minute);
    _date_scroll_controller = ScrollController();

    // 帧渲染完成后滚动到选中日期位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scroll_to_selected(animate: false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _is_cjk = LanguageUtil.is_cjk_language(context.locale.languageCode);
  }

  @override
  void dispose() {
    _hour_controller.dispose();
    _minute_controller.dispose();
    _date_scroll_controller.dispose();
    super.dispose();
  }

  /// 构建从今天开始到 horizon_days 结束的日期列表。
  List<DateTime> _build_dates() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return List.generate(
      ScheduleTimeStyle.horizon_days,
      (i) => start.add(Duration(days: i)),
    );
  }

  /// 查找与当前选中时间最接近的日期索引。
  int _find_closest_date_index() {
    final target = DateTime(
      _selection.selected_time.year,
      _selection.selected_time.month,
      _selection.selected_time.day,
    );
    for (int i = 0; i < _dates.length; i++) {
      if (_dates[i] == target) return i;
    }
    return 0;
  }

  /// 获取当前选中的日期时间。
  DateTime get _current_result {
    final date = _dates[_selected_date_index];
    return DateTime(
      date.year, date.month, date.day, _selected_hour, _selected_minute,
    );
  }

  /// 检查当前选择是否有效（在最小/最大时间范围内）。
  bool get _is_valid {
    final result = _current_result;
    return !result.isBefore(_selection.minimum_time) &&
        !result.isAfter(_selection.maximum_time);
  }

  /// 确认选择：校验时间有效性后返回结果，无效时弹出提示。
  void _on_confirm() {
    final result = _current_result;
    if (result.isBefore(DateTime.now())) {
      showBottomTip(tr('creator_center.schedule_picker_past_time_error'));
      return;
    }
    Navigator.pop(context, result);
  }

  /// 当前滚动位置是否不在第一个（即需要显示"回到今天"按钮）。
  bool get _show_back_to_today => _selected_date_index > 3;

  /// 滚动到选中日期的位置。
  void _scroll_to_selected({bool animate = true}) {
    if (!_date_scroll_controller.hasClients) return;

    // 计算目标偏移：将选中卡片居中
    final double item_extent = _date_card_width + _date_card_gap;
    final double viewport_width = _date_scroll_controller.position.viewportDimension;
    final double target_offset =
        _selected_date_index * item_extent - (viewport_width / 2) + (item_extent / 2);
    final double clamped = target_offset.clamp(
      0.0,
      _date_scroll_controller.position.maxScrollExtent,
    );

    if (animate) {
      _date_scroll_controller.animateTo(
        clamped,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _date_scroll_controller.jumpTo(clamped);
    }
  }

  /// 回到第一个日期（明天/最近）。
  void _jump_to_first() {
    setState(() => _selected_date_index = 0);
    _scroll_to_selected();
  }

  /// 格式化星期几。
  String _format_weekday(DateTime date) {
    final locale = context.locale.toString();
    return DateFormat.E(locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final media_query = MediaQuery.of(context);
    final max_height = media_query.size.height *
        ScheduleTimeStyle.sheet_height_factor;

    return Container(
      constraints: BoxConstraints(maxHeight: max_height),
      decoration: BoxDecoration(
        color: AuthorStyle.surface(widget.is_dark),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ScheduleTimeStyle.sheet_radius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽把手
          BottomSheetDragHandle(is_dark: widget.is_dark),

          // 标题栏
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ScheduleTimeStyle.sheet_padding,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('creator_center.schedule_picker_title'),
                  style: TextStyle(
                    fontSize: _is_cjk
                        ? ScheduleTimeStyle.title_size_cjk
                        : ScheduleTimeStyle.title_size_alphabetic,
                    fontWeight: ScheduleTimeStyle.title_weight,
                    color: AuthorStyle.primary_text(widget.is_dark),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: AuthorStyle.secondary_text(widget.is_dark),
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          const SizedBox(height: ScheduleTimeStyle.section_gap),

          // 日期选择区域
          _build_date_section(),

          const SizedBox(height: ScheduleTimeStyle.section_gap),

          // 时间选择区域
          _build_time_section(),

          const SizedBox(height: ScheduleTimeStyle.section_gap),

          // 底部按钮
          _build_action_buttons(),

          // 底部安全区域
          SizedBox(height: media_query.viewPadding.bottom + 16),
        ],
      ),
    );
  }

  /// 构建日期选择区域。
  Widget _build_date_section() {
    final accent = widget.is_dark ? ColorConstants.themeColor : ColorConstants.lightTextColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标签行：左侧标签 + 右侧"回到今天"按钮
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ScheduleTimeStyle.sheet_padding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr('creator_center.schedule_picker_date_label'),
                style: TextStyle(
                  fontSize: _is_cjk
                      ? ScheduleTimeStyle.label_size_cjk
                      : ScheduleTimeStyle.label_size_alphabetic,
                  fontWeight: ScheduleTimeStyle.body_weight,
                  color: AuthorStyle.secondary_text(widget.is_dark),
                ),
              ),
              // 超过前面几个卡片后显示"回到今天"
              AnimatedOpacity(
                opacity: _show_back_to_today ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: _show_back_to_today ? _jump_to_first : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(
                        alpha: widget.is_dark ? 0.12 : 0.06,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accent.withValues(
                          alpha: widget.is_dark ? 0.25 : 0.15,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.today_rounded,
                          size: 14,
                          color: accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tr('creator_center.schedule_picker_back_today'),
                          style: TextStyle(
                            fontSize: _is_cjk ? 12 : 11,
                            fontWeight: ScheduleTimeStyle.body_weight,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            controller: _date_scroll_controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: _date_section_padding,
            ),
            itemCount: _dates.length,
            itemBuilder: (context, index) {
              final date = _dates[index];
              final is_selected = index == _selected_date_index;

              return GestureDetector(
                onTap: () {
                  setState(() => _selected_date_index = index);
                  _scroll_to_selected();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _date_card_width,
                  margin: const EdgeInsets.only(right: _date_card_gap),
                  decoration: BoxDecoration(
                    color: is_selected
                        ? accent.withValues(
                            alpha: widget.is_dark ? 0.15 : 0.08)
                        : AuthorStyle.secondary_surface(widget.is_dark),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: is_selected
                          ? accent.withValues(
                              alpha: widget.is_dark ? 0.4 : 0.3)
                          : AuthorStyle.border(widget.is_dark),
                      width: is_selected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _format_weekday(date),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: is_selected
                              ? ScheduleTimeStyle.title_weight
                              : ScheduleTimeStyle.body_weight,
                          color: is_selected
                              ? accent
                              : AuthorStyle.secondary_text(widget.is_dark),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: is_selected
                              ? FontConfig.adjustedWeight(FontWeight.w600)
                              : ScheduleTimeStyle.title_weight,
                          color: is_selected
                              ? accent
                              : AuthorStyle.primary_text(widget.is_dark),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat.MMM(context.locale.toString())
                            .format(date),
                        style: TextStyle(
                          fontSize: 10,
                          color: is_selected
                              ? accent.withValues(alpha: 0.7)
                              : AuthorStyle.secondary_text(widget.is_dark),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 构建时间选择区域（时:分 滚轮）。
  Widget _build_time_section() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ScheduleTimeStyle.sheet_padding,
          ),
          child: Text(
            tr('creator_center.schedule_picker_time_label'),
            style: TextStyle(
              fontSize: _is_cjk
                  ? ScheduleTimeStyle.label_size_cjk
                  : ScheduleTimeStyle.label_size_alphabetic,
              fontWeight: ScheduleTimeStyle.body_weight,
              color: AuthorStyle.secondary_text(widget.is_dark),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: ScheduleTimeStyle.wheel_height,
          margin: const EdgeInsets.symmetric(
            horizontal: ScheduleTimeStyle.sheet_padding,
          ),
          decoration: BoxDecoration(
            color: AuthorStyle.secondary_surface(widget.is_dark),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // 小时滚轮
              Expanded(
                child: _build_wheel_picker(
                  controller: _hour_controller,
                  item_count: 24,
                  selected_value: _selected_hour,
                  on_changed: (value) =>
                      setState(() => _selected_hour = value),
                  format: (value) => value.toString().padLeft(2, '0'),
                ),
              ),
              // 分隔符
              Text(
                ':',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
                  color: AuthorStyle.primary_text(widget.is_dark),
                ),
              ),
              // 分钟滚轮
              Expanded(
                child: _build_wheel_picker(
                  controller: _minute_controller,
                  item_count: 60,
                  selected_value: _selected_minute,
                  on_changed: (value) =>
                      setState(() => _selected_minute = value),
                  format: (value) => value.toString().padLeft(2, '0'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建单个滚轮选择器。
  Widget _build_wheel_picker({
    required FixedExtentScrollController controller,
    required int item_count,
    required int selected_value,
    required ValueChanged<int> on_changed,
    required String Function(int) format,
  }) {
    final accent =
        widget.is_dark ? ColorConstants.themeColor : ColorConstants.lightTextColor;

    return CupertinoPicker(
      scrollController: controller,
      itemExtent: ScheduleTimeStyle.wheel_row_height,
      backgroundColor: Colors.transparent,
      selectionOverlay: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: accent.withValues(alpha: 0.2),
              width: 1,
            ),
            bottom: BorderSide(
              color: accent.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
      ),
      onSelectedItemChanged: on_changed,
      children: List.generate(item_count, (index) {
        final is_selected = index == selected_value;
        return Center(
          child: Text(
            format(index),
            style: TextStyle(
              fontSize: _is_cjk
                  ? ScheduleTimeStyle.wheel_size_cjk
                  : ScheduleTimeStyle.wheel_size_alphabetic,
              fontWeight: is_selected
                  ? ScheduleTimeStyle.title_weight
                  : ScheduleTimeStyle.body_weight,
              color: is_selected
                  ? accent
                  : AuthorStyle.secondary_text(widget.is_dark),
            ),
          ),
        );
      }),
    );
  }

  /// 构建底部操作按钮。
  Widget _build_action_buttons() {
    final accent =
        widget.is_dark ? ColorConstants.themeColor : ColorConstants.lightTextColor;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ScheduleTimeStyle.sheet_padding,
      ),
      child: Row(
        children: [
          // 取消按钮
          Expanded(
            child: SizedBox(
              height: ScheduleTimeStyle.button_height,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: AuthorStyle.secondary_text(widget.is_dark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: AuthorStyle.border(widget.is_dark),
                    ),
                  ),
                ),
                child: Text(
                  tr('creator_center.schedule_picker_cancel'),
                  style: TextStyle(
                    fontSize: _is_cjk ? 15 : 14,
                    fontWeight: ScheduleTimeStyle.body_weight,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 确认按钮
          Expanded(
            flex: 2,
            child: SizedBox(
              height: ScheduleTimeStyle.button_height,
              child: ElevatedButton(
                onPressed: _is_valid ? _on_confirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: widget.is_dark
                      ? AuthorStyle.dark_surface
                      : Colors.white,
                  disabledBackgroundColor:
                      accent.withValues(alpha: 0.3),
                  disabledForegroundColor:
                      accent.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  tr('creator_center.schedule_picker_confirm'),
                  style: TextStyle(
                    fontSize: _is_cjk ? 15 : 14,
                    fontWeight: ScheduleTimeStyle.title_weight,
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
