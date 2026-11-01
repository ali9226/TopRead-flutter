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
        expect(
          top,
          hasLength(
            TileQuestLayoutPatterns.cap_count_for_layers(profile.layers),
          ),
        );
        if (difficulty == 8) {
          expect(top, hasLength(6));
          continue;
        }
        expect(top, hasLength(8));
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
    'half-x and quarter-y phases have consistent gaps and no same-layer overlap',
    () {
      for (var seed = 0; seed < 24; seed++) {
        final state = TileQuestGenerator.generate(level: 2, seed: seed);
        for (final tile in state.tiles.where(_central)) {
          // TODO x 半格（并排两牌各挡一半）、y 四分格（把同位叠柱摊薄）。
          final x_phase = (tile.x - TileQuestLayoutPatterns.grid_gap / 2) * 2;
          final y_phase = (tile.y - TileQuestLayoutPatterns.grid_gap / 2) * 4;
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

  test('同位叠柱有上限：没有任何位置需要反复点超过 max_exact_stack 次', () {
    // TODO 难度 10 的容量核（_append_barrier）是刻意把门牌堆在一格的必败设计，
    // TODO 不受本上限约束；1-9 才是普通牌阵，必须封顶。
    for (final difficulty in [6, 8, 9, 9.5]) {
      for (final seed in [0, 17, 730, 104729]) {
        final state = TileQuestGenerator.generate(
          level: 2,
          seed: seed,
          difficulty: difficulty,
        );
        final by_cell = <String, int>{};
        for (final tile in state.tiles) {
          final key = '${tile.x}:${tile.y}';
          by_cell[key] = (by_cell[key] ?? 0) + 1;
        }
        for (final entry in by_cell.entries) {
          expect(
            entry.value,
            lessThanOrEqualTo(TileQuestLayoutPatterns.max_exact_stack),
            reason: 'difficulty $difficulty seed $seed cell ${entry.key}',
          );
        }
      }
    }
  });

  test('没有孤立叠柱：每根叠柱都被并排牌压住', () {
    // TODO 参考《羊了个羊》：绝不允许「一个格子孤零零一直堆」——那种位置
    // TODO 连点十次都点不完，玩家会觉得被耍。叠柱必须被并排牌遮住，
    // TODO 揭开后看不穿下面还有多深。
    // TODO 辅助牌岛是孤立牌堆的重灾区，必须严格 ≥2 张并排遮挡；
    // TODO 主阵深叠柱（≥3 张）同样必须 ≥2；主阵轮廓边界格几何上只有一侧
    // TODO 有牌，那里不叠柱即可（≤2 张）。
    for (final difficulty in [6, 8, 9, 9.5]) {
      for (final seed in [0, 17, 730, 104729]) {
        final state = TileQuestGenerator.generate(
          level: 2,
          seed: seed,
          difficulty: difficulty,
        );
        final by_cell = <String, List<TileQuestTile>>{};
        for (final tile in state.tiles) {
          by_cell.putIfAbsent('${tile.x}:${tile.y}', () => []).add(tile);
        }
        for (final entry in by_cell.entries) {
          final cell = entry.value.first;
          if (entry.value.length < 2) continue;
          final helper = cell.region_id.startsWith('side_');
          if (!helper && entry.value.length < 3) continue;
          final cover = <String>{};
          for (final other in state.tiles) {
            if (other.id == cell.id) continue;
            if ((other.y - cell.y).abs() > 1.2) continue;
            final dx = (other.x - cell.x).abs();
            if (dx < .2 || dx > .9) continue;
            if (!TileQuestGeometry.overlaps(cell, other) &&
                !TileQuestGeometry.overlaps(other, cell)) {
              continue;
            }
            cover.add('${other.x}:${other.y}');
          }
          expect(
            cover.length,
            greaterThanOrEqualTo(2),
            reason:
                'difficulty $difficulty seed $seed '
                'cell ${entry.key} region=${cell.region_id} '
                'n=${entry.value.length} 只有 ${cover.length} 张相邻牌遮挡',
          );
        }
      }
    }
  });

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
    // TODO 同位叠柱封顶后牌摊到更多格位，遮挡链从 40 层略降到 35 层——
    // TODO 用一点链深换「同一处不必连点十次」的点击体验，性价比更高。
    expect(exposed_layers, greaterThanOrEqualTo(35));
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
        final required = difficulty == 10 ? 3 : 0;
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
