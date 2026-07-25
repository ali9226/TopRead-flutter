// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:app/config/constant.dart';
import 'package:app/websocket/config.dart';
import 'package:app/websocket/websocket_status.dart';
import 'package:app/websocket/websocket_heartbeat.dart';
import 'package:app/websocket/websocket_reconnect.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:app/util/log_util.dart';
import 'package:uuid/uuid.dart';

/// 本地存储访客 UUID 的 key。
const String _visitor_uuid_key = 'visitor_uuid';

/// WebSocket 服务。
///
/// 负责与后端 WebSocket 服务器的连接、认证。
/// 支持已登录用户（token）和匿名访客（UUID）两种连接方式。
class WebSocketService with WidgetsBindingObserver {
  /// 单例。
  static final WebSocketService _instance = WebSocketService._();
  factory WebSocketService() => _instance;
  WebSocketService._();

  /// WebSocket 通道。
  WebSocketChannel? _channel;

  /// 连接状态。
  WebSocketStatus _status = WebSocketStatus.disconnected;

  /// 状态流控制器。
  final _status_controller = StreamController<WebSocketStatus>.broadcast();

  /// 消息流控制器。
  final _message_controller = StreamController<Map<String, dynamic>>.broadcast();

  /// 心跳管理器。
  late final WebSocketHeartbeat _heartbeat;

  /// 重连管理器。
  late final WebSocketReconnect _reconnect;

  /// 是否已销毁。
  bool _is_disposed = false;

  /// 是否在前台。
  bool _is_foreground = true;

  /// 是否已注册生命周期观察者。
  bool _observer_registered = false;

  /// 当前连接是否为访客模式。
  bool _is_visitor = false;

  /// 连接状态流。
  Stream<WebSocketStatus> get status_stream => _status_controller.stream;

  /// 消息流。
  Stream<Map<String, dynamic>> get message_stream => _message_controller.stream;

  /// 是否已连接。
  bool get is_connected => _status == WebSocketStatus.connected;

  /// 当前是否为访客模式。
  bool get is_visitor => _is_visitor;

  /// 初始化子模块。
  void _init_modules() {
    _heartbeat = WebSocketHeartbeat(
      onPing: () => send({'type': 'ping'}),
    );
    _reconnect = WebSocketReconnect(
      onReconnect: () => connect(),
    );
  }

  /// 注册生命周期观察者。
  void _ensure_observer() {
    if (!_observer_registered) {
      _init_modules();
      WidgetsBinding.instance.addObserver(this);
      _observer_registered = true;
    }
  }

