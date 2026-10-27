import 'package:uuid/uuid.dart';

/// 一次账号、作品绑定的累计时长；单调时钟避免系统时间调整和网络重试重复累计。
class ReadingEngagementTracker {
  ReadingEngagementTracker({
    required this.user_id,
    required this.novel_id,
    String? session_id,
  }) : session_id = session_id ?? const Uuid().v4();

  final int user_id;
  final int novel_id;
  final String session_id;
  int _elapsed_ms = 0;
  int? _last_sample_ms;
  bool _was_active = false;
  bool has_started = false;

  int get seconds => _elapsed_ms ~/ 1000;

  /// 只有相邻两次采样都在正文前台才计时。后台/弹窗边界宁少计一帧，不计入遮挡时间。
  /// 丢帧或系统挂起后的一次采样最多计入一秒，不能把定时器停顿当成长时间阅读。
  void sample({required bool active, required int monotonic_ms}) {
    final previous = _last_sample_ms;
    if (active && _was_active && previous != null) {
      _elapsed_ms += (monotonic_ms - previous).clamp(0, 1000);
    }
    _last_sample_ms = monotonic_ms;
    _was_active = active;
    has_started = has_started || active;
  }

  ReadingHeartbeat get heartbeat => ReadingHeartbeat(
    user_id: user_id,
    novel_id: novel_id,
    session_id: session_id,
    seconds: seconds,
  );
}

/// 队列中的不可变快照，切篇后仍只提交原作品的时长。
class ReadingHeartbeat {
  const ReadingHeartbeat({
    required this.user_id,
    required this.novel_id,
    required this.session_id,
    required this.seconds,
  });

  final int user_id;
  final int novel_id;
  final String session_id;
  final int seconds;
}
