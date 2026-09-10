// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app/api/creator_workspace.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/work_editor/_shared/backend_draft_loader.dart';
import 'package:app/pages/work_editor/index.dart';
import 'package:app/pages/work_editor/single_chapter/index.dart';
import 'package:app/pages/work_editor/single_chapter/logic.dart';
import 'package:go_router/go_router.dart';
import 'logic.dart';
import 'style.dart';
import 'widgets/workspace_details.dart';
import 'widgets/workspace_directory.dart';
import '../_shared/widgets/editor_actions.dart';
import 'package:app/util/language_util/index.dart';
import '../_shared/work_recovery.dart';
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
  int _section = 0;
  bool _section_initialized = false;
  @override
  void initState() {
    super.initState();
    model = WorkspaceController(widget.novelId)..addListener(_changed);
    model.refresh();
  }

  void _changed() {
    if (mounted) {
      setState(() {
        if (!_section_initialized && model.data.isNotEmpty) {
          _section_initialized = true;
          _section = model.isLong && model.isPublished ? 1 : 0;
        }
      });
    }
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

  /// 资料沿用原有编辑流程，章节管理始终按单章读写。
  Widget _details(bool is_dark, bool is_cjk) => WorkspaceDetails(
    novel: model.novel,
    is_dark: is_dark,
    is_cjk: is_cjk,
    is_published: model.isPublished,
    draft_title: model.draft.isNotEmpty && !model.isPublished
        ? '${model.draft['title'] ?? ''}'
        : null,
    on_read: !model.isPublished || working
        ? null
        : () => context.push(
            model.isLong
                ? '/read?id=${widget.novelId}&title=${Uri.encodeComponent('${model.novel['language_title'] ?? model.novel['title'] ?? ''}')}'
                : '/short_story_read?id=${widget.novelId}',
          ),
    on_delete: model.data['can_delete'] != true || working || model.busy
        ? null
        : () => _act(() async {
            if (!await _confirm(tr('creator_workspace.delete_work_hint'))) {
              return;
            }
            await CreatorWorkspaceApi.call('creator_work/delete', {
              'novel_id': widget.novelId,
              'request_key': creatorRequestKey(),
            });
            if (mounted) Navigator.pop(context);
          }),
  );

  String _scheduleTime(dynamic raw) {
    final date = DateTime.tryParse('$raw');
    return date == null
        ? '$raw'
        : DateFormat('yyyy-MM-dd HH:mm').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final is_dark = _device_info.dark.value;
    final is_cjk = LanguageUtil.is_cjk_language(context.locale.languageCode);
    final locked = working || model.busy;
    final has_data = model.data.isNotEmpty;
    final chapters_selected = model.isLong && _section == 1;
    return Scaffold(
      backgroundColor: AuthorStyle.background(is_dark),
      appBar: AppBar(
        backgroundColor: AuthorStyle.surface(is_dark),
        surfaceTintColor: Colors.transparent,
        foregroundColor: AuthorStyle.primary_text(is_dark),
        elevation: 0,
        title: Text(
          tr('creator_center.edit_work_title'),
          style: WorkspaceStyle.body(
            is_dark,
            is_cjk,
          ).copyWith(fontWeight: AuthorStyle.title_weight),
        ),
        actions: [
          IconButton(
            onPressed: locked ? null : model.refresh,
            tooltip: MaterialLocalizations.of(
              context,
            ).refreshIndicatorSemanticLabel,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      bottomNavigationBar: !has_data
          ? null
          : EditorBottomBar(
              is_dark: is_dark,
              is_cjk: is_cjk,
              current_step: 0,
              is_last_step: true,
              primary_icon: chapters_selected
                  ? Icons.add_rounded
                  : Icons.edit_outlined,
              primary_title: tr(
                chapters_selected
                    ? 'creator_workspace.new_chapter'
                    : model.isLong
                    ? 'creator_workspace.edit_details'
                    : 'creator_workspace.edit_short',
              ),
              on_primary:
                  locked ||
                      (!chapters_selected &&
                          model.data['can_edit_work'] != true)
                  ? null
                  : chapters_selected
                  ? () => _editChapter(null)
                  : _editWork,
              on_previous: () {},
            ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: !has_data
            ? Center(
                child: model.error == null
                    ? const CircularProgressIndicator(color: AuthorStyle.gold)
                    : Padding(
                        padding: WorkspaceStyle.padding,
                        child: Text(
                          model.error!,
                          style: WorkspaceStyle.body(is_dark, is_cjk),
                        ),
                      ),
              )
            : Column(
                children: [
                  if (model.isLong)
                    Material(
                      color: AuthorStyle.surface(is_dark),
                      child: DefaultTabController(
                        length: 2,
                        initialIndex: _section,
                        child: TabBar(
                          onTap: (index) => setState(() => _section = index),
                          indicatorColor: AuthorStyle.gold,
                          dividerColor: AuthorStyle.border(is_dark),
                          labelColor: AuthorStyle.primary_text(is_dark),
                          unselectedLabelColor: AuthorStyle.secondary_text(
                            is_dark,
                          ),
                          labelStyle: WorkspaceStyle.body(
                            is_dark,
                            is_cjk,
                          ).copyWith(fontWeight: AuthorStyle.emphasis_weight),
                          tabs: [
                            Tab(text: tr('creator_workspace.details')),
                            Tab(text: tr('creator_workspace.chapters')),
                          ],
                        ),
                      ),
                    ),
                  if (locked)
                    LinearProgressIndicator(
                      color: AuthorStyle.gold,
                      backgroundColor: AuthorStyle.selected_tab_surface(
                        is_dark,
                      ),
                    ),
                  if (model.error != null)
                    Padding(
                      padding: WorkspaceStyle.padding,
                      child: Text(
                        model.error!,
                        style: WorkspaceStyle.caption(is_dark, is_cjk),
                      ),
                    ),
                  if (creatorNumber(model.pending['release_status']) == 2)
                    Container(
                      width: double.infinity,
                      padding: WorkspaceStyle.padding,
                      color: AuthorStyle.selected_tab_surface(is_dark),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('creator_center.scheduled_edit_hint'),
                            style: WorkspaceStyle.caption(is_dark, is_cjk),
                          ),
                          if (model.pending['scheduled_publish_time'] != null)
                            Text(
                              _scheduleTime(
                                model.pending['scheduled_publish_time'],
                              ),
                              style: WorkspaceStyle.caption(is_dark, is_cjk),
                            ),
                          TextButton(
                            onPressed: locked ? null : _cancelSchedule,
                            child: Text(
                              tr('creator_workspace.cancel_schedule'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: IndexedStack(
                      index: chapters_selected ? 1 : 0,
                      children: [
                        _details(is_dark, is_cjk),
                        if (model.isLong)
                          WorkspaceDirectory(
                            model: model,
                            is_dark: is_dark,
                            is_cjk: is_cjk,
                            working: working,
                            on_open: _editChapter,
                            on_action: _chapterAction,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  });
}
