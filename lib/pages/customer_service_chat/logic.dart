// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import 'package:app/config/constant.dart';
import 'package:app/models/file_upload.dart';
import 'package:app/websocket/websocket_service.dart';
import 'package:app/stores/customer_service_chat_history_store.dart';
import 'package:app/util/audio_util/play_ringtone.dart';
import 'package:app/util/log_util.dart';
import 'style.dart';

/// TODO 在线客服聊天页交互逻辑。
///
/// 全局消息、分页和 WebSocket 数据由 [CustomerServiceChatHistoryStore]
/// 统一管理；当前类只负责页面级控制器、输入交互和滚动行为。
class ChatLogic {
  /// TODO 靠近底部时收到新消息自动跟随的距离。
  static const double _follow_bottom_threshold = 160;

  /// TODO 全局聊天历史状态。
  final CustomerServiceChatHistoryStore _history_store =
      Get.find<CustomerServiceChatHistoryStore>();

  /// TODO 输入框控制器。
  final TextEditingController text_controller = TextEditingController();

  /// TODO 输入框焦点节点。
  final FocusNode focus_node = FocusNode();

  /// TODO 反向消息列表滚动控制器，offset=0 始终是最新消息一端。
  final ScrollController scroll_controller = ScrollController();

  /// TODO 是否显示表情面板。
  bool show_emoji_panel = false;

  /// TODO 页面状态更新回调。
  final VoidCallback on_update;

  /// TODO 上次已处理的管理员实时消息序号。
  late int _received_message_revision;

  /// TODO 滚动请求序号，用于合并同一帧内的重复跟随请求。
  int _scroll_request_revision = 0;

  /// TODO 页面逻辑是否已经释放。
  bool _is_disposed = false;

  ChatLogic(this.on_update) {
    _received_message_revision = _history_store.received_message_revision;
    _history_store.addListener(_handle_store_update);
    scroll_controller.addListener(_handle_scroll);
    focus_node.addListener(_handle_focus_change);
    unawaited(_history_store.open_conversation());
  }

  List<ChatMessageItem> get messages => _history_store.messages;
  bool get is_loading_history => _history_store.is_loading_more;
  bool get is_initial_loading => _history_store.is_initial_loading;
  bool get has_more_history => _history_store.has_more_history;

  /// TODO 按稳定键返回消息在反向列表中的索引。
  int? find_message_index_by_key(String local_key) {
    return _history_store.find_message_index_by_key(local_key);
  }

  /// TODO 响应全局 Store 变化并只对真实新回复执行跟随滚动。
  void _handle_store_update() {
    final int latest_revision = _history_store.received_message_revision;
    final bool received_new_message =
        latest_revision != _received_message_revision;

    double old_offset = 0;
    double old_max_extent = 0;
    bool should_follow_bottom = true;
    if (received_new_message && scroll_controller.hasClients) {
      old_offset = scroll_controller.offset;
      old_max_extent = scroll_controller.position.maxScrollExtent;
      should_follow_bottom = old_offset <= _follow_bottom_threshold;
    }

    _received_message_revision = latest_revision;
    if (!received_new_message) return;
    AudioUtil.play_message_ringtone();

    if (should_follow_bottom) {
      scroll_to_bottom();
    } else {
      _preserve_viewport_after_bottom_insert(old_offset, old_max_extent);
    }
  }

  /// TODO 输入框获得焦点时关闭表情面板，并保持最新消息可见。
  void _handle_focus_change() {
    if (!focus_node.hasFocus) return;
    close_emoji_panel();
    scroll_to_bottom();
  }

  /// TODO 只在接近历史顶部时触发下一页，避免频繁请求。
  void _handle_scroll() {
    if (!scroll_controller.hasClients) return;
    _try_load_more_history(scroll_controller.position);
  }

  /// TODO 捕获用户下拉和边缘回弹通知，确保到达历史顶部必定触发分页。
  bool handle_scroll_notification(ScrollNotification notification) {
    if (notification.depth == 0) {
      _try_load_more_history(notification.metrics);
    }
    return false;
  }

  /// TODO 在反向列表的最大 offset 边缘加载更旧消息。
  void _try_load_more_history(ScrollMetrics metrics) {
    if (is_loading_history || !has_more_history) return;

    final double distance_to_history_edge =
        metrics.maxScrollExtent - metrics.pixels;
    if (distance_to_history_edge <=
        CustomerServiceChatStyle.history_load_threshold) {
      unawaited(_history_store.load_more_history());
    }
  }

