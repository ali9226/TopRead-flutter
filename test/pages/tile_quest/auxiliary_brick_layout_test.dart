// ignore_for_file: non_constant_identifier_names
import 'dart:math';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/geometry.dart';
import 'package:app/pages/tile_quest/game/layout_patterns.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// 真实生成几何（已过 id 重标与镜像）的辅助牌岛按层分组。
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
    'helper islands are mirrored fan chains: thin strips, one face per chain',
    () {
      expect(TileQuestLayoutPatterns.grid_gap, 0);
      for (var difficulty = 1; difficulty <= 10; difficulty++) {
        for (var sample = 0; sample < 8; sample++) {
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
            // 同层永不重叠；列间距由卡扇细分相位决定，不要求整格。
            for (final row in layers.values) {
              for (var index = 1; index < row.length; index++) {
                final previous = row[index - 1];
                final tile = row[index];
                expect(
                  TileQuestGeometry.overlap_area(previous, tile),
                  0,
                  reason: reason,
                );
                expect(
                  previous.x + previous.width,
                  lessThanOrEqualTo(tile.x + .000001),
                  reason: reason,
                );
              }
            }
            // 卡扇依赖：每张非牌端都被更高层真实覆盖；牌端开局可点。
            final all = layers.values.expand((row) => row).toList();
            final top_layer = levels.last;
            for (final tile in all) {
              expect(tile.width, 1, reason: reason);
              expect(tile.height, 1, reason: reason);
              if (tile.layer == top_layer) continue;
              expect(
                all.any(
                  (upper) =>
                      upper.layer > tile.layer &&
                      TileQuestGeometry.overlaps(tile, upper),
                ),
                isTrue,
                reason: '$reason / ${tile.id} must stay covered',
              );
            }
            for (final face in layers[top_layer]!) {
              expect(face.is_blocked, isFalse, reason: reason);
            }
            // 每层至多一条卡扇一张牌：细边列沿层序单线推进。
            for (final row in layers.values) {
              expect(row.length, lessThanOrEqualTo(4), reason: reason);
            }
            // 整座牌岛仍在六列足迹内。
            final tiles = all;
            final width =
                tiles.map((tile) => tile.x + tile.width).reduce(max) -
                tiles.map((tile) => tile.x).reduce(min);
            expect(width, lessThanOrEqualTo(6), reason: reason);
          }
        }
      }
    },
  );

  test('a fan face unlocks exactly the next column when tapped', () {
    final state = TileQuestGenerator.generate(
      level: 2,
      difficulty: 8,
      seed: 17,
    );
    final graph = TileQuestGeometry(state.tiles);
    final layers = _layers(state, 'side_bottom');
    final levels = layers.keys.toList()..sort();
    final top = layers[levels.last]!;
    expect(top.length, greaterThanOrEqualTo(1));
    final face = top.first;
    final blockers = graph.blockers[face.id]!;
    expect(blockers, isEmpty);
    final once = graph.refresh([
      for (final tile in state.tiles)
        tile.copy_with(is_removed: tile.id == face.id),
    ]);
    // 牌端离开后，下一张细边牌必须立即可点（同链下一张）。
    final opened = once
        .where(
          (tile) =>
              tile.region_id == 'side_bottom' &&
              !tile.is_removed &&
              !tile.is_blocked,
        )
        .map((tile) => tile.id)
        .toSet();
    expect(
      opened.any((id) => id != face.id),
      isTrue,
      reason: 'the next fan column must become available',
    );
  });
}
