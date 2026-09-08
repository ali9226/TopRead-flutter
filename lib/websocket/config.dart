/// WebSocket 连接配置。
class WebsocketConfig {
  /// WebSocket 请求地址。
  ///
  /// 本地调试时使用 `ws://192.168.31.120:5008`，发布前需切换为正式地址。
  static String get requestUrl {
    // 本地调试地址
    return "ws://192.168.31.120:5008";
    // 正式地址（发布前取消注释上面一行，注释此行）
    // return "wss://websocket.read.top";
  }
}
