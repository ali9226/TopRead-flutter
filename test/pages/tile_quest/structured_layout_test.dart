// ignore_for_file: non_constant_identifier_names
import 'dart:convert';
import 'dart:math';
import 'package:app/pages/tile_quest/game/config.dart';
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/geometry.dart';
import 'package:app/pages/tile_quest/game/layout_patterns.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/game/validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'certificate_replay.dart';

bool _central(TileQuestTile tile) =>
    tile.region_id == 'main' || tile.region_id == 'core';

double _intersection(TileQuestTile left, TileQuestTile right) =>
    max(
      0.0,
      min(left.x + left.width, right.x + right.width) - max(left.x, right.x),
    ) *
    max(
      0.0,
      min(left.y + left.height, right.y + right.height) - max(left.y, right.y),
    );

void main() {
  test(
    'deep templates retain several separated top choices across depth basins',
    () {
      for (final difficulty in [8, 9, 10]) {
        final state = TileQuestGenerator.generate(
          level: 2,
          seed: 91000009,
          difficulty: difficulty,
        );
        final profile = DifficultyProfile.for_difficulty(difficulty);
        final highest_layer = state.tiles.map((tile) => tile.layer).reduce(max);
        final top = state.tiles
            .where((tile) => _central(tile) && tile.layer == highest_layer)
            .toList();
        expect(
          top,
          hasLength(
            TileQuestLayoutPatterns.cap_count_for_layers(profile.layers),
          ),
        );
        if (difficulty == 8) {
          expect(top, hasLength(4));
          continue;
        }
        expect(top, hasLength(6));
        expect(
          top.map((tile) => tile.x).toSet().length,
          greaterThanOrEqualTo(3),
        );
        expect(
          top.map((tile) => tile.y).toSet().length,
          greaterThanOrEqualTo(2),
        );
        expect(top.every((tile) => !tile.is_blocked), isTrue);
        final graph = TileQuestGeometry(state.tiles);
        final before = state.clickable_tiles.map((tile) => tile.id).toSet();
        final after = graph.refresh([
          for (final tile in state.tiles)
            tile.copy_with(is_removed: tile.id == top.first.id),
        ]);
        expect(
          after
              .where(
                (tile) =>
                    _central(tile) && !tile.is_removed && !tile.is_blocked,
              )
              .length,
          greaterThanOrEqualTo(5),
        );
        expect(before, containsAll(top.map((tile) => tile.id)));
      }
    },
  );

  test(
    'every template has isolated deep helpers, several main basins and exact stock',
    () {
      for (var difficulty = 1; difficulty <= 10; difficulty++) {
        for (final seed in [0, 17, 730, 104729]) {
          final profile = DifficultyProfile.for_difficulty(difficulty);
          final state = TileQuestGenerator.generate(
            level: 2,
            seed: seed,
            difficulty: difficulty,
          );
          final barrier_ids = {
            ...?state.expert_barrier?.front_ids,
            ...?state.expert_barrier?.partner_ids,
          };
          final ordinary = state.tiles
              .where((tile) => !barrier_ids.contains(tile.id))
              .toList();
          final central = ordinary.where(_central).toList();
          final helpers = state.tiles
              .where((tile) => tile.region_id.startsWith('side_'))
              .toList();
          expect(state.tiles, hasLength(profile.tile_count));
          expect(
            ordinary.map((tile) => tile.layer).toSet(),
            hasLength(profile.layers),
          );
          expect(helpers.map((tile) => tile.region_id).toSet(), {
            'side_top',
            'side_bottom',
          });
          expect(central.map((tile) => tile.region_id).toSet(), {
            'main',
            'core',
          });
          final minimum_x = state.tiles.map((tile) => tile.x).reduce(min);
          final maximum_x = state.tiles
              .map((tile) => tile.x + tile.width)
              .reduce(max);
          expect(
            maximum_x - minimum_x,
            lessThanOrEqualTo(TileQuestLayoutPatterns.footprint_width),
          );
          for (final tile in helpers) {
            expect(
              tile.region_id == 'side_top' ? tile.y < 1 : tile.y >= 8,
              isTrue,
            );
            for (final main_tile in central) {
              final vertical_gap = max(
                tile.y - main_tile.y - main_tile.height,
                main_tile.y - tile.y - tile.height,
              );
              expect(vertical_gap, greaterThanOrEqualTo(1));
            }
          }
          final layer_offset = ordinary.map((tile) => tile.layer).reduce(min);
          final counts = [
            for (var layer = 0; layer < profile.layers; layer++)
              central
                  .where((tile) => tile.layer == layer + layer_offset)
                  .length,
          ];
          expect(
            counts.first,
            inInclusiveRange(
              TileQuestLayoutPatterns.cap_capacity,
              TileQuestLayoutPatterns.base_capacity,
            ),
          );
          expect(
            counts.last,
            TileQuestLayoutPatterns.cap_count_for_layers(profile.layers),
          );
          final inventory = <int, int>{};
          for (final tile in state.tiles) {
            inventory[tile.type] = (inventory[tile.type] ?? 0) + 1;
            expect(tile.x, greaterThanOrEqualTo(0));
            expect(tile.y, greaterThanOrEqualTo(0));
            expect(tile.x + tile.width, lessThanOrEqualTo(7));
            expect(tile.y + tile.height, lessThanOrEqualTo(9));
          }
          expect(inventory, hasLength(profile.type_count));
          expect(inventory.values.every((count) => count % 3 == 0), isTrue);
        }
      }
    },
  );

  test(
    'whole and half-grid phases have consistent gaps and no same-layer overlap',
    () {
      for (var seed = 0; seed < 24; seed++) {
        final state = TileQuestGenerator.generate(level: 2, seed: seed);
        for (final tile in state.tiles.where(_central)) {
          final x_phase = (tile.x - TileQuestLayoutPatterns.grid_gap / 2) * 2;
          final y_phase = (tile.y - TileQuestLayoutPatterns.grid_gap / 2) * 2;
          expect(x_phase, closeTo(x_phase.round(), .000001));
          expect(y_phase, closeTo(y_phase.round(), .000001));
          expect(tile.width, TileQuestLayoutPatterns.tile_extent);
          expect(tile.height, TileQuestLayoutPatterns.tile_extent);
        }
        for (var index = 0; index < state.tiles.length; index++) {
          final tile = state.tiles[index];
          for (final other in state.tiles.skip(index + 1)) {
            if (tile.layer != other.layer) continue;
            expect(
              _intersection(tile, other),
              0,
              reason: '${tile.id}/${other.id} seed $seed',
            );
            expect(TileQuestGeometry.overlaps(tile, other), isFalse);
          }
        }
      }
    },
  );

  test('the small visible core reveals hidden lower layers immediately', () {
    final state = TileQuestGenerator.generate(
      level: 2,
      seed: 730,
      difficulty: 9,
    );
    final core = state.tiles.where((tile) => tile.region_id == 'core').toList();
    expect(
      core.where((tile) => tile.is_blocked).length,
      greaterThan(core.length * .8),
    );
    final graph = TileQuestGeometry(state.tiles);
    final initial_open = state.clickable_tiles.map((tile) => tile.id).toSet();
    final peeled = graph.refresh([
      for (final tile in state.tiles)
        tile.copy_with(is_removed: initial_open.contains(tile.id)),
    ]);
    final newly_open = peeled
        .where((tile) => !tile.is_removed && !tile.is_blocked)
        .toList();
    expect(newly_open, isNotEmpty);
    expect(
      newly_open.any(
        (tile) =>
            _central(tile) &&
            tile.layer < state.tiles.map((tile) => tile.layer).reduce(max),
      ),
      isTrue,
    );
    expect(
      newly_open.every((tile) => state.tile_by_id(tile.id).is_blocked),
      isTrue,
    );
    var remaining = peeled;
    var exposed_layers = 0;
    while (remaining.any((tile) => !tile.is_removed)) {
      final available = remaining
          .where((tile) => !tile.is_removed && !tile.is_blocked)
          .map((tile) => tile.id)
          .toSet();
      expect(available, isNotEmpty);
      remaining = graph.refresh([
        for (final tile in remaining)
          tile.copy_with(
            is_removed: tile.is_removed || available.contains(tile.id),
          ),
      ]);
      exposed_layers++;
    }
    expect(exposed_layers, greaterThanOrEqualTo(39));
  });

  test(
    'template geometry depends on the seed and stock, never sprite allocation',
    () {
      final profile = DifficultyProfile.for_difficulty(
        8,
      ).with_inventory(tile_count: 390, type_count: 10);
      for (var seed = 0; seed < 12; seed++) {
        final first = TileQuestLayoutPatterns.generate(profile, Random(seed));
        final second = TileQuestLayoutPatterns.generate(
          profile.with_inventory(tile_count: profile.tile_count, type_count: 7),
          Random(seed),
        );
        expect(
          first.map((tile) => tile.to_json()).toList(),
          second.map((tile) => tile.to_json()).toList(),
        );
        expect(first.every((tile) => tile.type == 0), isTrue);
        final final_state = TileQuestGenerator.generate(level: 2, seed: seed);
        final restored = TileQuestState.from_json(
          jsonDecode(jsonEncode(final_state.to_json())),
        );
        expect(restored.to_json(), final_state.to_json());
      }
    },
  );

  test(
    'new structures retain real zero, one and three-Remove solution budgets',
    () {
      for (var difficulty = 1; difficulty <= 10; difficulty++) {
        final state = TileQuestGenerator.generate(
          level: 2,
          seed: 982451653,
          difficulty: difficulty,
        );
        final barrier = state.expert_barrier;
        final required = difficulty == 10
            ? 3
            : difficulty >= 5
            ? 1
            : 0;
        if (barrier == null) {
          expect(required, 0);
          expect(TileQuestValidator.validate_solution(state).valid, isTrue);
        } else {
          expect(barrier.minimum_remove_uses, required);
          barrier.validate(state);
          expect(
            TileQuestValidator.validate_tool_solution(
              state,
              barrier.witness,
              remove_uses: required - 1,
            ).valid,
            isFalse,
          );
          expect(
            TileQuestValidator.validate_tool_solution(
              state,
              barrier.witness,
              remove_uses: required,
            ).valid,
            isTrue,
          );
        }
        if (difficulty == 10) {
          expect(state.certified_solution, isEmpty);
          continue;
        }
        final engine = TileQuestEngine(state);
        for (final id in state.certified_solution) {
          expect(replay_certificate_step(engine, id).accepted, isTrue);
        }
        expect(engine.state.status, TileQuestStatus.won);
        expect(engine.state.tools_used, required);
      }
    },
  );
}
