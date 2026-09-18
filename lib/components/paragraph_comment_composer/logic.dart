// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'input_panel_logic.dart';
import 'package:app/components/paragraph_comment_composer/style.dart';
import 'package:app/components/paragraph_comment_composer/upload_image.dart';

/// 一张选中的本地图片；上传失败保留字节，用户可移除或再次发送重试。
class ParagraphCommentImage {
  final Uint8List bytes;
  final String filename;
  String? url;

  ParagraphCommentImage({required this.bytes, required this.filename});
}

/// 管理段评草稿、表情插入、图片上传和提交生命周期。
class ParagraphCommentComposerLogic extends ChangeNotifier {
  /// 返回 true 表示服务端已接受评论，此时才关闭弹窗。
  final Future<bool> Function(String content, List<String> images) on_send;
  final VoidCallback on_close;
  final Future<List<XFile>> Function()? pick_images;
  final Future<String?> Function(Uint8List bytes, String filename) upload_image;
  final TextEditingController controller = TextEditingController();
  final FocusNode focus_node = FocusNode();
  final List<ParagraphCommentImage> images = <ParagraphCommentImage>[];

  /// 键盘和表情的占位独立管理，不混入图片上传及发送状态。
  final ParagraphInputPanelLogic input_panel = ParagraphInputPanelLogic();

  bool get show_emoji => input_panel.show_emoji;
  bool is_picking = false;
  bool is_uploading = false;
  bool is_sending = false;
  // 路由退出动画期间控件尚未销毁，仍需立刻阻止迟到的异步回调。
  bool _is_closed = false;
  bool _is_disposed = false;
  String? error_key;

  ParagraphCommentComposerLogic({
    required this.on_send,
    required this.on_close,
    this.pick_images,
    this.upload_image = upload_paragraph_comment_image,
  }) {
    controller.addListener(_refresh);
    input_panel.addListener(_refresh);
  }

  bool get is_busy => is_picking || is_uploading || is_sending;
  bool get is_active => !_is_closed && !_is_disposed;
  bool get can_send =>
      is_active &&
      !is_busy &&
      (controller.text.trim().isNotEmpty || images.isNotEmpty);

  /// 切换键盘与表情面板，失焦不会关闭整个编辑弹窗。
  void toggle_emoji() {
    if (!is_active || is_sending) return;
    if (!show_emoji) {
      input_panel.activate_emoji();
      focus_node.unfocus();
    } else {
      input_panel.activate_keyboard();
      focus_node.requestFocus();
    }
    _refresh();
  }

  /// 与后端统一按 UTF-16 长度限制文本，避免表情超过服务端限制。
  TextEditingValue limit_content(
    TextEditingValue old_value,
    TextEditingValue new_value,
  ) => new_value.text.length <= ParagraphCommentComposerStyle.max_content_length
      ? new_value
      : old_value;

  /// 用户直接点按输入框时切回系统键盘。
  void activate_input() {
    if (!is_active || !show_emoji) return;
    input_panel.activate_keyboard();
    focus_node.requestFocus();
    _refresh();
  }

