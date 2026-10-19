// ignore_for_file: non_constant_identifier_names
import 'package:flutter/foundation.dart';
import '../game/models.dart';
import 'reveal_style.dart';

/// 规则立即解锁，视觉用既有场景时钟连续退去遮罩。
///
/// 只有正在变亮或变暗的牌持有轨迹；静态棋盘不会随普通飞牌时钟重绘。
/// 轨迹只依赖牌 ID，旋转屏幕、缩放和图集重新解码不会重启动画。
class QuestBoardReveal extends ChangeNotifier {
  final Map<int, bool> _targets = {};
  final Map<int, _QuestRevealTrack> _tracks = {};
  double _now = 0;

  bool get is_animating => _tracks.isNotEmpty;

  /// 换局从新牌阵的真实状态开始，不继承上一局相同 ID 的遮罩。
  void reset(
    Iterable<TileQuestTile> tiles, {
    double now = 0,
    Map<int, bool> blocked_overrides = const {},
  }) {
    _now = now;
    _tracks.clear();
    _targets
      ..clear()
      ..addEntries(
        tiles.map(
          (tile) => MapEntry(
            tile.id,
            blocked_overrides[tile.id] ?? (!tile.is_removed && tile.is_blocked),
          ),
        ),
      );
  }

  /// 接收一次规则事务；快速反向变化从当前亮度及速度继续，不能闪回端点。
  void update(
    Iterable<TileQuestTile> tiles,
    double now, {
    bool animate = true,
    Map<int, bool> blocked_overrides = const {},
  }) {
    _now = now;
    final alive = <int>{};
    var changed = false;
    for (final tile in tiles) {
      alive.add(tile.id);
      final before = _targets[tile.id];
      // 正在揭开的牌可立即飞走；轨迹继续归零，飞牌不能突然闪白。
      final blocked =
          blocked_overrides[tile.id] ?? (!tile.is_removed && tile.is_blocked);
      if (before != null && before != blocked) {
        final sample = sample_at(tile.id, now, blocked: before);
        if (animate) {
          _tracks[tile.id] = _QuestRevealTrack(
            started_at: now,
            initial: sample.amount,
            initial_velocity: sample.velocity,
            target: blocked ? 1 : 0,
          );
        } else {
          _tracks.remove(tile.id);
        }
        changed = true;
      }
      _targets[tile.id] = blocked;
    }
    _targets.removeWhere((id, _) => !alive.contains(id));
    _tracks.removeWhere((id, _) => !alive.contains(id));
    if (!animate && _tracks.isNotEmpty) {
      _tracks.clear();
      changed = true;
    }
    if (changed) notifyListeners();
  }

  /// 主时钟调用一次即可推进所有遮罩，最后一帧通知后恢复完全静态。
  void advance(double now) {
    if (_tracks.isEmpty) return;
    _now = now;
    _tracks.removeWhere((_, track) => now >= track.ends_at);
    notifyListeners();
  }

  /// 0 是正常牌，1 是完全遮挡牌；命中检测始终使用引擎的 blocked。
  double amount_of(int id, {required bool blocked}) {
    final track = _tracks[id];
    // 数百张静态牌不分配 sample record，只有短暂变化的牌计算曲线。
    if (track == null) return (_targets[id] ?? blocked) ? 1 : 0;
    return track.sample(_now).amount;
  }

  /// 返回实际绘制轨迹及其每毫秒速度，便于检验连续点击/撤回不会跳帧。
  ({double amount, double velocity}) sample_at(
    int id,
    double now, {
    required bool blocked,
  }) =>
      _tracks[id]?.sample(now) ??
      (amount: (_targets[id] ?? blocked) ? 1 : 0, velocity: 0);
}

/// 两端 Hermite 轨迹，终点速度为零，反向接续保留起点速度。
class _QuestRevealTrack {
  const _QuestRevealTrack({
    required this.started_at,
    required this.initial,
    required this.initial_velocity,
    required this.target,
  });
  final double started_at, initial, initial_velocity, target;
  double get ends_at => started_at + QuestRevealStyle.duration_ms;

  ({double amount, double velocity}) sample(double now) {
    if (now <= started_at) {
      return (amount: initial, velocity: initial_velocity);
    }
    if (now >= ends_at) return (amount: target, velocity: 0);
    final t = (now - started_at) / QuestRevealStyle.duration_ms;
    final t2 = t * t;
    final t3 = t2 * t;
    final tangent = initial_velocity * QuestRevealStyle.duration_ms;
    final value =
        (2 * t3 - 3 * t2 + 1) * initial +
        (t3 - 2 * t2 + t) * tangent +
        (-2 * t3 + 3 * t2) * target;
    final velocity =
        ((6 * t2 - 6 * t) * initial +
            (3 * t2 - 4 * t + 1) * tangent +
            (-6 * t2 + 6 * t) * target) /
        QuestRevealStyle.duration_ms;
    return (
      amount: value.clamp(0.0, 1.0),
      velocity: value <= 0 || value >= 1 ? 0 : velocity,
    );
  }
}
