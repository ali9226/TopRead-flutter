// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app/common_style/selection_chip/index.dart';
import 'package:app/components/bottom_sheet_drag_handle/index.dart';
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
        ? const Color(0xFF1C1C1E)
        : Colors.white;
    final Color textColor = widget.is_dark ? Colors.white : Colors.black;
    final Color subtitleColor = widget.is_dark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF666666);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽把手
            BottomSheetDragHandle(is_dark: widget.is_dark),
            // 标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tr('comment.action.report'),
                      style: TextStyle(
                        fontSize: is_cjk ? 18 : 17,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                        color: textColor,
                      ),
                    ),
                  ),
                  Text(
                    '${_selected_indexes.length}/${_complaint_list.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 提示文字
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  tr('comment.report.hint'),
                  style: TextStyle(
                    fontSize: is_cjk ? 13 : 12,
                    color: subtitleColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 标签区域
            Flexible(
              child: _complaint_list.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        tr('comment.report.empty'),
                        style: TextStyle(fontSize: 14, color: subtitleColor),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
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
            const SizedBox(height: 20),
            // 底部按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // 取消按钮
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: widget.is_dark
                                  ? const Color(0xFF38383A)
                                  : const Color(0xFFE0E0E0),
                            ),
                          ),
                        ),
                        child: Text(
                          tr('common.cancel'),
                          style: TextStyle(
                            fontSize: is_cjk ? 16 : 15,
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
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _selected_indexes.isEmpty
                            ? null
                            : () {
                                final reasons = _selected_indexes
                                    .map((i) => _complaint_list[i]['title'] ?? '')
                                    .where((r) => r.isNotEmpty)
                                    .toList();
                                Navigator.of(context).pop(reasons);
                              },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: ColorConstants.themeColor,
                          foregroundColor: ColorConstants.lightTextColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor:
                              ColorConstants.themeColor.withValues(alpha: 0.4),
                          disabledForegroundColor: ColorConstants.lightTextColor
                              .withValues(alpha: 0.6),
                        ),
                        child: Text(
                          tr('comment.report.submit'),
                          style: TextStyle(
                            fontSize: is_cjk ? 16 : 15,
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