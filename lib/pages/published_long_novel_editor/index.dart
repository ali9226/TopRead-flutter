// ignore_for_file: non_constant_identifier_names

import 'package:app/components/image_source_sheet/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/work_editor/_shared/widgets/editor_actions.dart';
import 'package:app/pages/work_editor/_shared/widgets/steps/step_basic/step_basic.dart';
import 'package:app/pages/work_editor/_shared/widgets/steps/step_category/step_category.dart';
import 'package:app/pages/work_editor/single_chapter/index.dart';
import 'package:app/pages/work_editor/_shared/style.dart';
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
  int _last_tab_index = 0;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 3, vsync: this)
      ..addListener(_on_tab_changed);
    model = PublishedNovelController(widget.novel_id)..addListener(_changed);
    model.load();
  }

  void _on_tab_changed() {
    if (tabs.index != _last_tab_index) {
      _last_tab_index = tabs.index;
      FocusManager.instance.primaryFocus?.unfocus();
    }
    _changed();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _leave() async {
    if (model.saving || model.uploading) return;
    if (model.dirty || model.pending_section != null) {
      String? action;
      await showMessage(
        message: tr('creator_center.unsaved_changes_message'),
        iconData: Icons.info_outline_rounded,
        leftButtonText: tr('creator_center.no_save'),
        rightButtonText: tr('creator_center.save_and_exit'),
        onLeftPressed: () async => action = 'discard',
        onRightPressed: () async {
          action = 'save';
          // 乐观锁：发起保存请求后立即退出，不等结果
          for (final section in [0, 1]) {
            if (section == 0 && model.details_dirty) {
              model.update_section(section).then((_) {
                if (model.error == null) showBottomTip(tr('published_editor.updated'));
              }).catchError((_) {});
            } else if (section == 1 && model.settings_dirty) {
              model.update_section(section).then((_) {
                if (model.error == null) showBottomTip(tr('published_editor.updated'));
              }).catchError((_) {});
            }
          }
          if (model.order_dirty) {
            model.update_order().then((_) {
              if (model.error == null) showBottomTip(tr('published_editor.updated'));
            }).catchError((_) {});
          }
        },
      );
      if (action == null || !mounted) return;
    }
    setState(() => _allow_pop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _update(int section) async {
    if (model.saving || model.uploading) return;
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
  Widget _section(int section, Widget child, bool dark, bool cjk) {
    final bottom_inset = MediaQuery.viewInsetsOf(context).bottom;
    final safe_bottom = MediaQuery.viewPaddingOf(context).bottom;
    final button_bottom = bottom_inset > 0
        ? bottom_inset + 8
        : safe_bottom + 14;
    return Stack(
      children: [
        Positioned.fill(
          child: AbsorbPointer(absorbing: model.locked, child: child),
        ),
        Positioned(
          left: WorkEditorStyle.page_padding,
          right: WorkEditorStyle.page_padding,
          bottom: button_bottom,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: WorkEditorStyle.content_max_width,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed:
                      model.loading ||
                          model.chapters_loading ||
                          model.saving ||
                          model.uploading ||
                          (model.pending_section != null &&
                              model.pending_section != section)
                      ? null
                      : () => _update(section),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(
                      WorkEditorStyle.action_height,
                    ),
                    backgroundColor: AuthorStyle.gold,
                    foregroundColor: WorkEditorStyle.action_foreground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        WorkEditorStyle.action_radius,
                      ),
                    ),
                    textStyle: TextStyle(
                      fontSize: cjk
                          ? WorkEditorStyle.action_font_size_cjk
                          : WorkEditorStyle.action_font_size_alphabetic,
                      fontWeight: AuthorStyle.title_weight,
                    ),
                  ),
                  child: Text(tr('published_editor.update')),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

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
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
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
      ),
    );
  });
}
