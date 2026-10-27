import 'dart:async';

import 'package:app/api/bookshelf.dart';
import 'package:app/config/constant.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:flutter/widgets.dart';

import 'tracker.dart';

export 'tracker.dart';

typedef ReadingIdentity = ({int user_id, int novel_id});
typedef ReadingHeartbeatSender =
    Future<bool> Function(ReadingHeartbeat heartbeat);

/// 两种正文共用的前台阅读时长上报，不依赖滚动百分比，也不修改续读位置。
class ReadingEngagementController with WidgetsBindingObserver {
  ReadingEngagementController({
    required this.identity,
    required this.is_body_visible,
    ReadingHeartbeatSender? sender,
    int Function()? monotonic_ms,
    bool schedule_timer = true,
  }) : _sender = sender ?? _send_heartbeat,
       _monotonic_ms =
           monotonic_ms ?? (Stopwatch()..start()).elapsedMillisecondsGetter {
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    if (schedule_timer) {
      _timer = Timer.periodic(
        const Duration(milliseconds: 250),
        (_) => sample(),
      );
    }
  }

  final ReadingIdentity? Function() identity;
  final bool Function() is_body_visible;
  final ReadingHeartbeatSender _sender;
  final int Function() _monotonic_ms;
  final Map<String, ReadingHeartbeat> _pending = {};
  final Map<String, int> _acknowledged = {};
  Timer? _timer;
  ReadingEngagementTracker? _tracker;
  bool _foreground = true;
  bool _draining = false;
  bool _disposed = false;
  int _last_flush_ms = 0;
  bool _last_active = false;

  static Future<bool> _send_heartbeat(ReadingHeartbeat heartbeat) async {
    // getData 在调用时同步读取内存值，再返回 Future。必须在首个 await 前捕获本次身份，
    // 不能让 postRequest 的异步语种准备随后读到另一个账号的凭证。
    final token_future = StorageUtil.getData(Constant.tokenKey);
    final token = await token_future;
    if (token == null || token.isEmpty) return false;
    return save_read_progress(
      novel_id: heartbeat.novel_id,
      reading_session_id: heartbeat.session_id,
      reading_seconds: heartbeat.seconds,
      reading_only: true,
      authorization_token: token,
    );
  }

  /// 页面可在布局/切篇边界立即采样，周期采样补充未触发重建的路由遮挡变化。
  void sample({bool force_pause = false}) {
    if (_disposed) return;
    final now = _monotonic_ms();
    final current = identity();
    final previous = _tracker;
    if (previous != null &&
        (current?.user_id != previous.user_id ||
            current?.novel_id != previous.novel_id)) {
      previous.sample(active: false, monotonic_ms: now);
      // 账号已切换时禁止旧身份请求进入新账号；同一账号切篇仍提交旧作品的最后快照。
      if (current?.user_id == previous.user_id) {
        _enqueue(previous.heartbeat);
      } else {
        _pending.clear();
      }
      _tracker = null;
      _last_active = false;
    }
    final active =
        !force_pause &&
        _foreground &&
        current != null &&
        current.user_id > 0 &&
        current.novel_id > 0 &&
        is_body_visible();
    if (_tracker == null && active) {
      _tracker = ReadingEngagementTracker(
        user_id: current.user_id,
        novel_id: current.novel_id,
      );
      _last_flush_ms = now;
    }
    final tracker = _tracker;
    if (tracker == null) return;
    final just_started = !tracker.has_started && active;
    tracker.sample(active: active, monotonic_ms: now);
    if (just_started ||
        (_last_active && !active) ||
        now - _last_flush_ms >= 10000) {
      _last_flush_ms = now;
      _enqueue(tracker.heartbeat);
    }
    _last_active = active;
  }

  void _enqueue(ReadingHeartbeat snapshot) {
    if (_acknowledged[snapshot.session_id] == snapshot.seconds) return;
    _pending[snapshot.session_id] = snapshot;
    unawaited(_drain());
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (_pending.isNotEmpty) {
        final snapshot = _pending.remove(_pending.keys.first)!;
        if (identity()?.user_id != snapshot.user_id) continue;
        var saved = false;
        try {
          saved = await _sender(snapshot);
        } catch (_) {
          /* 下次心跳重试相同累计水位。 */
        }
        if (!saved) {
          // 等待网络期间可能已切号。旧请求的失败不能重新堵住新账号的零秒基线。
          if (identity()?.user_id != snapshot.user_id) continue;
          _pending.putIfAbsent(snapshot.session_id, () => snapshot);
          break;
        }
        _acknowledged[snapshot.session_id] = snapshot.seconds;
      }
    } finally {
      _draining = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    sample(force_pause: !_foreground);
  }

  void dispose() {
    if (_disposed) return;
    sample(force_pause: true);
    final tracker = _tracker;
    if (tracker?.has_started ?? false) _enqueue(tracker!.heartbeat);
    _disposed = true;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}

extension on Stopwatch {
  int elapsedMillisecondsGetter() => elapsedMilliseconds;
}
