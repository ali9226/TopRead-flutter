// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/work_editor/style.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

/// TODO 长篇小说内容编辑器。
///
/// 编辑模式：
/// - 先选择章节，然后编辑该章节的正文
///
/// 新增模式：
/// - 默认展示第一章标题输入框 + 正文输入框
/// - 支持添加更多章节
class LongContentEditor extends StatelessWidget {
  /// TODO 是否夜间主题。
  final bool is_dark;

  /// TODO 是否编辑模式（已有作品）。
  final bool is_editing;

  /// TODO 章节列表。
  final List<CreatorChapterDraft> chapters;

  /// TODO 章节总字数。
  final int chapter_word_count;

  /// TODO 添加章节回调。
  final VoidCallback on_add_chapter;

  /// TODO 编辑章节回调。
  final ValueChanged<int> on_edit_chapter;

  /// TODO 删除章节回调。
  final ValueChanged<int> on_delete_chapter;

  /// TODO 章节拖拽排序回调。
  final void Function(int oldIndex, int newIndex) on_reorder_chapters;

  /// TODO 文件上传回调（解析文件内容到新章节）。
  final VoidCallback on_file_upload;

  const LongContentEditor({
    super.key,
    required this.is_dark,
    required this.is_editing,
    required this.chapters,
    required this.chapter_word_count,
    required this.on_add_chapter,
    required this.on_edit_chapter,
    required this.on_delete_chapter,
    required this.on_reorder_chapters,
    required this.on_file_upload,
  });

  @override
  Widget build(BuildContext context) {
    final int count = chapters.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 标题行：章节统计 + 添加按钮 + 文件上传按钮。
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                easy.tr(
                  'creator_center.chapter_summary',
                  args: <String>['$count', '$chapter_word_count'],
                ),
                style: TextStyle(
                  color: AuthorStyle.secondary_text(is_dark),
                  fontSize: 13,
                  fontWeight: AuthorStyle.body_weight,
                ),
              ),
            ),
            /// 文件上传按钮。
            _build_file_upload_button(),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: on_add_chapter,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(easy.tr('creator_center.add_chapter')),
              style: FilledButton.styleFrom(
                backgroundColor:
                    is_dark ? AuthorStyle.gold : AuthorStyle.deep_gold,
                foregroundColor: is_dark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                textStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: WorkEditorStyle.field_label_weight,
                ),
              ),
            ),
          ],
        ),

        /// 章节列表或空状态。
        if (count == 0)
          _build_empty_state(context)
        else
          _build_chapter_list(context),
      ],
    );
  }

  /// TODO 构建文件上传按钮。
  Widget _build_file_upload_button() {
    final Color gold = is_dark ? AuthorStyle.gold : AuthorStyle.deep_gold;

    return InkWell(
      onTap: on_file_upload,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: gold.withValues(alpha: is_dark ? 0.15 : 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: gold.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.upload_file_rounded,
              size: 16,
              color: gold,
            ),
            const SizedBox(width: 4),
            Text(
              easy.tr('creator_center.upload_file'),
              style: TextStyle(
                fontSize: 12,
                color: gold,
                fontWeight: AuthorStyle.body_weight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// TODO 构建空状态提示。
  Widget _build_empty_state(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AuthorStyle.border(is_dark)),
        color: AuthorStyle.secondary_surface(is_dark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.library_books_outlined,
            size: 40,
            color: AuthorStyle.secondary_text(is_dark).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            easy.tr('creator_center.empty_chapter_title'),
            style: TextStyle(
              color: AuthorStyle.primary_text(is_dark),
              fontSize: 15,
              fontWeight: WorkEditorStyle.field_label_weight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            easy.tr('creator_center.empty_chapter_subtitle'),
            style: TextStyle(
              color: AuthorStyle.secondary_text(is_dark),
              fontSize: 12,
              fontWeight: AuthorStyle.body_weight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// TODO 构建可拖拽排序的章节列表。
  Widget _build_chapter_list(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 16),
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
                  '${chapter.word_count} ${easy.tr('creator_center.words')}',
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
