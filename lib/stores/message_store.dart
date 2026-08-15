// ignore_for_file: non_constant_identifier_names, constant_identifier_names

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

typedef MessageListFetcher =
    Future<MessageListResult?> Function({
      required int page,
      required int page_size,
      int? type,
    });

/// 消息桶：每个筛选类型独立存储，互不干扰。
class _MessageBucket {
  final list = <MessageData>[].obs;
  bool has_loaded = false;
  bool has_more = true;
  bool refresh_pending = false;
  int current_page = 1;
  final is_loading = false.obs;

  /// 当前分桶真正在途的请求任务。
  Future<void>? request;

  /// 清空数据时递增，防止旧响应回写到新会话。
  int data_revision = 0;

  /// 当前在途请求的上下文，用于判断重复请求是复用还是追加刷新。
  int request_data_revision = -1;
  int request_auth_revision = -1;
  int request_mutation_revision = -1;
  bool request_is_refresh = false;
}

/// 全局消息状态管理。
///
/// 消息列表按类型分桶存储（全部/评论/点赞/收藏），切换筛选时直接展示对应桶的数据，
/// 不会出现竞态问题。未读数统计、角标等全局状态仍统一管理。
class MessageStore extends GetxController {
  MessageStore({
    Future<MessageUnreadCount?> Function()? fetch_unread_count,
    Future<message_api.MessageReadAllResult> Function()? read_all_messages,
    MessageListFetcher? fetch_message_list,
  }) : _fetch_unread_count = fetch_unread_count ?? message_api.get_unread_count,
       _read_all_messages = read_all_messages ?? message_api.read_all_messages,
       _fetch_message_list =
           fetch_message_list ?? message_api.inquire_message_list;

  /// 单例实例。
  static MessageStore get to => Get.find<MessageStore>();

  /// 未读统计请求实现，测试时可注入可控异步结果。
  final Future<MessageUnreadCount?> Function() _fetch_unread_count;

  /// 全部已读请求实现，测试时可注入可控异步结果。
  final Future<message_api.MessageReadAllResult> Function() _read_all_messages;

  /// 消息列表请求实现，测试时可注入可控异步结果。
  final MessageListFetcher _fetch_message_list;

  /// 未读消息总数（用于底部导航角标）。
  final unread_total = 0.obs;

  /// 在线客服未读消息数。
  final chat_unread = 0.obs;

  /// 系统通知及后端未来扩展类型的未读数。
  final system_unread = 0.obs;

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

  /// FCM 前台消息触发权威统计补拉的防抖定时器。
  Timer? _foreground_refresh_timer;

  /// 任意已应用未读状态的版本，用于丢弃并发请求的旧响应。
  int _unread_state_revision = 0;

  /// 本地已读操作版本，用于阻止操作前的列表响应恢复旧状态。
  int _local_unread_mutation_revision = 0;

  /// 最近一次未读统计请求序号。
  int _latest_statistics_request = 0;

  /// 未读统计当前在途任务。
  Future<void>? _statistics_request;

  /// 在途统计任务失效后是否需要串行补一次。
  bool _statistics_refresh_pending = false;

  /// 当前在途统计请求的状态上下文。
  int _statistics_request_auth_revision = -1;
  int _statistics_request_unread_revision = -1;
  int _statistics_request_mutation_revision = -1;

  /// 是否正在向后端同步全部已读。
  bool _is_marking_all_read = false;

  /// 全部已读期间是否收到需要再次校准未读数的信号。
  bool _unread_reconcile_pending = false;

  /// 全部已读期间是否收到需要刷新当前消息列表的信号。
  bool _list_refresh_pending = false;

  /// WebSocket 消息订阅。
  StreamSubscription? _ws_subscription;

  /// 是否已向 FCM 服务注册前台补拉回调。
  bool _foreground_callback_registered = false;

  /// 已处理的客服实时消息 ID，用于防止重连或重复推送造成角标重复累加。
  final Set<int> _processed_chat_message_ids = <int>{};

  /// 已处理的普通实时消息 ID，用于防止 Redis 重试或重连补发造成重复累加。
  final Set<int> _processed_message_ids = <int>{};

  /// 客服消息去重窗口大小。
  static const int _processed_chat_message_limit = 200;

