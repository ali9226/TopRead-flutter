// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';

import '../game/engine.dart';
import '../game/generator.dart';
import '../game/models.dart';

/// 洗牌同时返回完整引擎快照与动画事件，保留 Undo 历史。
class TileQuestPreparedShuffle {
  const TileQuestPreparedShuffle({required this.engine, required this.result});

  final TileQuestEngine engine;
  final TileQuestActionResult result;
}

/// 可注入的计算服务，便于测试异步重入与隔离生成耗时。
///
/// [seed] 为每局随机种子；[layout_seed] 为当日共享布局种子（缺省回退 seed）。
abstract interface class TileQuestWorkService {
  Future<TileQuestState> generate({
    required int level,
    required int seed,
    required int unlocked_level,
    String? challenge_id,
    int? layout_seed,
    num? difficulty,
  });

  Future<TileQuestPreparedShuffle> shuffle(
    Map<String, dynamic> engine_json, {
    required int seed,
  });
}

/// 关卡构造及有界洗牌搜索在独立 isolate 运行，避免阻塞移动端动画。
class TileQuestIsolateWork implements TileQuestWorkService {
  @override
  Future<TileQuestState> generate({
    required int level,
    required int seed,
    required int unlocked_level,
    String? challenge_id,
    int? layout_seed,
    num? difficulty,
  }) => compute(_generate_level, <String, dynamic>{
    'level': level,
    'seed': seed,
    'unlocked_level': unlocked_level,
    'challenge_id': challenge_id,
    'layout_seed': layout_seed,
    'difficulty': difficulty,
  });

  @override
  Future<TileQuestPreparedShuffle> shuffle(
    Map<String, dynamic> engine_json, {
    required int seed,
  }) => compute(_shuffle_level, <String, dynamic>{
    'engine': engine_json,
    'seed': seed,
  });
}

/// 顶层入口不会意外捕获页面、控制器或平台服务。
TileQuestState _generate_level(Map<String, dynamic> parameters) =>
    TileQuestGenerator.generate(
      level: parameters['level']!,
      seed: parameters['seed']!,
      unlocked_level: parameters['unlocked_level']!,
      challenge_id: parameters['challenge_id'] as String?,
      layout_seed: parameters['layout_seed'] as int?,
      difficulty: parameters['difficulty'] as num?,
    );

TileQuestPreparedShuffle _shuffle_level(Map<String, dynamic> parameters) {
  final TileQuestEngine engine = TileQuestEngine.restore(
    parameters['engine'] as Map<String, dynamic>,
  );
  final TileQuestActionResult result = engine.shuffle(
    seed: parameters['seed'] as int,
  );
  return TileQuestPreparedShuffle(engine: engine, result: result);
}
