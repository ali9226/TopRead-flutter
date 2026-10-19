// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:math' as math;
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/geometry.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/widgets/landscape_board_layout.dart';
import 'package:app/pages/tile_quest/widgets/scene_layout.dart';
import 'package:app/pages/tile_quest/widgets/tile_surface_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _epsilon = .000001;
const _viewports = <Size>[
  Size(720, 320),
  Size(844, 390),
  // 以安全区域扣除两侧刘海、手势区后的实际空间测试。
  Size(750, 343),
  Size(800, 366),
  Size(1194, 760),
];

double _screen_occlusion(Rect lower, Rect upper) {
  final width =
      math.min(lower.right, upper.right) - math.max(lower.left, upper.left);
  final height =
      math.min(lower.bottom, upper.bottom) - math.max(lower.top, upper.top);
  return width <= 0 || height <= 0
      ? 0
      : width * height / (lower.width * lower.height);
}

void _expect_inside(Rect inner, Rect outer) {
  expect(inner.left, greaterThanOrEqualTo(outer.left - _epsilon));
  expect(inner.top, greaterThanOrEqualTo(outer.top - _epsilon));
  expect(inner.right, lessThanOrEqualTo(outer.right + _epsilon));
  expect(inner.bottom, lessThanOrEqualTo(outer.bottom + _epsilon));
}

