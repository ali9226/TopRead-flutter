// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/comments/logic.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/pages/comics/widgets/comic_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 回复列表扁平展示但保留回复对象，长评论完整换行，日期明确为 UTC。
class ComicCommentItem extends StatelessWidget {
  final Map<String, dynamic> comment;
  final ComicCommentsLogic logic;
  final int root_id;
  final bool reply;
  const ComicCommentItem({
    super.key,
    required this.comment,
    required this.logic,
    required this.root_id,
    this.reply = false,
  });

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('comics.delete_comment')),
        content: Text(tr('comics.delete_comment_confirm')),
        actions: <Widget>[
          TextButton(
            style: ComicsStyle.text_button(context),
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('comics.cancel')),
          ),
          TextButton(
            style: ComicsStyle.text_button(context),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              tr('comics.delete'),
              style: ComicsStyle.text(
                context,
                color: ColorConstants.dangerColor,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await logic.delete(comment, root_id);
  }

  @override
  Widget build(BuildContext context) {
    final id = comics_int(comment['id']);
    final nickname = comment['nickname']?.toString() ?? '';
    final raw_time = comment['create_time']?.toString() ?? '';
    final normalized_time = raw_time.isEmpty
        ? null
        : DateTime.tryParse(
            raw_time.contains('Z') ||
                    RegExp(r'[+-]\d\d:\d\d$').hasMatch(raw_time)
                ? raw_time
                : '${raw_time.replaceFirst(' ', 'T')}Z',
          );
    final date = normalized_time == null
        ? ''
        : '${DateFormat('yyyy-MM-dd HH:mm').format(normalized_time.toUtc())} UTC';
    final liked = comics_bool(comment['is_liked']);
    final deleted =
        comics_bool(comment['is_deleted']) || comment['status'] == 'deleted';
    return Padding(
      padding: EdgeInsets.fromLTRB(
        reply ? 16 : 0,
        ComicsStyle.gap,
        0,
        ComicsStyle.small_gap,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipOval(
            child: SizedBox.square(
              dimension: reply ? 28 : 36,
              child: '${comment['avatar_url'] ?? ''}'.isEmpty
                  ? ColoredBox(
                      color: ComicsStyle.outline(context),
                      child: Icon(
                        Icons.person_outline,
                        size: reply ? 18 : 22,
                        color: ComicsStyle.muted(context),
                      ),
                    )
                  : ComicImage(
                      url: '${comment['avatar_url']}',
                      semantic_label: nickname,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  nickname,
                  style: ComicsStyle.text(context, size: 13, strong: true),
                ),
                if (date.isNotEmpty)
                  Text(
                    date,
                    style: ComicsStyle.text(
                      context,
                      size: 10,
                      color: ComicsStyle.muted(context),
                    ),
                  ),
                const SizedBox(height: ComicsStyle.small_gap),
                if (reply && '${comment['reply_to_nickname'] ?? ''}'.isNotEmpty)
                  Text(
                    tr(
                      'comics.replying_to',
                      namedArgs: <String, String>{
                        'name': '${comment['reply_to_nickname']}',
                      },
                    ),
                    style: ComicsStyle.text(
                      context,
                      size: 11,
                      color: ComicsStyle.muted(context),
                    ),
                  ),
                SelectableText(
                  deleted
                      ? tr('comics.comment_deleted')
                      : '${comment['comment_content'] ?? ''}',
                  style: ComicsStyle.text(
                    context,
                    color: deleted ? ComicsStyle.muted(context) : null,
                  ),
                ),
                if (!deleted)
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: <Widget>[
                      TextButton.icon(
                        style: ComicsStyle.text_button(context),
                        onPressed: logic.busy_comments.contains(id)
                            ? null
                            : () => logic.like(comment),
                        icon: Icon(
                          liked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 16,
                          color: liked
                              ? ColorConstants.dangerColor
                              : ComicsStyle.muted(context),
                        ),
                        label: Text(
                          '${comics_int(comment['like_count'])}',
                          style: ComicsStyle.text(
                            context,
                            size: 12,
                            color: ComicsStyle.muted(context),
                          ),
                        ),
                      ),
                      TextButton(
                        style: ComicsStyle.text_button(context),
                        onPressed: () => logic.reply_to(comment, root_id),
                        child: Text(
                          tr('comics.reply'),
                          style: ComicsStyle.text(
                            context,
                            size: 12,
                            color: ComicsStyle.muted(context),
                          ),
                        ),
                      ),
                      if (logic.user_id == comics_int(comment['user_id']))
                        IconButton(
                          tooltip: tr('comics.delete'),
                          onPressed: logic.busy_comments.contains(id)
                              ? null
                              : () => _delete(context),
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: ComicsStyle.muted(context),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
