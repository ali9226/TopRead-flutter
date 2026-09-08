// ignore_for_file: non_constant_identifier_names

import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/work_editor/widgets/step_utils.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

/// TODO 短篇小说内容编辑器。
///
/// 包含：
/// 1. 文件上传按钮（支持 txt、docx 文件解析）
/// 2. 正文输入框
/// 3. 字数统计
class ShortContentEditor extends StatelessWidget {
  /// TODO 是否夜间主题。
  final bool is_dark;

  /// TODO 正文输入控制器。
  final TextEditingController content_controller;

  /// TODO 当前字数。
  final int word_count;

  /// TODO 内容变化回调。
  final VoidCallback on_content_changed;

  /// TODO 文件上传回调。
  final VoidCallback on_file_upload;

  const ShortContentEditor({
    super.key,
    required this.is_dark,
    required this.content_controller,
    required this.word_count,
    required this.on_content_changed,
    required this.on_file_upload,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 标题行：标签 + 字数统计 + 文件上传按钮。
        Row(
          children: <Widget>[
            Expanded(
              child: StepUtils.build_field_label(
                easy.tr('creator_center.short_content_label'),
                is_dark,
                required: true,
              ),
            ),
            Text(
              '$word_count${easy.tr('read.chapter_word_count_suffix')}',
              style: TextStyle(
                color: AuthorStyle.secondary_text(is_dark),
                fontSize: 12,
                fontWeight: AuthorStyle.body_weight,
              ),
            ),
            const SizedBox(width: 12),
            /// 文件上传按钮。
            _build_file_upload_button(),
          ],
        ),
        const SizedBox(height: 8),

        /// 正文输入框。
        TextField(
          controller: content_controller,
          style: StepUtils.input_text_style(is_dark),
          decoration: InputDecoration(
            hintText: easy.tr('creator_center.short_content_hint'),
            hintStyle: TextStyle(
              color: AuthorStyle.secondary_text(is_dark).withValues(alpha: .65),
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
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
}
