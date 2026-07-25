import 'package:app/websocket/websocket_service.dart';
import 'package:app/util/log_util.dart';

/// WebSocket 认证切换处理。
///
/// 负责处理用户登录/登出时的 WebSocket 连接切换：
/// 1. 登录成功：通知后端旧 UUID 会话失效，断开旧连接，用新 token 重新连接。
/// 2. 登出：断开连接，以访客身份重新连接。
class WebSocketAuth {
  /// 登录成功后切换 WebSocket 连接。
  ///
  /// 流程：
  /// 1. 如果当前是访客模式，通知后端旧 UUID 会话即将失效。
  /// 2. 断开当前连接。
  /// 3. 用新 token 重新连接（后端解密 token 获取用户 id）。
  static Future<void> onLoginSuccess() async {
    final ws = WebSocketService();

    // 如果当前是访客模式，通知后端旧 UUID 会话即将失效。
    if (ws.is_visitor && ws.is_connected) {
      logUtil(msg: 'WebSocket 登录切换：通知后端旧访客会话失效');
      ws.send({
        'type': 'visitor_logout',
        'data': {'reason': 'user_login'},
      });
    }

    // 断开当前连接。
    ws.disconnect();

    // 用新 token 重新连接。
    logUtil(msg: 'WebSocket 登录切换：以用户身份重新连接');
    await ws.connect();
  }

  /// 登出后切换 WebSocket 连接。
  ///
  /// 流程：
  /// 1. 断开当前连接。
  /// 2. 以访客身份重新连接（内部会自动生成新的 UUID）。
  static Future<void> onLogout() async {
    final ws = WebSocketService();

    logUtil(msg: 'WebSocket 登出切换：断开当前连接');
    ws.disconnect();

    logUtil(msg: 'WebSocket 登出切换：以访客身份重新连接');
    await ws.connect();
  }
}
