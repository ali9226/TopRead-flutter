// ignore_for_file: non_constant_identifier_names
import 'dart:io';

import 'package:app/pages/tile_quest/game/config.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/tile_palette.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the engine and renderer share exactly the requested fifteen icons', () {
    expect(quest_tile_assets, <String>[
      'watermelon',
      'strawberry',
      'pink_flower',
      'blueberries',
      'carrot',
      'apple',
      'grapes',
      'lemon',
      'mushroom',
      'snowflake',
      'potion',
      'leaf',
      'shell',
      'avocado',
      'blue_gem',
    ]);
    expect(TileQuestConfig.max_tile_types, quest_tile_assets.length);
    expect(quest_tile_assets.toSet(), hasLength(quest_tile_assets.length));
    for (final name in quest_tile_assets) {
      expect(File('assets/img/game/tile_$name.png').existsSync(), isTrue);
    }
  });

  test(
    'every difficulty generates only distinct supported visual identities',
    () {
      for (var difficulty = 1; difficulty <= 10; difficulty++) {
        for (final seed in <int>[17, 91, 3107]) {
          final state = TileQuestGenerator.generate(
            level: 2,
            difficulty: difficulty,
            seed: seed,
          );
          final types = state.tiles.map((tile) => tile.type).toSet();
          expect(
            types.length,
            DifficultyProfile.for_difficulty(difficulty).type_count,
          );
          expect(
            types,
            everyElement(inInclusiveRange(0, quest_tile_assets.length - 1)),
          );
          expect(
            types.map((type) => quest_tile_assets[type]).toSet(),
            hasLength(types.length),
          );
        }
      }
    },
  );
}
