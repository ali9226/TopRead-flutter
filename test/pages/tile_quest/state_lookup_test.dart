// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:flutter_test/flutter_test.dart';

TileQuestState _state(List<TileQuestTile> tiles) => TileQuestState(
  tiles: tiles,
  level: 1,
  seed: 71,
  challenge_id: 'indexed-state',
);

void main() {
  test(
    'identity index resolves sparse unordered ids to the original tiles',
    () {
      final tiles = <TileQuestTile>[
        for (var index = 0; index < 600; index++)
          TileQuestTile(
            id: (599 - index) * 17,
            type: index % 3,
            layer: 0,
            x: 0,
            y: 0,
          ),
      ];
      final state = _state(tiles);
      for (final tile in tiles) {
        expect(state.tile_by_id(tile.id), same(tile));
      }
      expect(() => state.tile_by_id(-1), throwsStateError);
      expect(() => state.tile_by_id(1), throwsStateError);
    },
  );

  test('copying a snapshot cannot reuse stale tile types or removal flags', () {
    final tiles = <TileQuestTile>[
      for (var id = 0; id < 3; id++)
        TileQuestTile(id: id, type: 0, layer: 0, x: 0, y: 0),
    ];
    final before = _state(tiles);
    expect(before.tile_by_id(1), same(tiles[1]));
    final changed = tiles[1].copy_with(type: 2, is_removed: true);
    final after = before.copy_with(tiles: [tiles[0], changed, tiles[2]]);
    expect(after.tile_by_id(1), same(changed));
    expect(before.tile_by_id(1), same(tiles[1]));
    expect(before.tile_by_id(1).is_removed, isFalse);
    expect(after.tile_by_id(1).type, 2);
    expect(after.tile_by_id(1).is_removed, isTrue);
  });

  test(
    'indexing never masks duplicate tile ids during state or save validation',
    () {
      final duplicate = _state(const [
        TileQuestTile(id: 0, type: 0, layer: 0, x: 0, y: 0),
        TileQuestTile(id: 0, type: 0, layer: 0, x: 1, y: 0),
        TileQuestTile(id: 2, type: 0, layer: 0, x: 2, y: 0),
      ]);
      // Warm the index before validation so duplicate rejection cannot depend on
      // whether a caller or painter happened to perform an identity lookup first.
      duplicate.tile_by_id(0);
      expect(() => TileQuestEngine(duplicate), throwsFormatException);
      expect(
        () => TileQuestState.from_json(duplicate.to_json()),
        throwsFormatException,
      );
    },
  );
}
