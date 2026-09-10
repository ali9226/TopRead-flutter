// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/author_center/author_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../logic.dart';
import '../style.dart';

/// 独立章节行，同时保留打开正文、草稿删除、公开章节移动和删除入口。
class WorkspaceChapterTile extends StatelessWidget {
  const WorkspaceChapterTile({
    super.key,
    required this.row,
    required this.is_dark,
    required this.is_cjk,
    required this.status,
    required this.scheduled,
    required this.on_open,
    required this.on_action,
    this.schedule_time,
    this.show_actions = true,
  });

  final Map<String, dynamic> row;
  final bool is_dark;
  final bool is_cjk;
  final bool scheduled;
  final bool show_actions;
  final String status;
  final String? schedule_time;
  final VoidCallback? on_open;
  final ValueChanged<String>? on_action;

  @override
  Widget build(BuildContext context) {
    final published = creatorNumber(row['chapter_id']) > 0;
    final can_discard =
        !published && creatorNumber(row['revision_status']) == 1;
    final title = '${row['title'] ?? ''}'.trim();
    final number = creatorNumber(row['chapter_no']);
    return Padding(
      padding: const EdgeInsets.only(bottom: WorkspaceStyle.gap),
      child: Material(
        color: AuthorStyle.surface(is_dark),
        borderRadius: BorderRadius.circular(WorkspaceStyle.radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: on_open,
          child: Padding(
            padding: WorkspaceStyle.padding,
            child: Row(
              children: [
                Icon(
                  scheduled ? Icons.schedule_rounded : Icons.article_outlined,
                  color: is_dark ? AuthorStyle.gold : AuthorStyle.deep_gold,
                  size: WorkspaceStyle.icon_size,
                ),
                const SizedBox(width: WorkspaceStyle.gap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${number > 0 ? '$number. ' : ''}${title.isEmpty ? tr('creator_workspace.untitled') : title}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: WorkspaceStyle.body(
                          is_dark,
                          is_cjk,
                        ).copyWith(fontWeight: AuthorStyle.emphasis_weight),
                      ),
                      const SizedBox(height: WorkspaceStyle.small_gap),
                      Text(
                        '$status · ${creatorNumber(row['word_count'])} ${tr('creator_workspace.characters')}',
                        style: WorkspaceStyle.caption(is_dark, is_cjk),
                      ),
                      if (schedule_time != null)
                        Text(
                          schedule_time!,
                          style: WorkspaceStyle.caption(is_dark, is_cjk),
                        ),
                    ],
                  ),
                ),
                if (show_actions && !scheduled && (published || can_discard))
                  PopupMenuButton<String>(
                    enabled: on_action != null,
                    color: AuthorStyle.surface(is_dark),
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      color: AuthorStyle.secondary_text(is_dark),
                    ),
                    onSelected: on_action,
                    itemBuilder: (_) => [
                      if (can_discard)
                        PopupMenuItem(
                          value: 'discard',
                          child: Text(tr('creator_workspace.discard_chapter')),
                        ),
                      if (published) ...[
                        PopupMenuItem(
                          value: 'up',
                          child: Text(tr('creator_workspace.move_up')),
                        ),
                        PopupMenuItem(
                          value: 'down',
                          child: Text(tr('creator_workspace.move_down')),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(tr('creator_workspace.request_delete')),
                        ),
                      ],
                    ],
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AuthorStyle.secondary_text(is_dark),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
