import 'dart:async';
import 'package:app/util/log_util.dart';

/// WebSocket 心跳检测管理。
///
/// 负责定时发送心跳包保持连接活跃，支持前后台切换时自动暂停/恢复。
class WebSocketHeartbeat {
  /// 心跳定时器。
  Timer? _timer;

  /// 心跳间隔（毫秒）。
  static const int _interval_ms = 25000;

  /// 发送心跳的回调函数。
  final void Function() onPing;

  WebSocketHeartbeat({required this.onPing});

  /// 启动心跳定时器。
  void start() {
    stop();
    _timer = Timer.periodic(
      const Duration(milliseconds: _interval_ms),
      (_) {
        logUtil(msg: 'WebSocket 心跳 ping');
        onPing();
      },
    );
  }

  /// 停止心跳定时器。
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// 是否正在运行。
  bool get isRunning => _timer != null;
}
