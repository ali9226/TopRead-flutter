// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app/websocket/websocket_service.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/audio_util/play_ringtone.dart';
import 'package:app/api/post_request.dart';
import 'widgets/chat_message_list.dart';

/// 在线客服聊天逻辑处理。
///
/// 管理消息收发、WebSocket 监听、历史消息加载。
class ChatLogic {
    /// 当前上下文。
    final BuildContext context;

    /// WebSocket 消息订阅。
    StreamSubscription? _ws_subscription;

    /// 消息列表。
    final List<ChatMessageItem> messages = [];

    /// 当前会话ID（后端返回）。
    int session_id = 0;

    /// 是否正在加载。
    bool is_loading = false;

    /// 消息列表滚动控制器。
    final ScrollController scroll_controller = ScrollController();

    /// 输入框控制器。
    final TextEditingController text_controller = TextEditingController();

    /// 输入框焦点节点。
    final FocusNode focus_node = FocusNode();

    /// 是否显示表情面板。
    bool show_emoji_panel = false;

    /// 状态更新回调。
    final VoidCallback on_update;

    ChatLogic(this.context, this.on_update) {
        _listen_websocket();
    }

    /// 监听 WebSocket 推送的聊天消息。
    void _listen_websocket() {
        final ws = WebSocketService();
        _ws_subscription = ws.message_stream.listen((data) {
            final String type = data['type'] ?? '';

            switch (type) {
                case 'chat_receive':
                    // TODO 收到管理员回复
                    _handle_chat_receive(data['data']);
                    break;
                case 'chat_send_success':
                    // TODO 消息发送成功确认
                    _handle_send_success(data['data']);
                    break;
                case 'chat_history':
                    // TODO 历史消息
                    _handle_chat_history(data['data']);
                    break;
                case 'chat_admin_reply':
                    // TODO 管理员回复（管理员发的消息也会广播回来，需要区分）
                    _handle_chat_receive(data['data']);
                    break;
            }
        });
    }

    /// 处理收到的聊天消息（管理员回复）。
    void _handle_chat_receive(dynamic payload) {
        if (payload is! Map) return;
        final Map<String, dynamic> msg = Map<String, dynamic>.from(payload);

        final int sender_type = _parse_int(msg['sender_type']);
        // TODO 只处理管理员发的消息（用户自己发的通过 send_success 确认）
        if (sender_type != 2) return;

        final ChatMessageItem item = ChatMessageItem(
            id: _parse_int(msg['id']),
            sender_type: sender_type,
            message_type: _parse_int(msg['message_type']),
            content: msg['content']?.toString() ?? '',
            create_time: msg['create_time']?.toString() ?? '',
            sender_name: msg['sender_name']?.toString() ?? '',
        );

        // TODO 如果还没有 session_id，记录下来
        if (session_id == 0 && msg['session_id'] != null) {
            session_id = _parse_int(msg['session_id']);
        }

        messages.add(item);
        on_update();

        // TODO 播放消息提示铃声
        AudioUtil.play_message_ringtone();

        // TODO 滚动到底部
        _scroll_to_bottom();
    }

    /// 处理消息发送成功确认。
    void _handle_send_success(dynamic payload) {
        if (payload is! Map) return;
        final Map<String, dynamic> data = Map<String, dynamic>.from(payload);

        // TODO 记录 session_id（首次发送时后端返回）
        if (session_id == 0 && data['session_id'] != null) {
            session_id = _parse_int(data['session_id']);
        }
    }