void main() {
  test(
    'two full-width auxiliary islands become six-row columns without losing dependencies',
    () {
      final tiles = <TileQuestTile>[
        for (var row = 0; row < 5; row++)
          for (var column = 0; column < 6; column++)
            TileQuestTile(
              id: row * 6 + column,
              type: 0,
              region_id: 'main',
              layer: 21,
              x: column + .012,
              y: row + 2.012,
              width: .976,
              height: .976,
            ),
        for (var side = 0; side < 2; side++)
          for (var layer = 0; layer < 4; layer++)
            for (var column = 0; column < 6; column++)
              TileQuestTile(
                id: 30 + side * 24 + layer * 6 + column,
                type: column % 3,
                region_id: side == 0 ? 'side_top' : 'side_bottom',
                layer: layer,
                x: column + .012,
                y: side == 0 ? .012 : 8.012,
                width: .976,
                height: .976,
              ),
      ];
      final reflow = QuestLandscapeBoardLayout(tiles);
      expect(reflow.reflowed, isTrue);
      final state = TileQuestState(
        tiles: tiles,
        level: 2,
        seed: 0,
        challenge_id: 'two-full-auxiliary-islands',
      );
      final layout = QuestSceneLayout(const Size(844, 390), state);
      for (final lower in tiles) {
        _expect_inside(layout.board_tile(lower), layout.board);
        for (final upper in tiles) {
          expect(
            _screen_occlusion(
              layout.board_tile(lower),
              layout.board_tile(upper),
            ),
            closeTo(
              TileQuestGeometry.occlusion_area_ratio(lower, upper),
              _epsilon,
            ),
            reason: '${lower.id} / ${upper.id}',
          );
        }
      }
      expect(layout.board_tile(tiles.first).width, greaterThan(44));
      for (final region in ['side_top', 'side_bottom']) {
        final positions = tiles
            .where((tile) => tile.region_id == region)
            .map(reflow.position)
            .toSet();
        expect(positions.map((position) => position.dx).toSet(), hasLength(1));
        expect(positions.map((position) => position.dy).toSet(), hasLength(6));
      }
    },
  );

  test(
    'horizontal islands preserve every pairwise occlusion at all difficulties',
    () {
      for (var difficulty = 1; difficulty <= 10; difficulty++) {
        for (final seed in [0, 1, 17, 730]) {
          final state = TileQuestGenerator.generate(
            level: 2,
            difficulty: difficulty,
            seed: seed,
          );
          final reflow = QuestLandscapeBoardLayout(state.tiles);
          expect(reflow.reflowed, isTrue, reason: '$difficulty / $seed');
          final layout = QuestSceneLayout(const Size(844, 390), state);
          final rectangles = [
            for (final tile in state.tiles) layout.board_tile(tile),
          ];
          var largest_error = 0.0;
          for (var left = 0; left < state.tiles.length; left++) {
            for (var right = 0; right < state.tiles.length; right++) {
              final logical = TileQuestGeometry.occlusion_area_ratio(
                state.tiles[left],
                state.tiles[right],
              );
              final visual = _screen_occlusion(
                rectangles[left],
                rectangles[right],
              );
              largest_error = math.max(largest_error, (logical - visual).abs());
            }
          }
          expect(
            largest_error,
            lessThan(_epsilon),
            reason: '$difficulty / $seed',
          );
        }
      }
    },
  );

  test(
    'brick-bond helpers keep half-row supports and full card scale in landscape',
    () {
      for (var difficulty = 1; difficulty <= 10; difficulty++) {
        for (final seed in [2, 3, 11, 104729]) {
          final state = TileQuestGenerator.generate(
            level: 2,
            difficulty: difficulty,
            seed: seed,
          );
          final reflow = QuestLandscapeBoardLayout(state.tiles);
          expect(reflow.reflowed, isTrue, reason: '$difficulty / $seed');
          for (final size in [_viewports.first, _viewports[1]]) {
            final layout = QuestSceneLayout(size, state);
            final tutorial = QuestSceneLayout(
              size,
              TileQuestGenerator.generate(level: 1, seed: seed),
            );
            expect(layout.unit, closeTo(tutorial.unit, _epsilon));
            for (final region in ['side_top', 'side_bottom']) {
              final helpers = state.tiles
                  .where((tile) => tile.region_id == region)
                  .toList();
              final first_layer = helpers
                  .map((tile) => tile.layer)
                  .reduce(math.min);
              var crossed_supports = 0;
              for (final upper in helpers) {
                final upper_rect = layout.board_tile(upper);
                _expect_inside(upper_rect, layout.board);
                // No fixed inset survives in new stock: every helper retains
                // the shared full-width scale instead of shrinking after reflow.
                expect(upper_rect.width, closeTo(layout.unit, _epsilon));
                if (upper.layer == first_layer) continue;
                final supports = helpers
                    .where(
                      (lower) =>
                          lower.layer == upper.layer - 1 &&
                          TileQuestGeometry.overlaps(lower, upper),
                    )
                    .toList();
                expect(supports.length, inInclusiveRange(1, 2));
                for (final lower in supports) {
                  final lower_rect = layout.board_tile(lower);
                  expect(
                    _screen_occlusion(lower_rect, upper_rect),
                    closeTo(
                      TileQuestGeometry.occlusion_area_ratio(lower, upper),
                      _epsilon,
                    ),
                  );
                  // An upright helper island becomes a vertical brick bond.
                  // Neighbouring layers must remain half a card apart, rather
                  // than being collapsed back into the former same-place pile.
                  expect(
                    (lower_rect.center.dy - upper_rect.center.dy).abs(),
                    closeTo(layout.unit_y / 2, _epsilon),
                  );
                }
                if (supports.length == 2) {
                  crossed_supports++;
                  expect(
                    upper_rect.center.dy,
                    closeTo(
                      (layout.board_tile(supports[0]).center.dy +
                              layout.board_tile(supports[1]).center.dy) /
                          2,
                      _epsilon,
                    ),
                  );
                }
              }
              expect(
                crossed_supports,
                greaterThan(0),
                reason: '$difficulty / $seed / $region / $size',
              );
            }
          }
        }
      }
    },
  );

  test(
    'landscape boards use playable tile sizes and separate all control bounds',
    () {
      final state = TileQuestGenerator.generate(
        level: 2,
        difficulty: 10,
        seed: 17,
      );
      for (final size in _viewports) {
        final layout = QuestSceneLayout(size, state);
        final minimum_width = size.height >= 366 ? 44.0 : 37.0;
        expect(layout.landscape, isTrue);
        expect(
          layout.board_tile(state.tiles.first).width,
          greaterThanOrEqualTo(minimum_width),
          reason: '$size',
        );
        expect(layout.header.height, 44);
        expect(layout.board.top, greaterThan(layout.header.bottom));
        expect(layout.board.overlaps(layout.reserve), isFalse);
        expect(layout.board.overlaps(layout.tray), isFalse);
        expect(layout.board.overlaps(layout.tools), isFalse);
        expect(layout.tools.height, greaterThanOrEqualTo(44));
        final first_slot = layout.tray_tile(0);
        final last_slot = layout.tray_tile(QuestSceneLayout.slot_count - 1);
        expect(
          first_slot.width,
          lessThanOrEqualTo(QuestSceneLayout.maximum_tray_edge),
        );
        expect(
          (first_slot.left + last_slot.right) / 2,
          closeTo(layout.tray.center.dx, _epsilon),
        );
        for (final bounds in [
          layout.header,
          layout.board,
          layout.tray,
          layout.reserve,
          layout.tools,
        ]) {
          _expect_inside(bounds, Offset.zero & size);
        }
        for (final tile in state.tiles) {
          _expect_inside(layout.board_tile(tile), layout.board);
        }
        // 消去辅助顶层也不能把其列缩回横排或改变任何尚未消除牌的位置。
        final removed = state.copy_with(
          tiles: state.tiles
              .map((tile) => tile.copy_with(is_removed: true))
              .toList(),
        );
        final empty_layout = QuestSceneLayout(size, removed);
        for (final tile in state.tiles) {
          expect(empty_layout.board_tile(tile), layout.board_tile(tile));
        }
      }
    },
  );

  test(
    'all same-sized screens keep the same card scale through tutorial and every difficulty',
    () {
      for (final size in _viewports) {
        final tutorial = TileQuestGenerator.generate(level: 1, seed: 0);
        final reference = QuestSceneLayout(size, tutorial);
        for (var difficulty = 1; difficulty <= 10; difficulty++) {
          final state = TileQuestGenerator.generate(
            level: 2,
            difficulty: difficulty,
            seed: 730,
          );
          final layout = QuestSceneLayout(size, state);
          expect(layout.unit, closeTo(reference.unit, _epsilon));
          expect(
            layout.unit_y,
            closeTo(
              reference.unit * QuestTileSurfaceStyle.tile_aspect_ratio,
              _epsilon,
            ),
          );
        }
      }
    },
  );

  test(
    'legacy unpartitioned nine-row saves retain their geometry and fit horizontally',
    () {
      final tiles = [
        for (var index = 0; index < 63; index++)
          TileQuestTile(
            id: index,
            type: index % 3,
            layer: 0,
            x: (index % 7).toDouble(),
            y: (index ~/ 7).toDouble(),
          ),
      ];
      final state = TileQuestState(
        tiles: tiles,
        level: 2,
        difficulty: 4,
        seed: 1,
        challenge_id: 'legacy-horizontal',
      );
      final reflow = QuestLandscapeBoardLayout(tiles);
      expect(reflow.reflowed, isFalse);
      for (final tile in tiles) {
        expect(reflow.position(tile), Offset(tile.x, tile.y));
      }
      for (final size in _viewports) {
        final layout = QuestSceneLayout(size, state);
        for (final tile in tiles) {
          _expect_inside(layout.board_tile(tile), layout.board);
        }
      }
    },
  );

  test(
    'unknown regions and cross-island dependencies keep their original positions',
    () {
      final original = TileQuestGenerator.generate(
        level: 2,
        difficulty: 4,
        seed: 730,
      );
      final main = original.tiles.firstWhere(
        (tile) => tile.region_id == 'main',
      );
      final helper = original.tiles.firstWhere(
        (tile) => tile.region_id == 'side_top',
      );
      for (final tiles in <List<TileQuestTile>>[
        original.tiles
            .map(
              (tile) => tile.id == helper.id
                  ? tile.copy_with(region_id: 'custom_helper')
                  : tile,
            )
            .toList(),
        original.tiles
            .map(
              (tile) => tile.id == helper.id
                  ? TileQuestTile(
                      id: tile.id,
                      type: tile.type,
                      layer: tile.layer,
                      region_id: tile.region_id,
                      x: main.x,
                      y: main.y,
                      width: tile.width,
                      height: tile.height,
                    )
                  : tile,
            )
            .toList(),
      ]) {
        final reflow = QuestLandscapeBoardLayout(tiles);
        expect(reflow.reflowed, isFalse);
        for (final tile in tiles) {
          expect(reflow.position(tile), Offset(tile.x, tile.y));
        }
      }
    },
  );
}
