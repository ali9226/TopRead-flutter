// ignore_for_file: non_constant_identifier_names
import 'dart:math';
import 'package:app/pages/tile_quest/game/config.dart';
import 'package:app/pages/tile_quest/game/expert_barrier.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/geometry.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/game/validator.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../tool/tile_quest/evaluator.dart';

/// Distinguish the complete stepped structure, independent of ids and sprites.
String _template_signature(TileQuestState state) =>
    (state.tiles
            .map(
              (tile) => '${tile.region_id}/${tile.layer}/${tile.x}/${tile.y}',
            )
            .toList()
          ..sort())
        .join(';');

List<int> _lead_path(TileQuestState state) =>
    state.expert_barrier?.lead_solution ?? state.certified_solution;

({
  double early_pressure,
  double late_pressure,
  double early_choices,
  double late_choices,
  int early_max,
  int late_types,
})
_curve(TileQuestState state) {
  final path = _lead_path(state);
  final graph = TileQuestGeometry(state.tiles);
  final remaining = state.tiles.map((tile) => tile.id).toSet();
  final counts = List<int>.filled(TileQuestConfig.max_tile_types, 0);
  final early_pressure = <int>[], late_pressure = <int>[];
  final early_choices = <int>[], late_choices = <int>[];
  final late_types = <int>{};
  var occupancy = 0;
  final opening_count = state.clickable_tiles
      .where((tile) => tile.region_id != 'gate')
      .length;
  for (var index = 0; index < path.length; index++) {
    final choices = remaining
        .where((id) => !graph.blockers[id]!.any(remaining.contains))
        .length;
    final type = state.tile_by_id(path[index]).type;
    remaining.remove(path[index]);
    counts[type]++;
    occupancy++;
    if (counts[type] == 3) {
      counts[type] = 0;
      occupancy -= 3;
    }
    if (index < opening_count) {
      early_pressure.add(occupancy);
      early_choices.add(choices);
    }
    if (index >= path.length * 2 ~/ 3) {
      late_pressure.add(occupancy);
      late_choices.add(choices);
      late_types.add(type);
    }
  }
  double mean(List<int> values) =>
      values.reduce((a, b) => a + b) / values.length;
  return (
    early_pressure: mean(early_pressure),
    late_pressure: mean(late_pressure),
    early_choices: mean(early_choices),
    late_choices: mean(late_choices),
    early_max: early_pressure.reduce(max),
    late_types: late_types.length,
  );
}