    /// 处理历史消息。
    void _handle_chat_history(dynamic payload) {
        if (payload is! Map) return;
        final Map<String, dynamic> data = Map<String, dynamic>.from(payload);

        final List<dynamic> msg_list = data['messages'] is List ? data['messages'] : [];
        final int new_session_id = _parse_int(data['session_id']);

        if (new_session_id > 0) {
            session_id = new_session_id;
        }

        final List<ChatMessageItem> history = msg_list.map((msg) {
            final Map<String, dynamic> m = Map<String, dynamic>.from(msg);
            return ChatMessageItem(
                id: _parse_int(m['id']),
                sender_type: _parse_int(m['sender_type']),
                message_type: _parse_int(m['message_type']),
                content: m['content']?.toString() ?? '',
                create_time: m['create_time']?.toString() ?? '',
                sender_name: m['sender_name']?.toString() ?? '',
            );
        }).toList();

        // TODO 历史消息插入到列表前面
        messages.insertAll(0, history);
        is_loading = false;
        on_update();
    }

    /// 发送文字消息。
    void send_text_message() {
        final String text = text_controller.text.trim();
        if (text.isEmpty) return;

        // TODO 先添加到本地列表（乐观更新）
        messages.add(ChatMessageItem(
            id: DateTime.now().millisecondsSinceEpoch,
            sender_type: 1,
            message_type: 1,
            content: text,
            create_time: DateTime.now().toIso8601String(),
        ));
        on_update();
        _scroll_to_bottom();

        // TODO 通过 WebSocket 发送
        WebSocketService().send_chat_message(
            message_type: 1,
            content: text,
        );

        text_controller.clear();
    }

    /// 发送表情消息。
    void send_emoji_message(String emoji) {
        if (emoji.isEmpty) return;

        messages.add(ChatMessageItem(
            id: DateTime.now().millisecondsSinceEpoch,
            sender_type: 1,
            message_type: 2,
            content: emoji,
            create_time: DateTime.now().toIso8601String(),
        ));
        on_update();
        _scroll_to_bottom();

        WebSocketService().send_chat_message(
            message_type: 2,
            content: emoji,
        );
    }

    /// 选择并发送图片。
    Future<void> pick_and_send_image() async {
        try {
            final ImagePicker picker = ImagePicker();
            final XFile? image = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1024,
                maxHeight: 1024,
                imageQuality: 85,
            );

            if (image == null) return;

            // TODO 上传图片获取 URL
            final String? image_url = await _upload_image(image.path);
            if (image_url == null || image_url.isEmpty) return;

            messages.add(ChatMessageItem(
                id: DateTime.now().millisecondsSinceEpoch,
                sender_type: 1,
                message_type: 3,
                content: image_url,
                create_time: DateTime.now().toIso8601String(),
            ));
            on_update();
            _scroll_to_bottom();

            WebSocketService().send_chat_message(
                message_type: 3,
                content: image_url,
            );
        } catch (e) {
            logUtil(msg: 'TODO 选择图片失败: $e', type: 'e');
        }
    }

    /// 上传图片到服务器，返回图片 URL。
    Future<String?> _upload_image(String file_path) async {
        try {
            // TODO 使用已有的图片上传接口
            final results = await postRequest<Map<String, dynamic>>(
                path: 'upload/image',
                parameter: <String, dynamic>{'file_path': file_path},
                showTips: true,
            );
            if (results.status && results.content != null) {
                return results.content!['url']?.toString();
            }
        } catch (e) {
            logUtil(msg: 'TODO 图片上传失败: $e', type: 'e');
        }
        return null;
    }

    /// 切换表情面板显示。
    void toggle_emoji_panel() {
        show_emoji_panel = !show_emoji_panel;
        if (show_emoji_panel) {
            focus_node.unfocus();
        } else {
            focus_node.requestFocus();
        }
        on_update();
    }

    /// 滚动到底部。
    void _scroll_to_bottom() {
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (scroll_controller.hasClients) {
                scroll_controller.animateTo(
                    scroll_controller.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                );
            }
        });
    }

    /// 解析整数。
    static int _parse_int(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value;
        return int.tryParse(value.toString()) ?? 0;
    }

    /// 销毁资源。
    void dispose() {
        _ws_subscription?.cancel();
        scroll_controller.dispose();
        text_controller.dispose();
        focus_node.dispose();
    }
}
