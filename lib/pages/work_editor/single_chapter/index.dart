import 'dart:convert';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/stores/device_info.dart';
import '../widgets/chapter_publish_sheet.dart';
import 'package:flutter/material.dart';
import 'package:app/api/creator_workspace.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:app/stores/user_information.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import '../workspace/logic.dart';
import 'logic.dart';

/* TODO 单章编辑路由：只读取当前章；原章发布即时生效，新章节可独立定时发布。 */
class SingleChapterPage extends StatefulWidget {
  const SingleChapterPage({super.key, required this.revisionId});
  final int revisionId;
  @override
  State<SingleChapterPage> createState() => _SingleChapterPageState();
}

class _SingleChapterPageState extends State<SingleChapterPage> {
  final title = TextEditingController();
  final content = TextEditingController();
  ChapterDraftController? draft;
  String? failure;
  bool readOnly = false;
  bool is_published = false;
  bool is_scheduled = false;
  bool is_publishing = false;
  Map<String, dynamic> chapter = {};
  Map<String, dynamic>? publish_request;
  bool allowPop = false;
  late final int owner;
  String get storageKey =>
      'creator_chapter_recovery_${owner}_${widget.revisionId}';
  @override
  void initState() {
    super.initState();
    owner = Get.find<UserInformation>().userInfo.value?.id ?? 0;
    _load();
  }

