// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/work_editor/_shared/style.dart';
import 'package:app/pages/work_editor/_shared/widgets/step_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../logic.dart';
import '../style.dart';
import 'workspace_chapter_tile.dart';

/// 分页目录只显示元数据，正文仍按需读取，适用于大量章节的作品。
class WorkspaceDirectory extends StatefulWidget {
  const WorkspaceDirectory({
    super.key,
    required this.model,
    required this.is_dark,
    required this.is_cjk,
    required this.working,
    required this.on_open,
    required this.on_action,
  });

  final WorkspaceController model;
  final bool is_dark;
  final bool is_cjk;
  final bool working;
  final ValueChanged<Map<String, dynamic>> on_open;
  final void Function(Map<String, dynamic>, String) on_action;

  @override
  State<WorkspaceDirectory> createState() => _WorkspaceDirectoryState();
}

class _WorkspaceDirectoryState extends State<WorkspaceDirectory> {
  late final TextEditingController _search = TextEditingController(
    text: widget.model.keyword,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final dark = widget.is_dark;
    final cjk = widget.is_cjk;
    final locked = widget.working || model.busy;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: WorkEditorStyle.content_max_width,
        ),
        child: Column(
          children: [
            Padding(
              padding: WorkspaceStyle.padding,
              child: TextField(
                controller: _search,
                enabled: !locked,
                textInputAction: TextInputAction.search,
                style: WorkspaceStyle.body(dark, cjk),
                decoration:
                    StepUtils.field_decoration(
                      dark,
                      hint: tr('creator_workspace.search'),
                    ).copyWith(
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AuthorStyle.secondary_text(dark),
                      ),
                      suffixIcon: IconButton(
                        tooltip: tr('common.cancel'),
                        onPressed: locked
                            ? null
                            : () {
                                _search.clear();
                                model.loadChapters(search: '');
                              },
                        icon: Icon(
                          Icons.close_rounded,
                          color: AuthorStyle.secondary_text(dark),
                        ),
                      ),
                    ),
                onSubmitted: (value) =>
                    model.loadChapters(search: value.trim()),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: WorkEditorStyle.page_padding,
              ),
              child: Row(
                children: ['all', 'draft', 'scheduled']
                    .map(
                      (state) => Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: WorkspaceStyle.gap,
                        ),
                        child: ChoiceChip(
                          showCheckmark: false,
                          label: Text(
                            tr(
                              state == 'scheduled'
                                  ? 'creator_workspace.scheduled'
                                  : 'creator_workspace.filter_$state',
                            ),
                          ),
                          selected: model.filter == state,
                          selectedColor: AuthorStyle.selected_tab_surface(dark),
                          backgroundColor: AuthorStyle.surface(dark),
                          side: BorderSide.none,
                          labelStyle: WorkspaceStyle.caption(dark, cjk)
                              .copyWith(
                                color: model.filter == state
                                    ? AuthorStyle.selected_tab_text(dark)
                                    : AuthorStyle.secondary_text(dark),
                                fontWeight: AuthorStyle.emphasis_weight,
                              ),
                          onSelected: locked
                              ? null
                              : (_) => model.loadChapters(
                                  state: state,
                                  search: _search.text.trim(),
                                ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AuthorStyle.gold,
                onRefresh: () async {
                  if (!locked) await model.refresh();
                },
                child: ListView.builder(
                  key: const PageStorageKey('workspace_chapter_directory'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: WorkspaceStyle.padding,
                  itemCount: model.chapters.length + 1,
                  itemBuilder: (context, index) {
                    if (index == model.chapters.length) {
                      return model.hasMore
                          ? TextButton(
                              onPressed: locked
                                  ? null
                                  : () => model.loadChapters(more: true),
                              child: Text(tr('creator_workspace.load_more')),
                            )
                          : Padding(
                              padding: WorkspaceStyle.padding,
                              child: Text(
                                tr(
                                  model.chapters.isEmpty
                                      ? 'creator_workspace.empty_chapters'
                                      : 'creator_workspace.end',
                                ),
                                textAlign: TextAlign.center,
                                style: WorkspaceStyle.caption(dark, cjk),
                              ),
                            );
                    }
                    final row = model.chapters[index];
                    final scheduled =
                        creatorNumber(row['release_status']) == 2 ||
                        row['is_scheduled'] == true;
                    final raw_time = row['scheduled_publish_time'];
                    final time = DateTime.tryParse('$raw_time');
                    return WorkspaceChapterTile(
                      key: ValueKey(
                        '${row['chapter_id']}_${row['revision_id']}',
                      ),
                      row: row,
                      is_dark: dark,
                      is_cjk: cjk,
                      scheduled: scheduled,
                      status: tr(
                        scheduled
                            ? 'creator_workspace.scheduled'
                            : creatorNumber(row['chapter_id']) > 0
                            ? 'creator_workspace.published'
                            : 'creator_workspace.new_draft',
                      ),
                      schedule_time: !scheduled || raw_time == null
                          ? null
                          : time == null
                          ? '$raw_time'
                          : DateFormat(
                              'yyyy-MM-dd HH:mm',
                            ).format(time.toLocal()),
                      on_open: locked ? null : () => widget.on_open(row),
                      on_action: locked
                          ? null
                          : (action) => widget.on_action(row, action),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
