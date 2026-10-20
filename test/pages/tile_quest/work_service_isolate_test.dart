// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/tile_quest/game/config.dart';
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/game/validator.dart';
import 'package:app/pages/tile_quest/services/work_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'native worker preserves snapshots and Undo across a full level shuffle',
    () async {
      final work = TileQuestIsolateWork();
      final generated = await work.generate(
        level: 2,
        seed: 58,
        unlocked_level: 2,
        challenge_id: 'native-worker-shuffle',
      );
      expect(
        generated.tiles.length,
        DifficultyProfile.for_difficulty(
          TileQuestConfig.gameDifficulty,
        ).tile_count,
      );
      final engine = TileQuestEngine(generated);
      final tapped_id = generated.certified_solution.first;
      expect(engine.tap_tile(tapped_id).accepted, isTrue);
      final snapshot = engine.export_json();
      final prepared = await work.shuffle(snapshot, seed: 9127);
      expect(prepared.result.accepted, isTrue, reason: prepared.result.reason);
      expect(engine.export_json(), snapshot);
      expect(prepared.result.before.to_json(), engine.state.to_json());
      expect(prepared.result.after, same(prepared.engine.state));
      expect(prepared.engine.state.tray, [tapped_id]);
      expect(prepared.engine.state.tile_by_id(tapped_id).is_removed, isTrue);
      // 纯随机洗牌不保证有解，只校验状态结构与库存。
      expect(prepared.engine.state.certified_solution, isEmpty);
      expect(prepared.engine.undo().accepted, isTrue);
      expect(prepared.engine.state.tile_by_id(tapped_id).is_removed, isFalse);
      expect(prepared.engine.state.tray, isEmpty);
      expect(prepared.engine.state.tools[TileQuestTool.shuffle], 0);
      expect(prepared.engine.state.tools[TileQuestTool.undo], 0);
      TileQuestValidator.validate_state(prepared.engine.state);
    },
  );

  test(
    'native worker rejects malformed saves before preparing an animation',
    () async {
      final state = TileQuestState(
        tiles: const [
          TileQuestTile(id: 0, type: 0, layer: 0, x: 0, y: 0),
          TileQuestTile(id: 0, type: 0, layer: 0, x: 1, y: 0),
          TileQuestTile(id: 2, type: 0, layer: 0, x: 2, y: 0),
        ],
        level: 1,
        seed: 71,
        challenge_id: 'malformed-worker-state',
      );
      await expectLater(
        TileQuestIsolateWork().shuffle({
          'version': TileQuestConfig.save_version,
          'state': state.to_json(),
          'undo_state': null,
        }, seed: 17),
        throwsFormatException,
      );
    },
  );
}
