// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:app/api/customer_service_chat.dart';
import 'package:app/websocket/websocket_service.dart';
import 'package:app/stores/message_store.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:app/util/utc_time_util.dart';

/// TODO 在线客服消息数据。
///
/// [id] 为服务端消息 ID；本地乐观消息在确认前使用负数 ID。
/// [local_key] 在消息从本地状态切换为服务端状态时保持不变，
/// 用于保证 Flutter 列表元素复用的稳定性。
class ChatMessageItem {
  final int id;
  final int sender_type;
  final int message_type;
  final String content;
  final String create_time;
  final String sender_name;
  final bool is_uploading;
  final bool is_pending;
  final String server_content;
  final String local_key;

  const ChatMessageItem({
    required this.id,
    required this.sender_type,
    required this.message_type,
    required this.content,
    required this.create_time,
    required this.local_key,
    this.sender_name = '',
    this.is_uploading = false,
    this.is_pending = false,
    this.server_content = '',
  });

  /// TODO 从服务端响应构建消息。
  factory ChatMessageItem.from_json(Map<String, dynamic> json) {
    final int message_id = _parse_int(json['id']);
    return ChatMessageItem(
      id: message_id,
      sender_type: _parse_int(json['sender_type']),
      message_type: _parse_int(json['message_type']),
      content: json['content']?.toString() ?? '',
      create_time: normalize_utc_time(json['create_time']?.toString() ?? ''),
      sender_name: json['sender_name']?.toString() ?? '',
      local_key: 'server_$message_id',
    );
  }

  /// TODO 生成指定字段更新后的不可变消息。
  ChatMessageItem copy_with({
    int? id,
    int? sender_type,
    int? message_type,
    String? content,
    String? create_time,
    String? sender_name,
    bool? is_uploading,
    bool? is_pending,
    String? server_content,
    String? local_key,
  }) {
    return ChatMessageItem(
      id: id ?? this.id,
      sender_type: sender_type ?? this.sender_type,
      message_type: message_type ?? this.message_type,
      content: content ?? this.content,
      create_time: create_time ?? this.create_time,
      sender_name: sender_name ?? this.sender_name,
      is_uploading: is_uploading ?? this.is_uploading,
      is_pending: is_pending ?? this.is_pending,
      server_content: server_content ?? this.server_content,
      local_key: local_key ?? this.local_key,
    );
  }

  /// TODO 将服务端消息并入当前消息，同时保留本地图片预览路径。
  ChatMessageItem merge_server_message(ChatMessageItem server_message) {
    final bool keep_local_image =
        message_type == 3 &&
        content.isNotEmpty &&
        !content.startsWith('http') &&
        server_message.content.startsWith('http');

    return server_message.copy_with(
      content: keep_local_image ? content : server_message.content,
      server_content: server_message.content,
      local_key: local_key,
      is_uploading: false,
      is_pending: false,
    );
  }

