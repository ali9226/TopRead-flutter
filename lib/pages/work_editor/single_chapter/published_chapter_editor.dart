// ignore_for_file: non_constant_identifier_names

import 'package:app/api/creator_workspace.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/work_editor/_shared/widgets/chapter_publish_sheet.dart';
import 'package:app/pages/work_editor/_shared/widgets/editor_actions.dart';
import 'package:app/pages/work_editor/_shared/widgets/editor_keyboard_layout.dart';
import 'package:app/pages/work_editor/workspace/style.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/dialog/show_message.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'logic.dart';
import 'widgets/chapter_writing_surface.dart';

/// 已发布作品的新增/更新共用编辑器：进入页面只读，提交时才生成事务版本。
class PublishedChapterEditor extends StatefulWidget {
  const PublishedChapterEditor({
    super.key,
    required this.novel_id,
    required this.novel_language_id,
    this.chapter_id,
    this.scheduled_revision_id,
  });
  final int novel_id;
  final int novel_language_id;
  final int? chapter_id;
  final int? scheduled_revision_id;
  @override
  State<PublishedChapterEditor> createState() => _PublishedChapterEditorState();
}

class _PublishedChapterEditorState extends State<PublishedChapterEditor> {
  final title = TextEditingController();
  final content = TextEditingController();
  Map<String, dynamic> original = {};
  Map<String, dynamic>? pending;
  bool loading = false;
  bool saving = false;
  bool dirty = false;
  bool allow_pop = false;
  String? error;
  bool get is_new =>
      widget.chapter_id == null && widget.scheduled_revision_id == null;

  @override
  void initState() {
    super.initState();
    title.addListener(_changed);
    content.addListener(_changed);
    if (!is_new) _load();
  }

  void _changed() {
    if (mounted) setState(() => dirty = true);
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final row = await CreatorWorkspaceApi.call('creator_chapter/get_editor', {
        'novel_id': widget.novel_id,
        if (widget.chapter_id != null) 'chapter_id': widget.chapter_id,
        if (widget.scheduled_revision_id != null)
          'revision_id': widget.scheduled_revision_id,
      });
      if (!mounted) return;
      original = row;
      title.text = '${row['title'] ?? ''}';
      content.text = '${row['content'] ?? ''}';
      dirty = false;
    } catch (e) {
      if (mounted) error = '$e';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _submit() async {
    if (saving || loading) return;
    if (title.text.trim().isEmpty) {
      setState(() => error = tr('creator_center.required_chapter_title'));
      return;
    }
    if (content.text.trim().isEmpty) {
      setState(() => error = tr('creator_center.required_chapter_content'));
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    // 包括设置发布方式期间也禁用重复提交。
    setState(() => saving = true);
    try {
      if (pending == null) {
        var mode = CreatorReleaseMode.immediate;
        DateTime? time;
        if (is_new) {
          final options = await show_chapter_publish_sheet(
            context: context,
            is_dark: Get.find<DeviceInfo>().dark.value,
          );
          if (options == null || !mounted) return;
          mode = options.mode;
          time = options.time;
        }
        pending = {
          'novel_id': widget.novel_id,
          'novel_language_id': widget.novel_language_id,
          if (widget.chapter_id != null) 'chapter_id': widget.chapter_id,
          if (widget.chapter_id != null)
            'base_revision_id': original['published_revision_id'],
          if (widget.scheduled_revision_id != null) ...{
            'revision_id': widget.scheduled_revision_id,
            'replace_scheduled': true,
          },
          'title': title.text.trim(),
          'content': content.text,
          'rights_confirmed': true,
          'release_mode': mode == CreatorReleaseMode.scheduled ? 2 : 1,
          if (mode == CreatorReleaseMode.scheduled)
            'scheduled_publish_time': time!.toUtc().toIso8601String(),
          'request_key': creatorRequestKey(),
        };
      }
      await CreatorWorkspaceApi.call('creator_chapter/publish', pending!);
      if (!mounted) return;
      setState(() {
        allow_pop = true;
        dirty = false;
      });
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (e is CreatorWorkspaceException && e.serverRejected) pending = null;
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _leave() async {
    if (saving) return;
    if (dirty) {
      String? action;
      await showMessage(
        message: tr('creator_center.unsaved_changes_message'),
        iconData: Icons.info_outline_rounded,
        leftButtonText: tr('creator_center.no_save'),
        rightButtonText: tr('creator_center.save_and_exit'),
        onLeftPressed: () async => action = 'discard',
        onRightPressed: () async {
          action = 'save';
          await _submit();
        },
      );
      if (action == null || !mounted) return;
      if (action == 'discard') {
        setState(() => allow_pop = true);
        await WidgetsBinding.instance.endOfFrame;
        if (mounted) Navigator.pop(context);
      }
      return;
    }
    setState(() => allow_pop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    title.dispose();
    content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final dark = Get.find<DeviceInfo>().dark.value;
    final cjk = LanguageUtil.is_cjk_language(context.locale.languageCode);
    return PopScope(
      canPop: allow_pop,
      onPopInvokedWithResult: (did_pop, _) {
        if (!did_pop) _leave();
      },
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: AuthorStyle.background(dark),
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: BackButton(onPressed: _leave),
            backgroundColor: AuthorStyle.background(dark),
            surfaceTintColor: Colors.transparent,
            foregroundColor: AuthorStyle.primary_text(dark),
            title: Text(
              tr(
                is_new
                    ? 'creator_workspace.new_chapter'
                    : 'creator_workspace.edit_chapter',
              ),
              style: WorkspaceStyle.body(dark, cjk),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.keyboard_hide_rounded),
                tooltip: tr('common.done'),
                onPressed: () =>
                    FocusManager.instance.primaryFocus?.unfocus(),
              ),
            ],
          ),
          body: loading
              ? const Center(
                  child: CircularProgressIndicator(color: AuthorStyle.gold),
                )
              : !is_new && original.isEmpty
              ? Center(
                  child: TextButton(
                    onPressed: _load,
                    child: Text(error ?? tr('published_editor.retry')),
                  ),
                )
              : EditorKeyboardLayout(
                  header: error == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: WorkspaceStyle.padding,
                          child: Text(
                            error!,
                            style: WorkspaceStyle.caption(dark, cjk),
                          ),
                        ),
                  content: ChapterWritingSurface(
                    title_controller: title,
                    content_controller: content,
                    is_dark: dark,
                    is_cjk: cjk,
                    read_only: saving || pending != null,
                  ),
                  footer: EditorBottomBar(
                    is_dark: dark,
                    is_cjk: cjk,
                    current_step: 0,
                    is_last_step: true,
                    primary_title: tr(
                      is_new
                          ? 'creator_center.publish'
                          : 'published_editor.update',
                    ),
                    primary_icon: is_new
                        ? Icons.send_rounded
                        : Icons.check_rounded,
                    on_primary: saving ? null : _submit,
                    on_previous: () {},
                  ),
                ),
        ),
      ),
    );
  });
}
