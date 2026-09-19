// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../style.dart';

/// 返回菜单选择，由调用者检查生命周期后执行异步操作。
Future<String?> show_paragraph_comment_actions({
  required BuildContext context,
  required bool is_owner,
  required bool is_dark,
  required bool is_cjk,
}) => showModalBottomSheet<String>(
  context: context,
  backgroundColor: ParagraphCommentSheetStyle.surface(is_dark),
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(
    top: Radius.circular(ParagraphCommentSheetStyle.reply_radius),
  )),
  builder: (menu_context) => SafeArea(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      for (final action in <(String, IconData, String)>[
        ('copy', Icons.copy_rounded, 'paragraph_comment.copy'),
        ('reply', Icons.reply_rounded, 'comment.reply'),
        if (is_owner)
          ('delete', Icons.delete_outline_rounded, 'paragraph_comment.delete'),
        ('cancel', Icons.close_rounded, 'common.cancel'),
      ])
        ListTile(
          leading: Icon(action.$2, size: ParagraphCommentSheetStyle.icon_size,
            color: action.$1 == 'delete' ? ParagraphCommentSheetStyle.danger
                : ParagraphCommentSheetStyle.body(is_dark)),
          title: Text(tr(action.$3), style: ParagraphCommentSheetStyle.text(
            is_dark: is_dark, is_cjk: is_cjk,
          )),
          onTap: () => Navigator.of(menu_context).pop(action.$1),
        ),
    ]),
  ),
);

Future<bool> confirm_paragraph_comment_delete({
  required BuildContext context,
  required bool is_dark,
  required bool is_cjk,
}) async => await showDialog<bool>(
  context: context,
  builder: (dialog_context) => AlertDialog(
    backgroundColor: ParagraphCommentSheetStyle.surface(is_dark),
    title: Text(tr('paragraph_comment.delete'),
      style: ParagraphCommentSheetStyle.text(
        is_dark: is_dark, is_cjk: is_cjk, heading: true,
      )),
    content: Text(tr('paragraph_comment.delete_confirm'),
      style: ParagraphCommentSheetStyle.text(is_dark: is_dark, is_cjk: is_cjk)),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(dialog_context).pop(false),
        style: ParagraphCommentSheetStyle.button(
          is_dark: is_dark, is_cjk: is_cjk,
        ),
        child: Text(tr('common.cancel')),
      ),
      TextButton(
        onPressed: () => Navigator.of(dialog_context).pop(true),
        style: ParagraphCommentSheetStyle.button(
          is_dark: is_dark, is_cjk: is_cjk, destructive: true,
        ),
        child: Text(tr('paragraph_comment.delete')),
      ),
    ],
  ),
) ?? false;
