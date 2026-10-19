// ignore_for_file: non_constant_identifier_names
import 'dart:io';

import 'package:app/pages/tile_quest/game/config.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/tile_palette.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the engine and renderer share exactly the requested fifteen icons', () {
    expect(quest_tile_assets, <String>[
      'mushroom',
      'carrot',
      'watermelon',
      'lemon',
      'shovel',
      'glove',
      'leaf',
      'strawberry',
      'milk_bottle',
      'scissors',
      'hay',
      'yarn',
      'star',
      'grapes',
      'snowflake',
    ]);
    expect(TileQuestConfig.max_tile_types, quest_tile_assets.length);
    expect(quest_tile_assets.toSet(), hasLength(quest_tile_assets.length));
    for (var type = 0; type < quest_tile_assets.length; type++) {
      expect(
        quest_tile_asset_path(type),
        'assets/img/tile_quest/icons/tile_${quest_tile_assets[type]}.png',
      );
      expect(File(quest_tile_asset_path(type)).existsSync(), isTrue);
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
