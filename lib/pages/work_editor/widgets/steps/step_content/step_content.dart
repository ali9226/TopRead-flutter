// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/work_editor/widgets/editor_section_card.dart';
import 'package:app/pages/work_editor/widgets/step_utils.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

import 'widgets/long_content_editor.dart';
import 'widgets/short_content_editor.dart';

/// TODO 步骤3：作品内容编辑。
///
/// 根据作品类型（长篇/短篇）委托给对应的子组件：
/// - 短篇：[ShortContentEditor] - 正文输入框 + 文件上传
/// - 长篇：[LongContentEditor] - 章节标题 + 正文输入框 + 文件上传
class StepContent extends StatelessWidget {
  /// TODO 是否夜间主题。
  final bool is_dark;

  /// TODO 作品类型。
  final CreatorWorkType work_type;

  /// TODO 是否编辑模式（已有作品）。
  final bool is_editing;

  /// TODO 长篇章节列表。
  final List<CreatorChapterDraft> chapters;

  /// TODO 短篇正文控制器。
  final TextEditingController short_content_controller;

  /// TODO 长篇章节标题控制器。
  final TextEditingController chapter_title_controller;

  /// TODO 长篇章节正文控制器。
  final TextEditingController chapter_content_controller;

  /// TODO 长篇章节总字数。
  final int chapter_word_count;

  /// TODO 短篇字数。
  final int short_word_count;

  /// TODO 长篇当前输入字数。
  final int current_chapter_word_count;

  /// TODO 编辑章节回调。
  final ValueChanged<int> on_edit_chapter;

  /// TODO 删除章节回调。
  final ValueChanged<int> on_delete_chapter;

  /// TODO 章节拖拽排序回调。
  final void Function(int oldIndex, int newIndex) on_reorder_chapters;

  /// TODO 短篇内容变化回调。
  final VoidCallback on_short_content_changed;

  /// TODO 长篇内容变化回调。
  final VoidCallback on_chapter_content_changed;

  /// TODO 短篇文件上传回调。
  final VoidCallback on_short_file_upload;

  /// TODO 长篇文件上传回调。
  final VoidCallback on_long_file_upload;

  const StepContent({
    super.key,
    required this.is_dark,
    required this.work_type,
    required this.is_editing,
    required this.chapters,
    required this.short_content_controller,
    required this.chapter_title_controller,
    required this.chapter_content_controller,
    required this.chapter_word_count,
    required this.short_word_count,
    required this.current_chapter_word_count,
    required this.on_edit_chapter,
    required this.on_delete_chapter,
    required this.on_reorder_chapters,
    required this.on_short_content_changed,
    required this.on_chapter_content_changed,
    required this.on_short_file_upload,
    required this.on_long_file_upload,
  });

  @override
  Widget build(BuildContext context) {
    final bool is_long = work_type == CreatorWorkType.long;

    return StepUtils.build_step_scroll_view(
      context: context,
      children: <Widget>[
        EditorSectionCard(
          title: easy.tr('creator_center.content_title'),
          subtitle: easy.tr(
            is_long
                ? 'creator_center.content_long_subtitle'
                : 'creator_center.content_short_subtitle',
          ),
          is_dark: is_dark,
          child: is_long
              ? LongContentEditor(
                  is_dark: is_dark,
                  is_editing: is_editing,
                  chapters: chapters,
                  chapter_word_count: chapter_word_count,
                  chapter_title_controller: chapter_title_controller,
                  chapter_content_controller: chapter_content_controller,
                  current_word_count: current_chapter_word_count,
                  on_content_changed: on_chapter_content_changed,
                  on_file_upload: on_long_file_upload,
                  on_edit_chapter: on_edit_chapter,
                  on_delete_chapter: on_delete_chapter,
                  on_reorder_chapters: on_reorder_chapters,
                )
              : ShortContentEditor(
                  is_dark: is_dark,
                  content_controller: short_content_controller,
                  word_count: short_word_count,
                  on_content_changed: on_short_content_changed,
                  on_file_upload: on_short_file_upload,
                ),
        ),
      ],
    );
  }
}
