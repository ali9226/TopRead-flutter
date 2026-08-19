/*
  TODO websocket配置
 */
class WebsocketConfig {
  // TODO websocket 请求地址。
  // TODO 浏览器端本地调试时走 0.0.0.0，其他端继续走局域网地址。
  static String get requestUrl {
    // if (kIsWeb && kDebugMode) {
    //   return "ws://192.168.31.120:5008";
    // }
    // TODO 生产环境地址，需要根据实际部署修改
    // return "wss://websocket.read.top";
    return "ws://192.168.31.120:5008";
  }
}
