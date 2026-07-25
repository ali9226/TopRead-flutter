// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:app/models/message_data.dart';
import 'package:app/api/message.dart' as message_api;
import 'package:app/api/post_request.dart';
import 'package:app/fcm/fcm_service.dart';
import 'package:app/stores/utils/merge_unique_message_list.dart';
import 'package:app/websocket/websocket_service.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/storage_util/index.dart';

/// 消息桶：每个筛选类型独立存储，互不干扰。
class _MessageBucket {
  final list = <MessageData>[].obs;
  bool has_loaded = false;
  bool has_more = true;
  int current_page = 1;
  final is_loading = false.obs;
}

/// 全局消息状态管理。
///
/// 消息列表按类型分桶存储（全部/评论/点赞/收藏），切换筛选时直接展示对应桶的数据，
/// 不会出现竞态问题。未读数统计、角标等全局状态仍统一管理。
class MessageStore extends GetxController {
  /// 单例实例。
  static MessageStore get to => Get.find<MessageStore>();

  /// 未读消息总数（用于底部导航角标）。
  final unread_total = 0.obs;

  /// 在线客服未读消息数。
  final chat_unread = 0.obs;

  /// 评论相关未读数（评论回复）。
  final comment_unread = 0.obs;

  /// 评论相关总数。
  final comment_total = 0.obs;

  /// 点赞相关未读数（评论点赞 + 小说点赞）。
  final like_unread = 0.obs;

  /// 点赞相关总数。
  final like_total = 0.obs;

  /// 收藏相关未读数（小说收藏）。
  final favorite_unread = 0.obs;

  /// 收藏相关总数。
  final favorite_total = 0.obs;

  /// 角标更新防抖定时器。
  Timer? _badge_update_timer;

  /// WebSocket 消息订阅。
  StreamSubscription? _ws_subscription;

  // ==================== 分桶存储 ====================

  /// 按类型分桶：null=全部, 2=评论, 3=点赞, 5=收藏。
  final Map<int?, _MessageBucket> _buckets = {
    null: _MessageBucket(),
    2: _MessageBucket(),
    3: _MessageBucket(),
    5: _MessageBucket(),
  };

  /// 当前激活的筛选类型。
  ///
  /// 使用响应式状态作为消息页筛选的唯一数据源，确保常驻页面也能同步外部筛选。
  final Rxn<int> _active_type = Rxn<int>();

  /// 获取当前激活的桶。
  _MessageBucket get _active_bucket => _buckets[_active_type.value]!;

  /// 当前展示的消息列表（代理到激活桶的 list）。
  List<MessageData> get message_list => _active_bucket.list;

  /// 当前是否还有更多数据。
  bool get has_more => _active_bucket.has_more;

  /// 当前是否已完成首次加载。
  bool get has_loaded => _active_bucket.has_loaded;

  /// 当前筛选类型（只读）。
  int? get filter_type => _active_type.value;

  /// 当前桶是否正在加载中。
  bool get is_loading => _active_bucket.is_loading.value;

  @override
  void onInit() {
    super.onInit();
    _listen_websocket();
  }

  // ==================== 筛选切换 ====================

  /// 切换消息类型筛选。
  /// [type] 为 null 时显示全部消息。
  /// 如果目标桶已有数据则直接展示，否则自动加载。
  Future<void> set_filter_type(int? type) async {
    if (_active_type.value == type) return;
    _active_type.value = type;

    // 如果目标桶未加载过，自动加载
    if (!_active_bucket.has_loaded) {
      await fetch_message_list(page: 1, is_refresh: true);
    }
  }

  // ==================== 数据加载 ====================

  /// 刷新所有数据（未读数 + 当前桶第一页）。
  @override
  Future<void> refresh() async {
    await Future.wait(<Future<void>>[
      fetch_statistics(),
      fetch_message_list(page: 1, is_refresh: true),
    ]);
  }

  /// 静默刷新（后台更新当前桶数据）。
  Future<void> silent_refresh() async {
    await Future.wait(<Future<void>>[
      fetch_statistics(),
      fetch_message_list(page: 1, is_refresh: true, silent: true),
    ]);
  }