  /// 生命周期变化处理。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        // 回到前台，恢复心跳，必要时重连。
        _is_foreground = true;
        if (_status == WebSocketStatus.connected) {
          _heartbeat.start();
        } else if (_status != WebSocketStatus.connecting) {
          connect();
        }
        break;
      case AppLifecycleState.paused:
        // 进入后台，暂停心跳（避免被系统杀死）。
        _is_foreground = false;
        _heartbeat.stop();
        break;
      default:
        break;
    }
  }

  /// 获取或生成访客 UUID。
  ///
  /// 首次访问时生成 UUID 并缓存到本地，后续直接读取。
  /// 可在 connect() 之前单独调用，确保 UUID 已存在。
  Future<String> get_or_create_visitor_uuid() async {
    final String? cached = await StorageUtil.getData(_visitor_uuid_key);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final String uuid = const Uuid().v4();
    await StorageUtil.saveData(_visitor_uuid_key, uuid);
    logUtil(msg: 'WebSocket 生成新的访客 UUID: $uuid');
    return uuid;
  }

  /// 连接 WebSocket 服务器。
  ///
  /// 已登录用户使用 token 连接，未登录用户使用 visitor_id（UUID）连接。
  Future<void> connect() async {
    if (_is_disposed) return;
    if (_status == WebSocketStatus.connecting || _status == WebSocketStatus.connected) {
      return;
    }

    _ensure_observer();
    _update_status(WebSocketStatus.connecting);

    try {
      final String base_url = WebsocketConfig.requestUrl;
      String ws_url;

      // 检查是否有 token（已登录）。
      final String? token = await StorageUtil.getData(Constant.tokenKey);
      if (token != null && token.isNotEmpty) {
        ws_url = '$base_url?token=${Uri.encodeComponent(token)}';
        _is_visitor = false;
        logUtil(msg: 'WebSocket 以已登录用户身份连接');
      } else {
        final String visitor_id = await get_or_create_visitor_uuid();
        ws_url = '$base_url?visitor_id=${Uri.encodeComponent(visitor_id)}';
        _is_visitor = true;
        logUtil(msg: 'WebSocket 以访客身份连接: $visitor_id');
      }

      logUtil(msg: 'WebSocket 连接地址: $ws_url');

      _channel = WebSocketChannel.connect(Uri.parse(ws_url));

      _channel!.stream.listen(
        _on_message,
        onDone: _on_done,
        onError: _on_error,
      );

      // 连接成功，重置重连状态。
      _reconnect.reset();
      _update_status(WebSocketStatus.connected);

      // 只在前台时启动心跳。
      if (_is_foreground) {
        _heartbeat.start();
      }

      logUtil(msg: 'WebSocket 连接成功');
    } catch (e) {
      logUtil(msg: 'WebSocket 连接异常: $e', type: 'e');
      _update_status(WebSocketStatus.disconnected);
      _reconnect.schedule(isForeground: _is_foreground);
    }
  }

  /// 断开连接。
  void disconnect() {
    _heartbeat.stop();
    _reconnect.cancel();
    _channel?.sink.close();
    _channel = null;
    _update_status(WebSocketStatus.disconnected);
    logUtil(msg: 'WebSocket 已断开');
  }

  /// 发送消息。
  void send(Map<String, dynamic> data) {
    if (!is_connected || _channel == null) return;
    try {
      _channel!.sink.add(json.encode(data));
    } catch (e) {
      logUtil(msg: 'WebSocket 发送失败: $e', type: 'e');
    }
  }

  /// 发送聊天消息。
  ///
  /// [message_type] 消息类型：1=文字 2=表情 3=图片
  /// [content] 消息内容
  void send_chat_message({int message_type = 1, required String content}) {
    send({
      'type': 'chat_send',
      'data': {
        'message_type': message_type,
        'content': content,
      },
    });
  }

  /// 请求聊天历史消息。
  ///
  /// [session_id] 会话ID
  /// [page] 页码
  /// [page_size] 每页数量
  void fetch_chat_history({required int session_id, int page = 1, int page_size = 50}) {
    send({
      'type': 'chat_history',
      'data': {
        'session_id': session_id,
        'page': page,
        'page_size': page_size,
      },
    });
  }

  /// 标记聊天消息为已读。
  ///
  /// [session_id] 会话ID
  void mark_chat_read({required int session_id}) {
    send({
      'type': 'mark_read',
      'data': {
        'session_id': session_id,
      },
    });
  }

  /// 请求获取未读数。
  void fetch_unread_count() {
    send({'type': 'get_unread'});
  }

  /// 初始化聊天会话（获取或创建用户的会话）。
  void init_chat_session() {
    send({'type': 'chat_init_session'});
  }

  /// 处理收到的消息。
  void _on_message(dynamic message) {
    try {
      final Map<String, dynamic> data = json.decode(message.toString());
      _message_controller.add(data);
    } catch (e) {
      logUtil(msg: 'WebSocket 消息解析失败: $e', type: 'e');
    }
  }

  /// 连接关闭处理。
  void _on_done() {
    final closeCode = _channel?.closeCode;
    final closeReason = _channel?.closeReason;
    logUtil(msg: 'WebSocket 连接关闭 code=$closeCode reason=$closeReason');
    _heartbeat.stop();
    _channel = null;
    _update_status(WebSocketStatus.disconnected);
    _reconnect.schedule(isForeground: _is_foreground);
  }

  /// 连接错误处理。
  void _on_error(dynamic error) {
    logUtil(msg: 'WebSocket 错误: $error', type: 'e');
    _heartbeat.stop();
    _channel = null;
    _update_status(WebSocketStatus.disconnected);
    _reconnect.schedule(isForeground: _is_foreground);
  }

  /// 更新状态。
  void _update_status(WebSocketStatus new_status) {
    _status = new_status;
    _status_controller.add(new_status);
  }

  /// 销毁服务。
  void dispose() {
    _is_disposed = true;
    if (_observer_registered) {
      WidgetsBinding.instance.removeObserver(this);
      _observer_registered = false;
    }
    disconnect();
    _status_controller.close();
    _message_controller.close();
  }
}