  /// 普通消息去重窗口大小。
  static const int _processed_message_limit = 500;

  /// 最近处理的客服消息 ID，用于抵御乱序事件覆盖较新的权威未读数。
  int _latest_chat_message_id = 0;

  /// 最近处理的服务端消息状态版本，用于丢弃队列中迟到的旧事件。
  int _latest_server_state_version = 0;

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
    FcmService().on_foreground_data = handle_foreground_notification;
    _foreground_callback_registered = true;
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
    if (_is_marking_all_read) {
      _unread_reconcile_pending = true;
      return;
    }

    final UserInformation user_information = Get.find<UserInformation>();
    if (!user_information.isLoggedIn.value) return;

    final Future<void>? active_request = _statistics_request;
    if (active_request != null) {
      if (_statistics_request_auth_revision != user_information.auth_revision ||
          _statistics_request_unread_revision != _unread_state_revision ||
          _statistics_request_mutation_revision !=
              _local_unread_mutation_revision) {
        _statistics_refresh_pending = true;
      }
      await active_request;
      return;
    }

    late final Future<void> request;
    request = _drain_statistics_requests();
    _statistics_request = request;
    try {
      await request;
    } finally {
      if (identical(_statistics_request, request)) {
        _statistics_request = null;
      }
    }
  }

  /// 串行执行未读统计请求，过期期间的多次补拉只合并为一次。
  Future<void> _drain_statistics_requests() async {
    do {
      _statistics_refresh_pending = false;
      await _fetch_statistics_once();
    } while (_statistics_refresh_pending);
  }

  /// 执行一轮未读统计请求。
  Future<void> _fetch_statistics_once() async {
    final UserInformation user_information = Get.find<UserInformation>();
    if (!user_information.isLoggedIn.value) return;
    final int request_revision = user_information.auth_revision;
    final int unread_revision = _unread_state_revision;
    final int mutation_revision = _local_unread_mutation_revision;
    final int statistics_request = ++_latest_statistics_request;
    _statistics_request_auth_revision = request_revision;
    _statistics_request_unread_revision = unread_revision;
    _statistics_request_mutation_revision = mutation_revision;

    final MessageUnreadCount? result = await _fetch_unread_count();
    if (result == null) return;
    if (!user_information.can_apply_authenticated_response(request_revision)) {
      return;
    }
    if (_is_marking_all_read ||
        unread_revision != _unread_state_revision ||
        mutation_revision != _local_unread_mutation_revision ||
        statistics_request != _latest_statistics_request) {
      return;
    }

    _apply_unread_count(result);
  }

  /// 获取消息列表（加载到当前激活的桶）。
  Future<void> fetch_message_list({
    required int page,
    bool is_refresh = false,
    bool silent = false,
  }) async {
    if (_is_marking_all_read) {
      _unread_reconcile_pending = true;
      _list_refresh_pending = true;
      return;
    }

    final UserInformation user_information = Get.find<UserInformation>();
    if (!user_information.isLoggedIn.value) return;

    final int? requested_type = _active_type.value;
    final _MessageBucket bucket = _active_bucket;
    final Future<void>? active_request = bucket.request;
    if (active_request != null) {
      final bool request_context_changed =
          bucket.request_data_revision != bucket.data_revision ||
          bucket.request_auth_revision != user_information.auth_revision ||
          bucket.request_mutation_revision != _local_unread_mutation_revision;
      if (request_context_changed ||
          (is_refresh && !bucket.request_is_refresh)) {
        bucket.refresh_pending = true;
        bucket.is_loading.value = true;
      }
      await active_request;
      return;
    }

    late final Future<void> request;
    request = _drain_message_list_requests(
      bucket: bucket,
      requested_type: requested_type,
      page: page,
      is_refresh: is_refresh,
    );
    bucket.request = request;

    try {
      await request;
    } finally {
      if (identical(bucket.request, request)) {
        bucket.request = null;
      }
    }
  }

  /// 串行执行单个筛选桶的列表请求。
  Future<void> _drain_message_list_requests({
    required _MessageBucket bucket,
    required int? requested_type,
    required int page,
    required bool is_refresh,
  }) async {
    int next_page = page;
    bool next_is_refresh = is_refresh;
    bucket.is_loading.value = true;

    try {
      do {
        bucket.refresh_pending = false;
        await _fetch_message_list_once(
          bucket: bucket,
          requested_type: requested_type,
          page: next_page,
          is_refresh: next_is_refresh,
        );
        next_page = 1;
        next_is_refresh = bucket.refresh_pending;
      } while (next_is_refresh);
    } finally {
      bucket.is_loading.value = false;
    }
  }

  /// 执行某个筛选桶的一轮列表请求。
  Future<void> _fetch_message_list_once({
    required _MessageBucket bucket,
    required int? requested_type,
    required int page,
    required bool is_refresh,
  }) async {
    final UserInformation user_information = Get.find<UserInformation>();
    if (!user_information.isLoggedIn.value) return;
    final int request_revision = user_information.auth_revision;
    final int unread_revision = _unread_state_revision;
    final int mutation_revision = _local_unread_mutation_revision;
    final int data_revision = bucket.data_revision;
    bucket.request_data_revision = data_revision;
    bucket.request_auth_revision = request_revision;
    bucket.request_mutation_revision = mutation_revision;
    bucket.request_is_refresh = is_refresh;

    try {
      final MessageListResult? result = await _fetch_message_list(
        page: page,
        page_size: 20,
        type: requested_type,
      );

      if (result == null || data_revision != bucket.data_revision) return;
      if (!user_information.can_apply_authenticated_response(
        request_revision,
      )) {
        return;
      }
      if (_is_marking_all_read ||
          mutation_revision != _local_unread_mutation_revision) {
        return;
      }

      final bool can_apply_unread = unread_revision == _unread_state_revision;
      final MessageData? current_chat_message = requested_type == null
          ? _latest_chat_summary(bucket)
          : null;
      if (can_apply_unread) {
        chat_unread.value = result.chat_unread;
      }

      bucket.list.value = merge_unique_message_list(
        current_messages: is_refresh ? const <MessageData>[] : bucket.list,
        incoming_messages: result.list,
      );
      bucket.current_page = page;

      // TODO 仅全部桶展示客服摘要；实时状态已更新时保留较新的本地摘要。
      if (requested_type == null) {
        final List<MessageData> filtered = bucket.list
            .where(
              (MessageData message) => message.type != MessageType.chat_reply,
            )
            .toList(growable: false);
        final MessageData? chat_message = can_apply_unread
            ? result.chat_message
            : current_chat_message;
        bucket.list.value = chat_message == null
            ? filtered
            : merge_unique_message_list(
                current_messages: <MessageData>[chat_message],
                incoming_messages: filtered,
              );
        if (chat_message != null) {
          _remember_loaded_chat_summary(chat_message);
        }
      }

      if (can_apply_unread) {
        _recompute_unread_total();
      }
      bucket.has_more = result.list.length >= 20;
      bucket.has_loaded = true;
    } catch (error) {
      debugPrint('MessageStore fetch_message_list failed: $error');
    }
  }

  /// 加载更多（当前桶翻页）。
  Future<void> load_more() async {
    final bucket = _active_bucket;
    if (bucket.request != null || !bucket.has_more) return;
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
        bucket.list[index] = old.copy_with(notify_status: NotifyStatus.read);
        bucket.list.refresh();
      }
    }

    if (unread_message != null) {
      _local_unread_mutation_revision++;
      _unread_state_revision++;
      _update_type_unread(unread_message.type, -1);
      _recompute_unread_total();
    }
  }

  /// 立即在本地标记所有消息为已读，并与服务端权威状态完成一次校准。
  Future<void> mark_all_as_read() async {
    if (_is_marking_all_read) return;
    _is_marking_all_read = true;
    _unread_reconcile_pending = false;
    _list_refresh_pending = false;
    _local_unread_mutation_revision++;
    final int operation_revision = _local_unread_mutation_revision;
    _unread_state_revision++;

    for (final bucket in _buckets.values) {
      bucket.list.value = bucket.list
          .where((m) => m.type != MessageType.chat_reply)
          .map((m) {
            if (m.is_unread) {
              return m.copy_with(notify_status: NotifyStatus.read);
            }
            return m;
          })
          .toList();
    }

    chat_unread.value = 0;
    comment_unread.value = 0;
    like_unread.value = 0;
    favorite_unread.value = 0;
    system_unread.value = 0;
    _recompute_unread_total();

    bool should_recover = false;
    bool needs_authoritative_fetch = false;
    try {
      final message_api.MessageReadAllResult result =
          await _read_all_messages();
      if (operation_revision != _local_unread_mutation_revision) return;
      if (!result.success) {
        debugPrint('TODO MessageStore mark_all_as_read sync failed');
        should_recover = true;
      } else if (result.unread_count != null) {
        if (result.state_version > _latest_server_state_version) {
          _latest_server_state_version = result.state_version;
        }
        _apply_unread_count(result.unread_count!);
      } else {
        // TODO 兼容尚未返回权威快照的旧版后端。
        needs_authoritative_fetch = true;
      }
    } catch (e) {
      debugPrint('TODO MessageStore mark_all_as_read sync error: $e');
      should_recover = true;
    } finally {
      _is_marking_all_read = false;
    }

    if (should_recover) {
      await _recover_after_mutation_failure();
      return;
    }

    if (_list_refresh_pending) {
      _list_refresh_pending = false;
      _unread_reconcile_pending = false;
      await silent_refresh();
    } else if (_unread_reconcile_pending || needs_authoritative_fetch) {
      _unread_reconcile_pending = false;
      await fetch_statistics();
    }
  }

  /// 标记所有客服消息为已读，并拉取最新未读数据同步本地状态。
  Future<void> _sync_chat_messages_read() async {
    try {
      await message_api.read_all_chat_messages();
      await fetch_statistics();
    } catch (e) {
      debugPrint('TODO MessageStore _sync_chat_messages_read error: $e');
    }
  }

  /// 删除单条消息（从所有桶中移除）。
  ///
  /// 客服消息：从列表移除 + 标记所有客服消息为已读（不删除数据）。
  /// 其他消息：从列表移除 + 调用删除 API。
  Future<void> delete_message(int message_id) async {
    // 先从列表移除，确保 Dismissible 在同一帧内从树中消失。
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

    if (deleted_message == null) return;

    // 客服消息：移除栏目 + 标记全部已读，不删除数据
    if (deleted_message.type == MessageType.chat_reply) {
      for (final bucket in _buckets.values) {
        bucket.list.value = bucket.list
            .where((m) => m.type != MessageType.chat_reply)
            .toList();
      }
      chat_unread.value = 0;
      _recompute_unread_total();
      unawaited(_sync_chat_messages_read());
      return;
    }

    // 其他消息：更新未读数 + 调用删除 API
    if (deleted_message.is_unread) {
      _local_unread_mutation_revision++;
      _unread_state_revision++;
      _update_type_unread(deleted_message.type, -1);
      _recompute_unread_total();
    }
    final bool success = await message_api.delete_message(id: message_id);
    if (!success) {
      debugPrint(
        'TODO MessageStore delete_message API failed for id: $message_id',
      );
      await _recover_after_mutation_failure();
    }
  }

  /// 乐观更新失败后，使未读统计和当前可见列表恢复到数据库权威状态。
  Future<void> _recover_after_mutation_failure() async {
    for (final bucket in _buckets.values) {
      bucket.has_loaded = false;
    }
    await Future.wait(<Future<void>>[
      fetch_statistics(),
      fetch_message_list(page: 1, is_refresh: true, silent: true),
    ]);
  }

  /// 更新在线客服未读数。
  void update_chat_unread(int count) {
    _local_unread_mutation_revision++;
    _unread_state_revision++;
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
    final UserInformation user_information = Get.find<UserInformation>();
    final int request_revision = user_information.auth_revision;
    if (!user_information.can_apply_visitor_response(request_revision)) {
      return;
    }

    comment_unread.value = 0;
    comment_total.value = 0;
    like_unread.value = 0;
    like_total.value = 0;
    favorite_unread.value = 0;
    favorite_total.value = 0;
    system_unread.value = 0;
    for (final bucket in _buckets.values) {
      bucket.list.clear();
    }

    final String? visitor_id = await StorageUtil.getData('visitor_uuid');
    if (!user_information.can_apply_visitor_response(request_revision)) {
      return;
    }
    if (visitor_id == null || visitor_id.isEmpty) {
      chat_unread.value = 0;
      _recompute_unread_total(force_badge_sync: true);
      return;
    }

    final int unread = await message_api.get_visitor_chat_unread(
      visitor_id: visitor_id,
    );
    if (!user_information.can_apply_visitor_response(request_revision)) {
      return;
    }
    chat_unread.value = unread;
    _recompute_unread_total(force_badge_sync: true);
  }

  /// 清空所有数据（登出时调用）。
  void clear() {
    _local_unread_mutation_revision++;
    _unread_state_revision++;
    _latest_statistics_request++;
    _statistics_refresh_pending = false;
    _is_marking_all_read = false;
    _unread_reconcile_pending = false;
    _list_refresh_pending = false;
    for (final bucket in _buckets.values) {
      bucket.data_revision++;
      bucket.list.clear();
      bucket.has_loaded = false;
      bucket.has_more = true;
      bucket.refresh_pending = false;
      bucket.current_page = 1;
      bucket.is_loading.value = false;
    }
    _active_type.value = null;
    unread_total.value = 0;
    chat_unread.value = 0;
    system_unread.value = 0;
    comment_unread.value = 0;
    comment_total.value = 0;
    like_unread.value = 0;
    like_total.value = 0;
    favorite_unread.value = 0;
    favorite_total.value = 0;
    _processed_message_ids.clear();
    _processed_chat_message_ids.clear();
    _latest_chat_message_id = 0;
    _latest_server_state_version = 0;
    _recompute_unread_total(force_badge_sync: true);
  }

  // ==================== 内部方法 ====================

  /// 应用后端返回的权威未读统计。
  void _apply_unread_count(MessageUnreadCount result) {
    comment_unread.value = result.comment_unread;
    comment_total.value = result.comment_total;
    like_unread.value = result.like_unread;
    like_total.value = result.like_total;
    favorite_unread.value = result.favorite_unread;
    favorite_total.value = result.favorite_total;
    chat_unread.value = result.chat_unread;
    system_unread.value = result.system_unread;
    _recompute_unread_total(force_badge_sync: true);
  }

  /// 获取消息桶中现有的客服摘要。
  MessageData? _latest_chat_summary(_MessageBucket bucket) {
    for (final MessageData message in bucket.list) {
      if (message.type == MessageType.chat_reply) return message;
    }
    return null;
  }

  /// 记录接口加载到的客服摘要，防止稍后到达的重复实时事件再次处理。
  void _remember_loaded_chat_summary(MessageData message) {
    if (message.id <= 0) return;
    if (message.id > _latest_chat_message_id) {
      _latest_chat_message_id = message.id;
    }
    _remember_chat_message(message.id);
  }

  /// 重新计算未读总数并更新角标。
  void _recompute_unread_total({bool force_badge_sync = false}) {
    final int new_total =
        comment_unread.value +
        like_unread.value +
        favorite_unread.value +
        system_unread.value +
        chat_unread.value;
    if (!force_badge_sync && new_total == unread_total.value) return;
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
    } else if (type == MessageType.system) {
      system_unread.value = (system_unread.value + delta).clamp(0, 9999);
    }
  }

  /// 从 WebSocket 数据更新未读数。
  void _update_unread_from_ws(Map<String, dynamic> data) {
    final int comment = _parse_int(data['comment_unread']);
    final int like = _parse_int(data['like_unread']);
    final int favorite = _parse_int(data['favorite_unread']);
    final int chat = data.containsKey('chat_unread')
        ? _parse_int(data['chat_unread'])
        : chat_unread.value;

    comment_unread.value = comment;
    comment_total.value = _parse_int(data['comment_total']);
    like_unread.value = like;
    like_total.value = _parse_int(data['like_total']);
    favorite_unread.value = favorite;
    favorite_total.value = _parse_int(data['favorite_total']);
    if (data.containsKey('chat_unread')) {
      chat_unread.value = chat;
    }

    if (data.containsKey('system_unread')) {
      system_unread.value = _parse_int(data['system_unread']);
    } else if (data.containsKey('total')) {
      final int known_unread = comment + like + favorite + chat;
      system_unread.value = (_parse_int(data['total']) - known_unread).clamp(
        0,
        9999,
      );
    }
    _recompute_unread_total(force_badge_sync: true);
  }

  /// 全部已读同步期间只记录刷新需求，不允许旧实时快照恢复角标。
  bool _defer_realtime_unread_update() {
    if (!_is_marking_all_read) return false;
    _unread_reconcile_pending = true;
    return true;
  }

  /// 应用实时权威快照，并使更早发出的 HTTP 请求失效。
  void _apply_realtime_unread(Map<String, dynamic> data) {
    if (_defer_realtime_unread_update()) return;
    _update_unread_from_ws(data);
    _unread_state_revision++;
  }

  /// 监听 WebSocket 推送。
  void _listen_websocket() {
    final ws = WebSocketService();
    _ws_subscription = ws.message_stream.listen(handle_websocket_event);
  }

  /// 处理 WebSocket 推送，并同步消息列表与全局未读角标。
  ///
  /// 公开该入口便于对实时推送协议编写无网络依赖的回归测试。
  void handle_websocket_event(Map<String, dynamic> data) {
    final String type = data['type']?.toString() ?? '';
    final dynamic payload = data['data'];
    bool suppress_unread_update = false;
    if (payload is Map) {
      final int state_version = _parse_int(payload['state_version']);
      if (state_version > 0) {
        final bool is_reconnect_snapshot = type == 'unread_count';
        if (state_version < _latest_server_state_version ||
            (state_version == _latest_server_state_version &&
                !is_reconnect_snapshot)) {
          // TODO 旧消息事件仍可补入列表，但绝不能覆盖更新版本的未读状态。
          if (type == 'new_message' ||
              type == 'chat_receive' ||
              type == 'chat_message') {
            suppress_unread_update = true;
          } else {
            return;
          }
        } else {
          _latest_server_state_version = state_version;
        }
      }
    }

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
          final dynamic message_data = payload_map['message'];
          if (message_data is Map) {
            final Map<String, dynamic> msg = Map<String, dynamic>.from(
              message_data,
            );
            MessageData new_message = MessageData.from_json(msg);
            if (suppress_unread_update) {
              new_message = _message_with_current_unread_status(new_message);
            }
            final bool is_new_event = _remember_message(new_message.id);
            final bool is_cached = _is_message_cached(new_message);

            // TODO 权威快照已经包含当前消息，存在快照时绝不能再次本地加一。
            if (suppress_unread_update) {
              // TODO 更高版本的状态已经生效，此事件只用于补齐列表内容。
            } else if (unread_data != null) {
              _apply_realtime_unread(unread_data);
            } else if (is_new_event &&
                !is_cached &&
                new_message.is_unread &&
                !_defer_realtime_unread_update()) {
              _update_type_unread(new_message.type, 1);
              _recompute_unread_total();
              _unread_state_revision++;
            }

            _insert_message_to_buckets(new_message);
          } else if (unread_data != null) {
            _apply_realtime_unread(unread_data);
          }
        }
        break;

      case 'unread_count':
        if (payload is Map) {
          _apply_realtime_unread(Map<String, dynamic>.from(payload));
        }
        break;

      case 'chat_unread':
        if (payload is Map) {
          if (_defer_realtime_unread_update()) break;
          final Map<String, dynamic> chat_data = Map<String, dynamic>.from(
            payload,
          );
          final int unread = _parse_int(chat_data['unread']);
          chat_unread.value = unread;
          _recompute_unread_total();
          _unread_state_revision++;
        }
        break;

      case 'message_state_changed':
        if (payload is Map) {
          _handle_message_state_changed(Map<String, dynamic>.from(payload));
        }
        break;

      case 'chat_receive':
        _handle_received_chat_message(
          payload,
          suppress_unread_update: suppress_unread_update,
        );
        break;

      case 'chat_message':
        if (payload is Map) {
          final Map<String, dynamic> chat_data = Map<String, dynamic>.from(
            payload,
          );
          final dynamic message_data = chat_data['message'];
          if (message_data is Map &&
              (!suppress_unread_update || chat_unread.value > 0)) {
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
          if (suppress_unread_update) break;
          if (_defer_realtime_unread_update()) break;
          final int unread = _parse_int(chat_data['unread']);
          chat_unread.value = unread;
          _recompute_unread_total();
          _unread_state_revision++;
        }
        break;

      default:
        break;
    }
  }

  /// 处理管理员实时回复并立即更新客服角标。
  void _handle_received_chat_message(
    dynamic payload, {
    bool suppress_unread_update = false,
  }) {
    if (payload is! Map) return;
    final Map<String, dynamic> chat_data = Map<String, dynamic>.from(payload);
    if (_parse_int(chat_data['sender_type']) != 2) return;

    final int message_id = _parse_int(chat_data['id']);
    if (message_id > 0 && !_remember_chat_message(message_id)) return;
    final bool is_latest_message =
        message_id <= 0 || message_id >= _latest_chat_message_id;
    if (message_id > _latest_chat_message_id) {
      _latest_chat_message_id = message_id;
    }

    if (is_latest_message &&
        (!suppress_unread_update || chat_unread.value > 0)) {
      _upsert_chat_summary(chat_data);
    }
    if (suppress_unread_update) return;
    if (_defer_realtime_unread_update()) return;

    if (chat_data.containsKey('unread')) {
      _apply_authoritative_chat_unread(
        _parse_int(chat_data['unread']),
        is_latest_message: is_latest_message,
      );
    } else if (chat_data.containsKey('chat_unread')) {
      _apply_authoritative_chat_unread(
        _parse_int(chat_data['chat_unread']),
        is_latest_message: is_latest_message,
      );
    } else {
      chat_unread.value = (chat_unread.value + 1).clamp(0, 9999);
    }
    _recompute_unread_total();
    _unread_state_revision++;
  }

  /// 将管理员最新回复实时写入“全部消息”桶的客服摘要。
  void _upsert_chat_summary(Map<String, dynamic> chat_data) {
    final int message_id = _parse_int(chat_data['id']);
    if (message_id <= 0) return;

    final String content = chat_data['content']?.toString() ?? '';
    final MessageData summary = MessageData(
      id: message_id,
      user_id: 0,
      title: '',
      introduction: content,
      content: content,
      type: MessageType.chat_reply,
      send_user: _parse_int(chat_data['sender_id']),
      send_time:
          chat_data['create_time']?.toString() ??
          chat_data['send_time']?.toString() ??
          '',
      notify_status: NotifyStatus.unread,
      sender_name: chat_data['sender_name']?.toString() ?? '客服',
      sender_avatar: chat_data['sender_avatar']?.toString() ?? '',
    );
    final _MessageBucket all_bucket = _buckets[null]!;
    final List<MessageData> without_chat = all_bucket.list
        .where((message) => message.type != MessageType.chat_reply)
        .toList();
    all_bucket.list.value = <MessageData>[summary, ...without_chat];
  }

  /// 旧版本实时消息仅根据当前权威分类未读数决定卡片的已读样式。
  MessageData _message_with_current_unread_status(MessageData message) {
    final int type_unread = switch (message.type) {
      MessageType.comment_reply => comment_unread.value,
      MessageType.comment_like || MessageType.novel_like => like_unread.value,
      MessageType.novel_favorite => favorite_unread.value,
      MessageType.system => system_unread.value,
      _ => 0,
    };
    return message.copy_with(
      notify_status: type_unread > 0 ? NotifyStatus.unread : NotifyStatus.read,
    );
  }

  /// 应用后端权威未读数，乱序旧事件只允许抬高而不能降低当前值。
  void _apply_authoritative_chat_unread(
    int unread, {
    required bool is_latest_message,
  }) {
    if (is_latest_message || unread > chat_unread.value) {
      chat_unread.value = unread;
    }
  }

  /// 记录已处理的客服消息，并限制集合大小避免长期运行时无限增长。
  bool _remember_chat_message(int message_id) {
    if (!_processed_chat_message_ids.add(message_id)) return false;
    if (_processed_chat_message_ids.length > _processed_chat_message_limit) {
      _processed_chat_message_ids.remove(_processed_chat_message_ids.first);
    }
    return true;
  }

  /// 记录普通消息事件，并限制集合大小。
  bool _remember_message(int message_id) {
    if (message_id <= 0) return true;
    if (!_processed_message_ids.add(message_id)) return false;
    if (_processed_message_ids.length > _processed_message_limit) {
      _processed_message_ids.remove(_processed_message_ids.first);
    }
    return true;
  }

  /// 判断普通消息是否已存在于任意缓存桶。
  bool _is_message_cached(MessageData message) {
    return _buckets.values.any(
      (bucket) => bucket.list.any(
        (cached) => cached.identity_key == message.identity_key,
      ),
    );
  }

  /// 应用其他设备产生的已读或删除状态，并使用权威快照更新全部角标。
  void _handle_message_state_changed(Map<String, dynamic> payload) {
    final String action = payload['action']?.toString() ?? '';
    final int message_id = _parse_int(payload['message_id']);

    if (action == 'read' && message_id > 0) {
      _mark_cached_message_as_read(message_id);
    } else if (action == 'delete' && message_id > 0) {
      _remove_cached_message(message_id);
    } else if (action == 'read_all') {
      _mark_all_cached_messages_as_read();
      _remove_cached_chat_message();
    } else if (action == 'chat_read') {
      _remove_cached_chat_message();
    }

    final dynamic unread_data = payload['unread_count'];
    if (unread_data is Map) {
      _apply_realtime_unread(Map<String, dynamic>.from(unread_data));
      return;
    }

    // TODO 兼容快照查询临时失败的后端事件，主动补拉避免跨设备状态长期不一致。
    if (_defer_realtime_unread_update()) return;
    unawaited(fetch_statistics());
  }

  /// 将缓存中的指定普通消息标记为已读。
  void _mark_cached_message_as_read(int message_id) {
    for (final bucket in _buckets.values) {
      final int index = bucket.list.indexWhere(
        (message) =>
            message.type != MessageType.chat_reply && message.id == message_id,
      );
      if (index < 0 || !bucket.list[index].is_unread) continue;
      bucket.list[index] = bucket.list[index].copy_with(
        notify_status: NotifyStatus.read,
      );
      bucket.list.refresh();
    }
  }

  /// 从所有缓存桶移除指定普通消息。
  void _remove_cached_message(int message_id) {
    for (final bucket in _buckets.values) {
      bucket.list.value = bucket.list
          .where(
            (message) =>
                message.type == MessageType.chat_reply ||
                message.id != message_id,
          )
          .toList();
    }
  }

  /// 将所有缓存普通消息标记为已读。
  void _mark_all_cached_messages_as_read() {
    for (final bucket in _buckets.values) {
      bucket.list.value = bucket.list
          .map(
            (message) =>
                message.type != MessageType.chat_reply && message.is_unread
                ? message.copy_with(notify_status: NotifyStatus.read)
                : message,
          )
          .toList();
    }
  }

  /// 从消息中心缓存移除客服摘要。
  void _remove_cached_chat_message() {
    for (final bucket in _buckets.values) {
      bucket.list.value = bucket.list
          .where((message) => message.type != MessageType.chat_reply)
          .toList();
    }
  }

  /// FCM 前台推送兜底：WebSocket 短暂断开时也能恢复页面及 App 图标角标。
  void handle_foreground_notification(Map<String, dynamic> data) {
    _foreground_refresh_timer?.cancel();
    _foreground_refresh_timer = Timer(const Duration(milliseconds: 300), () {
      if (!Get.isRegistered<UserInformation>()) return;
      final UserInformation user_information = Get.find<UserInformation>();
      if (user_information.isLoggedIn.value) {
        // TODO FCM 可能是客服消息唯一可达信号，同时刷新角标与当前消息列表摘要。
        if (data['biz_type']?.toString() == 'customer_service') {
          _buckets[null]!.has_loaded = false;
        }
        unawaited(silent_refresh());
      } else {
        unawaited(fetch_visitor_chat_unread());
      }
    });
  }

  /// 将新消息插入到匹配的桶中（自动去重，原子替换）。
  void _insert_message_to_buckets(MessageData message) {
    for (final entry in _buckets.entries) {
      final int? bucket_type = entry.key;
      final _MessageBucket bucket = entry.value;

      // 客服消息与普通消息可能共用数字 ID，必须按稳定身份去重。
      if (bucket.list.any(
        (MessageData cached) => cached.identity_key == message.identity_key,
      )) {
        continue;
      }

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
    _foreground_refresh_timer?.cancel();
    if (_foreground_callback_registered) {
      FcmService().on_foreground_data = null;
      _foreground_callback_registered = false;
    }
    super.onClose();
  }
}
