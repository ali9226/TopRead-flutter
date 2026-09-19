// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../style.dart';

/// 段评列表输入入口统一打开已有图文/表情编辑器。
class ParagraphCommentInputBar extends StatelessWidget {
  final bool is_dark;
  final bool is_cjk;
  final bool is_busy;
  final VoidCallback on_compose;

  const ParagraphCommentInputBar({
    super.key,
    required this.is_dark,
    required this.is_cjk,
    required this.is_busy,
    required this.on_compose,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(border: Border(top: BorderSide(
      color: ParagraphCommentSheetStyle.divider(is_dark),
    ))),
    padding: const EdgeInsets.symmetric(
      horizontal: ParagraphCommentSheetStyle.horizontal_padding,
      vertical: ParagraphCommentSheetStyle.small_spacing,
    ),
    child: SafeArea(top: false, child: Row(children: [
      Expanded(child: InkWell(
        key: const ValueKey('paragraph_comment_compose'),
        onTap: is_busy ? null : on_compose,
        borderRadius: BorderRadius.circular(ParagraphCommentSheetStyle.input_radius),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ParagraphCommentSheetStyle.horizontal_padding,
            vertical: ParagraphCommentSheetStyle.input_vertical_padding,
          ),
          decoration: BoxDecoration(
            color: ParagraphCommentSheetStyle.inset(is_dark),
            borderRadius: BorderRadius.circular(ParagraphCommentSheetStyle.input_radius),
          ),
          child: Text(tr('paragraph_comment.input_hint'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ParagraphCommentSheetStyle.text(
              is_dark: is_dark, is_cjk: is_cjk, secondary: true,
            )),
        ),
      )),
      const SizedBox(width: ParagraphCommentSheetStyle.small_spacing),
      IconButton.filled(
        onPressed: is_busy ? null : on_compose,
        tooltip: tr('paragraph_comment.write'),
        style: IconButton.styleFrom(
          backgroundColor: ParagraphCommentSheetStyle.accent,
          foregroundColor: ParagraphCommentSheetStyle.title(false),
          disabledBackgroundColor: ParagraphCommentSheetStyle.inset(is_dark),
        ),
        icon: const Icon(Icons.edit_outlined, size: ParagraphCommentSheetStyle.icon_size),
      ),
    ])),
  );
}
