// ignore_for_file: non_constant_identifier_names

import 'package:app/components/comment_list/models/comment_data.dart';
import 'package:app/components/comment_list/widgets/comment_item.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/comics/comments/logic.dart';
import 'package:app/pages/comics/comments/style.dart';
import 'package:app/pages/comics/style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// TODO 同一小说评论项呈现漫画主评论及其扁平回复，数据与审核范围仍完全独立。
class ComicCommentItem extends StatelessWidget {
  const ComicCommentItem({
    super.key,
    required this.comment,
    required this.logic,
  });
  final CommentData comment;
  final ComicCommentsLogic logic;

  /// TODO 长按菜单只提供已实现的复制和本人删除，不误调用小说举报接口。
  Future<void> _actions(BuildContext context, CommentData target) async {
    final delete = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: Text(tr('comment.action.copy')),
              onTap: () {
                Clipboard.setData(ClipboardData(text: target.content));
                Navigator.pop(context, false);
              },
            ),
            if (logic.user_id > 0 && target.user_id == logic.user_id)
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: ColorConstants.dangerColor,
                ),
                title: Text(tr('comics.delete_comment')),
                onTap: () => Navigator.pop(context, true),
              ),
          ],
        ),
      ),
    );
    if (delete != true || !context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('comics.delete_comment')),
        content: Text(tr('comics.delete_comment_confirm')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('comics.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              tr('comics.delete'),
              style: TextStyle(color: ColorConstants.dangerColor),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await logic.delete(target, comment.id);
  }

  /// TODO 在途点赞呈现公共忙碌状态，正文、头像和日夜排版全部来自小说组件。
  CommentData _display(CommentData data) =>
      data.copy_with(is_sending: logic.busy_comments.contains(data.id));

  @override
  Widget build(BuildContext context) {
    final thread = logic.threads[comment.id];
    final count = logic.reply_counts[comment.id] ?? 0;
    return CommentItem(
      comment: _display(comment).copy_with(
        replies: thread?.expanded == true
            ? thread!.items.map(_display).toList()
            : const <CommentData>[],
      ),
      is_dark: ComicsStyle.is_dark(context),
      on_reply: (target, _) => logic.reply_to(target, comment.id),
      on_like: logic.like,
      on_long_press: (target) => _actions(context, target),
      thread_controls: count > 0 || thread != null
          ? Padding(
              padding: const EdgeInsets.only(
                left: ComicCommentsStyle.replies_indent,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: ValueKey<String>('comic_thread_${comment.id}'),
                  onPressed: () => logic.replies(comment.id),
                  child: Text(
                    thread?.expanded == true
                        ? tr('comics.hide_replies')
                        : tr(
                            'comics.show_replies',
                            namedArgs: <String, String>{'count': '$count'},
                          ),
                  ),
                ),
              ),
            )
          : null,
      thread_footer: thread?.expanded == true
          ? Padding(
              padding: const EdgeInsets.only(
                left: ComicCommentsStyle.replies_indent,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (thread!.loading)
                    const Padding(
                      padding: EdgeInsets.all(
                        ComicCommentsStyle.footer_padding,
                      ),
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  if (thread.error != null) ...<Widget>[
                    Text(
                      thread.error!,
                      style: ComicsStyle.text(
                        context,
                        color: ComicsStyle.muted(context),
                      ),
                    ),
                    TextButton(
                      onPressed: () => logic.replies(comment.id, refresh: true),
                      child: Text(tr('comics.retry')),
                    ),
                  ],
                  if (!thread.loading &&
                      thread.error == null &&
                      thread.has_more)
                    TextButton(
                      onPressed: () => logic.replies(comment.id, more: true),
                      child: Text(tr('comics.load_more')),
                    ),
                ],
              ),
            )
          : null,
    );
  }
}
