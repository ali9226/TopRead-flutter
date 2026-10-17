import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../tool/tile_quest/evaluator.dart';

void main() {
  test(
    'search counts root and descendant expansions inside its hard budget',
    () {
      final state = TileQuestGenerator.generate(
        level: 2,
        seed: 47,
        difficulty: 10,
      );
      for (final budget in [1, 2, 8, 96]) {
        final run = TileQuestEvaluator(
          search_depth: 3,
          node_budget: budget,
        ).simulate(state, TileQuestStrategy.limited_search, policy_seed: 11);
        expect(run.max_search_nodes, inInclusiveRange(1, budget));
      }
    },
  );

  test(
    'all development strategies support varied sparse tutorial sprite indices',
    () {
      final evaluator = TileQuestEvaluator(search_depth: 2, node_budget: 48);
      for (final seed in [1, 17, 214, 730]) {
        final state = TileQuestGenerator.generate(level: 1, seed: seed);
        expect(state.tiles.map((tile) => tile.type).toSet(), hasLength(3));
        for (final strategy in TileQuestStrategy.values) {
          final first = evaluator.simulate(state, strategy, policy_seed: 73);
          final second = evaluator.simulate(state, strategy, policy_seed: 73);
          expect(first.to_json(), second.to_json());
          expect(
            first.won,
            isTrue,
            reason:
                'three-type tutorial must remain forgiving for ${strategy.name} at seed $seed',
          );
          expect(first.steps, inInclusiveRange(1, state.total_count));
          expect(first.occupancy_sum / first.steps, inInclusiveRange(0, 7));
          expect(first.remaining_tiles, state.total_count - first.steps);
        }
      }
    },
  );

  test(
    'summary reports failure and choice metrics without claiming human rates',
    () {
      final evaluator = TileQuestEvaluator();
      final summary = evaluator.summarize(const [
        TileQuestSimulation(
          won: true,
          steps: 18,
          occupancy_sum: 18,
          available_sum: 54,
          remaining_tiles: 0,
        ),
        TileQuestSimulation(
          won: false,
          steps: 10,
          occupancy_sum: 38,
          available_sum: 26,
          remaining_tiles: 8,
        ),
      ]);
      expect(summary['simulated_clear_rate'], .5);
      expect(summary['average_failure_steps'], 10);
      expect(summary['average_failure_remaining_board_tiles'], 8);
      expect(summary['average_available_moves'], closeTo(80 / 28, .0001));
      expect(summary['average_tray_fill_ratio'], closeTo(56 / 28 / 7, .0001));
    },
  );
}