  /// 获取统计数据（总数和未读数）。
  Future<void> fetch_statistics() async {
    if (!Get.find<UserInformation>().isLoggedIn.value) return;

    final MessageUnreadCount? result = await message_api.get_unread_count();
    if (result == null) return;

    comment_unread.value = result.comment_unread;
    comment_total.value = result.comment_total;
    like_unread.value = result.like_unread;
    like_total.value = result.like_total;
    favorite_unread.value = result.favorite_unread;
    favorite_total.value = result.favorite_total;
    chat_unread.value = result.chat_unread;
    _recompute_unread_total();
  }

  /// 获取消息列表（加载到当前激活的桶）。
  Future<void> fetch_message_list({
    required int page,
    bool is_refresh = false,
    bool silent = false,
  }) async {
    if (!Get.find<UserInformation>().isLoggedIn.value) return;

    final int? requested_type = _active_type.value;
    final bucket = _active_bucket;
    if (bucket.is_loading.value) return;
    bucket.is_loading.value = true;

    try {
      final MessageListResult? result = await message_api.inquire_message_list(
        page: page,
        page_size: 20,
        type: requested_type,
      );

      if (result == null) {
        return;
      }

      // 更新客服聊天未读数
      chat_unread.value = result.chat_unread;

      if (is_refresh) {
        bucket.list.value = merge_unique_message_list(
          current_messages: const <MessageData>[],
          incoming_messages: result.list,
        );
        bucket.current_page = page;
      } else {
        // 后端关联多语言封面时，同一条消息可能在当前页或相邻页重复。
        // 一次性合并并按稳定身份去重，避免 ListView 收到重复 Key。
        bucket.list.value = merge_unique_message_list(
          current_messages: bucket.list,
          incoming_messages: result.list,
        );
        bucket.current_page = page;
      }

      // 仅全部桶插入客服消息
      if (requested_type == null && result.chat_message != null) {
        final filtered = bucket.list
            .where((m) => m.type != MessageType.chat_reply)
            .toList();
        bucket.list.value = merge_unique_message_list(
          current_messages: <MessageData>[result.chat_message!],
          incoming_messages: filtered,
        );
      }

      _recompute_unread_total();
      bucket.has_more = result.list.length >= 20;
      bucket.has_loaded = true;
    } catch (e) {
      debugPrint('TODO MessageStore fetch_message_list error: $e');
    } finally {
      bucket.is_loading.value = false;
    }
  }

  /// 加载更多（当前桶翻页）。
  Future<void> load_more() async {
    final bucket = _active_bucket;
    if (bucket.is_loading.value || !bucket.has_more) return;
    await fetch_message_list(page: bucket.current_page + 1);
  }

  // ==================== 消息操作 ====================

  /// 标记单条消息为已读（更新所有包含该消息的桶）。
  Future<void> mark_as_read(int message_id) async {
    final bool success = await message_api.read_message(id: message_id);
    if (!success) return;

    MessageData? unread_message;
    for (final bucket in _buckets.values) {
      final int index = bucket.list.indexWhere((m) => m.id == message_id);
      if (index >= 0 && bucket.list[index].is_unread) {
        final old = bucket.list[index];
        unread_message ??= old;
        bucket.list[index] = MessageData(
          id: old.id,
          user_id: old.user_id,
          title: old.title,
          introduction: old.introduction,
          content: old.content,
          type: old.type,
          send_user: old.send_user,
          send_time: old.send_time,
          notify_status: NotifyStatus.read,
          sender_name: old.sender_name,
          sender_avatar: old.sender_avatar,
          novel_cover: old.novel_cover,
        );
        bucket.list.refresh();
      }
    }

    if (unread_message != null) {
      _update_type_unread(unread_message.type, -1);
      _recompute_unread_total();
    }
  }

  /// 标记所有消息为已读（更新所有桶）。
  Future<void> mark_all_as_read() async {
    final bool success = await message_api.read_all_messages();
    if (!success) return;

    for (final bucket in _buckets.values) {
      bucket.list.value = bucket.list
          .where((m) => m.type != MessageType.chat_reply)
          .map((m) {
            if (m.is_unread) {
              return MessageData(
                id: m.id,
                user_id: m.user_id,
                title: m.title,
                introduction: m.introduction,
                content: m.content,
                type: m.type,
                send_user: m.send_user,
                send_time: m.send_time,
                notify_status: NotifyStatus.read,
                sender_name: m.sender_name,
                sender_avatar: m.sender_avatar,
                novel_cover: m.novel_cover,
              );
            }
            return m;
          })
          .toList();
    }

    chat_unread.value = 0;
    comment_unread.value = 0;
    like_unread.value = 0;
    favorite_unread.value = 0;
    _recompute_unread_total();
  }

