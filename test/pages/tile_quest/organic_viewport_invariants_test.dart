// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:math' as math;
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/geometry.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/widgets/landscape_board_layout.dart';
import 'package:app/pages/tile_quest/widgets/scene_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _epsilon = .000001;
const _viewports = [
  Size(320, 568),
  Size(390, 844),
  Size(430, 844),
  Size(720, 320),
  Size(750, 343),
  Size(844, 390),
];

bool _central(TileQuestTile tile) =>
    tile.region_id == 'main' || tile.region_id == 'core';

/// Sorting physical slots deliberately excludes randomized ids and sprites.
/// A palette shuffle or mirrored certificate cannot fake geometric diversity.
String _shape_signature(Iterable<TileQuestTile> tiles) {
  final slots =
      tiles
          .map(
            (tile) =>
                '${tile.region_id}:${tile.layer}:${tile.x.toStringAsFixed(3)}:'
                '${tile.y.toStringAsFixed(3)}',
          )
          .toList()
        ..sort();
  return slots.join('|');
}

void main() {
  test('seeded main silhouettes retain genuine all-layer empty channels', () {
    final cuts = <String>{};
    for (var seed = 0; seed < 32; seed++) {
      final state = TileQuestGenerator.generate(
        level: 2,
        difficulty: 8,
        seed: seed,
      );
      final main = state.tiles.where(_central).toList();
      final empty = <String>[];
      // The seven-cell storage world leaves one exterior column. These
      // probes stay inside both possible six-column mirrored footprints,
      // and one full row away from the upper/lower helper groups.
      for (var row = 3; row <= 5; row++) {
        for (var column = 1; column <= 5; column++) {
          final cell = Rect.fromLTWH(
            column.toDouble(),
            row.toDouble(),
            1,
            1,
          ).deflate(.005);
          if (main.every(
            (tile) => !cell.overlaps(
              Rect.fromLTWH(tile.x, tile.y, tile.width, tile.height),
            ),
          )) {
            empty.add('$column:$row');
          }
        }
      }
      expect(empty, isNotEmpty, reason: 'No real through-layer cut: $seed');
      cuts.add(empty.join('|'));
    }
    // These signatures ignore ids, types and z. Recoloring the same filled
    // pyramid cannot satisfy the spatial variety expected from this board.
    expect(cuts.length, greaterThanOrEqualTo(8));
  });

  test(
    'seeded physical contours and exposed main surfaces have substantial variety',
    () {
      final contours = <String>{};
      final exposed = <String>{};
      final anchors = <String>{};
      for (var seed = 0; seed < 32; seed++) {
        final state = TileQuestGenerator.generate(
          level: 2,
          difficulty: 8,
          seed: seed,
        );
        final barrier = state.expert_barrier!;
        final barrier_ids = {...barrier.front_ids, ...barrier.partner_ids};
        final ordinary = state.tiles
            .where((tile) => !barrier_ids.contains(tile.id))
            .toList();
        contours.add(_shape_signature(ordinary));
        exposed.add(
          _shape_signature(
            ordinary.where((tile) => _central(tile) && !tile.is_blocked),
          ),
        );
        final anchor = state.tile_by_id(barrier.front_ids.first);
        anchors.add(
          '${anchor.x.toStringAsFixed(3)}:${anchor.y.toStringAsFixed(3)}',
        );
      }
      expect(contours.length, greaterThanOrEqualTo(24));
      expect(exposed.length, greaterThanOrEqualTo(24));
      expect(anchors.length, greaterThanOrEqualTo(8));
    },
  );

  test(
    'both edge islands share ordinary sprites through real brick-bond dependencies',
    () {
      for (final difficulty in [1, 4, 5, 8, 9, 10]) {
        for (final seed in [0, 1, 17, 730, 104729, 982451653]) {
          final state = TileQuestGenerator.generate(
            level: 2,
            difficulty: difficulty,
            seed: seed,
          );
          final barrier_ids = {
            ...?state.expert_barrier?.front_ids,
            ...?state.expert_barrier?.partner_ids,
          };
          final main_types = state.tiles
              .where((tile) => _central(tile) && !barrier_ids.contains(tile.id))
              .map((tile) => tile.type)
              .toSet();
          for (final region in ['side_top', 'side_bottom']) {
            final helpers = state.tiles
                .where((tile) => tile.region_id == region)
                .toList();
            final layers = <int, List<TileQuestTile>>{};
            for (final tile in helpers) {
              layers.putIfAbsent(tile.layer, () => []).add(tile);
            }
            final levels = layers.keys.toList()..sort();
            expect(levels.length, greaterThanOrEqualTo(3));
            for (var index = 1; index < levels.length; index++) {
              final lower = layers[levels[index - 1]]!;
              final upper = layers[levels[index]]!;
              expect(
                upper.any(
                  (tile) =>
                      lower
                          .where(
                            (support) =>
                                TileQuestGeometry.overlaps(support, tile),
                          )
                          .length ==
                      2,
                ),
                isTrue,
                reason: '$difficulty / $seed / $region / ${levels[index]}',
              );
              expect(
                upper.any(
                  (tile) => lower.any((support) => support.x == tile.x),
                ),
                isFalse,
              );
            }
            expect(
              helpers.map((tile) => tile.type).toSet().intersection(main_types),
              isNotEmpty,
              reason: '$difficulty / $seed / $region',
            );
          }
        }
      }
    },
  );

  test(
    'the mandatory capacity chain is genuinely covered inside the main island',
    () {
      for (final difficulty in [5, 8, 9, 10]) {
        for (var seed = 0; seed < 16; seed++) {
          final state = TileQuestGenerator.generate(
            level: 2,
            difficulty: difficulty,
            seed: seed,
          );
          final barrier = state.expert_barrier!;
          final ids = {...barrier.front_ids, ...barrier.partner_ids};
          final ordinary = state.tiles
              .where((tile) => !ids.contains(tile.id))
              .toList();
          for (final id in ids) {
            final tile = state.tile_by_id(id);
            expect(_central(tile), isTrue);
            expect(tile.is_blocked, isTrue);
            expect(
              ordinary.any((upper) => TileQuestGeometry.overlaps(tile, upper)),
              isTrue,
              reason: '$difficulty / $seed / $id',
            );
          }
          expect(state.tiles.any((tile) => tile.region_id == 'gate'), isFalse);
        }
      }
    },
  );

  test(
    'all seeded islands fit phones in either orientation without shrinking on removal',
    () {
      for (final difficulty in [1, 4, 5, 8, 9, 10]) {
        for (final seed in [0, 1, 17, 730, 104729, 982451653]) {
          final state = TileQuestGenerator.generate(
            level: 2,
            difficulty: difficulty,
            seed: seed,
          );
          expect(QuestLandscapeBoardLayout(state.tiles).reflowed, isTrue);
          final removed = state.copy_with(
            tiles: [
              for (final tile in state.tiles) tile.copy_with(is_removed: true),
            ],
          );
          for (final size in _viewports) {
            final layout = QuestSceneLayout(size, state);
            final empty = QuestSceneLayout(size, removed);
            for (final tile in state.tiles) {
              final rect = layout.board_tile(tile);
              expect(
                rect.left,
                greaterThanOrEqualTo(layout.board.left - _epsilon),
              );
              expect(
                rect.top,
                greaterThanOrEqualTo(layout.board.top - _epsilon),
              );
              expect(
                rect.right,
                lessThanOrEqualTo(layout.board.right + _epsilon),
              );
              expect(
                rect.bottom,
                lessThanOrEqualTo(layout.board.bottom + _epsilon),
              );
              expect(empty.board_tile(tile), rect);
            }
            final width = state.tiles
                .map((tile) => layout.board_tile(tile).width)
                .reduce(math.min);
            if (layout.landscape) {
              expect(width, greaterThanOrEqualTo(size.height >= 366 ? 44 : 37));
            }
          }
        }
      }
    },
  );
}
