// ignore_for_file: non_constant_identifier_names

import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/work_editor/_shared/style.dart';
import 'package:app/pages/work_editor/_shared/widgets/long_chapter_tile.dart';
import 'package:app/pages/work_editor/workspace/logic.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../logic.dart';

/// 已发布长篇章节目录，参考新建长篇第三步弹窗风格。
class PublishedChapterDirectory extends StatelessWidget {
  const PublishedChapterDirectory({
    super.key,
    required this.model,
    required this.is_dark,
    required this.is_cjk,
    required this.on_open,
    required this.on_new_chapter,
  });
  final PublishedNovelController model;
  final bool is_dark;
  final bool is_cjk;
  final ValueChanged<Map<String, dynamic>> on_open;
  final VoidCallback on_new_chapter;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final rows = model.visible_chapters;
      final secondary = AuthorStyle.secondary_text(is_dark);

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: WorkEditorStyle.page_padding,
              vertical: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    model.ordering
                        ? tr('creator_center.chapter_directory_reorder_hint')
                        : '${tr('creator_center.chapter_count', namedArgs: {'count': '${rows.length}'})} · ${tr('creator_center.chapter_directory_hint')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: secondary,
                      fontSize: is_cjk
                          ? WorkEditorStyle.directory_hint_size_cjk
                          : WorkEditorStyle.directory_hint_size_alphabetic,
                    ),
                  ),
                ),
                if (!model.ordering && rows.length > 1) ...[
                  GestureDetector(
                    onTap: model.locked
                        ? null
                        : () {
                            model.descending = !model.descending;
                            model.notifyListeners();
                          },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: SvgIcon(
                        name: 'move',
                        width: 20,
                        height: 20,
                        color: secondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                GestureDetector(
                  onTap: model.locked || model.saved == null
                      ? null
                      : on_new_chapter,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AuthorStyle.gold,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: rows.isEmpty
                ? Center(
                    child: Text(
                      tr('creator_workspace.empty_chapters'),
                      style: TextStyle(
                        color: secondary,
                        fontSize: 14,
                      ),
                    ),
                  )
                : model.ordering
                ? ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: WorkEditorStyle.page_padding,
                    ),
                    buildDefaultDragHandles: false,
                    itemCount: rows.length,
                    onReorderItem: model.reorder,
                    proxyDecorator: (child, index, animation) => child,
                    itemBuilder: (context, index) =>
                        _row(rows[index], index),
                  )
                : ListView.builder(
                    key: const PageStorageKey('published_chapters'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: WorkEditorStyle.page_padding,
                    ),
                    itemCount: rows.length,
                    itemBuilder: (context, index) =>
                        _row(rows[index], index),
                  ),
          ),
          _DirectoryFooter(
            is_dark: is_dark,
            ordering: model.ordering,
            has_chapters: rows.length > 1,
            on_reorder_toggle: model.toggle_ordering,
            on_new_chapter: on_new_chapter,
            on_cancel_order: model.order_dirty || model.error != null
                ? model.cancel_order
                : null,
          ),
        ],
      );
    },
  );

  Widget _row(Map<String, dynamic> row, int index) {
    final scheduled =
        row['is_scheduled'] == true ||
        row['is_scheduled'] == 1 ||
        row['release_status'] == 2;
    final date = DateTime.tryParse('${row['scheduled_publish_time']}');
    return LongChapterTile(
      key: ValueKey('chapter_${row['chapter_id'] ?? row['revision_id']}'),
      title: '${row['title'] ?? ''}',
      number: '${row['chapter_no'] ?? ''}',
      subtitle:
          '${tr('creator_center.chapter_word_count', namedArgs: {'count': '${creatorNumber(row['word_count'])}'})}${scheduled ? ' · ${tr('creator_workspace.scheduled')}' : ''}',
      dark: is_dark,
      index: index,
      ordering: model.ordering,
      scheduled: scheduled,
      schedule_time: scheduled && date != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(date.toLocal())
          : null,
      on_open: model.locked
          ? null
          : () {
              if (!model.ordering && !model.order_dirty) on_open(row);
            },
    );
  }
}

/// 底部操作栏：排序 + 新建章节。
class _DirectoryFooter extends StatelessWidget {
  const _DirectoryFooter({
    required this.is_dark,
    required this.ordering,
    required this.has_chapters,
    required this.on_reorder_toggle,
    required this.on_new_chapter,
    required this.on_cancel_order,
  });

  final bool is_dark;
  final bool ordering;
  final bool has_chapters;
  final VoidCallback on_reorder_toggle;
  final VoidCallback on_new_chapter;
  final VoidCallback? on_cancel_order;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      maintainBottomViewPadding: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: has_chapters ? on_reorder_toggle : null,
                icon: Icon(
                  ordering ? Icons.check_rounded : Icons.swap_vert_rounded,
                  size: 18,
                ),
                label: Text(
                  ordering
                      ? tr('creator_center.reorder_done')
                      : tr('creator_center.reorder'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AuthorStyle.primary_text(is_dark),
                  side: BorderSide(color: AuthorStyle.border(is_dark)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            if (on_cancel_order != null) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: tr('common.cancel'),
                onPressed: on_cancel_order,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: ordering ? null : on_new_chapter,
                icon: const Icon(Icons.add_rounded, size: 19),
                label: Text(
                  tr('creator_workspace.new_chapter'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AuthorStyle.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
