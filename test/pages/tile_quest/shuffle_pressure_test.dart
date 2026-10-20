// ignore_for_file: non_constant_identifier_names
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/game/validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final difficulty in [8, 9]) {
    test('difficulty $difficulty Shuffle always succeeds and preserves stock', () {
      for (var seed = 0; seed < 12; seed++) {
        for (final held in [false, true]) {
          final engine = TileQuestEngine(
            TileQuestGenerator.generate(
              level: 2,
              difficulty: difficulty,
              seed: seed,
            ),
          );
          if (held) {
            final opening = engine.state.certified_solution.take(6).toList();
            for (final id in opening.take(5)) {
              expect(engine.tap_tile(id).accepted, isTrue);
            }
            if (engine.state.status == TileQuestStatus.playing) {
              engine.remove();
            }
            if (opening.isNotEmpty &&
                engine.state.status == TileQuestStatus.playing) {
              engine.tap_tile(opening.last);
            }
          }
          if (engine.state.status != TileQuestStatus.playing) continue;
          final before = engine.state;
          final before_types =
              before.tiles.map((tile) => tile.type).toList()..sort();
          final result = engine.shuffle(seed: seed + 99);
          expect(
            result.accepted,
            isTrue,
            reason: '$difficulty/$seed/$held: ${result.reason}',
          );
          expect(engine.state.tray, before.tray);
          expect(engine.state.reserve, before.reserve);
          expect(
            engine.state.tiles.map((tile) => tile.type).toList()..sort(),
            before_types,
          );
          expect(engine.state.certified_solution, isEmpty);
          expect(engine.state.tools[TileQuestTool.shuffle], 0);
          TileQuestValidator.validate_state(engine.state);
        }
      }
    });
  }
}