  /// 在当前光标/选区处插入表情，保留此前输入内容。
  void insert_emoji(String emoji) {
    if (!is_active || is_sending) return;
    final TextEditingValue value = controller.value;
    final int start = value.selection.isValid
        ? value.selection.start.clamp(0, value.text.length)
        : value.text.length;
    final int end = value.selection.isValid
        ? value.selection.end.clamp(start, value.text.length)
        : start;
    final String next_text = value.text.replaceRange(start, end, emoji);
    if (next_text.length > ParagraphCommentComposerStyle.max_content_length) {
      return;
    }
    controller.value = TextEditingValue(
      text: next_text,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  /// 打开系统相册并立即上传；权限取消和上传失败不会丢失文字草稿。
  Future<void> add_images() async {
    if (!is_active || is_busy) return;
    if (images.length >= ParagraphCommentComposerStyle.max_images) {
      error_key = 'paragraph_comment.image_limit';
      _refresh();
      return;
    }
    is_picking = true;
    input_panel.deactivate();
    error_key = null;
    focus_node.unfocus();
    _refresh();
    try {
      final List<XFile> selected =
          await (pick_images?.call() ??
              ImagePicker().pickMultiImage(
                maxWidth: ParagraphCommentComposerStyle.image_max_dimension,
                maxHeight: ParagraphCommentComposerStyle.image_max_dimension,
                imageQuality: ParagraphCommentComposerStyle.image_quality,
              ));
      if (!is_active) return;
      final int remaining =
          ParagraphCommentComposerStyle.max_images - images.length;
      for (final XFile image in selected.take(remaining)) {
        final Uint8List bytes = await image.readAsBytes();
        if (!is_active) return;
        images.add(ParagraphCommentImage(bytes: bytes, filename: image.name));
      }
      if (selected.length > remaining) {
        error_key = 'paragraph_comment.image_limit';
      }
      is_picking = false;
      _refresh();
      await _upload_pending_images();
    } catch (_) {
      if (is_active) error_key = 'paragraph_comment.image_upload_failed';
    } finally {
      if (is_active) {
        is_picking = false;
        focus_node.requestFocus();
        _refresh();
      }
    }
  }

  /// 移除图片不会影响其余已上传图片，下次发送不会重复上传成功项。
  void remove_image(ParagraphCommentImage image) {
    if (!is_active || is_busy) return;
    images.remove(image);
    error_key = null;
    _refresh();
  }

  /// 串行补传尚未上传的图片；任一失败则保留全部草稿并禁止部分提交。
  Future<bool> _upload_pending_images() async {
    if (!is_active) return false;
    if (images.every((ParagraphCommentImage image) => image.url != null)) {
      return true;
    }
    is_uploading = true;
    _refresh();
    try {
      for (final ParagraphCommentImage image in images) {
        if (image.url != null) continue;
        final String? url = await upload_image(image.bytes, image.filename);
        if (!is_active) return false;
        if (url == null || url.isEmpty) {
          error_key = 'paragraph_comment.image_upload_failed';
          return false;
        }
        image.url = url;
        _refresh();
      }
      return true;
    } catch (_) {
      if (is_active) error_key = 'paragraph_comment.image_upload_failed';
      return false;
    } finally {
      if (is_active) {
        is_uploading = false;
        _refresh();
      }
    }
  }

  /// 支持文字、表情、纯图片及图文；锁定提交以避免连续点击重复发段评。
  Future<void> send() async {
    if (!can_send) return;
    if (controller.text.trim().length >
        ParagraphCommentComposerStyle.max_content_length) {
      error_key = 'paragraph_comment.content_too_long';
      _refresh();
      return;
    }
    is_sending = true;
    error_key = null;
    _refresh();
    try {
      if (!await _upload_pending_images() || !is_active) return;
      final bool success = await on_send(
        controller.text.trim(),
        images.map((ParagraphCommentImage image) => image.url!).toList(),
      );
      if (!is_active) return;
      if (success) {
        close();
      } else {
        error_key = 'paragraph_comment.send_failed';
      }
    } catch (_) {
      if (is_active) error_key = 'paragraph_comment.send_failed';
    } finally {
      if (is_active) {
        is_sending = false;
        _refresh();
      }
    }
  }

  /// 遮罩、空白和成功提交统一通过此入口关闭键盘及路由。
  void close() {
    if (!is_active) return;
    deactivate();
    on_close();
  }

  /// 遮罩和系统返回已执行路由退出，只停止输入和异步回调，不再重复 pop。
  void deactivate() {
    if (!is_active) return;
    _is_closed = true;
    input_panel.deactivate();
    focus_node.unfocus();
  }

  void _refresh() {
    if (is_active) notifyListeners();
  }

  @override
  void dispose() {
    _is_disposed = true;
    input_panel.removeListener(_refresh);
    input_panel.dispose();
    controller.removeListener(_refresh);
    focus_node.unfocus();
    focus_node.dispose();
    controller.dispose();
    super.dispose();
  }
}
