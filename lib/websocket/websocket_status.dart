/// WebSocket 连接状态。
enum WebSocketStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// WebSocket 消息类型。
class WebSocketMessageType {
  static const String connected = 'connected';
  static const String pong = 'pong';
  static const String new_message = 'new_message';
  static const String unread_count = 'unread_count';
  static const String chat_receive = 'chat_receive';
  static const String chat_send_success = 'chat_send_success';
  static const String chat_session_list = 'chat_session_list';
  static const String chat_history = 'chat_history';
  static const String chat_init_session = 'chat_init_session';
}
