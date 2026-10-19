// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/geometry.dart';
import 'package:app/pages/tile_quest/game/geometry_style.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:flutter_test/flutter_test.dart';

TileQuestTile tile({
  int id = 0,
  int layer = 0,
  double x = 0,
  double y = 0,
  double width = 1,
  double height = 1,
}) => TileQuestTile(
  id: id,
  type: 0,
  layer: layer,
  x: x,
  y: y,
  width: width,
  height: height,
);

void main() {
  test(
    'occlusion threshold compares actual area against the lower rectangle',
    () {
      final lower = tile();
      const threshold = TileQuestGeometryStyle.minimum_occlusion_area_ratio;
      final at_threshold = tile(layer: 1, width: threshold);
      final below_threshold = tile(layer: 1, width: threshold / 2);
      final above_threshold = tile(layer: 1, width: threshold * 2);
      expect(TileQuestGeometry.overlap_area(lower, at_threshold), threshold);
      expect(TileQuestGeometry.overlaps(lower, at_threshold), isFalse);
      expect(TileQuestGeometry.overlaps(lower, below_threshold), isFalse);
      expect(TileQuestGeometry.overlaps(lower, above_threshold), isTrue);

      final large_lower = tile(x: 1, y: 2, width: 2, height: 2);
      final partial_upper = tile(layer: 1, x: 2, y: 3, width: 3);
      expect(TileQuestGeometry.overlap_area(large_lower, partial_upper), 1);
      expect(
        TileQuestGeometry.occlusion_area_ratio(large_lower, partial_upper),
        .25,
      );
    },
  );

  test('edge contact and same-layer neighbors never form blocker edges', () {
    final lower = tile();
    expect(TileQuestGeometry.overlaps(lower, tile(layer: 1, x: 1)), isFalse);
    expect(TileQuestGeometry.overlaps(lower, tile(layer: 1, y: 1)), isFalse);
    expect(TileQuestGeometry.overlaps(lower, tile(layer: 1, x: 2)), isFalse);
    expect(TileQuestGeometry.overlaps(lower, tile(x: .5)), isFalse);
    expect(TileQuestGeometry.overlaps(tile(layer: 2), lower), isFalse);
    expect(
      TileQuestGeometry.overlaps(lower, tile(layer: 1, x: .5, y: .5)),
      isTrue,
    );
  });

  test(
    'an exposed lower layer stays clickable beside a separate high stack',
    () {
      final tiles = [
        tile(id: 0, layer: 1),
        tile(id: 1, layer: 8, x: 3),
        tile(id: 2, layer: 7, x: 3),
        tile(id: 3, layer: 1, x: 1),
      ];
      final geometry = TileQuestGeometry(tiles);
      final refreshed = geometry.refresh(tiles);
      expect(geometry.blockers[0], isEmpty);
      expect(geometry.blockers[2], {1});
      expect(refreshed.map((value) => value.is_blocked), [
        false,
        false,
        true,
        false,
      ]);
    },
  );

  test('a committed tap immediately exposes the next physical layer', () {
    final tiles = [for (var id = 0; id < 3; id++) tile(id: id, layer: id)];
    final geometry = TileQuestGeometry(tiles);
    final engine = TileQuestEngine(
      TileQuestState(
        tiles: geometry.refresh(tiles),
        level: 1,
        seed: 1,
        challenge_id: 'geometry_exposure',
      ),
    );
    expect(engine.state.clickable_tiles.map((value) => value.id), [2]);
    expect(engine.tap_tile(2).accepted, isTrue);
    expect(engine.state.tile_by_id(1).is_blocked, isFalse);
    expect(engine.state.tile_by_id(0).is_blocked, isTrue);
    expect(engine.state.clickable_tiles.map((value) => value.id), [1]);
    expect(engine.tap_tile(1).accepted, isTrue);
    expect(engine.state.clickable_tiles.map((value) => value.id), [0]);
    expect(engine.tap_tile(0).accepted, isTrue);
    expect(engine.state.status, TileQuestStatus.won);
  });

  test('region metadata survives copies and complete save round trips', () {
    final original = TileQuestGenerator.generate(level: 1, seed: 57);
    final state = original.copy_with(
      tiles: [
        for (final value in original.tiles)
          value.copy_with(region_id: value.id.isEven ? 'core' : 'side_top'),
      ],
    );
    final restored = TileQuestState.from_json(state.to_json());
    expect(restored.to_json(), state.to_json());
    final core = state.tiles.first;
    expect(core.copy_with(type: 1, is_removed: true).region_id, core.region_id);
    expect(core.copy_with(region_id: 'side_bottom').region_id, 'side_bottom');
    expect(
      TileQuestTile(id: 4, type: 0, layer: 0, x: 2.5, y: 3.25).region_id,
      'main',
    );
  });

  test(
    'grid diagnostics derive from the authoritative fractional position',
    () {
      final value = TileQuestTile(
        id: 4,
        type: 0,
        layer: 2,
        region_id: 'core',
        x: 2.5,
        y: 3.25,
      );
      expect(value.grid_row, 3);
      expect(value.grid_column, 2);
      expect(value.offset_x, .5);
      expect(value.offset_y, .25);
      expect(value.grid_column + value.offset_x, value.x);
      expect(value.grid_row + value.offset_y, value.y);
    },
  );

  test(
    'legacy saves without region metadata retain their original geometry',
    () {
      final state = TileQuestGenerator.generate(level: 1, seed: 57);
      final json = state.to_json();
      for (final raw in json['tiles'] as List) {
        (raw as Map).remove('region_id');
      }
      final restored = TileQuestState.from_json(json);
      expect(
        restored.tiles.every((value) => value.region_id == 'main'),
        isTrue,
      );
      expect(restored.to_json(), state.to_json());
    },
  );

  test('malformed region metadata is rejected instead of defaulted', () {
    final state = TileQuestGenerator.generate(level: 1, seed: 57);
    for (final invalid in [null, 4, '', 'Core', 'side top', 'a' * 33]) {
      final json = state.to_json();
      ((json['tiles'] as List).first as Map)['region_id'] = invalid;
      expect(
        () => TileQuestState.from_json(json),
        throwsFormatException,
        reason: 'Invalid region identifier: $invalid',
      );
    }
  });
}
