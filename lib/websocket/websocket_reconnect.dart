import 'dart:async';
import 'package:app/util/log_util.dart';

/// WebSocket 自动重连管理。
///
/// 负责断开连接后自动重连，支持指数退避策略。
class WebSocketReconnect {
  /// 重连定时器。
  Timer? _timer;

  /// 重连次数。
  int _count = 0;

  /// 最大重连次数。
  static const int _max_count = 20;

  /// 重连间隔（毫秒），会指数退避。
  int _interval_ms = 2000;

  /// 执行重连的回调函数。
  final void Function() onReconnect;

  WebSocketReconnect({required this.onReconnect});

  /// 安排重连。
  ///
  /// 超过最大重连次数后不再重连。
  /// 后台时不重连，等回到前台再连。
  void schedule({required bool isForeground}) {
    if (_count >= _max_count) {
      logUtil(msg: 'WebSocket 重连次数已达上限', type: 'w');
      return;
    }
    if (!isForeground) {
      logUtil(msg: 'WebSocket 后台不重连，等回到前台再连');
      return;
    }

    cancel();

    final delay = Duration(milliseconds: _interval_ms);
    _timer = Timer(delay, () {
      _count++;
      _interval_ms = (_interval_ms * 1.5).toInt().clamp(2000, 30000);
      logUtil(msg: 'WebSocket 第 $_count 次重连...');
      onReconnect();
    });
  }

  /// 取消重连定时器。
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// 重置重连状态（连接成功后调用）。
  void reset() {
    _count = 0;
    _interval_ms = 2000;
  }

  /// 是否正在等待重连。
  bool get isWaiting => _timer != null;
}
