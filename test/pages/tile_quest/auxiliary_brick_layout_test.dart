// ignore_for_file: non_constant_identifier_names
import 'dart:math';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/geometry.dart';
import 'package:app/pages/tile_quest/game/layout_patterns.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Read the real generated geometry after identity shuffling and mirroring.
Map<int, List<TileQuestTile>> _layers(TileQuestState state, String region) {
  final result = <int, List<TileQuestTile>>{};
  for (final tile in state.tiles.where((tile) => tile.region_id == region)) {
    result.putIfAbsent(tile.layer, () => []).add(tile);
  }
  for (final row in result.values) {
    row.sort((left, right) => left.x.compareTo(right.x));
  }
  return result;
}

void main() {
  test(
    'all difficulty helper islands are continuous real half-grid brick bonds',
    () {
      expect(TileQuestLayoutPatterns.grid_gap, 0);
      for (var difficulty = 1; difficulty <= 10; difficulty++) {
        for (var sample = 0; sample < 12; sample++) {
          final seed = 104729 * sample;
          final state = TileQuestGenerator.generate(
            level: 2,
            difficulty: difficulty,
            seed: seed,
          );
          for (final region in ['side_top', 'side_bottom']) {
            final layers = _layers(state, region);
            final levels = layers.keys.toList()..sort();
            final reason = '$difficulty / $seed / $region';
            expect(levels.length, greaterThanOrEqualTo(3), reason: reason);
            for (final row in layers.values) {
              expect(row.length, greaterThanOrEqualTo(2), reason: reason);
              for (var index = 0; index < row.length; index++) {
                final tile = row[index];
                expect(tile.width, 1);
                expect(tile.height, 1);
                expect(tile.y, region == 'side_top' ? 0 : 8);
                if (index == 0) continue;
                final previous = row[index - 1];
                expect(previous.x + previous.width, tile.x, reason: reason);
                expect(TileQuestGeometry.overlap_area(previous, tile), 0);
              }
            }
            for (var layer = 1; layer < levels.length; layer++) {
              final lower = layers[levels[layer - 1]]!;
              final upper = layers[levels[layer]]!;
              expect((upper.length - lower.length).abs(), 1, reason: reason);
              for (var index = 0; index < upper.length; index++) {
                final tile = upper[index];
                final supports = lower
                    .where((value) => TileQuestGeometry.overlaps(value, tile))
                    .toList();
                final is_wide_shoulder =
                    upper.length > lower.length &&
                    (index == 0 || index == upper.length - 1);
                expect(
                  supports.length,
                  is_wide_shoulder ? 1 : 2,
                  reason: reason,
                );
                for (final support in supports) {
                  expect((support.x - tile.x).abs(), .5, reason: reason);
                  expect(
                    TileQuestGeometry.occlusion_area_ratio(support, tile),
                    .5,
                  );
                }
              }
            }
            // Each complete island still fits its original 6×1 reference bounds.
            final tiles = layers.values.expand((row) => row);
            final width =
                tiles.map((tile) => tile.x + tile.width).reduce(max) -
                tiles.map((tile) => tile.x).reduce(min);
            expect(width, lessThanOrEqualTo(6), reason: reason);
          }
        }
      }
    },
  );

  test(
    'a helper lower tile waits for every overlapping upper brick to leave',
    () {
      final state = TileQuestGenerator.generate(
        level: 2,
        difficulty: 8,
        seed: 17,
      );
      final graph = TileQuestGeometry(state.tiles);
      final layers = _layers(state, 'side_top');
      final levels = layers.keys.toList()..sort();
      final top_layer = levels.last;
      final top = layers[top_layer]!;
      final lower = layers[levels[levels.length - 2]]!.firstWhere(
        (tile) =>
            top
                .where((upper) => TileQuestGeometry.overlaps(tile, upper))
                .length ==
            2,
      );
      final covering = top
          .where((upper) => TileQuestGeometry.overlaps(lower, upper))
          .toList();
      final once = graph.refresh([
        for (final tile in state.tiles)
          tile.copy_with(is_removed: tile.id == covering.first.id),
      ]);
      expect(once.firstWhere((tile) => tile.id == lower.id).is_blocked, isTrue);
      final twice = graph.refresh([
        for (final tile in once)
          tile.copy_with(
            is_removed: tile.is_removed || tile.id == covering.last.id,
          ),
      ]);
      expect(
        twice.firstWhere((tile) => tile.id == lower.id).is_blocked,
        isFalse,
      );
    },
  );
}