  /// TODO 解析可能由字符串传输的整数字段。
  static int _parse_int(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

/// TODO 在线客服聊天全局状态。
///
/// 消息按“最新到最旧”保存，与 `ListView(reverse: true)` 的子节点顺序一致。
/// 加载更旧历史时只会在列表尾部增加节点，已显示节点的索引和视口
/// 偏移都不变，因此不需要任何布局后的跳转补偿。
class CustomerServiceChatHistoryStore extends GetxController {
  /// TODO 单次历史请求数量，兼顾首屏速度和翻页频率。
  static const int page_size = 30;

  /// TODO 访客 UUID 的本地存储键。
  static const String _visitor_uuid_key = 'visitor_uuid';

  /// TODO 访客标识加载器，允许测试精确模拟异步身份竞态。
  final Future<String> Function() _visitor_id_loader;

  /// TODO 所有已缓存消息，顺序为最新到最旧。
  final RxList<ChatMessageItem> messages = <ChatMessageItem>[].obs;

  /// TODO WebSocket 全局订阅，使页面退出后仍能补入新消息。
  StreamSubscription<Map<String, dynamic>>? _websocket_subscription;

  /// TODO 监听登录账号变化，及时切换聊天缓存所属身份。
  Worker? _user_identity_worker;

  /// TODO 当前用户的缓存隔离标识。
  String _identity_key = '';

  /// TODO 身份切换递增序号，用于废弃上一账号尚未返回的请求。
  int _identity_revision = 0;

  /// TODO 异步身份准备序号，防止早期访客请求覆盖后到的登录身份。
  int _identity_preparation_revision = 0;

  /// TODO 当前后端会话键，用于过滤其他账号消息。
  String _session_key = '';

  /// TODO 当前请求用的已登录用户 ID。
  int _user_id = 0;

  /// TODO 当前请求用的访客会话标识。
  String _visitor_id = '';

  /// TODO 后端返回的会话 ID。
  int _session_id = 0;

  /// TODO 后端当前总消息数。
  int _server_total = 0;

  /// TODO 后端是否还存在未被 exclude_ids 覆盖的历史消息。
  bool _has_more_history = true;

  /// TODO 是否至少完成过一次最近历史同步。
  bool _has_loaded = false;

  /// TODO 是否正在同步最近历史。
  bool _is_syncing_latest = false;

  /// TODO 是否正在准备当前用户或访客身份。
  bool _is_preparing_identity = false;

  /// TODO 是否正在加载更旧历史。
  bool _is_loading_more = false;

  /// TODO 当前可见聊天页实例数，用于决定是否立即清空未读数。
  int _active_page_count = 0;

  /// TODO 用于生成不与服务端 ID 冲突的本地消息 ID。
  int _next_local_id = -1;

  /// TODO 按真实发送顺序等待 WebSocket 确认的本地消息。
  final List<int> _pending_confirmation_ids = <int>[];

  /// TODO 收到管理员实时消息的递增序号，供页面精确判断自动滚动。
  int _received_message_revision = 0;

  int get session_id => _session_id;
  String get identity_key => _identity_key;
  String get session_key => _session_key;
  bool get has_loaded => _has_loaded;
  bool get is_syncing_latest => _is_syncing_latest;
  bool get is_loading_more => _is_loading_more;
  bool get is_initial_loading =>
      messages.isEmpty && (_is_preparing_identity || _is_syncing_latest);
  bool get has_more_history => _has_more_history;
  int get received_message_revision => _received_message_revision;

  /// TODO 只统计已获得服务端 ID 的消息，排除本地乐观消息。
  int get _server_message_count =>
      messages.where((ChatMessageItem item) => item.id > 0).length;

  CustomerServiceChatHistoryStore({
    Future<String> Function()? visitor_id_loader,
  }) : _visitor_id_loader = visitor_id_loader ?? _load_or_create_visitor_id;

  @override
  void onInit() {
    super.onInit();
    // TODO 只监听 WebSocket 消息，不主动请求历史
    _websocket_subscription = WebSocketService().message_stream.listen(
      handle_websocket_event,
    );
    // TODO 监听用户信息变化，但只在页面打开时才刷新历史
    if (Get.isRegistered<UserInformation>()) {
      _user_identity_worker = ever(
        Get.find<UserInformation>().userInfo,
        (_) => _on_user_identity_changed(),
      );
    }
  }

  /// TODO 用户身份变化时的处理（登录/登出）。
  ///
  /// 只在页面已打开时才刷新历史。
  /// 历史数据只在用户打开客服聊天页面时才加载。
  void _on_user_identity_changed() {
    // TODO 如果页面已打开，刷新历史
    if (_active_page_count > 0) {
      unawaited(_refresh_identity_and_history());
    }
  }

  /// TODO 在页面打开时重新校验身份并补齐漏消息。
  Future<void> _refresh_identity_and_history() async {
    if (!Get.isRegistered<UserInformation>()) return;
    if (!await _prepare_identity()) return;
    await synchronize_latest_history();
  }

  /// TODO 打开聊天会话。
  ///
  /// 已有缓存会立即供 UI 使用；同时从第一页开始向后查找与
  /// 缓存的重叠点，将退出页面期间可能缺失的所有消息补齐。
  Future<void> open_conversation() async {
    _active_page_count++;
    _is_preparing_identity = true;
    update();

    bool ready = false;
    try {
      ready = await _prepare_identity();
    } catch (error) {
      logUtil(msg: '准备在线客服用户身份失败: $error', type: 'e');
    } finally {
      _is_preparing_identity = false;
      update();
    }
    if (!ready) return;
    await synchronize_latest_history();

    // 用户打开客服页面，标记所有消息为已读
    if (Get.isRegistered<MessageStore>()) {
      Get.find<MessageStore>().update_chat_unread(0);
    }
    if (_session_id > 0) {
      final bool sent = WebSocketService().mark_chat_read(
        session_id: _session_id,
      );
      if (!sent) {
        // TODO 本次历史 HTTP 请求已经完成已读落库；重连事件会再次同步最新历史。
        logUtil(msg: '客服已读 WebSocket 暂未发送，等待重连后校准', type: 'w');
      }
    }
  }

  /// TODO 关闭页面可见状态，保留全部消息和分页信息。
  void close_conversation() {
    _active_page_count = math.max(0, _active_page_count - 1);
  }

  /// TODO 同步最近历史并自动补齐与本地缓存之间的缺口。
  Future<void> synchronize_latest_history() async {
    if (_is_syncing_latest || _is_loading_more || _identity_key.isEmpty) return;

    _is_syncing_latest = true;
    update();

    final int request_identity_revision = _identity_revision;
    final int request_user_id = _user_id;
    final String request_visitor_id = _visitor_id;

    try {
      final Map<String, dynamic>? result = await request_history(
        user_id: request_user_id,
        visitor_id: request_visitor_id,
        exclude_ids: _server_message_ids,
      );
      if (request_identity_revision != _identity_revision) return;
      if (result == null) return;

      _apply_response_metadata(result);
      final List<ChatMessageItem> parsed = _parse_messages(result['list']);
      _merge_server_messages(parsed);
      _has_loaded = true;
      update();
    } catch (error) {
      logUtil(msg: '同步在线客服历史失败: $error', type: 'e');
    } finally {
      if (request_identity_revision == _identity_revision) {
        _is_syncing_latest = false;
        update();
      }
    }
  }

  /// TODO 加载更旧的一页历史。
  Future<void> load_more_history() async {
    if (_is_loading_more || _is_syncing_latest || !has_more_history) return;
    if (!await _prepare_identity()) return;
    if (_is_loading_more || _is_syncing_latest || !has_more_history) return;

    _is_loading_more = true;
    update();

    final int request_identity_revision = _identity_revision;
    final int request_user_id = _user_id;
    final String request_visitor_id = _visitor_id;
    try {
      final Map<String, dynamic>? result = await request_history(
        user_id: request_user_id,
        visitor_id: request_visitor_id,
        exclude_ids: _server_message_ids,
      );
      if (request_identity_revision != _identity_revision) return;
      if (result == null) return;

      _apply_response_metadata(result);
      final List<ChatMessageItem> page_messages = _parse_messages(
        result['list'],
      );
      _merge_server_messages(page_messages);
      _has_loaded = true;
    } catch (error) {
      logUtil(msg: '加载更旧在线客服历史失败: $error', type: 'e');
    } finally {
      if (request_identity_revision == _identity_revision) {
        _is_loading_more = false;
        update();
      }
    }
  }

  /// TODO 创建并缓存本地乐观消息，返回本地消息 ID。
  int add_local_message({
    required int message_type,
    required String content,
    bool is_uploading = false,
  }) {
    final int local_id = _next_local_id--;
    final ChatMessageItem message = ChatMessageItem(
      id: local_id,
      sender_type: 1,
      message_type: message_type,
      content: content,
      create_time: DateTime.now().toUtc().toIso8601String(),
      is_uploading: is_uploading,
      is_pending: true,
      local_key: 'local_${local_id.abs()}',
    );
    messages.insert(0, message);
    update();
    return local_id;
  }

  /// TODO 记录已通过 WebSocket 真实发送、正在等待确认的消息。
  void register_pending_confirmation(int local_id) {
    if (!_pending_confirmation_ids.contains(local_id)) {
      _pending_confirmation_ids.add(local_id);
    }
  }

  /// TODO 完成图片上传，保留本地路径作为预览并记录服务端 URL。
  void mark_image_upload_complete(int local_id, String server_url) {
    final int index = messages.indexWhere(
      (ChatMessageItem item) => item.id == local_id,
    );
    if (index < 0) return;

    messages[index] = messages[index].copy_with(
      is_uploading: false,
      server_content: server_url,
    );
    update();
  }

  /// TODO 标记图片上传失败，停止加载遮罩且不等待发送确认。
  void mark_image_upload_failed(int local_id) {
    final int index = messages.indexWhere(
      (ChatMessageItem item) => item.id == local_id,
    );
    if (index < 0) return;

    messages[index] = messages[index].copy_with(
      is_uploading: false,
      is_pending: false,
    );
    _pending_confirmation_ids.remove(local_id);
    update();
  }

  /// TODO 根据稳定键查找反向列表中的子节点索引。
  int? find_message_index_by_key(String local_key) {
    final int index = messages.indexWhere(
      (ChatMessageItem item) => item.local_key == local_key,
    );
    return index < 0 ? null : index;
  }

  /// TODO 准备当前登录用户或访客的请求身份。
  ///
  /// 访客会话键与 WebSocket 服务端保持 `visitor_{uuid}` 格式，
  /// 避免 HTTP 历史和实时消息被错误分到两个会话。
  Future<bool> _prepare_identity() async {
    final int preparation_revision = ++_identity_preparation_revision;
    final UserInformation user_information = Get.find<UserInformation>();
    final int user_id = user_information.userInfo.value?.id ?? 0;

    String identity_key;
    String session_key;
    String visitor_id = '';
    if (user_id > 0) {
      identity_key = 'user_$user_id';
      session_key = '$user_id';
    } else {
      final String visitor_uuid = await _visitor_id_loader();
      if (preparation_revision != _identity_preparation_revision) return false;
      identity_key = 'visitor_$visitor_uuid';
      session_key = identity_key;
      visitor_id = session_key;
    }

    if (preparation_revision != _identity_preparation_revision) return false;
    final int current_user_id = user_information.userInfo.value?.id ?? 0;
    if (current_user_id != user_id) return _prepare_identity();

    if (_identity_key != identity_key) {
      _identity_revision++;
      _identity_key = identity_key;
      _session_key = session_key;
      _user_id = user_id;
      _visitor_id = visitor_id;
      _reset_conversation();
    }
    return true;
  }

  /// TODO 读取或生成本机访客 UUID。
  static Future<String> _load_or_create_visitor_id() async {
    String? visitor_uuid = await StorageUtil.getData(_visitor_uuid_key);
    if (visitor_uuid == null || visitor_uuid.isEmpty) {
      visitor_uuid = const Uuid().v4();
      await StorageUtil.saveData(_visitor_uuid_key, visitor_uuid);
    }
    return visitor_uuid;
  }

  /// TODO 切换账号时清空上一身份的内存数据，防止会话串扰。
  void _reset_conversation() {
    messages.clear();
    _session_id = 0;
    _server_total = 0;
    _has_more_history = true;
    _has_loaded = false;
    _is_syncing_latest = false;
    _is_loading_more = false;
    _pending_confirmation_ids.clear();
    update();
  }

  /// TODO 传入已有消息 ID，请求一批未缓存历史。
  Future<Map<String, dynamic>?> request_history({
    required int user_id,
    required String visitor_id,
    required List<int> exclude_ids,
  }) {
    return CustomerServiceChatApi.get_my_history(
      user_id: user_id,
      visitor_id: visitor_id,
      page_size: page_size,
      exclude_ids: exclude_ids,
    );
  }

  /// TODO 当前已缓存的全部服务端消息 ID，用于后端精确排除。
  List<int> get _server_message_ids => messages
      .where((ChatMessageItem item) => item.id > 0)
      .map((ChatMessageItem item) => item.id)
      .toSet()
      .toList(growable: false);

  /// TODO 应用每次 HTTP 响应中的会话和总数信息。
  void _apply_response_metadata(Map<String, dynamic> result) {
    final int response_session_id = _parse_int(result['session_id']);
    if (response_session_id > 0) {
      _session_id = response_session_id;
    }
    _server_total = _parse_int(result['total']);
    _has_more_history = _parse_bool(
      result['has_more'],
      fallback: _server_message_count < _server_total,
    );
  }

  /// TODO 将动态数组解析为强类型消息。
  List<ChatMessageItem> _parse_messages(dynamic source) {
    if (source is! List) return <ChatMessageItem>[];

    return source
        .whereType<Map>()
        .map(
          (Map item) =>
              ChatMessageItem.from_json(Map<String, dynamic>.from(item)),
        )
        .where((ChatMessageItem item) => item.id > 0)
        .toList();
  }

  /// TODO 去重并入服务端消息，并按时间从新到旧稳定排序。
  void _merge_server_messages(List<ChatMessageItem> server_messages) {
    if (server_messages.isEmpty) return;

    for (final ChatMessageItem server_message in server_messages) {
      final int server_index = messages.indexWhere(
        (ChatMessageItem item) => item.id == server_message.id,
      );
      if (server_index >= 0) {
        messages[server_index] = messages[server_index].merge_server_message(
          server_message,
        );
        continue;
      }

      final int pending_index = _find_matching_pending_message(server_message);
      if (pending_index >= 0) {
        final int local_id = messages[pending_index].id;
        messages[pending_index] = messages[pending_index].merge_server_message(
          server_message,
        );
        _pending_confirmation_ids.remove(local_id);
        continue;
      }

      messages.add(server_message);
    }

    messages.sort(_compare_messages_newest_first);
    messages.refresh();
  }

  /// TODO 将 HTTP 中已落库的用户消息与本地乐观消息匹配。
  int _find_matching_pending_message(ChatMessageItem server_message) {
    if (server_message.sender_type != 1) return -1;

    return messages.lastIndexWhere((ChatMessageItem local_message) {
      if (!local_message.is_pending || local_message.id > 0) return false;
      if (local_message.message_type != server_message.message_type) {
        return false;
      }
      return local_message.content == server_message.content ||
          local_message.server_content == server_message.content;
    });
  }

  /// TODO 处理全局 WebSocket 消息，页面退出后仍持续更新缓存。
  void handle_websocket_event(Map<String, dynamic> event) {
    final String type = event['type']?.toString() ?? '';
    switch (type) {
      case 'connected':
        // 只在客服页面打开时才刷新历史，避免启动时请求 my_history 接口。
        if (_active_page_count > 0) {
          unawaited(_refresh_identity_and_history());
        }
        break;
      case 'chat_receive':
      case 'chat_admin_reply':
        handle_received_message(event['data']);
        break;
      case 'chat_send_success':
        handle_send_success(event['data']);
        break;
    }
  }

  /// TODO 将管理员实时回复并入当前缓存。
  void handle_received_message(dynamic payload) {
    if (payload is! Map) return;
    if (_identity_key.isEmpty) {
      unawaited(_refresh_identity_and_history());
      return;
    }
    final Map<String, dynamic> data = Map<String, dynamic>.from(payload);
    if (_parse_int(data['sender_type']) != 2) return;

    final int payload_session_id = _parse_int(data['session_id']);
    final String payload_session_key = data['session_key']?.toString() ?? '';
    final bool has_comparable_session_ids =
        payload_session_id > 0 && _session_id > 0;
    if (has_comparable_session_ids && payload_session_id != _session_id) {
      return;
    }
    if (!has_comparable_session_ids &&
        payload_session_key.isNotEmpty &&
        payload_session_key != _session_key) {
      return;
    }

    final ChatMessageItem message = ChatMessageItem.from_json(data);
    if (message.id <= 0 ||
        messages.any((ChatMessageItem item) => item.id == message.id)) {
      return;
    }

    if (payload_session_id > 0) {
      _session_id = payload_session_id;
    }
    _server_total++;
    // TODO WebSocket 回复就是当前会话最新事件，反向列表必须放在索引 0。
    // 不使用不同数据链路的时间文本重排，避免 HTTP 与 WebSocket
    // 时区表示差异将新回复误放到历史顶部。
    messages.insert(0, message);
    _received_message_revision++;
    update();

    // 用户正在客服页面，自动通知后端消息已读。
    if (_active_page_count > 0) {
      if (Get.isRegistered<MessageStore>()) {
        scheduleMicrotask(() => Get.find<MessageStore>().update_chat_unread(0));
      }
      if (_session_id > 0) {
        final bool sent = WebSocketService().mark_chat_read(
          session_id: _session_id,
        );
        if (!sent) {
          // TODO 能收到实时消息说明连接刚刚可用；若发送阶段恰好断线，重连会补做 HTTP 已读。
          logUtil(msg: '实时客服已读回执暂未发送，等待重连后校准', type: 'w');
        }
      }
    }
  }

  /// TODO 用服务端 ID 和时间替换最早等待确认的本地消息。
  void handle_send_success(dynamic payload) {
    if (payload is! Map) return;
    final Map<String, dynamic> data = Map<String, dynamic>.from(payload);

    final int response_session_id = _parse_int(data['session_id']);
    if (response_session_id > 0) {
      _session_id = response_session_id;
    }

    final int message_id = _parse_int(data['message_id']);
    if (message_id <= 0) return;

    while (_pending_confirmation_ids.isNotEmpty) {
      final int local_id = _pending_confirmation_ids.removeAt(0);
      final int local_index = messages.indexWhere(
        (ChatMessageItem item) => item.id == local_id,
      );
      if (local_index < 0) continue;

      final ChatMessageItem local_message = messages[local_index];
      final int duplicate_index = messages.indexWhere(
        (ChatMessageItem item) => item.id == message_id,
      );
      final bool server_message_already_cached =
          duplicate_index >= 0 && duplicate_index != local_index;
      if (server_message_already_cached) {
        final ChatMessageItem cached_server_message = messages[duplicate_index];
        messages[local_index] = local_message
            .merge_server_message(cached_server_message)
            .copy_with(
              id: message_id,
              create_time: normalize_utc_time(
                data['create_time']?.toString() ??
                    cached_server_message.create_time,
              ),
            );
        messages.removeAt(duplicate_index);
      } else {
        messages[local_index] = local_message.copy_with(
          id: message_id,
          create_time: normalize_utc_time(
            data['create_time']?.toString() ?? local_message.create_time,
          ),
          is_pending: false,
        );
      }

      _server_total = server_message_already_cached
          ? math.max(_server_total, _server_message_count)
          : math.max(_server_total + 1, _server_message_count);
      messages.refresh();
      update();
      break;
    }
  }

  /// TODO 消息新旧排序：服务端消息使用自增 ID，本地消息使用递减负 ID。
  ///
  /// 同一会话内服务端 ID 严格递增，比 HTTP/WebSocket 两条链路的
  /// 时间字符串更可靠；本地待确认消息始终位于已落库消息前方。
  static int _compare_messages_newest_first(
    ChatMessageItem left,
    ChatMessageItem right,
  ) {
    final bool left_is_local = left.id <= 0;
    final bool right_is_local = right.id <= 0;
    if (left_is_local != right_is_local) return left_is_local ? -1 : 1;
    return left_is_local
        ? left.id.compareTo(right.id)
        : right.id.compareTo(left.id);
  }

  /// TODO 解析可能由字符串传输的整数字段。
  static int _parse_int(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// TODO 解析后端布尔值，并兼容旧接口未返回 has_more 的情况。
  static bool _parse_bool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final String normalized_value = value?.toString().toLowerCase() ?? '';
    if (normalized_value == 'true' || normalized_value == '1') return true;
    if (normalized_value == 'false' || normalized_value == '0') return false;
    return fallback;
  }

  @override
  void onClose() {
    _websocket_subscription?.cancel();
    _user_identity_worker?.dispose();
    super.onClose();
  }
}