  /// 删除单条消息（从所有桶中移除）。
  Future<void> delete_message(int message_id) async {
    final bool success = await message_api.delete_message(id: message_id);
    if (!success) return;

    MessageData? deleted_message;
    for (final bucket in _buckets.values) {
      final index = bucket.list.indexWhere((m) => m.id == message_id);
      if (index >= 0) {
        deleted_message ??= bucket.list[index];
        bucket.list.value = bucket.list
            .where((m) => m.id != message_id)
            .toList();
      }
    }

    if (deleted_message?.is_unread ?? false) {
      _update_type_unread(deleted_message!.type, -1);
      _recompute_unread_total();
    }
  }

  /// 更新在线客服未读数。
  void update_chat_unread(int count) {
    chat_unread.value = count;
    if (count == 0) {
      for (final bucket in _buckets.values) {
        bucket.list.value = bucket.list
            .where((m) => m.type != MessageType.chat_reply)
            .toList();
      }
    }
    _recompute_unread_total();
  }

  /// 获取访客的客服聊天未读数（未登录时调用）。
  Future<void> fetch_visitor_chat_unread() async {
    comment_unread.value = 0;
    comment_total.value = 0;
    like_unread.value = 0;
    like_total.value = 0;
    favorite_unread.value = 0;
    favorite_total.value = 0;
    for (final bucket in _buckets.values) {
      bucket.list.clear();
    }

    final String? visitor_id = await StorageUtil.getData('visitor_uuid');
    if (visitor_id == null || visitor_id.isEmpty) {
      chat_unread.value = 0;
      _recompute_unread_total();
      return;
    }

    final int unread = await message_api.get_visitor_chat_unread(
      visitor_id: visitor_id,
    );
    chat_unread.value = unread;
    _recompute_unread_total();
  }

  /// 清空所有数据（登出时调用）。
  void clear() {
    for (final bucket in _buckets.values) {
      bucket.list.clear();
      bucket.has_loaded = false;
      bucket.has_more = true;
      bucket.current_page = 1;
      bucket.is_loading.value = false;
    }
    _active_type.value = null;
    unread_total.value = 0;
    chat_unread.value = 0;
    comment_unread.value = 0;
    comment_total.value = 0;
    like_unread.value = 0;
    like_total.value = 0;
    favorite_unread.value = 0;
    favorite_total.value = 0;
  }

  // ==================== 内部方法 ====================

  /// 重新计算未读总数并更新角标。
  void _recompute_unread_total() {
    final int new_total =
        comment_unread.value +
        like_unread.value +
        favorite_unread.value +
        chat_unread.value;
    if (new_total == unread_total.value) return;
    unread_total.value = new_total;
    _badge_update_timer?.cancel();
    _badge_update_timer = Timer(const Duration(milliseconds: 500), () {
      FcmService().update_badge(unread_total.value);
    });
  }

  /// 更新指定类型的未读数。
  void _update_type_unread(int type, int delta) {
    if (type == MessageType.comment_reply) {
      comment_unread.value = (comment_unread.value + delta).clamp(0, 9999);
    } else if (type == MessageType.comment_like ||
        type == MessageType.novel_like) {
      like_unread.value = (like_unread.value + delta).clamp(0, 9999);
    } else if (type == MessageType.novel_favorite) {
      favorite_unread.value = (favorite_unread.value + delta).clamp(0, 9999);
    }
  }

  /// 从 WebSocket 数据更新未读数。
  void _update_unread_from_ws(Map<String, dynamic> data) {
    comment_unread.value = _parse_int(data['comment_unread']);
    comment_total.value = _parse_int(data['comment_total']);
    like_unread.value = _parse_int(data['like_unread']);
    like_total.value = _parse_int(data['like_total']);
    favorite_unread.value = _parse_int(data['favorite_unread']);
    favorite_total.value = _parse_int(data['favorite_total']);
    _recompute_unread_total();
  }

