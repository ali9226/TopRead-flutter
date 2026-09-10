import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app/api/creator_workspace.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/work_editor/backend_draft_loader.dart';
import 'package:app/pages/work_editor/index.dart';
import 'package:app/pages/work_editor/single_chapter/index.dart';
import 'package:app/pages/work_editor/single_chapter/logic.dart';
import 'package:go_router/go_router.dart';
import 'logic.dart';
import '../work_recovery.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/user_information.dart';
import 'package:get/get.dart';

/* TODO 作品管理路由：已发布长篇资料与章节管理，资料即时生效，新章节独立设置发布时间。 */
class CreatorWorkspacePage extends StatefulWidget {
  const CreatorWorkspacePage({super.key, required this.novelId});
  final int novelId;
  @override
  State<CreatorWorkspacePage> createState() => _CreatorWorkspacePageState();
}

class _CreatorWorkspacePageState extends State<CreatorWorkspacePage> {
  late final WorkspaceController model;
  final DeviceInfo _device_info = Get.find<DeviceInfo>();
  bool working = false;
  @override
  void initState() {
    super.initState();
    model = WorkspaceController(widget.novelId)..addListener(_changed);
    model.refresh();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  void _error(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _act(Future<void> Function() action) async {
    if (working || model.busy) return;
    setState(() => working = true);
    try {
      await action();
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) {
        setState(() => working = false);
        await model.refresh();
      }
    }
  }

  Future<void> _editWork() => _act(() async {
    if (!model.isPublished && model.data['is_scheduled'] != true) {
      await CreatorWorkspaceApi.call('creator_work/begin_edit', {
        'novel_id': widget.novelId,
        'novel_language_id': model.languageId,
      });
    }
    final result = await CreatorWorkspaceApi.call('creator_work/get_info', {
      'novel_id': widget.novelId,
      'include_chapters': !model.isPublished && model.isLong,
      'novel_language_id': model.languageId,
    });
    final draft = creatorWorkDraftFromBackend(
      result,
      includeChapters: !model.isPublished && model.isLong,
    );
    if (!mounted) return;
    final recovery = await restoreCreatorWork(
      context,
      draft,
      Get.find<UserInformation>().userInfo.value?.id ?? 0,
    );
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatorWorkEditorPage(
          initial_work: recovery.draft,
          restorePending: recovery.restored,
          metadataOnly: model.isLong && model.isPublished,
          saveOnly: !model.isPublished && model.data['is_scheduled'] != true,
        ),
      ),
    );
  });
  Future<void> _editChapter(Map<String, dynamic>? row) => _act(() async {
    int id = creatorNumber(row?['revision_id']);
    if (id == 0) {
      final created =
          await CreatorWorkspaceApi.call('creator_chapter/begin_edit', {
            'novel_id': widget.novelId,
            'novel_language_id': model.languageId,
            if (row != null) 'chapter_id': row['chapter_id'],
            'request_key': creatorRequestKey(),
          });
      id = creatorNumber(created['revision_id']);
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SingleChapterPage(revisionId: id)),
    );
  });
  Future<bool> _confirm(String text) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(tr('creator_workspace.confirm')),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('common.cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr('creator_workspace.confirm')),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> _chapterAction(Map<String, dynamic> row, String action) =>
      _act(() async {
        final message = tr(
          action == 'discard'
              ? 'creator_workspace.discard_chapter_hint'
              : action == 'delete'
              ? 'creator_workspace.delete_chapter_hint'
              : 'creator_workspace.move_hint',
        );
        if (!await _confirm(message)) return;
        final path = action == 'discard'
            ? 'creator_chapter/delete_draft'
            : action == 'delete'
            ? 'creator_chapter/request_delete'
            : 'creator_chapter/move';
        await CreatorWorkspaceApi.call(path, {
          'novel_id': widget.novelId,
          'chapter_id': row['chapter_id'],
          'revision_id': row['revision_id'],
          'direction': action,
          'request_key': creatorRequestKey(),
        });
      });
  Future<void> _cancelSchedule() => _act(() async {
    if (!await _confirm(tr('creator_workspace.cancel_schedule_hint'))) return;
    await CreatorWorkspaceApi.call('creator_work/cancel_release', {
      'submission_id': model.pending['id'],
      'request_key': creatorRequestKey(),
    });
  });
  String _chapterState(Map<String, dynamic> row) {
    if (creatorNumber(row['release_status']) == 2 ||
        row['is_scheduled'] == true) {
      return tr('creator_workspace.scheduled');
    }
    return tr(
      creatorNumber(row['chapter_id']) > 0
          ? 'creator_workspace.published'
          : 'creator_workspace.new_draft',
    );
  }

  Widget _details() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        '${model.novel['language_title'] ?? model.novel['title'] ?? ''}',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      Text(
        tr(
          model.isPublished
              ? 'creator_workspace.published'
              : 'creator_workspace.unpublished',
        ),
      ),
      const SizedBox(height: 12),
      Text('${model.novel['introduction'] ?? ''}'),
      if (model.draft.isNotEmpty && !model.isPublished)
        Card(
          child: ListTile(
            title: Text(tr('creator_workspace.has_work_draft')),
            subtitle: Text('${model.draft['title']}'),
          ),
        ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: working || model.data['can_edit_work'] != true
            ? null
            : _editWork,
        icon: const Icon(Icons.edit_note),
        label: Text(
          tr(
            model.isLong
                ? 'creator_workspace.edit_details'
                : 'creator_workspace.edit_short',
          ),
        ),
      ),
      if (model.isPublished)
        TextButton(
          onPressed: () => context.push(
            model.isLong
                ? '/read?id=${widget.novelId}&title=${Uri.encodeComponent('${model.novel['title']}')}'
                : '/short_story_read?id=${widget.novelId}',
          ),
          child: Text(tr('creator_workspace.read_public')),
        ),
      if (model.data['can_delete'] == true)
        TextButton(
          onPressed: working
              ? null
              : () => _act(() async {
                  if (!await _confirm(
                    tr('creator_workspace.delete_work_hint'),
                  )) {
                    return;
                  }
                  await CreatorWorkspaceApi.call('creator_work/delete', {
                    'novel_id': widget.novelId,
                    'request_key': creatorRequestKey(),
                  });
                  if (mounted) Navigator.pop(context);
                }),
          child: Text(tr('creator_workspace.delete_work')),
        ),
    ],
  );
  Widget _chapters() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: tr('creator_workspace.search'),
                  prefixIcon: const Icon(Icons.search),
                ),
                onSubmitted: (value) => model.loadChapters(search: value),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: working || model.busy
                  ? null
                  : () => _editChapter(null),
              tooltip: tr('creator_workspace.new_chapter'),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
      Wrap(
        spacing: 8,
        children: ['all', 'draft', 'scheduled']
            .map(
              (state) => ChoiceChip(
                label: Text(tr('creator_workspace.filter_$state')),
                selected: model.filter == state,
                onSelected: model.busy
                    ? null
                    : (_) => model.loadChapters(state: state),
              ),
            )
            .toList(),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: model.chapters.length + 1,
          itemBuilder: (context, index) {
            if (index == model.chapters.length) {
              return model.hasMore
                  ? TextButton(
                      onPressed: model.busy
                          ? null
                          : () => model.loadChapters(more: true),
                      child: Text(tr('creator_workspace.load_more')),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        tr(
                          model.chapters.isEmpty
                              ? 'creator_workspace.empty_chapters'
                              : 'creator_workspace.end',
                        ),
                      ),
                    );
            }
            final row = model.chapters[index];
            final state = creatorNumber(row['revision_status']);
            final scheduled =
                creatorNumber(row['release_status']) == 2 ||
                row['is_scheduled'] == true;
            return ListTile(
              leading: Icon(
                scheduled ? Icons.schedule : Icons.article_outlined,
              ),
              title: Text(
                '${creatorNumber(row['chapter_no']) > 0 ? '${row['chapter_no']}. ' : ''}${'${row['title']}'.isEmpty ? tr('creator_workspace.untitled') : row['title']}',
              ),
              subtitle: Text(
                '${_chapterState(row)} · ${row['word_count']} ${tr('creator_workspace.characters')}'
                '${scheduled && row['scheduled_publish_time'] != null ? '\n${_scheduleTime(row['scheduled_publish_time'])}' : ''}',
              ),
              onTap: working || model.busy ? null : () => _editChapter(row),
              trailing: scheduled
                  ? const Icon(Icons.edit_outlined)
                  : PopupMenuButton<String>(
                      onSelected: (value) => _chapterAction(row, value),
                      itemBuilder: (_) => [
                        if (state == 1 && creatorNumber(row['chapter_id']) == 0)
                          PopupMenuItem(
                            value: 'discard',
                            child: Text(
                              tr('creator_workspace.discard_chapter'),
                            ),
                          ),
                        if (creatorNumber(row['chapter_id']) > 0) ...[
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
                    ),
            );
          },
        ),
      ),
    ],
  );
  String _scheduleTime(dynamic raw) {
    final date = DateTime.tryParse('$raw');
    return date == null
        ? '$raw'
        : DateFormat('yyyy-MM-dd HH:mm').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final bool is_dark = _device_info.dark.value;

    return DefaultTabController(
      length: model.isLong ? 2 : 1,
      child: Scaffold(
        backgroundColor: AuthorStyle.background(is_dark),
        appBar: AppBar(
          backgroundColor: AuthorStyle.surface(is_dark),
          surfaceTintColor: Colors.transparent,
          foregroundColor: AuthorStyle.primary_text(is_dark),
          elevation: 0,
          title: Text(
            tr('creator_workspace.title'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: AuthorStyle.title_weight,
            ),
          ),
          actions: [
            IconButton(
              onPressed: model.busy || working ? null : model.refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: TabBar(
            indicatorColor: AuthorStyle.gold,
            labelColor: AuthorStyle.primary_text(is_dark),
            unselectedLabelColor: AuthorStyle.secondary_text(is_dark),
            tabs: [
              Tab(text: tr('creator_workspace.details')),
              if (model.isLong) Tab(text: tr('creator_workspace.chapters')),
            ],
          ),
        ),
        body: model.data.isEmpty
            ? Center(
                child: model.error == null
                    ? CircularProgressIndicator(color: AuthorStyle.gold)
                    : Text(
                        model.error!,
                        style: TextStyle(
                          color: AuthorStyle.secondary_text(is_dark),
                        ),
                      ),
              )
            : Column(
                children: [
                  if (model.busy || working)
                    LinearProgressIndicator(
                      color: AuthorStyle.gold,
                      backgroundColor: AuthorStyle.gold.withValues(alpha: 0.2),
                    ),
                  if (model.error != null)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        model.error!,
                        style: TextStyle(color: AuthorStyle.coral),
                      ),
                    ),
                  if (creatorNumber(model.pending['release_status']) == 2)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: AuthorStyle.gold.withValues(
                        alpha: is_dark ? .10 : .13,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('creator_center.scheduled_edit_hint')),
                          if (model.pending['scheduled_publish_time'] != null)
                            Text(
                              _scheduleTime(
                                model.pending['scheduled_publish_time'],
                              ),
                            ),
                          TextButton(
                            onPressed: working ? null : _cancelSchedule,
                            child: Text(
                              tr('creator_workspace.cancel_schedule'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      children: [_details(), if (model.isLong) _chapters()],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
