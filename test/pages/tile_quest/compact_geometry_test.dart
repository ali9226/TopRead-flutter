// ignore_for_file: non_constant_identifier_names
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/game/validator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Adjacent cells meet edge-to-edge. Deliberate whole-cell holes and separate
/// heaps are part of the irregular layouts; fractional sight gaps are not.
void expect_compact_layers(TileQuestState state) {
  const tolerance = .000001;
  final barrier = state.expert_barrier;
  final barrier_ids = <int>{
    if (barrier != null) ...barrier.front_ids,
    if (barrier != null) ...barrier.partner_ids,
  };
  // The expert gate is a physically independent stack with its own lattice.
  // Check both complete regions, including every gate and partner; a gap between
  // the two disjoint regions is intentional whitespace, not an adjacent seam.
  final regions = [
    state.tiles.where((tile) => !barrier_ids.contains(tile.id)).toList(),
    if (barrier != null)
      state.tiles.where((tile) => barrier_ids.contains(tile.id)).toList(),
  ];
  expect(regions.expand((tiles) => tiles).length, state.tiles.length);
  for (final region in regions) {
    final layer_ids = state.tiles.map((tile) => tile.layer).toSet();
    for (final layer in layer_ids) {
      final layer_tiles = region.where((tile) => tile.layer == layer).toList();
      for (final horizontal in [true, false]) {
        final lines = <double, List<TileQuestTile>>{};
        for (final tile in layer_tiles) {
          final line = horizontal ? tile.y : tile.x;
          lines.putIfAbsent(line, () => []).add(tile);
        }
        for (final line in lines.values) {
          line.sort(
            (left, right) => horizontal
                ? left.x.compareTo(right.x)
                : left.y.compareTo(right.y),
          );
          for (var index = 1; index < line.length; index++) {
            final before = line[index - 1];
            final after = line[index];
            final gap = horizontal
                ? after.x - before.x - before.width
                : after.y - before.y - before.height;
            expect(
              gap >= -tolerance && (gap - gap.round()).abs() < tolerance,
              isTrue,
              reason:
                  'level=${state.level} difficulty=${state.difficulty} '
                  'seed=${state.seed} layer=$layer '
                  'tiles=${before.id},${after.id} horizontal=$horizontal',
            );
          }
        }
      }
    }
  }
}

void main() {
  test(
    'tutorial keeps whole-tile row and column gaps and a legal complete path',
    () {
      final state = TileQuestGenerator.generate(level: 1, seed: 730);
      expect_compact_layers(state);
      for (final layer in <int>[0, 1]) {
        final tiles = state.tiles.where((tile) => tile.layer == layer).toList();
        expect(tiles, hasLength(9));
        final xs = tiles.map((tile) => tile.x).toSet().toList()..sort();
        final ys = tiles.map((tile) => tile.y).toSet().toList()..sort();
        expect(xs, hasLength(3));
        expect(ys, hasLength(3));
        for (var index = 1; index < 3; index++) {
          expect(xs[index] - xs[index - 1], 2);
          expect(ys[index] - ys[index - 1], 2);
        }
      }
      expect(TileQuestValidator.validate_solution(state).valid, isTrue);
    },
  );

  test('all difficulties have compact, reproducible and solvable layouts', () {
    for (var difficulty = 1; difficulty <= 10; difficulty++) {
      for (final seed in [0, 27, 730]) {
        final state = TileQuestGenerator.generate(
          level: 2,
          difficulty: difficulty,
          seed: seed,
        );
        expect_compact_layers(state);
        final same_seed = TileQuestGenerator.generate(
          level: 2,
          difficulty: difficulty,
          seed: seed,
        );
        expect(same_seed.to_json(), state.to_json());
        final barrier = state.expert_barrier;
        if (barrier != null) {
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
          continue;
        }
        expect(TileQuestValidator.validate_solution(state).valid, isTrue);

        // Replay the certified order through actual tray rules so tighter
        // neighboring rectangles cannot accidentally leave a blocked step.
        final engine = TileQuestEngine(state);
        for (final tile_id in state.certified_solution) {
          final result = engine.tap_tile(tile_id);
          expect(result.accepted, isTrue, reason: result.reason);
        }
        expect(engine.state.status, TileQuestStatus.won);
      }
    }
  });
}
