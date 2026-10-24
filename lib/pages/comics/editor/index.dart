// ignore_for_file: non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/components/image_source_sheet/index.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/editor/logic.dart';
import 'package:app/pages/comics/editor/models.dart';
import 'package:app/pages/comics/editor/style.dart';
import 'package:app/pages/comics/editor/widgets/action_bar.dart';
import 'package:app/pages/comics/editor/widgets/basic_info_form.dart';
import 'package:app/pages/comics/editor/widgets/language_section.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/pages/comics/widgets/empty_state.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/dialog/show_message.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

/// 漫画编辑器页面：基本信息 + 语种版本 + 章节图片 + 保存/提交/下架。
class ComicEditorPage extends StatefulWidget {
  /// 作品 id，0 或空表示新建。
  final int comic_id;

  /// 可注入的逻辑控制器（测试用）。
  final ComicEditorLogic? controller;

  const ComicEditorPage({super.key, this.comic_id = 0, this.controller});

  @override
  State<ComicEditorPage> createState() => _ComicEditorPageState();
}

class _ComicEditorPageState extends State<ComicEditorPage> {
  /// 编辑器业务逻辑。
  late final ComicEditorLogic _logic =
      widget.controller ?? ComicEditorLogic(widget.comic_id);

  /// 图片选择器。
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _logic.load();
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  /// 返回上一页；有未保存修改时二次确认。
  Future<void> _on_back() async {
    if (_logic.dirty) {
      final bool? leave = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialog_context) => AlertDialog(
          title: Text(tr('comics.unsaved_changes')),
          content: Text(tr('comics.save_draft')),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialog_context).pop(false),
              child: Text(tr('comics.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialog_context).pop(true),
              child: Text(tr('comics.delete')),
            ),
          ],
        ),
      );
      if (leave != true) return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  /// 保存草稿并提示结果。
  Future<void> _on_save_draft() async {
    final String? failure = await _logic.save_draft();
    if (!mounted) return;
    if (failure == null) {
      showBottomTip(tr('comics.draft_saved'));
    } else {
      showBottomTip(failure);
    }
  }

  /// 提交审核并提示结果。
  Future<void> _on_submit() async {
    final String? failure = await _logic.submit();
    if (!mounted) return;
    if (failure == null) {
      showBottomTip(tr('comics.submitted'));
    } else {
      showBottomTip(failure);
    }
  }

  /// 下架漫画确认。
  Future<void> _on_hide() async {
    await showMessage(
      message: tr('comics.remove_comic_confirm'),
      leftButtonText: tr('comics.cancel'),
      rightButtonText: tr('comics.remove_comic'),
      rightButtonColor: ColorConstants.dangerColor,
      iconColor: ColorConstants.dangerColor,
      onRightPressed: () async {
        final String? failure = await _logic.hide_comic();
        if (!mounted) return;
        if (failure == null) {
          showBottomTip(tr('comics.status_hidden'));
        } else {
          showBottomTip(failure);
        }
      },
    );
  }

  /// 选择并上传封面。
  Future<void> _pick_cover() async {
    await showImageSourceSheet(
      context: context,
      on_gallery: () => _upload_cover(ImageSource.gallery),
      on_camera: () => _upload_cover(ImageSource.camera),
    );
  }

  /// 执行封面上传。
  Future<void> _upload_cover(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 90,
    );
    if (file == null || !mounted) return;
    final Uint8List bytes = await file.readAsBytes();
    final ComicImageData? uploaded = await _logic.upload_image(
      bytes,
      file.name,
    );
    if (!mounted) return;
    if (uploaded == null) {
      showBottomTip(tr('comics.upload_failed'));
      return;
    }
    _logic.set_cover(uploaded.image_url);
  }

  /// 为指定章节批量上传图片。
  Future<void> _pick_chapter_images(int chapter_index) async {
    await showImageSourceSheet(
      context: context,
      on_gallery: () =>
          _upload_chapter_images(chapter_index, ImageSource.gallery),
      on_camera: () =>
          _upload_chapter_images(chapter_index, ImageSource.camera),
    );
  }

  /// 执行章节图片上传（相册可多选，拍照单张）。
  Future<void> _upload_chapter_images(
    int chapter_index,
    ImageSource source,
  ) async {
    final List<XFile> files = <XFile>[];
    if (source == ImageSource.gallery) {
      files.addAll(
        await _picker.pickMultiImage(maxWidth: 2400, imageQuality: 88),
      );
    } else {
      final XFile? shot = await _picker.pickImage(
        source: source,
        maxWidth: 2400,
        imageQuality: 88,
      );
      if (shot != null) files.add(shot);
    }
    if (files.isEmpty || !mounted) return;

    final List<ComicEditorImage> uploaded = <ComicEditorImage>[];
    for (final XFile file in files) {
      final Uint8List bytes = await file.readAsBytes();
      final ComicImageData? data = await _logic.upload_image(bytes, file.name);
      if (data != null) {
        uploaded.add(ComicEditorImage.from_data(data));
      }
    }
    if (uploaded.isEmpty) {
      if (mounted) showBottomTip(tr('comics.upload_failed'));
      return;
    }
    _logic.add_chapter_images(chapter_index, uploaded);
    if (mounted && uploaded.length != files.length) {
      showBottomTip(tr('comics.upload_failed'));
    }
  }

  /// 删除章节确认。
  Future<void> _remove_chapter(int chapter_index) async {
    await showMessage(
      message: tr('comics.remove_chapter_confirm'),
      leftButtonText: tr('comics.cancel'),
      rightButtonText: tr('comics.remove_chapter'),
      rightButtonColor: ColorConstants.dangerColor,
      iconColor: ColorConstants.dangerColor,
      onRightPressed: () async {
        _logic.remove_chapter(chapter_index);
      },
    );
  }

  /// 删除语种确认。
  Future<void> _remove_language(int language_index) async {
    await showMessage(
      message: tr('comics.remove_language_confirm'),
      leftButtonText: tr('comics.cancel'),
      rightButtonText: tr('comics.remove_language'),
      rightButtonColor: ColorConstants.dangerColor,
      iconColor: ColorConstants.dangerColor,
      onRightPressed: () async {
        _logic.remove_language(language_index);
      },
    );
  }

  /// 丢弃本地草稿确认。
  Future<void> _discard_draft() async {
    await showMessage(
      message: tr('comics.discard_draft'),
      leftButtonText: tr('comics.cancel'),
      rightButtonText: tr('comics.delete'),
      rightButtonColor: ColorConstants.dangerColor,
      iconColor: ColorConstants.dangerColor,
      onRightPressed: () async {
        await _logic.discard_draft();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = ComicsStyle.is_cjk(context);

    /// 审核中锁定编辑，避免后端 lock_work 直接报错。
    final bool enabled = !_logic.data.is_locked && !_logic.busy;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool did_pop, Object? result) {
        if (!did_pop) _on_back();
      },
      child: Scaffold(
        backgroundColor: ComicsStyle.background(context),
        appBar: WindowAppBar(
          child: AppBar(
            backgroundColor: ComicsStyle.background(context),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: _on_back,
            ),
            title: Text(
              _logic.data.is_new
                  ? tr('comics.new_comic')
                  : tr('comics.edit_comic'),
              style: ComicsStyle.heading(context),
            ),
            actions: <Widget>[
              /// 分享入口（已创建后可分享详情链接）。
              if (!_logic.data.is_new)
                IconButton(
                  tooltip: tr('comics.share'),
                  icon: const Icon(Icons.ios_share_rounded),
                  onPressed: () => _share(),
                ),
            ],
          ),
        ),
        bottomNavigationBar: ComicEditorActionBar(
          logic: _logic,
          enabled: enabled,
          on_save_draft: _on_save_draft,
          on_submit: _on_submit,
          on_hide: _logic.data.is_new ? null : _on_hide,
        ),
        body: WindowContentLayout(
          child: AnimatedBuilder(
            animation: _logic,
            builder: (BuildContext context, Widget? child) {
              if (_logic.loading) {
                return Center(
                  child: ComicsEmptyState(
                    loading: true,
                    message: tr('comics.loading'),
                  ),
                );
              }
              if (_logic.error != null && _logic.data.is_new) {
                return Center(
                  child: ComicsEmptyState(
                    error: _logic.error,
                    message: tr('comics.unavailable'),
                    on_retry: _logic.load,
                  ),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  ComicEditorStyle.page_padding,
                  ComicEditorStyle.section_spacing,
                  ComicEditorStyle.page_padding,
                  ComicEditorStyle.section_spacing,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    /// 本地草稿恢复横幅。
                    if (_logic.restored_draft)
                      _DraftBanner(on_discard: _discard_draft),

                    /// 审核锁定提示。
                    if (_logic.data.is_locked)
                      _LockedBanner(status: _logic.data.status),

                    /// 基本信息卡片。
                    _SectionCard(
                      child: BasicInfoForm(
                        logic: _logic,
                        enabled: enabled,
                        on_pick_cover: _pick_cover,
                      ),
                    ),

                    /// 语种 + 章节卡片。
                    const SizedBox(height: ComicEditorStyle.section_spacing),
                    _SectionCard(
                      child: LanguageSection(
                        logic: _logic,
                        enabled: enabled,
                        on_add_images: _pick_chapter_images,
                        on_remove_chapter: _remove_chapter,
                        on_remove_language: _remove_language,
                        on_pick_language_cover: _pick_cover,
                      ),
                    ),

                    /// 底部安全区留白。
                    const SizedBox(height: ComicEditorStyle.section_spacing),
                    if (is_cjk)
                      const SizedBox(height: LayoutConfig.space_4)
                    else
                      const SizedBox(height: LayoutConfig.space_8),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 复制分享链接并提示。
  void _share() {
    final String link = '/comics/detail?id=${_logic.data.id}';
    showBottomTip('${tr('comics.share_heading')}\n$link');
  }
}

/// 分区卡片容器：统一圆角、留白与日夜背景。
class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: ComicEditorStyle.card_padding_h,
        vertical: ComicEditorStyle.card_padding_v,
      ),
      decoration: BoxDecoration(
        color: ComicEditorStyle.card_background(context),
        borderRadius: BorderRadius.circular(ComicEditorStyle.card_radius),
        border: Border.all(
          color: ComicsStyle.outline(context).withValues(alpha: 0.7),
        ),
      ),
      child: child,
    );
  }
}

/// 本地草稿恢复横幅：提示 + 丢弃入口。
class _DraftBanner extends StatelessWidget {
  final VoidCallback on_discard;

  const _DraftBanner({required this.on_discard});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: ComicEditorStyle.banner_bottom_spacing,
      ),
      padding: ComicEditorStyle.banner_padding,
      decoration: BoxDecoration(
        color: ColorConstants.themeColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(ComicEditorStyle.banner_radius),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.history_rounded, size: 20),
          const SizedBox(width: LayoutConfig.space_10),
          Expanded(
            child: Text(
              tr('comics.draft_restored'),
              style: ComicsStyle.text(context, strong: true),
            ),
          ),
          TextButton(
            onPressed: on_discard,
            child: Text(
              tr('comics.discard_draft'),
              style: TextStyle(
                color: ColorConstants.dangerColor,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 审核锁定横幅。
class _LockedBanner extends StatelessWidget {
  final String status;

  const _LockedBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: ComicEditorStyle.banner_bottom_spacing,
      ),
      padding: ComicEditorStyle.banner_padding,
      decoration: BoxDecoration(
        color: ColorConstants.resolveTagColor(
          status.length,
        ).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(ComicEditorStyle.banner_radius),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.lock_outline_rounded, size: 20),
          const SizedBox(width: LayoutConfig.space_10),
          Expanded(
            child: Text(
              tr('comics.pending_locked'),
              style: ComicsStyle.text(context),
            ),
          ),
        ],
      ),
    );
  }
}
