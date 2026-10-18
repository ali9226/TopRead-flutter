// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:app/pages/tile_quest/game/config.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/expert_barrier.dart';
import 'tile_quest/evaluator.dart';

/// Usage: fvm dart run tool/tile_quest_evaluate.dart [seeds=20] [depth=3]
/// All policies play exactly the same seeded boards, without tools or certificates.
void main(List<String> arguments) {
  final int seeds = arguments.isEmpty ? 20 : int.tryParse(arguments[0]) ?? 0;
  final int depth = arguments.length < 2 ? 3 : int.tryParse(arguments[1]) ?? 0;
  if (seeds < 1 || seeds > 10000 || depth < 1 || depth > 6) {
    stderr.writeln('Expected 1–10000 seeds and search depth 1–6.');
    exitCode = 64;
    return;
  }
  final evaluator = TileQuestEvaluator(search_depth: depth);
  final reports = <Map<String, dynamic>>[];
  final previous_rates = <TileQuestStrategy, double>{};
  for (int difficulty = 1; difficulty <= 10; difficulty++) {
    final runs = {
      for (final strategy in TileQuestStrategy.values)
        strategy: <TileQuestSimulation>[],
    };
    final timer = Stopwatch()..start();
    for (int index = 0; index < seeds; index++) {
      final seed = 104729 + index * 7919;
      final state = TileQuestGenerator.generate(
        level: 2,
        seed: seed,
        difficulty: difficulty,
        unlocked_level: 2,
      );
      for (final strategy in TileQuestStrategy.values) {
        runs[strategy]!.add(
          evaluator.simulate(state, strategy, policy_seed: seed ^ 0x71e),
        );
      }
    }
    final profiles = DifficultyProfile.for_difficulty(difficulty);
    reports.add({
      'difficulty': difficulty,
      'tile_count': profiles.tile_count,
      'type_count': profiles.type_count,
      'layers': profiles.layers,
      'minimum_remove_uses': difficulty == 10
          ? TileQuestExpertBarrier.required_remove_uses
          : difficulty >= TileQuestConfig.mandatory_tool_difficulty
          ? TileQuestExpertBarrier.tool_required_remove_uses
          : 0,
      'target_human_failure_rate_uncalibrated': profiles.target_failure_rate,
      'strategies': {
        for (final entry in runs.entries)
          entry.key.name: (() {
            final summary = evaluator.summarize(entry.value);
            final rate = summary['simulated_clear_rate'] as double;
            summary['clear_rate_change_from_previous_difficulty'] =
                previous_rates.containsKey(entry.key)
                ? rate - previous_rates[entry.key]!
                : null;
            previous_rates[entry.key] = rate;
            return summary;
          })(),
      },
      'evaluation_ms': timer.elapsedMilliseconds,
    });
  }
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'schema_version': 1,
      'note':
          'Simulated policy clear rates are not human clear rates. Targets '
          'remain uncalibrated; use larger seed batches and player testing. '
          'limited_search has optimistic knowledge of patterns revealed by future '
          'moves, including currently covered tiles; other policies see exposed tiles. '
          'Difficulties 5–10 have static geometric barriers that cannot be completed '
          'without Remove, so every tool-free clear rate must be zero there.',
      'seeds_per_difficulty': seeds,
      'search_depth': depth,
      'search_node_budget_per_decision': evaluator.node_budget,
      'seed_start': 104729,
      'seed_stride': 7919,
      'levels': reports,
    }),
  );
}
