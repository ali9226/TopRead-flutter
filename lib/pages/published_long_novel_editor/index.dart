// ignore_for_file: non_constant_identifier_names

import 'package:app/components/image_source_sheet/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/work_editor/_shared/widgets/editor_actions.dart';
import 'package:app/pages/work_editor/_shared/widgets/steps/step_basic/step_basic.dart';
import 'package:app/pages/work_editor/_shared/widgets/steps/step_category/step_category.dart';
import 'package:app/pages/work_editor/single_chapter/index.dart';
import 'package:app/pages/work_editor/workspace/logic.dart';
import 'package:app/pages/work_editor/workspace/style.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/dialog/show_message.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'logic.dart';
import 'widgets/editor_header.dart';
import 'widgets/chapter_directory.dart';

/// 已发布长篇的资料、设置和章节直接编辑入口。
class PublishedLongNovelEditorPage extends StatefulWidget {
  const PublishedLongNovelEditorPage({super.key, required this.novel_id});
  final int novel_id;
  @override
  State<PublishedLongNovelEditorPage> createState() =>
      _PublishedLongNovelEditorPageState();
}

class _PublishedLongNovelEditorPageState
    extends State<PublishedLongNovelEditorPage>
    with SingleTickerProviderStateMixin {
  late final PublishedNovelController model;
  late final TabController tabs;
  bool _allow_pop = false;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 3, vsync: this)..addListener(_changed);
    model = PublishedNovelController(widget.novel_id)..addListener(_changed);
    model.load();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _leave() async {
    if (model.saving || model.uploading) return;
    if (model.dirty || model.pending_section != null) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(tr('creator_center.unsaved_changes_message')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('common.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr('creator_center.no_save')),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    setState(() => _allow_pop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _update(int section) async {
    try {
      if (section == 2) {
        await model.update_order();
      } else {
        await model.update_section(section);
      }
      if (mounted && model.error == null) {
        showBottomTip(tr('published_editor.updated'));
      }
    } catch (_) {
      /* 错误保留在页面内，网络结果未知时允许重试相同请求。 */
    }
  }

  Future<void> _chapter([Map<String, dynamic>? row]) async {
    if (model.locked || model.saved == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SingleChapterPage(
          novel_id: widget.novel_id,
          novel_language_id: model.saved!.novel_language_id!,
          chapter_id: creatorNumber(row?['chapter_id']) > 0
              ? creatorNumber(row?['chapter_id'])
              : null,
          scheduled_revision_id:
              row != null && creatorNumber(row['chapter_id']) == 0
              ? creatorNumber(row['revision_id'])
              : null,
        ),
      ),
    );
    if (!mounted) return;
    try {
      await model.load_chapters();
    } catch (e) {
      model.error = '$e';
      _changed();
    }
  }

  Future<void> _delete() async {
    bool confirmed = false;
    await showMessage(
      message: tr('creator_center.delete_confirm_message'),
      iconData: Icons.delete_outline_rounded,
      iconColor: ColorConstants.dangerColor,
      leftButtonText: tr('common.cancel'),
      rightButtonText: tr('creator_center.delete'),
      rightButtonColor: ColorConstants.dangerColor,
      onRightPressed: () async => confirmed = true,
    );
    if (!confirmed || !mounted) return;
    try {
      await model.delete_work();
      if (!mounted) return;
      setState(() => _allow_pop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      /* 错误由控制器保留，允许重试。 */
    }
  }

  /// 每个 Tab 拥有自己的操作栏，横向切换时与内容一起移动。
  Widget _section(int section, Widget child, bool dark, bool cjk) => Column(
    children: [
      Expanded(
        child: AbsorbPointer(absorbing: model.locked, child: child),
      ),
      EditorBottomBar(
        key: ValueKey('published_section_action_$section'),
        is_dark: dark,
        is_cjk: cjk,
        current_step: 0,
        is_last_step: true,
        primary_title: tr(
          section == 2 && !model.order_dirty
              ? 'creator_workspace.new_chapter'
              : 'published_editor.update',
        ),
        primary_icon: section == 2 && !model.order_dirty
            ? Icons.add_rounded
            : Icons.check_rounded,
        on_primary:
            model.loading ||
                model.chapters_loading ||
                model.saving ||
                model.uploading ||
                (model.pending_section != null &&
                    model.pending_section != section)
            ? null
            : section == 2 && !model.order_dirty
            ? _chapter
            : () => _update(section),
        on_previous: () {},
      ),
    ],
  );

  @override
  void dispose() {
    tabs.dispose();
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final dark = Get.find<DeviceInfo>().dark.value;
    final cjk = LanguageUtil.is_cjk_language(context.locale.languageCode);
    return PopScope(
      canPop: _allow_pop,
      onPopInvokedWithResult: (did_pop, _) {
        if (!did_pop) _leave();
      },
      child: Scaffold(
        backgroundColor: AuthorStyle.background(dark),
        body: Column(
          children: [
            PublishedEditorHeader(
              controller: tabs,
              is_dark: dark,
              is_cjk: cjk,
              on_back: _leave,
              on_delete:
                  model.saved == null ||
                      model.saving ||
                      model.loading ||
                      model.uploading ||
                      (model.pending_section != null &&
                          model.pending_section != 3)
                  ? null
                  : _delete,
            ),
            Expanded(
              child: model.saved == null
                  ? Center(
                      child: model.loading
                          ? const CircularProgressIndicator(
                              color: AuthorStyle.gold,
                            )
                          : TextButton(
                              onPressed: model.load,
                              child: Text(
                                model.error ?? tr('published_editor.retry'),
                              ),
                            ),
                    )
                  : Column(
                      children: [
                        if (model.saving ||
                            model.loading ||
                            model.chapters_loading)
                          const LinearProgressIndicator(
                            color: AuthorStyle.gold,
                          ),
                        if (model.error != null)
                          Padding(
                            padding: WorkspaceStyle.padding,
                            child: Text(
                              model.error!,
                              style: WorkspaceStyle.caption(dark, cjk),
                            ),
                          ),
                        Expanded(
                          child: TabBarView(
                            controller: tabs,
                            children: [
                              _section(
                                0,
                                StepBasic(
                                  is_dark: dark,
                                  is_editing: true,
                                  title_controller: model.title,
                                  introduction_controller: model.introduction,
                                  language_code: model.language_code,
                                  cover_local_path: model.cover_local_path,
                                  cover_url: model.cover_url,
                                  is_uploading_cover: model.uploading,
                                  on_pick_cover: () => showImageSourceSheet(
                                    context: context,
                                    on_gallery: () =>
                                        model.pick_cover(ImageSource.gallery),
                                    on_camera: () =>
                                        model.pick_cover(ImageSource.camera),
                                  ),
                                  on_language_changed: model.set_language,
                                ),
                                dark,
                                cjk,
                              ),
                              _section(
                                1,
                                StepCategory(
                                  is_dark: dark,
                                  selected_preference_map: model.preferences,
                                  on_toggle_preference: model.toggle_preference,
                                  showLength: false,
                                ),
                                dark,
                                cjk,
                              ),
                              AbsorbPointer(
                                absorbing: model.locked,
                                child: PublishedChapterDirectory(
                                  model: model,
                                  is_dark: dark,
                                  is_cjk: cjk,
                                  on_open: _chapter,
                                  on_new_chapter: () => _chapter(),
                                ),
                              ),
                            ],
                          ),
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
