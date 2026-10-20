// ignore_for_file: non_constant_identifier_names
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/index.dart';
import 'package:app/pages/tile_quest/logic.dart';
import 'package:app/pages/tile_quest/services/feedback_service.dart';
import 'package:app/pages/tile_quest/services/save_service.dart';
import 'package:app/pages/tile_quest/services/work_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Store implements TileQuestSaveStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String next) async => value = next;
}
class _Feedback implements TileQuestFeedbackService {
  @override
  Future<void> play(TileQuestFeedbackEvent event) async {}
}
class _Work implements TileQuestWorkService {
  @override
  Future<TileQuestState> generate({
    required int level,
    required int seed,
    required int unlocked_level,
    String? challenge_id,
  }) async => TileQuestGenerator.generate(
    level: level,
    seed: seed,
    unlocked_level: unlocked_level,
    challenge_id: challenge_id,
  );
  @override
  Future<TileQuestPreparedShuffle> shuffle(
    Map<String, dynamic> engine_json, {
    required int seed,
  }) async {
    final engine = TileQuestEngine.restore(engine_json);
    return TileQuestPreparedShuffle(engine: engine, result: engine.shuffle(seed: seed));
  }
}

void main() {
  testWidgets('restart button opens confirm dialog', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final logic = TileQuestLogic(
      save_service: TileQuestSaveService(
        store: _Store(),
        encode_snapshot: encode_tile_quest_snapshot,
      ),
      work_service: _Work(),
      feedback_service: _Feedback(),
      next_seed: () => 730,
      now_ms: () => 0,
      enable_timer: false,
    );
    await tester.pumpWidget(MaterialApp(home: TileQuestPage(logic: logic)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tile_quest_settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tile_quest_restart')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tile_quest_confirm_restart')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