  Future<Map<String, dynamic>> _fetch() => CreatorWorkspaceApi.call(
    'creator_chapter/get_info',
    {'revision_id': widget.revisionId},
  );
  Future<void> _load() async {
    try {
      final row = await _fetch();
      chapter = row;
      is_published =
          row['is_published'] == true || creatorNumber(row['chapter_id']) > 0;
      is_scheduled = row['is_scheduled'] == true;
      readOnly =
          (!is_published &&
              !is_scheduled &&
              creatorNumber(row['revision_status']) != 1) ||
          creatorNumber(row['change_type']) == 3;
      final initial = {
        'title': '${row['title'] ?? ''}',
        'content': '${row['content'] ?? ''}',
      };
      if (!mounted) return;
      draft = ChapterDraftController(
        revisionId: widget.revisionId,
        auto_save: !is_published && !is_scheduled,
        lockVersion: creatorNumber(row['lock_version']),
        initial: initial,
        send: (parameters) {
          if (Get.find<UserInformation>().userInfo.value?.id != owner)
            throw const CreatorWorkspaceException('登录账号已变化，请重新进入编辑器');
          return CreatorWorkspaceApi.call(
            'creator_chapter/save_draft',
            parameters,
          );
        },
        writeRecovery: (data) async {
          await StorageUtil.saveData(storageKey, jsonEncode(data));
        },
        clearRecovery: () => StorageUtil.removeData(storageKey),
      )..addListener(_changed);
      title.text = initial['title']!;
      content.text = initial['content']!;
      final raw = await StorageUtil.getData(storageKey);
      if (!mounted) return;
      if (!readOnly && raw != null) {
        final local = creatorMap(jsonDecode(raw));
        if (local['content'] != initial['content'] ||
            local['title'] != initial['title']) {
          final restore = await _compare(initial, local);
          if (!mounted) return;
          if (restore) {
            title.text = '${local['title'] ?? ''}';
            content.text = '${local['content'] ?? ''}';
            draft!.update(title.text, content.text);
          } else {
            await StorageUtil.removeData(storageKey);
          }
        }
      }
      title.addListener(_input);
      content.addListener(_input);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => failure = '$e');
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _input() {
    if (!readOnly && !is_publishing) draft?.update(title.text, content.text);
  }

  Future<bool> _compare(
    Map<String, dynamic> cloud,
    Map<String, dynamic> local,
  ) async =>
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(tr('creator_workspace.recovery_title')),
            content: SizedBox(
              width: 600,
              height: 320,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('creator_workspace.recovery_hint')),
                    const SizedBox(height: 16),
                    Text(tr('creator_workspace.cloud_copy')),
                    SelectableText('${cloud['title']}\n${cloud['content']}'),
                    const Divider(),
                    Text(tr('creator_workspace.local_copy')),
                    SelectableText('${local['title']}\n${local['content']}'),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(tr('creator_workspace.use_cloud')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(tr('creator_workspace.use_local')),
              ),
            ],
          ),
        ),
      ) ??
      false;
  Future<void> _merge() async {
    try {
      final latest = await _fetch();
      if (!mounted) return;
      if (creatorNumber(latest['revision_status']) != 1) {
        setState(() => failure = tr('creator_workspace.locked_recovery'));
        return;
      }
      final cloud = {'title': latest['title'], 'content': latest['content']};
      final keepLocal = await _compare(cloud, draft!.values);
      if (!mounted) return;
      draft!.acceptServerVersion(creatorNumber(latest['lock_version']), cloud);
      if (!keepLocal) {
        title.text = '${cloud['title']}';
        content.text = '${cloud['content']}';
      }
      draft!.update(title.text, content.text);
      await draft!.save();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _publish() async {
    if (draft == null || readOnly || is_publishing) return;
    if (Get.find<UserInformation>().userInfo.value?.id != owner) {
      setState(() => failure = tr('creator_workspace.account_changed'));
      return;
    }
    if (title.text.trim().isEmpty || content.text.trim().isEmpty) {
      setState(() => failure = tr('creator_center.required_chapter'));
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    var release_mode = CreatorReleaseMode.immediate;
    DateTime? scheduled_time;
    if (publish_request == null && !is_published) {
      final options = await show_chapter_publish_sheet(
        context: context,
        is_dark: Get.find<DeviceInfo>().dark.value,
        initial_mode: is_scheduled
            ? CreatorReleaseMode.scheduled
            : CreatorReleaseMode.immediate,
        initial_time: DateTime.tryParse(
          '${chapter['scheduled_publish_time']}',
        )?.toLocal(),
      );
      if (options == null || !mounted) return;
      release_mode = options.mode;
      scheduled_time = options.time;
    }
    setState(() => is_publishing = true);
    try {
      if (publish_request == null) {
        // 新章先完成串行草稿保存，避免发布与自动保存相互覆盖。
        if (!is_published && !is_scheduled) {
          await draft!.save();
          while (draft!.dirty && draft!.error == null) {
            await draft!.save();
          }
          if (draft!.dirty || draft!.conflict) {
            throw CreatorWorkspaceException(
              draft!.error ?? tr('creator_workspace.not_synced'),
            );
          }
        }
        publish_request = {
          'novel_id': chapter['novel_id'],
          'novel_language_id': chapter['novel_language_id'],
          'revision_id': widget.revisionId,
          if (is_scheduled) 'replace_scheduled': true,
          if (is_published) 'chapter_id': chapter['chapter_id'],
          'lock_version': draft!.lockVersion,
          'title': title.text.trim(),
          'content': content.text,
          'rights_confirmed': true,
          'release_mode': release_mode == CreatorReleaseMode.scheduled ? 2 : 1,
          if (release_mode == CreatorReleaseMode.scheduled)
            'scheduled_publish_time': scheduled_time!.toUtc().toIso8601String(),
          'request_key': creatorRequestKey(),
        };
      }
      await CreatorWorkspaceApi.call(
        'creator_chapter/publish',
        Map.of(publish_request!),
      );
      await StorageUtil.removeData(storageKey);
      if (!mounted) return;
      setState(() => allowPop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (error is CreatorWorkspaceException && error.serverRejected) {
        publish_request = null;
      }
      if (mounted) setState(() => failure = '$error');
    } finally {
      if (mounted) setState(() => is_publishing = false);
    }
  }

  Future<void> _leave() async {
    if (is_publishing) return;
    if ((is_published || is_scheduled) && draft?.dirty == true) {
      final should_publish = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(tr('creator_center.unsaved_changes_message')),
          content: Text(
            tr(
              is_scheduled
                  ? 'creator_center.scheduled_edit_hint'
                  : 'creator_center.editing_published_hint',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('creator_center.no_save')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr('creator_center.publish_and_exit')),
            ),
          ],
        ),
      );
      if (should_publish == null || !mounted) return;
      if (should_publish) {
        await _publish();
        return;
      }
      await draft!.flushLocal();
      await StorageUtil.removeData(storageKey);
    }
    if (draft != null && !readOnly && !is_published && !is_scheduled) {
      await draft!.save();
      if (draft!.dirty) {
        await draft!.flushLocal();
        if (!mounted) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(tr('creator_workspace.not_synced')),
            content: Text(
              draft!.localBackupReady
                  ? tr('creator_workspace.leave_recovery')
                  : '本机备份未完成，请留在页面复制正文或重试保存。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(tr('common.cancel')),
              ),
              if (draft!.localBackupReady)
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(tr('creator_workspace.leave_local')),
                ),
            ],
          ),
        );
        if (leave != true) return;
      }
    }
    if (!mounted) return;
    setState(() => allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    title.dispose();
    content.dispose();
    draft?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: allowPop,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _leave();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          tr(
            readOnly
                ? 'creator_workspace.preview'
                : 'creator_workspace.edit_chapter',
          ),
        ),
        actions: [
          if (!readOnly && draft != null && !is_published && !is_scheduled)
            TextButton(
              onPressed:
                  draft!.saving || is_publishing || publish_request != null
                  ? null
                  : draft!.save,
              child: Text(tr('creator_workspace.save_chapter')),
            ),
          if (!readOnly && draft != null)
            TextButton(
              onPressed: is_publishing || draft!.saving ? null : _publish,
              child: Text(
                tr(
                  is_publishing
                      ? 'creator_workspace.publishing'
                      : 'creator_center.publish',
                ),
              ),
            ),
        ],
      ),
      body: draft == null
          ? Center(
              child: failure == null
                  ? const CircularProgressIndicator()
                  : Text(failure!),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Text(
                    draft!.error ??
                        tr(
                          readOnly
                              ? 'creator_workspace.fixed_preview'
                              : is_scheduled
                              ? 'creator_center.scheduled_edit_hint'
                              : is_published
                              ? 'creator_center.editing_published_hint'
                              : draft!.saving
                              ? 'creator_workspace.saving'
                              : draft!.dirty
                              ? 'creator_workspace.not_synced'
                              : 'creator_workspace.saved',
                        ),
                  ),
                ),
                if (failure != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(failure!),
                  ),
                if (draft!.conflict)
                  TextButton(
                    onPressed: _merge,
                    child: Text(tr('creator_workspace.compare_merge')),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: title,
                    readOnly:
                        readOnly || is_publishing || publish_request != null,
                    maxLength: 255,
                    decoration: InputDecoration(
                      labelText: tr('creator_workspace.chapter_title'),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: TextField(
                      controller: content,
                      readOnly:
                          readOnly || is_publishing || publish_request != null,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(fontSize: 17, height: 1.8),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: tr('creator_workspace.write_content'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    ),
  );
}
