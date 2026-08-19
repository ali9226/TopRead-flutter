// ignore_for_file: non_constant_identifier_names

/// 消息去重器。
///
/// 使用有界集合记录已处理的消息 ID，防止 WebSocket 重连、
/// Redis 重试或重复推送造成角标重复累加。
class MessageDeduplicator {
  /// 已处理的客服消息 ID。
  final Set<int> _chat_ids = <int>{};

  /// 已处理的普通消息 ID。
  final Set<int> _message_ids = <int>{};

  /// 客服消息去重窗口大小。
  static const int _chat_limit = 200;

  /// 普通消息去重窗口大小。
  static const int _message_limit = 500;

  /// 记录已处理的客服消息，返回 false 表示重复。
  bool remember_chat(int id) {
    if (!_chat_ids.add(id)) return false;
    if (_chat_ids.length > _chat_limit) {
      _chat_ids.remove(_chat_ids.first);
    }
    return true;
  }

  /// 记录已处理的普通消息，返回 false 表示重复。
  ///
  /// ID <= 0 时视为新消息（如本地生成的临时消息）。
  bool remember(int id) {
    if (id <= 0) return true;
    if (!_message_ids.add(id)) return false;
    if (_message_ids.length > _message_limit) {
      _message_ids.remove(_message_ids.first);
    }
    return true;
  }

  /// 清空所有去重记录（登出时调用）。
  void clear() {
    _chat_ids.clear();
    _message_ids.clear();
  }
}
