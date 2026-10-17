// ignore_for_file: non_constant_identifier_names
import 'dart:math' as math;
import 'package:flutter/animation.dart';
import '../game/models.dart';
import '../style.dart';
import 'scene_layout.dart';

/// 入场与洗牌只改变绘制坐标，不修改规则坐标、遮挡或槽位库存。
class QuestBoardMotion {
  const QuestBoardMotion._();

  /// 低层先落定，高层稍后覆盖；所有起点都位于场景上沿之外。
  static Rect entrance_rect(
    QuestSceneLayout layout,
    TileQuestTile tile,
    int rank,
    int count,
    double elapsed_ms,
  ) {
    final target = layout.board_tile(tile);
    final progress = entrance_progress(rank, count, elapsed_ms);
    final source_top =
        -target.height -
        layout.size.height * TileQuestStyle.entry_source_height_fraction;
    return target.translate(0, (source_top - target.top) * (1 - progress));
  }

  static double entrance_progress(int rank, int count, double elapsed_ms) {
    final delay = count <= 1
        ? 0.0
        : rank /
              (count - 1) *
              (TileQuestStyle.entry_duration_ms - TileQuestStyle.entry_fall_ms);
    return Curves.easeOutCubic.transform(
      ((elapsed_ms - delay) / TileQuestStyle.entry_fall_ms).clamp(0.0, 1.0),
    );
  }

  /// 卡片聚拢到同一个正圆、多圈旋转再散开，规则位置和托盘不变。
  ///
  /// 聚拢权重在边界的一、二阶导数均为零；环绕角速度在阶段交界保持
  /// 连续，避免旧版聚完停下、转完又停下产生的机械感。
  static Rect shuffle_rect(
    QuestSceneLayout layout,
    Rect source,
    int index,
    int count,
    double progress,
  ) {
    final time = progress.clamp(0.0, 1.0);
    if (time == 0 || time == 1) return source;
    final presence = _shuffle_presence(time);
    final slot = index / math.max(1, count);
    final phase = shuffle_turns(time) * math.pi * 2;
    final initial_angle = slot * math.pi * 2 - math.pi / 2;
    final angle = initial_angle + phase;
    // 横纵使用同一个像素半径。取消逐牌环带和半径起伏，避免整体轮廓
    // 随相位被拉成椭圆；仅聚拢/散开的过渡会偏离最终圆周。
    final radius = shuffle_radius(layout);
    final orbit =
        layout.board.center + Offset(math.cos(angle), math.sin(angle)) * radius;
    return Rect.fromCenter(
      center: Offset.lerp(source.center, orbit, presence)!,
      width: source.width,
      height: source.height,
    );
  }

  /// 半径只由场景决定，与单牌序号、方向、时刻和原始位置无关。
  static double shuffle_radius(QuestSceneLayout layout) {
    final available_radius = math.max(
      0.0,
      math.min(
            layout.board.width - layout.unit,
            layout.board.height - layout.unit,
          ) *
          .5,
    );
    return math.min(
      math.min(layout.board.width, layout.board.height) *
          TileQuestStyle.shuffle_radius_fraction,
      available_radius * TileQuestStyle.shuffle_safe_radius_fraction,
    );
  }

  /// 连续角速度的积分：两端余弦加/减速，中间匀速，整段共3.8圈。
  /// 主搅动阶段本身超过三圈，聚拢及散开仍持续转动。
  static double shuffle_turns(double progress) {
    final time = progress.clamp(0.0, 1.0);
    const gather = TileQuestStyle.shuffle_gather_fraction;
    const scatter = TileQuestStyle.shuffle_scatter_fraction;
    const tail = 1 - scatter;
    const integral = gather / 2 + scatter - gather + tail / 2;
    final double distance;
    if (time < gather) {
      distance =
          time / 2 - gather / (2 * math.pi) * math.sin(math.pi * time / gather);
    } else if (time <= scatter) {
      distance = gather / 2 + time - gather;
    } else {
      final elapsed = time - scatter;
      distance =
          gather / 2 +
          scatter -
          gather +
          elapsed / 2 +
          tail / (2 * math.pi) * math.sin(math.pi * elapsed / tail);
    }
    return TileQuestStyle.shuffle_turns * distance / integral;
  }

  /// 全段保留正常牌面尺寸，聚拢只改变中心位置，不缩小牌面。
  static double shuffle_scale(double progress) => 1;

  /// 每张牌在搅动中独立轻摆，起落姿态均精确回到零。
  static double shuffle_rotation(double progress, {int index = 0}) {
    final phase = shuffle_turns(progress) * math.pi * 2;
    return math.sin(phase + index * 1.7) *
        TileQuestStyle.shuffle_rotation *
        _shuffle_presence(progress);
  }

  /// 换面窗口沿圆周轻微错开；调用方用返回值同尺寸叠加新图案，
  /// 不再通过横向压窄来隐藏换面，任何时刻都保留完整方块大小。
  static double shuffle_face_progress(
    double progress, {
    int index = 0,
    int count = 1,
  }) {
    final slot = count <= 1 ? .5 : index / (count - 1);
    final center =
        TileQuestStyle.shuffle_flip_center +
        (slot - .5) * TileQuestStyle.shuffle_flip_stagger;
    final start = center - TileQuestStyle.shuffle_flip_fraction / 2;
    return _smooth_step(
      ((progress - start) / TileQuestStyle.shuffle_flip_fraction).clamp(
        0.0,
        1.0,
      ),
    );
  }

  /// 全段只在棋盘与环带之间混合，边界平滑且没有逐帧分配临时集合。
  static double _shuffle_presence(double progress) {
    final time = progress.clamp(0.0, 1.0);
    final gather = time / TileQuestStyle.shuffle_gather_fraction;
    final scatter = (1 - time) / (1 - TileQuestStyle.shuffle_scatter_fraction);
    return _smooth_step(math.min(1.0, math.min(gather, scatter)));
  }

  static double _smooth_step(double value) =>
      value * value * value * (value * (value * 6 - 15) + 10);
}