void main() {
  test(
    'seeded templates vary their complete stepped structures without random scatter',
    () {
      final signatures = <String>{};
      for (var seed = 0; seed < 64; seed++) {
        final state = TileQuestGenerator.generate(
          level: 2,
          seed: seed,
          difficulty: 8,
        );
        signatures.add(_template_signature(state));
        expect(
          state.tiles.any((tile) => (tile.x % 1 - .5).abs() < .02),
          isTrue,
        );
        expect(
          state.tiles.every(
            (tile) =>
                tile.x >= 0 &&
                tile.y >= 0 &&
                tile.x + tile.width <= TileQuestConfig.board_logical_width &&
                tile.y + tile.height <= TileQuestConfig.board_logical_height,
          ),
          isTrue,
        );
      }
      expect(signatures.length, greaterThanOrEqualTo(8));
    },
  );

  test(
    'every difficulty has many exposed complete triples and increasing depth/count/variety',
    () {
      var previous_count = 0, previous_layers = 0, previous_types = 0;
      for (var difficulty = 1; difficulty <= 10; difficulty++) {
        final profile = DifficultyProfile.for_difficulty(difficulty);
        expect(profile.tile_count, greaterThan(previous_count));
        expect(profile.layers, greaterThan(previous_layers));
        expect(profile.type_count, greaterThanOrEqualTo(previous_types));
        previous_count = profile.tile_count;
        previous_layers = profile.layers;
        previous_types = profile.type_count;
        for (final seed in [0, 17, 730]) {
          final state = TileQuestGenerator.generate(
            level: 2,
            seed: seed,
            difficulty: difficulty,
          );
          expect(state.total_count, profile.tile_count);
          expect(
            state.tiles.map((tile) => tile.type).toSet().length,
            profile.type_count,
          );
          expect(
            state.tiles
                .where(
                  (tile) =>
                      !(state.expert_barrier?.front_ids.contains(tile.id) ??
                          false) &&
                      !(state.expert_barrier?.partner_ids.contains(tile.id) ??
                          false),
                )
                .map((tile) => tile.layer)
                .toSet()
                .length,
            profile.layers,
          );
          expect(
            state.clickable_tiles.length,
            inInclusiveRange(
              profile.min_initial_choices,
              profile.max_initial_choices,
            ),
          );
          final visible_types = <int, int>{};
          for (final tile in state.clickable_tiles) {
            visible_types[tile.type] = (visible_types[tile.type] ?? 0) + 1;
          }
          expect(
            visible_types.values.fold<int>(0, (sum, count) => sum + count ~/ 3),
            greaterThanOrEqualTo(4),
          );
          expect(
            visible_types.length,
            lessThanOrEqualTo(difficulty == 10 ? 5 : 4),
          );
          TileQuestValidator.validate_state(state);
          final same = TileQuestGenerator.generate(
            level: 2,
            seed: seed,
            difficulty: difficulty,
          );
          expect(same.to_json(), state.to_json());
        }
      }
    },
  );

  test(
    'the actual legal path starts gentle then increases pressure and reduces choices',
    () {
      for (var difficulty = 1; difficulty <= 10; difficulty++) {
        for (final seed in [17, 730]) {
          final state = TileQuestGenerator.generate(
            level: 2,
            seed: seed,
            difficulty: difficulty,
          );
          final curve = _curve(state);
          expect(curve.early_max, 2);
          expect(curve.early_pressure, closeTo(1, .001));
          expect(curve.late_pressure, greaterThan(curve.early_pressure + .3));
          expect(
            curve.late_choices,
            lessThan(state.clickable_tiles.length * .85),
          );
          final opening_types = state.clickable_tiles
              .map((tile) => tile.type)
              .toSet();
          expect(curve.late_types, greaterThan(opening_types.length));
          if (difficulty >= 8) {
            expect(
              curve.late_pressure,
              greaterThan(difficulty == 10 ? 3 : 4),
              reason: 'difficulty $difficulty seed $seed',
            );
            expect(
              curve.late_types,
              greaterThanOrEqualTo(difficulty == 10 ? 5 : 8),
            );
          }
        }
      }
    },
  );

  test(
    'difficulty nine remains legal while identity and spatial scans cannot reconstruct its path',
    () {
      final evaluator = TileQuestEvaluator(search_depth: 3, node_budget: 96);
      final clears = {
        for (final strategy in TileQuestStrategy.values) strategy: 0,
      };
      for (var sample = 0; sample < 12; sample++) {
        final seed = 982451653 - sample * 15485863;
        final state = TileQuestGenerator.generate(
          level: 2,
          seed: seed,
          difficulty: 9,
        );
        expect(TileQuestValidator.validate_solution(state).valid, isTrue);
        expect(
          state.certified_solution.take(24).toList(),
          isNot(
            orderedEquals(state.certified_solution.take(24).toList()..sort()),
          ),
        );
        for (final strategy in TileQuestStrategy.values) {
          final run = evaluator.simulate(
            state,
            strategy,
            policy_seed: seed ^ 0x71e,
          );
          if (run.won) clears[strategy] = clears[strategy]! + 1;
        }
      }
      for (final entry in clears.entries) {
        expect(
          entry.value,
          lessThanOrEqualTo(1),
          reason:
              '${entry.key.name} must not expose a repeatable ordering shortcut',
        );
      }
    },
  );

  test(
    'expert boards keep an independent three-Remove witness and no two-charge win claim',
    () {
      for (final seed in [0, 17, 730, 104729]) {
        final state = TileQuestGenerator.generate(
          level: 2,
          seed: seed,
          difficulty: 10,
        );
        final barrier = state.expert_barrier!;
        expect(
          barrier.lead_solution,
          hasLength(state.total_count - barrier.core_tile_count),
        );
        expect(barrier.front_ids, hasLength(13));
        expect(
          barrier.partner_ids,
          hasLength(TileQuestExpertBarrier.partner_count),
        );
        expect(
          TileQuestValidator.validate_tool_solution(
            state,
            barrier.witness,
            remove_uses: 3,
          ).valid,
          isTrue,
        );
        expect(
          TileQuestValidator.validate_tool_solution(
            state,
            barrier.witness,
            remove_uses: 2,
          ).valid,
          isFalse,
        );
        if (TileQuestConfig.remove_uses_per_challenge < 3) {
          expect(state.certified_solution, isEmpty);
          expect(TileQuestValidator.validate_solution(state).valid, isFalse);
        }
        barrier.validate(state);
      }
    },
  );
}
