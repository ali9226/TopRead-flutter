// ignore_for_file: non_constant_identifier_names

import 'package:app/components/login_required_dialog/index.dart';
import 'package:app/components/paragraph_comment_composer/index.dart';
import 'package:app/models/paragraph_anchor.dart';
import 'package:app/models/paragraph_text_selection.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 长短篇共用段评入口，统一登录、弹窗互斥、选区检查和生命周期保护。
///
/// 仅负责打开段评编辑器（compose），列表展示已迁移到 showCommentSheet。
class ParagraphActions {
  bool _is_open = false;

  /// 打开期间阅读页暂停自动滚动及翻页。
  bool get is_open => _is_open;

  /// 使用当前正文重新解析锚点，异步登录或章节切换后不提交过期选区。
  ///
  /// 返回 true 表示发送成功，false 或 null 表示未发送或失败。
  Future<bool?> compose({
    required BuildContext context,
    required String paragraph_text,
    required TextSelection selection,
    required bool is_dark,
    required bool Function() is_current,
    required Future<ParagraphAnchor?> Function() resolve_anchor,
    required Future<bool> Function(
      ParagraphAnchor anchor,
      String text,
      List<String> images,
    )
    on_send,
  }) async {
    if (_is_open ||
        !selection.isValid ||
        selection.isCollapsed ||
        selection.start < 0 ||
        selection.end > paragraph_text.length) {
      return null;
    }
    _is_open = true;
    bool? send_result;
    try {
      final logged_in = await showLoginRequiredDialog(
        title: 'paragraph_comment.login_required'.tr(),
      );
      if (!logged_in || !context.mounted || !is_current()) return null;
      final anchor = await resolve_anchor();
      if (!context.mounted || !is_current()) return null;
      if (anchor == null) {
        showBottomTip('paragraph_comment.unavailable'.tr());
        return null;
      }
      await show_paragraph_comment_composer(
        context,
        quote: selected_paragraph_text(paragraph_text, selection),
        is_dark: is_dark,
        on_send: (text, images) async {
          if (!context.mounted || !is_current()) return false;
          final result = await on_send(anchor, text, images);
          send_result = result;
          return result;
        },
      );
      return send_result;
    } finally {
      _is_open = false;
    }
  }
}
