// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app/common_style/selection_chip/index.dart';
import 'package:app/components/bottom_sheet_drag_handle/index.dart';
import 'package:app/components/comment_list/widgets/comment_actions_style.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/util/language_util/index.dart';

/// 举报评论弹窗。
///
/// 从 Redis 配置获取投诉分类列表，以标签形式展示，支持多选。
/// 返回选中的理由列表，取消返回 null。
Future<List<String>?> showCommentReport({
  required BuildContext context,
  required bool is_dark,
}) async {
  final result = await showModalBottomSheet<List<String>>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (menu_context) => _CommentReportSheet(
      is_dark: is_dark,
    ),
  );
  return result;
}

/// 举报弹窗主体。
class _CommentReportSheet extends StatefulWidget {
  /// 是否为夜间主题。
  final bool is_dark;

  const _CommentReportSheet({
    required this.is_dark,
  });

  @override
  State<_CommentReportSheet> createState() => _CommentReportSheetState();
}

class _CommentReportSheetState extends State<_CommentReportSheet> {
  /// 已选中的理由索引。
  final Set<int> _selected_indexes = {};

  /// 投诉分类列表。
  List<Map<String, String>> _complaint_list = [];

  @override
  void initState() {
    super.initState();
    _load_complaint_list();
  }

  /// 从 Redis 配置加载投诉分类列表。
  void _load_complaint_list() {
    try {
      _complaint_list = Get.find<ProjectConfigStore>().complaint_list;
    } catch (_) {
      _complaint_list = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    final Color bgColor = widget.is_dark
        ? CommentActionsStyle.background_dark
        : CommentActionsStyle.background_light;
    final Color textColor = widget.is_dark ? Colors.white : Colors.black;
    final Color subtitleColor = CommentActionsStyle.subtitle_color;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(CommentActionsStyle.sheet_radius),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽把手
            BottomSheetDragHandle(is_dark: widget.is_dark),
            // 标题
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CommentActionsStyle.report_horizontal_padding,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tr('comment.action.report'),
                      style: TextStyle(
                        fontSize: is_cjk
                            ? CommentActionsStyle.report_title_font_size_cjk
                            : CommentActionsStyle.report_title_font_size_alphabetic,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                        color: textColor,
                      ),
                    ),
                  ),
                  Text(
                    '${_selected_indexes.length}/${_complaint_list.length}',
                    style: TextStyle(
                      fontSize: CommentActionsStyle.report_count_font_size,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: CommentActionsStyle.report_title_spacing),
            // 提示文字
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CommentActionsStyle.report_horizontal_padding,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  tr('comment.report.hint'),
                  style: TextStyle(
                    fontSize: is_cjk
                        ? CommentActionsStyle.report_hint_font_size_cjk
                        : CommentActionsStyle.report_hint_font_size_alphabetic,
                    color: subtitleColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: CommentActionsStyle.report_hint_spacing),
            // 标签区域
            Flexible(
              child: _complaint_list.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(
                        CommentActionsStyle.report_empty_padding,
                      ),
                      child: Text(
                        tr('comment.report.empty'),
                        style: TextStyle(
                          fontSize: CommentActionsStyle.report_empty_font_size,
                          color: subtitleColor,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CommentActionsStyle.report_horizontal_padding,
                      ),
                      child: Wrap(
                        spacing: CommentActionsStyle.report_chip_spacing,
                        runSpacing: CommentActionsStyle.report_chip_spacing,
                        children: List.generate(_complaint_list.length, (index) {
                          final item = _complaint_list[index];
                          return SelectionChip(
                            label: item['title'] ?? '',
                            selected: _selected_indexes.contains(index),
                            isDark: widget.is_dark,
                            onTap: () {
                              setState(() {
                                if (_selected_indexes.contains(index)) {
                                  _selected_indexes.remove(index);
                                } else {
                                  _selected_indexes.add(index);
                                }
                              });
                            },
                          );
                        }),
                      ),
                    ),
            ),
            const SizedBox(
              height: CommentActionsStyle.report_chips_button_spacing,
            ),
            // 底部按钮
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CommentActionsStyle.report_horizontal_padding,
              ),
              child: Row(
                children: [
                  // 取消按钮
                  Expanded(
                    child: SizedBox(
                      height: CommentActionsStyle.report_button_height,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              CommentActionsStyle.report_button_radius,
                            ),
                            side: BorderSide(
                              color: widget.is_dark
                                  ? CommentActionsStyle.separator_dark
                                  : CommentActionsStyle.separator_light,
                            ),
                          ),
                        ),
                        child: Text(
                          tr('common.cancel'),
                          style: TextStyle(
                            fontSize: is_cjk
                                ? CommentActionsStyle.button_font_size_cjk
                                : CommentActionsStyle.button_font_size_alphabetic,
                            fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 提交按钮
                  Expanded(
                    child: SizedBox(
                      height: CommentActionsStyle.report_button_height,
                      child: ElevatedButton(
                        onPressed: _selected_indexes.isEmpty
                            ? null
                            : () {
                                final reasons = _selected_indexes
                                    .map(
                                      (i) => _complaint_list[i]['title'] ?? '',
                                    )
                                    .where((r) => r.isNotEmpty)
                                    .toList();
                                Navigator.of(context).pop(reasons);
                              },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: ColorConstants.themeColor,
                          foregroundColor: ColorConstants.lightTextColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              CommentActionsStyle.report_button_radius,
                            ),
                          ),
                          disabledBackgroundColor:
                              ColorConstants.themeColor.withValues(alpha: 0.4),
                          disabledForegroundColor:
                              ColorConstants.lightTextColor.withValues(
                                alpha: 0.6,
                              ),
                        ),
                        child: Text(
                          tr('comment.report.submit'),
                          style: TextStyle(
                            fontSize: is_cjk
                                ? CommentActionsStyle.button_font_size_cjk
                                : CommentActionsStyle.button_font_size_alphabetic,
                            fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}