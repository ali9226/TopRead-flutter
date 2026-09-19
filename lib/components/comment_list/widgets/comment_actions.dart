// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:app/components/bottom_sheet_drag_handle/index.dart';
import 'package:app/components/comment_list/widgets/comment_actions_style.dart';
import 'package:app/components/login_required_dialog/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/util/dialog/show_message.dart';

/// 评论操作弹窗，长按评论时显示。
///
/// 包含：复制、不喜欢、投诉（待实现）、删除（仅自己的评论）、取消。
Future<String?> showCommentActions({
  required BuildContext context,
  required bool is_owner,
  required bool is_dark,
  required bool is_cjk,
  required String content,
}) async {
  final result = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (menu_context) => _CommentActionsSheet(
      is_owner: is_owner,
      is_dark: is_dark,
      is_cjk: is_cjk,
    ),
  );
  return result;
}

/// 评论操作弹窗主体。
class _CommentActionsSheet extends StatelessWidget {
  /// 是否是评论作者（显示删除按钮）。
  final bool is_owner;

  /// 是否为夜间主题。
  final bool is_dark;

  /// 是否为 CJK 语系。
  final bool is_cjk;

  const _CommentActionsSheet({
    required this.is_owner,
    required this.is_dark,
    required this.is_cjk,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = is_dark
        ? CommentActionsStyle.background_dark
        : CommentActionsStyle.background_light;
    final Color textColor = is_dark ? Colors.white : Colors.black;
    final Color destructiveColor = ColorConstants.dangerColor;
    final Color separatorColor = is_dark
        ? CommentActionsStyle.separator_dark
        : CommentActionsStyle.separator_light;

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
            BottomSheetDragHandle(is_dark: is_dark),
            // 操作按钮区域
            _buildAction(
              context: context,
              title: tr('comment.action.copy'),
              textColor: textColor,
              separatorColor: separatorColor,
              onTap: () => Navigator.of(context).pop('copy'),
            ),
            _buildAction(
              context: context,
              title: tr('comment.action.dislike'),
              subtitle: tr('comment.action.dislike_subtitle'),
              textColor: textColor,
              separatorColor: separatorColor,
              onTap: () => Navigator.of(context).pop('dislike'),
            ),
            _buildAction(
              context: context,
              title: tr('comment.action.report'),
              textColor: textColor,
              separatorColor: separatorColor,
              showSeparator: is_owner,
              onTap: () => Navigator.of(context).pop('report'),
            ),
            if (is_owner)
              _buildAction(
                context: context,
                title: tr('comment.action.delete'),
                textColor: destructiveColor,
                separatorColor: separatorColor,
                showSeparator: false,
                onTap: () => Navigator.of(context).pop('delete'),
              ),
            // 间隔
            Container(
              height: CommentActionsStyle.spacer_height,
              color: is_dark
                  ? CommentActionsStyle.spacer_dark
                  : CommentActionsStyle.spacer_light,
            ),
            // 取消按钮
            _buildAction(
              context: context,
              title: tr('common.cancel'),
              textColor: textColor,
              separatorColor: separatorColor,
              showSeparator: false,
              onTap: () => Navigator.of(context).pop('cancel'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建单个操作按钮，文字居中，无背景色，底部细线分隔。
  Widget _buildAction({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Color textColor,
    required Color separatorColor,
    required VoidCallback onTap,
    bool showSeparator = true,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(CommentActionsStyle.button_radius),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: CommentActionsStyle.button_vertical_padding,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: CommentActionsStyle.button_text_style(
                        is_cjk: is_cjk,
                        color: textColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: CommentActionsStyle.subtitle_spacing),
                      Text(
                        subtitle,
                        style: CommentActionsStyle.subtitle_text_style(is_cjk: is_cjk),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showSeparator)
          Container(
            height: CommentActionsStyle.separator_height,
            color: separatorColor.withValues(
              alpha: CommentActionsStyle.separator_opacity,
            ),
          ),
      ],
    );
  }
}

/// 确认删除评论的对话框（使用公共 showMessage 组件）。
Future<bool> confirmCommentDelete({
  required BuildContext context,
}) async {
  bool confirmed = false;
  await showMessage(
    message: tr('comment.action.delete_confirm'),
    leftButtonText: tr('common.cancel'),
    rightButtonText: tr('comment.action.delete'),
    rightButtonColor: ColorConstants.dangerColor,
    onRightPressed: () async {
      confirmed = true;
    },
  );
  return confirmed;
}

/// 检查登录状态，未登录则弹出登录提示。
Future<bool> checkLoginForComment() async {
  return await showLoginRequiredDialog(
    title: tr('comment.action.login_required'),
  );
}