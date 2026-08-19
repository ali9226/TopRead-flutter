// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'package:get/get.dart';
import 'package:app/models/message_data.dart';
import 'package:app/fcm/fcm_service.dart';

/// 消息未读计数管理器。
///
/// 集中管理各类型未读数（评论、点赞、收藏、客服、系统）和总角标，
/// 提供增量更新、权威快照应用和角标防抖同步。
class MessageUnreadCounter {
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

  /// 应用后端返回的权威未读统计。
  void apply_authoritative({
    required int comment_unread,
    required int comment_total,
    required int like_unread,
    required int like_total,
    required int favorite_unread,
    required int favorite_total,
    required int chat_unread,
    required int system_unread,
  }) {
    this.comment_unread.value = comment_unread;
    this.comment_total.value = comment_total;
    this.like_unread.value = like_unread;
    this.like_total.value = like_total;
    this.favorite_unread.value = favorite_unread;
    this.favorite_total.value = favorite_total;
    this.chat_unread.value = chat_unread;
    this.system_unread.value = system_unread;
    recompute_total(force_badge_sync: true);
  }

  /// 按消息类型增量更新未读数。
  ///
  /// [delta] 通常为 +1（新消息到达）或 -1（标记已读）。
  void update_by_type(int type, int delta) {
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

  /// 从 WebSocket 数据更新各类型未读数。
  void update_from_ws(Map<String, dynamic> data) {
    comment_unread.value = _parse_int(data['comment_unread']);
    comment_total.value = _parse_int(data['comment_total']);
    like_unread.value = _parse_int(data['like_unread']);
    like_total.value = _parse_int(data['like_total']);
    favorite_unread.value = _parse_int(data['favorite_unread']);
    favorite_total.value = _parse_int(data['favorite_total']);

    if (data.containsKey('chat_unread')) {
      chat_unread.value = _parse_int(data['chat_unread']);
    }

    if (data.containsKey('system_unread')) {
      system_unread.value = _parse_int(data['system_unread']);
    } else if (data.containsKey('total')) {
      final int known = comment_unread.value +
          like_unread.value +
          favorite_unread.value +
          chat_unread.value;
      system_unread.value = (_parse_int(data['total']) - known).clamp(0, 9999);
    }
    recompute_total(force_badge_sync: true);
  }

  /// 重新计算未读总数并更新角标。
  void recompute_total({bool force_badge_sync = false}) {
    final int new_total = comment_unread.value +
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

  /// 清零所有未读计数（登出时调用）。
  void clear() {
    unread_total.value = 0;
    chat_unread.value = 0;
    system_unread.value = 0;
    comment_unread.value = 0;
    comment_total.value = 0;
    like_unread.value = 0;
    like_total.value = 0;
    favorite_unread.value = 0;
    favorite_total.value = 0;
    recompute_total(force_badge_sync: true);
  }

  /// 释放定时器资源。
  void dispose() {
    _badge_update_timer?.cancel();
  }

  static int _parse_int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}
