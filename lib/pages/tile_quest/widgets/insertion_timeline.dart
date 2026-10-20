// ignore_for_file: non_constant_identifier_names
import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../game/models.dart';
import '../style.dart';
import 'scene_layout.dart';
import 'scene_motion.dart';

/// 一批连续点击共用槽位调度，每张牌拥有独立路径和消散时钟。
/// 只有撤回、移出、洗牌等改变牌来源的道具需要等待整批呈现完成。
class QuestInsertionTimeline {
  QuestInsertionTimeline(this.before, this.started_at) {
    for (final id in {...before.tray, ...before.reserve}) {
      tracks[id] = QuestInsertionTrack(before, id);
    }
  }

  final TileQuestState before;
  final double started_at;
  final List<QuestSceneMotion> motions = [];
  final Map<int, QuestInsertionTrack> tracks = {};
  double _slot_release_at = 0;
  double _last_match_at = 0;
  double ends_at = 0;

  TileQuestState get after => motions.last.result.after;
  Iterable<int> get incoming_ids => motions.map((motion) => motion.incoming_id);

  /// 下一组三消只等待上一组腾出槽位，粒子尾迹继续独立播放。
  /// 若多个组同帧点击，后组从点击时刻沿一条稍长曲线飞行，途中不停顿。
  ///
  /// [distance] 为起点到目标槽的航距；用它换算时长，近牌不显迟缓。
  void add(QuestSceneMotion motion, double now, {double distance = 0}) {
    if (distance > 0) motion.lock_flight(distance);
    final result = motion.result;
    final flight_start = math.max(
      started_at,
      motion.preflight ? motion.queued_at : now,
    );
    final flight_end = math.max(
      flight_start + motion.flight_ms,
      _slot_release_at,
    );
    final shift_start = math.max(flight_start, _last_match_at);
    motion.start(flight_start);
    motion.travel_ms = flight_end - flight_start;
    motions.add(motion);
    final incoming = QuestInsertionTrack(result.before, motion.incoming_id)
      ..incoming = true;
    tracks[motion.incoming_id] = incoming;
    for (var index = 0; index < result.settlement_tray.length; index++) {
      final id = result.settlement_tray[index];
      final track = tracks[id]!;
      track.move(
        index,
        id == motion.incoming_id ? flight_start : shift_start,
        flight_end,
        flying: id == motion.incoming_id,
      );
    }
    if (motion.matches) {
      final match_at = flight_end + TileQuestStyle.match_hold_ms;
      final compact_end = match_at + motion.compact_ms;
      for (final id in result.matched_ids) {
        tracks[id]!
          ..fade_at = match_at
          ..ends_at = match_at + TileQuestStyle.match_fade_ms;
      }
      for (var index = 0; index < result.after.tray.length; index++) {
        tracks[result.after.tray[index]]!.move(index, match_at, compact_end);
      }
      // 即使当前组清空主槽，也预留完整的让位时间，避免新牌覆盖碎粒中心。
      _last_match_at = match_at;
      _slot_release_at = match_at + TileQuestStyle.tray_compact_ms;
    }
    ends_at = math.max(ends_at, motion.ends_at);
  }
}

/// 单张牌的身份在整批中保持稳定，后续插入只延续路径，不重置来源。
class QuestInsertionTrack {
  QuestInsertionTrack(this.source, this.id)
    : _path = _QuestInsertionPath.source(source, id);

  final TileQuestState source;
  final int id;
  bool incoming = false;
  double? fade_at;
  double? ends_at;
  _QuestInsertionPath _path;

  int get type => source.tile_by_id(id).type;
  bool get reserve => source.reserve.contains(id) && !incoming;

  void move(int slot, double start, double end, {bool flying = false}) {
    // 相同目标不重启未结束的飞行，后点的牌不能让先点的牌减速等候。
    if (_path.slot == slot) return;
    // 插入牌只需让邻牌及时腾出一格，不应把邻牌重置成另一段完整飞行。
    // 尚在飞行的牌保留原落地时钟；接近落地时留足正常的横向让位时间。
    // 三消后的压缩从未来时点开始，仍严格使用调度器给定的释放时钟。
    final redirect_end = !flying && start < _path.ends_at
        ? math.min(
            end,
            math.max(_path.ends_at, start + TileQuestStyle.tray_compact_ms),
          )
        : end;
    _path = _QuestInsertionPath.move(
      _path,
      slot,
      start,
      redirect_end,
      flying: flying,
    );
  }

  Rect rect(QuestSceneLayout layout, double now) => _path.rect(layout, now);

