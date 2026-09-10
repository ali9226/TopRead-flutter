// ignore_for_file: non_constant_identifier_names

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app/components/image_source_sheet/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/work_editor/chapter_editor/index.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/work_editor/widgets/steps/step_publish/widgets/schedule_time/picker.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/upload_file.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// 作品编辑器文件处理 Mixin。
///
/// 负责文件上传、封面管理、章节管理等操作。
mixin WorkEditorFileMixin {
  /// 是否已挂载。
  bool get mounted;

  /// BuildContext。
  BuildContext get context;

  /// 设备信息。
  DeviceInfo get device_info;

  /// 封面选择器。
  ImagePicker get image_picker;

  /// 长篇章节列表。
  List<CreatorChapterDraft> get chapters;

  /// 本地封面图片路径（上传中使用）。
  String? get cover_local_path;
  set cover_local_path(String? value);

  /// 已上传的封面 URL。
  String? get cover_url;
  set cover_url(String? value);

  /// 是否正在上传封面。
  bool get is_uploading_cover;
  set is_uploading_cover(bool value);

  /// 标题输入控制器。
  dynamic get chapter_title_controller;

  /// 长篇章节正文输入控制器。
  dynamic get chapter_content_controller;

  /// 短篇正文输入控制器。
  dynamic get short_content_controller;

  /// 通知状态变更的回调。
  void Function(void Function()) get notifyStateChanged;

  /// 上传短篇文件（txt、docx），解析内容到正文框。
  Future<void> upload_short_file() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'docx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final PlatformFile file = result.files.first;
      final Uint8List? bytes = file.bytes;
      if (bytes == null) return;

      String content;
      if (file.name.endsWith('.docx')) {
        content = docxToText(bytes);
      } else {
        content = utf8.decode(bytes);
      }

      if (!mounted) return;

      notifyStateChanged(() {
        short_content_controller.text = content;
      });

      showBottomTip(easy.tr('creator_center.file_upload_success'));
    } catch (e) {
      if (!mounted) return;
      showBottomTip(easy.tr('creator_center.file_read_failed'));
    }
  }

  /// 上传长篇文件（txt、docx），解析内容到输入框。
  ///
  /// 如果标题输入框为空，使用文件名（去掉扩展名）作为章节标题。
  Future<void> upload_long_file() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'docx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final PlatformFile file = result.files.first;
      final Uint8List? bytes = file.bytes;
      if (bytes == null) return;

      String content;
      if (file.name.endsWith('.docx')) {
        content = docxToText(bytes);
      } else {
        content = utf8.decode(bytes);
      }

      if (!mounted) return;

      notifyStateChanged(() {
        // 填入正文内容。
        chapter_content_controller.text = content;

        // 如果标题为空，使用文件名作为标题。
        if (chapter_title_controller.text.trim().isEmpty) {
          final String title = file.name.replaceAll(
            RegExp(r'\.(txt|docx)$'),
            '',
          );
          chapter_title_controller.text = title;
        }
      });

      showBottomTip(easy.tr('creator_center.file_upload_success'));
    } catch (e) {
      if (!mounted) return;
      showBottomTip(easy.tr('creator_center.file_read_failed'));
    }
  }

  /// 选择相册或相机中的封面，上传到服务器。
  Future<void> pick_cover(ImageSource source) async {
    if (is_uploading_cover) return;

    try {
      final XFile? image = await image_picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 90,
      );
      if (image == null) return;

      if (!mounted) return;

      // 立即显示本地图片。
      notifyStateChanged(() {
        cover_local_path = image.path;
        is_uploading_cover = true;
      });

      // 上传到服务器。
      final String? url = await uploadFile(File(image.path));

      if (!mounted) return;

      if (url != null) {
        notifyStateChanged(() {
          cover_url = url;
          cover_local_path = null;
        });
      } else {
        showBottomTip(easy.tr('creator_center.cover_upload_failed'));
        notifyStateChanged(() => cover_local_path = null);
      }
    } catch (_) {
      if (mounted) {
        showBottomTip(easy.tr('creator_center.cover_upload_failed'));
        notifyStateChanged(() => cover_local_path = null);
      }
    } finally {
      if (mounted) notifyStateChanged(() => is_uploading_cover = false);
    }
  }

  /// 打开封面来源选择面板。
  Future<void> open_cover_picker() async {
    await showImageSourceSheet(
      context: context,
      on_gallery: () => pick_cover(ImageSource.gallery),
      on_camera: () => pick_cover(ImageSource.camera),
    );
  }

  /// 新增章节。
  Future<void> add_chapter() async {
    final CreatorChapterDraft? chapter = await Navigator.of(context)
        .push<CreatorChapterDraft>(
          MaterialPageRoute<CreatorChapterDraft>(
            builder: (BuildContext context) =>
                ChapterEditorPage(chapter_number: chapters.length + 1),
          ),
        );

    if (chapter == null || !mounted) return;
    notifyStateChanged(() => chapters.add(chapter));
  }

  /// 编辑指定章节。
  Future<void> edit_chapter(int index) async {
    final CreatorChapterDraft current_chapter = chapters[index];
    final CreatorChapterDraft? chapter = await Navigator.of(context)
        .push<CreatorChapterDraft>(
          MaterialPageRoute<CreatorChapterDraft>(
            builder: (BuildContext context) => ChapterEditorPage(
              chapter_number: index + 1,
              initial_chapter: current_chapter,
            ),
          ),
        );

    if (chapter == null || !mounted) return;
    notifyStateChanged(() => chapters[index] = chapter);
  }

  /// 删除章节前二次确认，避免误触导致本地长文本丢失。
  Future<void> delete_chapter(int index) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialog_context) {
        final bool is_dark = device_info.dark.value;
        return AlertDialog(
          backgroundColor: AuthorStyle.surface(is_dark),
          title: Text(
            easy.tr('creator_center.delete_chapter'),
            style: TextStyle(color: AuthorStyle.primary_text(is_dark)),
          ),
          content: Text(
            easy.tr('creator_center.delete_chapter_confirm'),
            style: TextStyle(color: AuthorStyle.secondary_text(is_dark)),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialog_context).pop(false),
              child: Text(easy.tr('common.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialog_context).pop(true),
              child: Text(
                easy.tr('creator_center.delete'),
                style: TextStyle(color: ColorConstants.dangerColor),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    notifyStateChanged(() => chapters.removeAt(index));
  }

  /// 打开底部日期时间选择器。
  Future<void> select_schedule_time({
    required DateTime? scheduled_publish_time,
    required void Function(DateTime?) on_time_selected,
  }) async {
    final bool is_dark = device_info.dark.value;

    final DateTime? result = await show_schedule_time_picker(
      context: context,
      is_dark: is_dark,
      initial_time: scheduled_publish_time,
    );

    if (result != null) {
      on_time_selected(result);
    }
  }
}
