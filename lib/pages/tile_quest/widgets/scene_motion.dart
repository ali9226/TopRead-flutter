// ignore_for_file: non_constant_identifier_names
import 'dart:math' as math;
import '../game/models.dart';
import '../style.dart';

/// Ordered presentation of an already committed rule transaction.
class QuestSceneMotion {
  QuestSceneMotion(this.result, this.queued_at, {this.preflight = false});
  final TileQuestActionResult result;
  final double queued_at;
  final bool preflight;
  double started_at = 0;
  double travel_ms = 0;
  bool match_feedback_sent = false;

  /// 本段航距对应的飞行时长；首次获知几何后锁定，预飞与落槽共用。
  double? _flight_ms;
  late final Set<int> moved_ids = result.moved_ids.toSet();
  late final Map<int, int> moved_indices = {
    for (var index = 0; index < result.moved_ids.length; index++)
      result.moved_ids[index]: index,
  };
  late final List<int> tool_ids = _ordered_tool_ids();

  /// Sorting and membership lookup are cached per transaction, not per frame.
  List<int> _ordered_tool_ids() =>
      {
        ...result.before.tray,
        ...result.before.reserve,
        ...result.after.tray,
        ...result.after.reserve,
        ...result.moved_ids,
      }.toList()..sort((a, b) {
        int rank(int id) =>
            (moved_ids.contains(id) ? 100 : 0) +
            (result.after.reserve.contains(id)
                ? result.after.reserve_depth(id)
                : -1);
        final order = rank(a).compareTo(rank(b));
        if (order != 0) return order;
        if (result.action == TileQuestAction.shuffle &&
            moved_ids.contains(a) &&
            moved_ids.contains(b)) {
          final layer_order = result.before
              .tile_by_id(a)
              .layer
              .compareTo(result.before.tile_by_id(b).layer);
          if (layer_order != 0) return layer_order;
        }
        return a.compareTo(b);
      });
  bool get inserts =>
      result.action == TileQuestAction.tap ||
      result.action == TileQuestAction.return_reserve;
  bool get matches => inserts && result.matched_ids.isNotEmpty;
  int get incoming_id => result.moved_ids.single;
  List<int> get insertion_tray => result.settlement_tray;

  /// 锁定本段飞行时长；同一事务的预飞与落槽必须共用，交接才不跳变。
  double lock_flight(double distance) =>
      _flight_ms ??= TileQuestStyle.flight_duration_ms(distance);

  /// 未获知航距时按最长航段兜底，保证调度仍然保守。
  double get flight_ms =>
      _flight_ms ?? TileQuestStyle.flight_duration_max_ms;

  /// 每张新牌从点击时刻独立计时，整段飞行都使用同一条曲线。
  /// 排在匹配或其他插入后面的牌也能直接落入槽位，不再在半空等队列。
  double preflight_progress(double now) => preflight
      ? _smooth_progress((now - queued_at) / flight_ms)
      : 0;

  /// 规则呈现仍按事务顺序交接；交接仅等待尚未完成的飞行部分。
  /// 已经并行落槽的牌无需重复补飞，匹配则从交接后正常保持、消散。
  void start(double now) {
    started_at = now;
    final base = flight_ms;
    travel_ms = inserts
        ? preflight
              ? (base - (now - queued_at)).clamp(0.0, base)
              : base
        : result.action == TileQuestAction.shuffle
        ? TileQuestStyle.shuffle_duration_ms
        : TileQuestStyle.tool_motion_ms;
  }

  double get compact_ms => matches && result.after.tray.isNotEmpty
      ? TileQuestStyle.tray_compact_ms
      : 0;
  double get match_start => travel_ms + TileQuestStyle.match_hold_ms;
  double get compact_start => match_start;
  double get duration_ms => matches
      ? match_start + math.max(TileQuestStyle.match_fade_ms, compact_ms)
      : travel_ms;
  double get ends_at => started_at + duration_ms;
  double elapsed(double now) => (now - started_at).clamp(0.0, duration_ms);
  double travel(double now) =>
      travel_ms <= 0 ? 1 : _smooth_progress(elapsed(now) / travel_ms);
  double flight(double now) =>
      preflight ? preflight_progress(now) : travel(now);
  double fade(double now) => matches
      ? ((elapsed(now) - match_start) / TileQuestStyle.match_fade_ms).clamp(
          0.0,
          1.0,
        )
      : 0;
  double compact(double now) => compact_ms == 0
      ? 0
      : _smooth_progress((elapsed(now) - compact_start) / compact_ms);

  /// 使用同一条解析曲线，起落速度均为零，调用方不得再次套入缓动。
  /// 不依赖 Cubic 的迭代求根，洗牌与道具每帧只计算一次共享进度。
  static double _smooth_progress(double value) {
    final time = value.clamp(0.0, 1.0);
    return time * time * (3 - 2 * time);
  }
}
