// ignore_for_file: non_constant_identifier_names
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/game/validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'certificate_replay.dart';

List<int> _lead_path(TileQuestState state) {
  final barrier = state.expert_barrier;
  if (barrier == null) return state.certified_solution;
  if (state.certified_solution.isEmpty) return barrier.lead_solution;
  final core_ids = {...barrier.front_ids, ...barrier.partner_ids};
  // Shuffle can replace the ordinary region's order. Its current certificate
  // carries the actual continuation; the barrier retains the original full
  // lead order for untouched-board reconstruction and its capacity witness.
  return state.certified_solution
      .takeWhile((id) => !core_ids.contains(id))
      .where((id) => id >= 0)
      .toList();
}

void main() {
  for (final difficulty in [8, 9]) {
    test('difficulty $difficulty Shuffle retains mixed six-slot pressure', () {
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
            final opening = _lead_path(engine.state).take(6).toList();
            for (final id in opening.take(5)) {
              expect(engine.tap_tile(id).accepted, isTrue);
            }
            expect(engine.remove().accepted, isTrue);
            expect(engine.tap_tile(opening.last).accepted, isTrue);
          }
          final before = engine.state;
          final before_json = engine.export_json();
          final result = engine.shuffle(seed: seed + 99);
          if (!result.accepted && difficulty == 9 && held) {
            // A key-preserving continuation may exceed the bounded search;
            // refusal must preserve both the state and the unused charge.
            expect(engine.export_json(), before_json);
            expect(engine.state.tools[TileQuestTool.shuffle], 1);
            continue;
          }
          expect(
            result.accepted,
            isTrue,
            reason: '$difficulty/$seed/$held: ${result.reason}',
          );
          expect(engine.state.tray, before.tray);
          expect(engine.state.reserve, before.reserve);
          final proof = TileQuestValidator.validate_solution(engine.state);
          expect(proof.valid, isTrue, reason: proof.reason);
          expect(proof.max_tray_occupancy, 6);
          final types = _lead_path(
            engine.state,
          ).map((id) => engine.state.tile_by_id(id).type).toList();
          var run = 1;
          var longest = 1;
          var plain_triples = 0;
          for (var index = 1; index < types.length; index++) {
            run = types[index] == types[index - 1] ? run + 1 : 1;
            if (run > longest) longest = run;
            if (index >= 2 &&
                types[index] == types[index - 1] &&
                types[index] == types[index - 2]) {
              plain_triples++;
            }
          }
          final kept_witness =
              _lead_path(before).length == _lead_path(engine.state).length &&
              List.generate(
                _lead_path(before).length,
                (index) =>
                    _lead_path(before)[index] ==
                    _lead_path(engine.state)[index],
              ).every((same) => same);
          if (kept_witness) {
            // A type bijection preserves the original challenge exactly,
            // including its deliberate warm-up; it must not add easy groups.
            final original = _lead_path(
              before,
            ).map((id) => before.tile_by_id(id).type).toList();
            var original_triples = 0;
            for (var index = 2; index < original.length; index++) {
              if (original[index] == original[index - 1] &&
                  original[index] == original[index - 2]) {
                original_triples++;
              }
            }
            expect(plain_triples, original_triples);
          } else {
            expect(longest, lessThanOrEqualTo(18));
            expect(
              plain_triples / types.length,
              lessThan(.18),
              reason: '$difficulty/$seed/held=$held',
            );
          }
          expect(
            engine.state.tiles.map((tile) => tile.type).toList()..sort(),
            before.tiles.map((tile) => tile.type).toList()..sort(),
          );
          if (seed == 0) {
            for (final id in List<int>.from(engine.state.certified_solution)) {
              final action = replay_certificate_step(engine, id);
              expect(action.accepted, isTrue);
            }
            expect(engine.state.status, TileQuestStatus.won);
            expect(engine.state.tools_used, greaterThanOrEqualTo(1));
          }
        }
      }
    });
  }
}