  /// TODO 阅读旧消息时收到新回复，保持当前可见内容不变。
  void _preserve_viewport_after_bottom_insert(
    double old_offset,
    double old_max_extent,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scroll_controller.hasClients) return;
      final double new_max_extent = scroll_controller.position.maxScrollExtent;
      final double inserted_extent = new_max_extent - old_max_extent;
      final double target_offset = (old_offset + inserted_extent).clamp(
        scroll_controller.position.minScrollExtent,
        new_max_extent,
      );
      scroll_controller.jumpTo(target_offset);
    });
  }

  /// TODO 发送文字消息并立即写入全局缓存。
  void send_text_message() {
    final String text = text_controller.text.trim();
    if (text.isEmpty) return;

    final int local_id = _history_store.add_local_message(
      message_type: 1,
      content: text,
    );
    _history_store.register_pending_confirmation(local_id);
    text_controller.clear();
    scroll_to_bottom();
    WebSocketService().send_chat_message(message_type: 1, content: text);
  }

  /// TODO 将表情插入当前光标位置。
  void insert_emoji(String emoji) {
    if (emoji.isEmpty) return;

    final TextSelection selection = text_controller.selection;
    final int selection_start = selection.isValid
        ? selection.start.clamp(0, text_controller.text.length)
        : text_controller.text.length;
    final int selection_end = selection.isValid
        ? selection.end.clamp(0, text_controller.text.length)
        : text_controller.text.length;
    final String updated_text = text_controller.text.replaceRange(
      selection_start,
      selection_end,
      emoji,
    );
    text_controller.value = TextEditingValue(
      text: updated_text,
      selection: TextSelection.collapsed(
        offset: selection_start + emoji.length,
      ),
    );
  }

  /// TODO 将选中图片立即加入全局缓存，然后在后台并发上传。
  void send_image_messages(List<String> file_paths) {
    final List<String> valid_paths = file_paths
        .where((String path) => path.isNotEmpty)
        .toList(growable: false);
    if (valid_paths.isEmpty) return;

    for (final String file_path in valid_paths) {
      final int local_id = _history_store.add_local_message(
        message_type: 3,
        content: file_path,
        is_uploading: true,
      );
      unawaited(_upload_and_send(local_id, file_path));
    }
    scroll_to_bottom();
  }

  /// TODO 上传图片后更新全局消息并通过 WebSocket 发送真实 URL。
  Future<void> _upload_and_send(int local_id, String file_path) async {
    try {
      final String? url = await _upload_file(File(file_path));
      if (url == null || url.isEmpty) {
        _history_store.mark_image_upload_failed(local_id);
        return;
      }

      final String remote_url = _resolve_upload_url(url);
      _history_store.mark_image_upload_complete(local_id, remote_url);
      _history_store.register_pending_confirmation(local_id);
      WebSocketService().send_chat_message(
        message_type: 3,
        content: remote_url,
      );
    } catch (error) {
      logUtil(msg: '图片上传失败: $error', type: 'e');
      _history_store.mark_image_upload_failed(local_id);
    }
  }

  /// TODO 将上传接口可能返回的相对路径转为完整网络地址。
  String _resolve_upload_url(String value) {
    final Uri? uploaded_uri = Uri.tryParse(value);
    if (uploaded_uri != null && uploaded_uri.hasScheme) return value;

    final Uri? request_uri = Uri.tryParse(Constant.requestUrl);
    return request_uri?.resolve(value).toString() ?? value;
  }

  /// TODO 上传单个图片文件并返回服务端 URL。
  Future<String?> _upload_file(File file) async {
    try {
      final String upload_url =
          '${Constant.requestUrl}${Constant.prefix}file/add';
      final FormData form_data = FormData.fromMap(<String, dynamic>{
        'file': await MultipartFile.fromFile(file.path),
      });
      final Response<dynamic> response = await Dio().post(
        upload_url,
        data: form_data,
      );
      if (response.statusCode != 200) return null;

      FileUpload result;
      if (response.data is Map<String, dynamic>) {
        result = FileUpload.fromJson(response.data as Map<String, dynamic>);
      } else if (response.data is String) {
        result = FileUpload.fromJson(
          Map<String, dynamic>.from(
            json.decode(response.data as String) as Map,
          ),
        );
      } else {
        return null;
      }
      return result.status && result.content.isNotEmpty ? result.content : null;
    } catch (error) {
      logUtil(msg: '图片上传异常: $error', type: 'e');
      return null;
    }
  }

  /// TODO 切换表情面板并保持最新消息可见。
  void toggle_emoji_panel() {
    show_emoji_panel = !show_emoji_panel;
    if (show_emoji_panel) {
      focus_node.unfocus();
    } else {
      focus_node.requestFocus();
    }
    on_update();
    scroll_to_bottom();
  }

  /// TODO 键盘弹出时关闭表情面板。
  void close_emoji_panel() {
    if (!show_emoji_panel) return;
    show_emoji_panel = false;
    on_update();
  }

  /// TODO 平滑跟随到最新消息；反向列表的底部为最小 offset。
  void scroll_to_bottom() {
    final int request_revision = ++_scroll_request_revision;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_is_disposed ||
          request_revision != _scroll_request_revision ||
          !scroll_controller.hasClients ||
          !scroll_controller.position.hasContentDimensions) {
        return;
      }

      final double target_offset = scroll_controller.position.minScrollExtent;
      if ((scroll_controller.offset - target_offset).abs() < 0.5) return;

      scroll_controller.animateTo(
        target_offset,
        duration: CustomerServiceChatStyle.scroll_animation_duration,
        curve: Curves.easeOutCubic,
      );
    });
  }

  /// TODO 释放页面资源，但不清空全局聊天历史。
  void dispose() {
    _is_disposed = true;
    _scroll_request_revision++;
    _history_store.removeListener(_handle_store_update);
    _history_store.close_conversation();
    focus_node.removeListener(_handle_focus_change);
    scroll_controller.removeListener(_handle_scroll);
    scroll_controller.dispose();
    text_controller.dispose();
    focus_node.dispose();
  }
}
