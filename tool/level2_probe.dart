// ignore_for_file: non_constant_identifier_names, constant_identifier_names
/// 第二关诊断探针：底部同图案聚集度 + 机器人胜率。
/// 用法: fvm dart run tool/level2_probe.dart [difficulty] [seeds]
import 'dart:math';
import 'package:app/pages/tile_quest/game/config.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/geometry.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'tile_quest/evaluator.dart';

void main(List<String> args) {
  final difficulty = args.isNotEmpty ? double.parse(args[0]) : 9.5;
  final seeds = args.length > 1 ? int.parse(args[1]) : 12;
  print('=== difficulty $difficulty, $seeds seeds ===');
  var cluster_scores = <double>[];
  var deep_dups = <double>[];
  var wins = <String, int>{};
  var attempts = <String, int>{};
  for (var seed = 1; seed <= seeds; seed++) {
    final state = TileQuestGenerator.generate(
      level: 2,
      seed: seed * 7919 + 13,
      difficulty: difficulty,
    );
    // 底部区（y >= 7.5）同层同图聚集：统计每一层里同图最大连续数
    final bottom = state.tiles.where((t) => t.y >= 7.5).toList();
    var max_run = 0;
    final by_layer = <int, List<TileQuestTile>>{};
    for (final t in bottom) {
      by_layer.putIfAbsent(t.layer, () => []).add(t);
    }
    for (final row in by_layer.values) {
      row.sort((a, b) => a.x.compareTo(b.x));
      var run = 1;
      for (var i = 1; i < row.length; i++) {
        if (row[i].type == row[i - 1].type) {
          run++;
          if (run > max_run) max_run = run;
        } else {
          run = 1;
        }
      }
    }
    cluster_scores.add(max_run.toDouble());
    // 深层（低 layer）重复：最深 1/3 层内同图占比
    final max_layer = state.tiles.map((t) => t.layer).reduce(max);
    final deep = state.tiles.where((t) => t.layer <= max_layer ~/ 3).toList();
    final type_count = <int, int>{};
    for (final t in deep) {
      type_count[t.type] = (type_count[t.type] ?? 0) + 1;
    }
    final deep_max = type_count.values.isEmpty ? 0 : type_count.values.reduce(max);
    deep_dups.add(deep.isEmpty ? 0 : deep_max / deep.length);
    // 机器人
    for (final strategy in [
      TileQuestStrategy.complete_triple,
      TileQuestStrategy.limited_search,
      TileQuestStrategy.release_blockers,
      TileQuestStrategy.row_major,
      TileQuestStrategy.random,
    ]) {
      final sim = TileQuestEvaluator(search_depth: 3, node_budget: 96)
          .simulate(state, strategy, policy_seed: seed);
      attempts[strategy.name] = (attempts[strategy.name] ?? 0) + 1;
      if (sim.won) wins[strategy.name] = (wins[strategy.name] ?? 0) + 1;
    }
  }
  double avg(List<double> xs) => xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;
  print('bottom same-type max-run per layer: avg=${avg(cluster_scores).toStringAsFixed(2)} '
      'max=${cluster_scores.reduce(max)}');
  print('deep-layer top-type share: avg=${(avg(deep_dups) * 100).toStringAsFixed(1)}%');
  print('bot win rates:');
  for (final name in attempts.keys) {
    print('  $name: ${wins[name] ?? 0}/${attempts[name]}');
  }
}
