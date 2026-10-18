// ignore_for_file: non_constant_identifier_names
import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/pages/tile_quest/game/config.dart';
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/geometry.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/game/validator.dart';
import 'certificate_replay.dart';

TileQuestEngine flat_board(List<int> types) {
  final tiles = List<TileQuestTile>.generate(
    types.length,
    (index) => TileQuestTile(
      id: index,
      type: types[index],
      layer: 0,
      x: (index % 8) * 1.1,
      y: (index ~/ 8) * 1.1,
    ),
  );
  return TileQuestEngine(
    TileQuestState(tiles: tiles, level: 1, seed: 1, challenge_id: 'test'),
  );
}

Map<String, dynamic> deep_json(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

void replay(TileQuestEngine engine, List<int> path) {
  for (final id in path) {
    final result = replay_certificate_step(engine, id);
    expect(result.accepted, isTrue, reason: 'id $id: ${result.reason}');
  }
}

void main() {
  group('atomic core rules', () {
    test('two identical tiles remain; three clear and win', () {
      final engine = flat_board([0, 0, 0]);
      expect(engine.tap_tile(0).matched_ids, isEmpty);
      engine.tap_tile(1);
      expect(engine.state.tray.length, 2);
      final last = engine.tap_tile(2);
      expect(last.matched_ids.toSet(), {0, 1, 2});
      expect(engine.state.status, TileQuestStatus.won);
      expect(engine.state.matched_count, 3);
      expect(engine.state.unlocked_level, 2);
    });
    test('seventh tile settles a triple before failure', () {
      final engine = flat_board([0, 0, 1, 2, 3, 4, 0, 1, 1, 2, 2, 3, 3, 4, 4]);
      for (var id = 0; id < 6; id++) {
        engine.tap_tile(id);
      }
      expect(engine.state.tray.length, 6);
      expect(engine.tap_tile(6).matched_ids.length, 3);
      expect(engine.state.tray.length, 4);
      expect(engine.state.status, TileQuestStatus.playing);
    });
    test('seven different tiles lose; an eighth operation is rejected', () {
      final engine = flat_board([
        for (var copy = 0; copy < 3; copy++)
          ...List.generate(7, (index) => index),
      ]);
      for (var id = 0; id < 7; id++) {
        expect(engine.tap_tile(id).accepted, isTrue);
      }
      expect(engine.state.status, TileQuestStatus.lost);
      expect(engine.tap_tile(7).accepted, isFalse);
      expect(engine.state.tray.length, 7);
      expect(engine.undo().accepted, isTrue);
      expect(engine.state.status, TileQuestStatus.playing);
      expect(engine.state.tray.length, 6);
    });
    test(
      'geometry blocks only positive overlap and refreshes after removal',
      () {
        final tiles = [
          const TileQuestTile(id: 0, type: 0, layer: 0, x: 0, y: 0),
          const TileQuestTile(id: 1, type: 0, layer: 1, x: .5, y: .5),
          const TileQuestTile(id: 2, type: 0, layer: 2, x: 1.5, y: .5),
        ];
        final geometry = TileQuestGeometry(tiles);
        final engine = TileQuestEngine(
          TileQuestState(
            tiles: geometry.refresh(tiles),
            level: 1,
            seed: 1,
            challenge_id: 'overlap',
          ),
        );
        expect(engine.tap_tile(0).accepted, isFalse);
        final result = engine.tap_tile(1);
        expect(result.accepted, isTrue);
        expect(result.unblocked_ids, [0]);
        expect(engine.tap_tile(0).accepted, isTrue);
        expect(engine.tap_tile(2).after.status, TileQuestStatus.won);
      },
    );
    test(
      'rapid duplicate taps do not duplicate inventory or change old snapshots',
      () {
        final engine = flat_board([0, 0, 0]);
        final before = engine.state;
        expect(engine.tap_tile(0).accepted, isTrue);
        for (var index = 0; index < 100; index++) {
          expect(engine.tap_tile(0).accepted, isFalse);
        }
        expect(engine.state.tray, [0]);
        expect(before.tiles.first.is_removed, isFalse);
        expect(() => engine.state.tray.add(2), throwsUnsupportedError);
      },
    );
  });

  group('tools and persistence', () {
    test(
      'Undo restores a full eliminated triple and remains spent after restore',
      () {
        final engine = flat_board([0, 0, 0, 1, 1, 1]);
        engine.tap_tile(0);
        engine.tap_tile(1);
        final snapshot = engine.state.to_json();
        engine.tap_tile(2);
        final restored = TileQuestEngine.restore(
          deep_json(engine.export_json()),
        );
        expect(restored.undo().accepted, isTrue);
        expect(restored.state.tray, snapshot['tray']);
        expect(
          restored.state.tiles.map((tile) => tile.to_json()).toList(),
          snapshot['tiles'],
        );
        expect(restored.state.matched_count, 0);
        expect(restored.state.tools[TileQuestTool.undo], 0);
        expect(restored.undo().accepted, isFalse);
        final reopened = TileQuestEngine.restore(
          deep_json(restored.export_json()),
        );
        expect(reopened.state.tools[TileQuestTool.undo], 0);
      },
    );
    test('Undo events include reserve returns and fully restored matches', () {
      final engine = flat_board([0, 0, 0, 1, 1, 1]);
      engine.tap_tile(0);
      engine.remove();
      engine.return_reserve(0);
      final action = engine.undo();
      expect(action.moved_ids, contains(0));
      expect(engine.state.reserve, [0]);
      expect(engine.state.tray, isEmpty);
      expect(engine.state.tools[TileQuestTool.remove], 1);
      expect(engine.state.tools[TileQuestTool.undo], 0);
      TileQuestValidator.validate_state(engine.state);

      final triple = flat_board([0, 0, 0, 1, 1, 1]);
      triple.tap_tile(0);
      triple.tap_tile(1);
      triple.tap_tile(2);
      expect(triple.undo().moved_ids.toSet(), {0, 1, 2});
    });

    test(
      'Undo across Remove or Shuffle preserves spent tools and valid inventory',
      () {
        for (final use_shuffle in [false, true]) {
          final engine = flat_board([0, 0, 0, 1, 1, 1]);
          engine.tap_tile(0);
          if (use_shuffle) {
            engine.shuffle(seed: 12);
          } else {
            engine.remove();
          }
          expect(engine.undo().accepted, isTrue);
          expect(engine.state.remaining_count, 6);
          expect(engine.state.tray, isEmpty);
          expect(engine.state.reserve, isEmpty);
          expect(engine.state.tools_used, 2);
          expect(engine.state.tools[TileQuestTool.undo], 0);
          expect(
            engine.state.tools[use_shuffle
                ? TileQuestTool.shuffle
                : TileQuestTool.remove],
            use_shuffle ? 0 : 1,
          );
          TileQuestValidator.validate_state(engine.state);
          expect(
            TileQuestEngine.restore(
              deep_json(engine.export_json()),
            ).export_json(),
            engine.export_json(),
          );
        }
      },
    );

    test(
      'Remove holds independent inventory; returning it settles and enables victory',
      () {
        final engine = flat_board([0, 0, 0]);
        engine.tap_tile(0);
        expect(engine.remove().accepted, isTrue);
        expect(engine.state.reserve, [0]);
        engine.tap_tile(1);
        engine.tap_tile(2);
        expect(engine.state.remaining_count, 0);
        expect(engine.state.status, TileQuestStatus.playing);
        expect(engine.state.tray.length, 2);
        expect(engine.return_reserve(0).matched_ids.length, 3);
        expect(engine.state.status, TileQuestStatus.won);
        expect(engine.remove().accepted, isFalse);
      },
    );
    test(
      'Remove transfers at most three twice, and save preserves both charges',
      () {
        final engine = flat_board([0, 0, 1, 1, 2, 2, 0, 1, 2]);
        for (var id = 0; id < 5; id++) {
          engine.tap_tile(id);
        }
        expect(engine.remove().moved_ids.length, 3);
        expect(engine.state.reserve.length, 3);
        expect(engine.state.tray.length, 2);
        final reopened = TileQuestEngine.restore(
          deep_json(engine.export_json()),
        );
        expect(reopened.state.tools[TileQuestTool.remove], 1);
        expect(reopened.remove().accepted, isTrue);
        expect(reopened.state.tools_used, 2);
        expect(reopened.state.reserve.length, 5);
        expect(reopened.remove().accepted, isFalse);
        expect(
          reopened.return_reserve(reopened.state.reserve.last).accepted,
          isTrue,
        );
      },
    );
    test(
      'Shuffle preserves geometry, tray, reserve and exact type multiset',
      () {
        final engine = TileQuestEngine(
          TileQuestGenerator.generate(level: 2, seed: 68),
        );
        replay(engine, engine.state.certified_solution.take(5).toList());
        engine.remove();
        final before = engine.state;
        final result = engine.shuffle(seed: 11);
        expect(result.accepted, isTrue, reason: result.reason);
        expect(engine.state.tray, before.tray);
        expect(engine.state.reserve, before.reserve);
        expect(
          engine.state.tiles
              .map(
                (tile) => [
                  tile.id,
                  tile.layer,
                  tile.x,
                  tile.y,
                  tile.is_removed,
                  tile.is_blocked,
                ],
              )
              .toList(),
          before.tiles
              .map(
                (tile) => [
                  tile.id,
                  tile.layer,
                  tile.x,
                  tile.y,
                  tile.is_removed,
                  tile.is_blocked,
                ],
              )
              .toList(),
        );
        final before_types = before.tiles.map((tile) => tile.type).toList()
          ..sort();
        final after_types = engine.state.tiles.map((tile) => tile.type).toList()
          ..sort();
        expect(after_types, before_types);
        expect(
          TileQuestValidator.validate_solution(engine.state).valid,
          isTrue,
        );
        replay(engine, List<int>.from(engine.state.certified_solution));
        expect(engine.state.status, TileQuestStatus.won);
        expect(engine.shuffle().accepted, isFalse);
      },
    );
    test(
      'Shuffle continuation stress covers all tray occupancies and reserve inventories',
      () {
        final observed_occupancies = <int>{};
        var accepted_count = 0;
        var rejected_count = 0;
        for (var difficulty = 1; difficulty <= 10; difficulty++) {
          for (var seed = 0; seed < 9; seed++) {
            final initial = TileQuestGenerator.generate(
              level: 2,
              seed: seed,
              difficulty: difficulty,
            );
            for (var prefix = 0; prefix < 9; prefix++) {
              final engine = TileQuestEngine(initial);
              final random = Random(seed * 199 + prefix * 13);
              for (
                var step = 0;
                step < prefix && engine.state.status == TileQuestStatus.playing;
                step++
              ) {
                final choices = engine.clickable_tiles;
                if (choices.isEmpty) break;
                // Alternate certified prefixes with real off-path player decisions.
                final next =
                    prefix.isEven &&
                        seed.isEven &&
                        engine.state.certified_solution.isNotEmpty
                    ? engine.state.certified_solution.first
                    : choices[random.nextInt(choices.length)].id;
                engine.tap_tile(next);
              }
              if (engine.state.status != TileQuestStatus.playing) continue;
              if (prefix % 3 == 1 && seed.isEven) engine.remove();
              observed_occupancies.add(engine.state.tray.length);
              final before = deep_json(engine.export_json());
              final before_types =
                  engine.state.tiles.map((tile) => tile.type).toList()..sort();
              final result = engine.shuffle(seed: seed * 31 + prefix);
              if (result.accepted) {
                accepted_count++;
                final barrier = engine.state.expert_barrier;
                if (barrier != null &&
                    barrier.minimum_remove_uses >
                        TileQuestConfig.initial_tool_uses(
                          TileQuestTool.remove,
                        ) &&
                    barrier.is_closed(engine.state)) {
                  expect(engine.state.certified_solution, isEmpty);
                  expect(
                    TileQuestValidator.validate_solution(engine.state).valid,
                    isFalse,
                  );
                  expect(
                    TileQuestValidator.validate_tool_solution(
                      engine.state,
                      barrier.witness,
                      remove_uses: barrier.minimum_remove_uses,
                    ).valid,
                    isTrue,
                    reason: 'barrier witness $difficulty/$seed/$prefix',
                  );
                  expect(barrier.to_json(), before['state']['expert_barrier']);
                } else {
                  expect(
                    TileQuestValidator.validate_solution(engine.state).valid,
                    isTrue,
                    reason: 'difficulty=$difficulty seed=$seed prefix=$prefix',
                  );
                }
                TileQuestValidator.validate_state(engine.state);
                expect(
                  engine.state.tiles.map((tile) => tile.type).toList()..sort(),
                  before_types,
                );
                expect(engine.state.tray, before['state']['tray']);
                expect(engine.state.reserve, before['state']['reserve']);
                final restored = TileQuestEngine.restore(
                  deep_json(engine.export_json()),
                );
                if (seed == 0 &&
                    prefix % 4 == 0 &&
                    restored.state.certified_solution.isNotEmpty) {
                  replay(
                    restored,
                    List<int>.from(restored.state.certified_solution),
                  );
                  expect(restored.state.status, TileQuestStatus.won);
                }
              } else {
                rejected_count++;
                expect(engine.export_json(), before);
                expect(engine.state.tools[TileQuestTool.shuffle], 1);
              }
            }
          }
        }
        expect(observed_occupancies, containsAll([0, 1, 2, 3, 4, 5, 6]));
        expect(accepted_count, greaterThan(100));
        expect(rejected_count, greaterThan(0));
      },
    );

    test(
      'Shuffle with six singleton tray tiles safely fails without charge',
      () {
        final engine = flat_board([
          for (var copy = 0; copy < 3; copy++)
            ...List.generate(6, (index) => index),
        ]);
        for (var id = 0; id < 6; id++) {
          engine.tap_tile(id);
        }
        final before = engine.export_json();
        expect(engine.shuffle().accepted, isFalse);
        expect(engine.export_json(), before);
        expect(engine.state.tools[TileQuestTool.shuffle], 1);
      },
    );
    test(
      'save round trips ongoing and ended states with monotonic metadata',
      () {
        final engine = TileQuestEngine(
          TileQuestGenerator.generate(level: 1, seed: 21),
        );
        replay(engine, engine.state.certified_solution.take(4).toList());
        engine.update_metadata(elapsed_ms: 7345, sound_enabled: false);
        final reopened = TileQuestEngine.restore(
          deep_json(engine.export_json()),
        );
        expect(reopened.export_json(), engine.export_json());
        expect(
          () => reopened.update_metadata(elapsed_ms: 0),
          throwsArgumentError,
        );
        replay(reopened, List<int>.from(reopened.state.certified_solution));
        expect(
          TileQuestEngine.restore(
            deep_json(reopened.export_json()),
          ).state.status,
          TileQuestStatus.won,
        );
      },
    );
    test(
      'strict save validation rejects corrupt IDs, inventory, geometry, tools, status and solution',
      () {
        final engine = TileQuestEngine(
          TileQuestGenerator.generate(level: 1, seed: 42),
        );
        final mutations = <void Function(Map<String, dynamic>)>[
          (json) => json['version'] = 999,
          (json) =>
              json['state']['tiles'][0]['id'] = json['state']['tiles'][1]['id'],
          (json) => json['state']['tray'] = [0],
          (json) => json['state']['tiles'][0]['x'] = -1,
          (json) => json['state']['tiles'][0]['type'] =
              TileQuestConfig.max_tile_types,
          (json) => json['state']['tools']['undo'] = 9,
          (json) => json['state']['status'] = 'won',
          (json) => json['state']['matched_count'] = 3,
          (json) => json['state']['certified_solution'] = [0, 0],
          (json) => json['state']['tiles'][0]['is_blocked'] =
              !(json['state']['tiles'][0]['is_blocked'] as bool),
        ];
        for (final mutate in mutations) {
          final corrupt = deep_json(engine.export_json());
          mutate(corrupt);
          expect(() => TileQuestEngine.restore(corrupt), throwsFormatException);
        }
      },
    );
  });

  group('seeded constructive levels', () {
    test(
      'every difficulty and multiple seeds have balanced, legal complete paths',
      () {
        for (var difficulty = 1; difficulty <= 10; difficulty++) {
          for (var seed = 0; seed < 12; seed++) {
            final state = TileQuestGenerator.generate(
              level: 2,
              seed: seed,
              difficulty: difficulty,
            );
            expect(
              state.total_count,
              DifficultyProfile.for_difficulty(difficulty).tile_count,
            );
            final barrier = state.expert_barrier;
            final check = barrier == null
                ? TileQuestValidator.validate_solution(state)
                : TileQuestValidator.validate_tool_solution(
                    state,
                    barrier.witness,
                    remove_uses: barrier.minimum_remove_uses,
                  );
            expect(
              check.valid,
              isTrue,
              reason: '$difficulty/$seed: ${check.reason}',
            );
            expect(check.max_tray_occupancy, lessThan(7));
            TileQuestValidator.validate_state(state);
            if (difficulty < 10) {
              final engine = TileQuestEngine(state);
              replay(engine, List<int>.of(state.certified_solution));
              expect(engine.state.status, TileQuestStatus.won);
              if (difficulty >= TileQuestConfig.mandatory_tool_difficulty) {
                expect(engine.state.tools_used, greaterThanOrEqualTo(1));
                expect(
                  engine.state.tools[TileQuestTool.remove],
                  lessThan(
                    TileQuestConfig.initial_tool_uses(TileQuestTool.remove),
                  ),
                );
              }
            }
          }
        }
      },
    );
    test(
      'tutorial has 18 tiles, three types, nine exposed upper tiles and wins with no tools',
      () {
        final state = TileQuestGenerator.generate(
          level: 1,
          seed: 12,
          difficulty: 10,
        );
        expect(state.total_count, 18);
        expect(state.tiles.map((tile) => tile.type).toSet().length, 3);
        expect(state.clickable_tiles.length, 9);
        final engine = TileQuestEngine(state);
        replay(engine, List<int>.from(state.certified_solution));
        expect(engine.state.status, TileQuestStatus.won);
        expect(engine.state.tools_used, 0);
      },
    );
    test(
      'same seed and config reproduce geometry, types and solution exactly',
      () {
        for (var difficulty = 1; difficulty <= 10; difficulty++) {
          final first = TileQuestGenerator.generate(
            level: 2,
            seed: 999,
            difficulty: difficulty,
          );
          final second = TileQuestGenerator.generate(
            level: 2,
            seed: 999,
            difficulty: difficulty,
          );
          expect(first.to_json(), second.to_json());
        }
      },
    );
    test(
      'difficulty changes count, variety, depth, interleaving and real tray pressure',
      () {
        final easy = TileQuestGenerator.generate(
          level: 2,
          seed: 123,
          difficulty: 1,
        );
        final hard = TileQuestGenerator.generate(
          level: 2,
          seed: 123,
          difficulty: 10,
        );
        expect(easy.total_count, lessThan(hard.total_count));
        expect(
          easy.tiles.map((tile) => tile.type).toSet().length,
          lessThan(hard.tiles.map((tile) => tile.type).toSet().length),
        );
        expect(
          easy.tiles.map((tile) => tile.layer).reduce((a, b) => a > b ? a : b),
          lessThan(
            hard.tiles
                .map((tile) => tile.layer)
                .reduce((a, b) => a > b ? a : b),
          ),
        );
        expect(
          TileQuestValidator.validate_tool_solution(
            hard,
            hard.expert_barrier!.witness,
            remove_uses: 3,
          ).max_tray_occupancy,
          6,
        );
      },
    );
    test(
      'generation stays below the configured ceiling and rejects invalid difficulty',
      () {
        final watch = Stopwatch()..start();
        final state = TileQuestGenerator.generate(
          level: 2,
          seed: 2026,
          difficulty: 10,
        );
        expect(
          state.tiles.length,
          DifficultyProfile.for_difficulty(10).tile_count,
        );
        expect(
          state.tiles.length,
          lessThanOrEqualTo(TileQuestConfig.max_tiles),
        );
        expect(watch.elapsedMilliseconds, lessThan(2000));
        expect(
          () => TileQuestGenerator.generate(level: 2, seed: 1, difficulty: 11),
          throwsArgumentError,
        );
      },
    );
  });
}
