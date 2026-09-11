// ignore_for_file: non_constant_identifier_names

import 'package:app/api/creator_workspace.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/work_editor/_shared/widgets/chapter_publish_sheet.dart';
import 'package:app/pages/work_editor/_shared/widgets/editor_actions.dart';
import 'package:app/pages/work_editor/_shared/style.dart';
import 'package:app/pages/work_editor/_shared/widgets/editor_keyboard_layout.dart';
import 'package:app/pages/work_editor/workspace/style.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/dialog/show_message.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  bool get _has_input =>
      title.text.trim().isNotEmpty || content.text.trim().isNotEmpty;

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

  Future<void> _save_and_exit() async {
    if (saving) return;
    if (title.text.trim().isEmpty) {
      showBottomTip(tr('creator_center.required_chapter_title'));
      return;
    }
    if (content.text.trim().isEmpty) {
      showBottomTip(tr('creator_center.required_chapter_content'));
      return;
    }
    await _submit();
  }

  Future<void> _leave() async {
    if (saving) return;
    if (!_has_input) {
      setState(() => allow_pop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context);
      return;
    }
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
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: (dark
                      ? SystemUiOverlayStyle.light
                      : SystemUiOverlayStyle.dark)
                  .copyWith(statusBarColor: Colors.transparent),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AuthorStyle.hero_gradient(dark),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right: -AuthorStyle.header_glow_size * 0.28,
                      top: -AuthorStyle.header_glow_size * 0.34,
                      child: Container(
                        width: AuthorStyle.header_glow_size,
                        height: AuthorStyle.header_glow_size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AuthorStyle.gold.withValues(
                            alpha: dark ? 0.08 : 0.20,
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AuthorStyle.gold.withValues(
                                alpha: dark ? 0.10 : 0.16,
                              ),
                              blurRadius: AuthorStyle.header_glow_blur,
                              spreadRadius:
                                  AuthorStyle.header_glow_blur * 0.16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: SizedBox(
                        height: kToolbarHeight,
                        child: Row(
                          children: [
                            BackButton(
                              onPressed: _leave,
                              color: AuthorStyle.primary_text(dark),
                            ),
                            Expanded(
                              child: Text(
                                tr(
                                  is_new
                                      ? 'creator_workspace.new_chapter'
                                      : 'creator_workspace.edit_chapter',
                                ),
                                style: WorkspaceStyle.body(dark, cjk),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: saving ? null : _save_and_exit,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AuthorStyle.gold,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: SvgIcon(
                                      name: 'check_04',
                                      width: 9,
                                      height: 9,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                  footer: _ChapterBottomBar(
                    is_dark: dark,
                    is_cjk: cjk,
                    is_new: is_new,
                    saving: saving,
                    on_submit: _submit,
                  ),
                ),
        ),
      ),
    );
  });
}

class _ChapterBottomBar extends StatelessWidget {
  const _ChapterBottomBar({
    required this.is_dark,
    required this.is_cjk,
    required this.is_new,
    required this.saving,
    required this.on_submit,
  });

  final bool is_dark;
  final bool is_cjk;
  final bool is_new;
  final bool saving;
  final VoidCallback on_submit;

  @override
  Widget build(BuildContext context) {
    final font_size = is_cjk
        ? WorkEditorStyle.action_font_size_cjk
        : WorkEditorStyle.action_font_size_alphabetic;

    return Container(
      constraints: const BoxConstraints(
        minHeight: WorkEditorStyle.bottom_bar_min_height,
      ),
      padding: EdgeInsets.fromLTRB(
        WorkEditorStyle.bottom_bar_horizontal_padding,
        WorkEditorStyle.bottom_bar_vertical_padding,
        WorkEditorStyle.bottom_bar_horizontal_padding,
        WorkEditorStyle.bottom_bar_vertical_padding +
            MediaQuery.viewPaddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AuthorStyle.surface(is_dark),
        border: Border(top: BorderSide(color: AuthorStyle.border(is_dark))),
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: WorkEditorStyle.content_max_width,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: saving ? null : on_submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(WorkEditorStyle.action_height),
                backgroundColor: AuthorStyle.gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    WorkEditorStyle.action_radius,
                  ),
                ),
                textStyle: TextStyle(
                  fontSize: font_size,
                  fontWeight: AuthorStyle.title_weight,
                ),
              ),
              child: Text(
                tr(is_new ? 'creator_center.publish' : 'published_editor.update'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