  /// 监听 WebSocket 推送。
  void _listen_websocket() {
    final ws = WebSocketService();
    _ws_subscription = ws.message_stream.listen((data) {
      final String type = data['type'] ?? '';
      final dynamic payload = data['data'];

      switch (type) {
        case 'new_message':
          if (payload is Map) {
            final Map<String, dynamic> payload_map = Map<String, dynamic>.from(
              payload,
            );

            final Map<String, dynamic>? unread_data =
                payload_map['unread_count'] is Map
                ? Map<String, dynamic>.from(payload_map['unread_count'])
                : null;
            if (unread_data != null) {
              _update_unread_from_ws(unread_data);
            }

            final dynamic message_data = payload_map['message'];
            if (message_data is Map) {
              final Map<String, dynamic> msg = Map<String, dynamic>.from(
                message_data,
              );
              final int msg_type = _parse_int(msg['type']);

              if (msg_type == MessageType.comment_reply) {
                comment_unread.value++;
              } else if (msg_type == MessageType.comment_like ||
                  msg_type == MessageType.novel_like) {
                like_unread.value++;
              } else if (msg_type == MessageType.novel_favorite) {
                favorite_unread.value++;
              }
              _recompute_unread_total();

              final new_message = MessageData.from_json(msg);
              _insert_message_to_buckets(new_message);
            }
          }
          break;

        case 'unread_count':
          if (payload is Map) {
            _update_unread_from_ws(Map<String, dynamic>.from(payload));
          }
          break;

        case 'chat_unread':
          if (payload is Map) {
            final Map<String, dynamic> chat_data = Map<String, dynamic>.from(
              payload,
            );
            final int unread = _parse_int(chat_data['unread']);
            chat_unread.value = unread;
            _recompute_unread_total();
          }
          break;

        case 'chat_message':
          if (payload is Map) {
            final Map<String, dynamic> chat_data = Map<String, dynamic>.from(
              payload,
            );
            final int unread = _parse_int(chat_data['unread']);
            chat_unread.value = unread;
            _recompute_unread_total();

            final dynamic message_data = chat_data['message'];
            if (message_data is Map) {
              final Map<String, dynamic> msg = Map<String, dynamic>.from(
                message_data,
              );
              final new_message = MessageData.from_json(msg);

              // 移除已有的客服消息后插入到全部桶
              final all_bucket = _buckets[null]!;
              final filtered = all_bucket.list
                  .where((m) => m.type != MessageType.chat_reply)
                  .toList();
              all_bucket.list.value = [new_message, ...filtered];
            }
          }
          break;

        default:
          break;
      }
    });
  }

  /// 将新消息插入到匹配的桶中（自动去重，原子替换）。
  void _insert_message_to_buckets(MessageData message) {
    for (final entry in _buckets.entries) {
      final int? bucket_type = entry.key;
      final _MessageBucket bucket = entry.value;

      // 去重：如果已存在则跳过
      if (bucket.list.any((m) => m.id == message.id)) continue;

      // 全部桶：总是插入
      if (bucket_type == null) {
        bucket.list.value = [message, ...bucket.list];
        continue;
      }
      // 类型桶：匹配时插入
      if (bucket_type == message.type) {
        bucket.list.value = [message, ...bucket.list];
      }
    }
  }

  /// 从后端查询聊天未读数。
  Future<void> fetch_chat_unread() async {
    if (!Get.find<UserInformation>().isLoggedIn.value) return;
    try {
      final results = await postRequest<Map<String, dynamic>>(
        path: 'customer_service_chat/unread_count',
        showTips: false,
        fromJson: (json) => json,
      );
      if (results.status && results.content != null) {
        final int unread = results.content!['unread'] is int
            ? results.content!['unread'] as int
            : int.tryParse(results.content!['unread']?.toString() ?? '0') ?? 0;
        chat_unread.value = unread;
        _recompute_unread_total();
      }
    } catch (e) {
      debugPrint('fetch_chat_unread error: $e');
    }
  }

  /// 解析整数。
  static int _parse_int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  @override
  void onClose() {
    _ws_subscription?.cancel();
    _badge_update_timer?.cancel();
    super.onClose();
  }
}
