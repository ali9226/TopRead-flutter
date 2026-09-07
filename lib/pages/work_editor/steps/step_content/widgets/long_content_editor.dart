// ignore_for_file: non_constant_identifier_names

import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/work_editor/style.dart';
import 'package:app/pages/work_editor/widgets/step_utils.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

/// TODO 长篇小说内容编辑器。
///
/// 编辑模式：
/// - 展示已保存的章节列表
///
/// 新增模式：
/// - 章节标题输入框
/// - 正文输入框（大）
/// - 文件上传按钮
/// - 字数统计
class LongContentEditor extends StatelessWidget {
  /// TODO 是否夜间主题。
  final bool is_dark;

  /// TODO 是否编辑模式（已有作品）。
  final bool is_editing;

  /// TODO 章节列表（编辑模式使用）。
  final List<CreatorChapterDraft> chapters;

  /// TODO 章节总字数。
  final int chapter_word_count;

  /// TODO 章节标题输入控制器（新增模式使用）。
  final TextEditingController chapter_title_controller;

  /// TODO 章节正文输入控制器（新增模式使用）。
  final TextEditingController chapter_content_controller;

  /// TODO 当前输入的字数。
  final int current_word_count;

  /// TODO 内容变化回调。
  final VoidCallback on_content_changed;

  /// TODO 文件上传回调。
  final VoidCallback on_file_upload;

  /// TODO 编辑章节回调（编辑模式使用）。
  final ValueChanged<int> on_edit_chapter;

  /// TODO 删除章节回调（编辑模式使用）。
  final ValueChanged<int> on_delete_chapter;

  /// TODO 章节拖拽排序回调（编辑模式使用）。
  final void Function(int oldIndex, int newIndex) on_reorder_chapters;

  const LongContentEditor({
    super.key,
    required this.is_dark,
    required this.is_editing,
    required this.chapters,
    required this.chapter_word_count,
    required this.chapter_title_controller,
    required this.chapter_content_controller,
    required this.current_word_count,
    required this.on_content_changed,
    required this.on_file_upload,
    required this.on_edit_chapter,
    required this.on_delete_chapter,
    required this.on_reorder_chapters,
  });

  @override
  Widget build(BuildContext context) {
    /// 编辑模式：展示章节列表。
    if (is_editing && chapters.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// 章节统计。
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              easy
                  .tr('creator_center.chapter_summary')
                  .replaceAll('{count}', '${chapters.length}')
                  .replaceAll('{words}', '$chapter_word_count'),
              style: TextStyle(
                color: AuthorStyle.secondary_text(is_dark),
                fontSize: 13,
                fontWeight: AuthorStyle.body_weight,
              ),
            ),
          ),

          /// 章节列表。
          _build_chapter_list(context),
        ],
      );
    }

    /// 新增模式：章节标题 + 正文输入 + 文件上传。
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 章节标题。
        StepUtils.build_field_label(
          easy.tr('creator_center.chapter_title_hint'),
          is_dark,
          required: true,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: chapter_title_controller,
          style: StepUtils.input_text_style(is_dark),
          decoration: StepUtils.field_decoration(
            is_dark,
            hint: easy.tr('creator_center.chapter_title_hint'),
          ),
          maxLines: 1,
        ),
        const SizedBox(height: WorkEditorStyle.field_spacing),

        /// 标题行：章节内容标签 + 字数统计 + 文件上传按钮。
        Row(
          children: <Widget>[
            Expanded(
              child: StepUtils.build_field_label(
                easy.tr('creator_center.chapter_content_label'),
                is_dark,
                required: true,
              ),
            ),
            Text(
              '$current_word_count${easy.tr('read.chapter_word_count_suffix')}',
              style: TextStyle(
                color: AuthorStyle.secondary_text(is_dark),
                fontSize: 12,
                fontWeight: AuthorStyle.body_weight,
              ),
            ),
            const SizedBox(width: 12),
            _build_file_upload_button(),
          ],
        ),
        const SizedBox(height: 8),

        /// 正文输入框。
        TextField(
          controller: chapter_content_controller,
          style: StepUtils.input_text_style(is_dark),
          decoration: StepUtils.field_decoration(
            is_dark,
            hint: easy.tr('creator_center.chapter_content_hint'),
          ),
          minLines: 18,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          onChanged: (_) => on_content_changed(),
        ),
      ],
    );
  }

  /// TODO 构建文件上传按钮。
  Widget _build_file_upload_button() {
    return InkWell(
      onTap: on_file_upload,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: ColorConstants.themeColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SvgIcon(
              name: 'upgrade',
              width: 16,
              height: 16,
              color: ColorConstants.lightTextColor,
            ),
            const SizedBox(width: 4),
            Text(
              easy.tr('creator_center.upload_file'),
              style: TextStyle(
                fontSize: 12,
                color: ColorConstants.lightTextColor,
                fontWeight: AuthorStyle.body_weight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// TODO 构建可拖拽排序的章节列表。
  Widget _build_chapter_list(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: chapters.length,
      onReorder: on_reorder_chapters,
      itemBuilder: (BuildContext context, int index) {
        return _build_chapter_item(
            context, index, ValueKey(chapters[index].local_id));
      },
    );
  }

  /// TODO 构建单个章节条目。
  Widget _build_chapter_item(BuildContext context, int index, Key key) {
    final CreatorChapterDraft chapter = chapters[index];

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AuthorStyle.secondary_surface(is_dark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AuthorStyle.border(is_dark)),
      ),
      child: Row(
        children: <Widget>[
          ReorderableDragStartListener(
            index: index,
            child: Icon(
              Icons.drag_handle_rounded,
              size: 20,
              color: AuthorStyle.secondary_text(is_dark),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color:
                  AuthorStyle.gold.withValues(alpha: is_dark ? 0.16 : 0.20),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: is_dark ? AuthorStyle.gold : AuthorStyle.deep_gold,
                fontSize: 12,
                fontWeight: WorkEditorStyle.field_label_weight,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  chapter.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AuthorStyle.primary_text(is_dark),
                    fontSize: 14,
                    fontWeight: WorkEditorStyle.field_label_weight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${chapter.word_count}${easy.tr('read.chapter_word_count_suffix')}',
                  style: TextStyle(
                    color: AuthorStyle.secondary_text(is_dark),
                    fontSize: 11,
                    fontWeight: AuthorStyle.body_weight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => on_edit_chapter(index),
            icon: Icon(
              Icons.edit_outlined,
              size: 18,
              color: is_dark ? AuthorStyle.gold : AuthorStyle.deep_gold,
            ),
            tooltip: easy.tr('creator_center.edit_chapter'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            onPressed: () => on_delete_chapter(index),
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: ColorConstants.dangerColor,
            ),
            tooltip: easy.tr('creator_center.delete_chapter'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
