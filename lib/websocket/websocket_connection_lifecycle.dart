// ignore_for_file: non_constant_identifier_names

/// WebSocket 连接代次管理器。
///
/// 每次开始连接都会获得唯一代次。连接被替换或主动断开后，旧连接迟到的
/// onDone/onError 回调无法再结束当前连接，也不会误触发自动重连。
class WebSocketConnectionLifecycle {
  /// 最近分配的连接代次。
  int _last_connection_id = 0;

  /// 当前有效连接代次。
  int? _active_connection_id;

  /// 开始一个新连接并返回它的唯一代次。
  int begin() {
    final int connection_id = ++_last_connection_id;
    _active_connection_id = connection_id;
    return connection_id;
  }

  /// 判断指定连接是否仍是当前有效连接。
  bool is_active(int connection_id) {
    return _active_connection_id == connection_id;
  }

  /// 结束指定连接。
  ///
  /// 仅当前有效连接可以结束成功。旧连接的迟到回调会返回 false。
  bool finish(int connection_id) {
    if (!is_active(connection_id)) {
      return false;
    }
    _active_connection_id = null;
    return true;
  }

  /// 主动作废当前连接。
  void invalidate() {
    _active_connection_id = null;
  }
}