  double fade(double now) => fade_at == null
      ? 0
      : ((now - fade_at!) / TileQuestStyle.match_fade_ms).clamp(0.0, 1.0);
}

/// 路径在当前布局中求值，旋转/窗口缩放后仍使用统一的槽位坐标。
/// 重定向继承旧路径的位置、尺寸和速度，避免连续点击把运动重置为静止。
class _QuestInsertionPath {
  _QuestInsertionPath.source(this.source, this.id)
    : previous = null,
      slot = null,
      starts_at = 0,
      ends_at = 0,
      flying = false;

  _QuestInsertionPath.move(
    this.previous,
    this.slot,
    this.starts_at,
    this.ends_at, {
    required this.flying,
  }) : source = null,
       id = null;

  final _QuestInsertionPath? previous;
  final TileQuestState? source;
  final int? id;
  final int? slot;
  final double starts_at, ends_at;
  final bool flying;

  QuestSceneLayout? _cached_layout;
  _QuestInsertionSample? _cached_origin;
  Rect? _cached_destination;
  double _cached_lift = 0;

  /// 一次布局只解析一次路径起点，逐帧不再递归计算所有历史曲线。
  void _resolve(QuestSceneLayout layout) {
    if (identical(_cached_layout, layout)) return;
    _cached_layout = layout;
    final origin = previous!._sample(layout, starts_at);
    final destination = layout.tray_tile(slot!);
    _cached_origin = origin;
    _cached_destination = destination;
    _cached_lift = flying
        ? math.min(
            TileQuestStyle.flight_lift_max,
            (origin.rect.center - destination.center).distance *
                TileQuestStyle.flight_lift_distance_fraction,
          )
        : 0;
  }

  Rect rect(QuestSceneLayout layout, double now) => _sample(layout, now).rect;

  /// 三次 Hermite 保留起始切线，终点速度为零。抬升曲线在两端的
  /// 位移、速度均为零，因此改变目标和最终落槽都不会突然减速或跳动。
  _QuestInsertionSample _sample(QuestSceneLayout layout, double now) {
    final parent = previous;
    if (parent == null) {
      return _QuestInsertionSample.still(layout.location(source!, id!));
    }
    if (now < starts_at) return parent._sample(layout, now);
    if (now >= ends_at || ends_at <= starts_at) {
      return _QuestInsertionSample.still(layout.tray_tile(slot!));
    }
    _resolve(layout);
    final origin = _cached_origin!;
    final destination = _cached_destination!;
    // 调度端已按航距写入 ends_at；让位拉长时整段曲线一起拉长，避免中途悬停。
    final duration = ends_at - starts_at;
    final time = ((now - starts_at) / duration).clamp(0.0, 1.0);
    final time_squared = time * time;
    final remaining = 1 - time;
    final progress = time_squared * (3 - 2 * time);
    final tangent_weight = time * remaining * remaining * duration;
    final progress_velocity = 6 * time * remaining / duration;
    final tangent_velocity = 3 * time_squared - 4 * time + 1;
    final delta = destination.center - origin.rect.center;
    final lift = _cached_lift * 16 * time_squared * remaining * remaining;
    final lift_velocity =
        _cached_lift * 32 * time * remaining * (1 - 2 * time) / duration;
    final center =
        origin.rect.center +
        delta * progress +
        origin.center_velocity * tangent_weight -
        Offset(0, lift);
    final width_delta = destination.width - origin.rect.width;
    final height_delta = destination.height - origin.rect.height;
    return _QuestInsertionSample(
      Rect.fromCenter(
        center: center,
        width:
            origin.rect.width +
            width_delta * progress +
            origin.width_velocity * tangent_weight,
        height:
            origin.rect.height +
            height_delta * progress +
            origin.height_velocity * tangent_weight,
      ),
      delta * progress_velocity +
          origin.center_velocity * tangent_velocity -
          Offset(0, lift_velocity),
      width_delta * progress_velocity +
          origin.width_velocity * tangent_velocity,
      height_delta * progress_velocity +
          origin.height_velocity * tangent_velocity,
    );
  }
}

/// 速度单位为像素/毫秒；尺寸也保留速度，避免重定向时缩放突然停一下。
class _QuestInsertionSample {
  const _QuestInsertionSample(
    this.rect,
    this.center_velocity,
    this.width_velocity,
    this.height_velocity,
  );

  const _QuestInsertionSample.still(this.rect)
    : center_velocity = Offset.zero,
      width_velocity = 0,
      height_velocity = 0;

  final Rect rect;
  final Offset center_velocity;
  final double width_velocity, height_velocity;
}
