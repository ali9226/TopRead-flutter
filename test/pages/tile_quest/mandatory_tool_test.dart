// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';

import 'package:app/pages/tile_quest/game/config.dart';
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/expert_barrier.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/geometry.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/game/validator.dart';
import 'package:flutter_test/flutter_test.dart';

/// An independent small board makes the capacity proof testable without relying
/// on the production generator or on a particular randomly grown silhouette.
TileQuestState mandatory_tool_fixture({int difficulty = 5}) {
  const lead_count = 18;
  final front_ids = List.generate(
    TileQuestExpertBarrier.tool_front_types.length,
    (index) => lead_count + index,
  );
  final partner_ids = List.generate(
    TileQuestExpertBarrier.tool_partner_types.length,
    (index) => lead_count + front_ids.length + index,
  );
  final barrier = TileQuestExpertBarrier(
    front_ids: front_ids,
    partner_ids: partner_ids,
    lead_solution: List.generate(lead_count, (index) => index),
  );
  final tiles = <TileQuestTile>[
    for (var id = 0; id < lead_count; id++)
      TileQuestTile(
        id: id,
        type: TileQuestExpertBarrier.tool_type_count + id ~/ 6,
        layer: 0,
        x: (id % 6).toDouble(),
        y: (id ~/ 6).toDouble(),
      ),
    for (var index = 0; index < front_ids.length; index++)
      TileQuestTile(
        id: front_ids[index],
        type: TileQuestExpertBarrier.tool_front_types[index],
        layer: TileQuestExpertBarrier.tool_tile_count - 1 - index,
        x: 5.5,
        y: 7,
      ),
    for (var index = 0; index < partner_ids.length; index++)
      TileQuestTile(
        id: partner_ids[index],
        type: TileQuestExpertBarrier.tool_partner_types[index],
        layer: (partner_ids.length - 1 - index) ~/ 2,
        x: 5.0 + index % 2,
        y: 7,
      ),
  ];
  return TileQuestState(
    tiles: TileQuestGeometry(tiles).refresh(tiles),
    level: 2,
    difficulty: difficulty,
    seed: 730,
    challenge_id: 'mandatory-tool-$difficulty',
    unlocked_level: 2,
    expert_barrier: barrier,
    certified_solution: barrier.witness,
  );
}

TileQuestActionResult replay_step(TileQuestEngine engine, int step) {
  if (step == TileQuestExpertBarrier.remove_step) return engine.remove();
  if (engine.state.reserve.contains(step)) return engine.return_reserve(step);
  return engine.tap_tile(step);
}

void expect_inventory(TileQuestState state) {
  expect(
    state.remaining_count +
        state.tray.length +
        state.reserve.length +
        state.matched_count,
    state.total_count,
  );
  TileQuestValidator.validate_state(state);
}

TileQuestEngine round_trip(TileQuestEngine engine) {
  final encoded =
      jsonDecode(jsonEncode(engine.export_json())) as Map<String, dynamic>;
  final restored = TileQuestEngine.restore(encoded);
  expect(restored.export_json(), encoded);
  return restored;
}

void main() {
  test('difficulty helpers keep the seven-gate and expert proofs distinct', () {
    for (var difficulty = 1; difficulty <= 10; difficulty++) {
      final active = difficulty >= TileQuestConfig.mandatory_tool_difficulty;
      expect(
        TileQuestExpertBarrier.front_types_for_difficulty(difficulty).length,
        !active
            ? 0
            : difficulty == 10
            ? 13
            : 7,
      );
      expect(
        TileQuestExpertBarrier.partner_types_for_difficulty(difficulty).length,
        !active
            ? 0
            : difficulty == 10
            ? 8
            : 5,
      );
      expect(
        TileQuestExpertBarrier.type_count_for_difficulty(difficulty),
        !active
            ? 0
            : difficulty == 10
            ? 7
            : 4,
      );
      expect(
        TileQuestExpertBarrier.tile_count_for_difficulty(difficulty),
        !active
            ? 0
            : difficulty == 10
            ? 21
            : 12,
      );
    }
  });

  for (var difficulty = 5; difficulty <= 9; difficulty++) {
    test('difficulty $difficulty has a strict six-space seven-gate bound', () {
      final engine = TileQuestEngine(
        mandatory_tool_fixture(difficulty: difficulty),
      );
      final barrier = engine.state.expert_barrier!;
      expect(barrier.minimum_remove_uses, 1);
      expect(barrier.core_tile_count, 12);
      expect(TileQuestExpertBarrier.safe_capacity(0), lessThan(7));
      expect(TileQuestExpertBarrier.safe_capacity(1), greaterThanOrEqualTo(7));
      final counts = <int, int>{};
      for (final id in barrier.front_ids) {
        final type = engine.state.tile_by_id(id).type;
        counts[type] = (counts[type] ?? 0) + 1;
        expect(
          engine.state.tiles.where((tile) => tile.type == type),
          hasLength(3),
        );
      }
      expect(counts.values.every((count) => count < 3), isTrue);
      for (final id in [...barrier.lead_solution, ...barrier.front_ids]) {
        if (id == barrier.front_ids.last) {
          expect(
            barrier.partner_ids.every(
              (partner) => engine.state.tile_by_id(partner).is_blocked,
            ),
            isTrue,
          );
        }
        expect(engine.tap_tile(id).accepted, isTrue);
        expect_inventory(engine.state);
      }
      expect(engine.state.status, TileQuestStatus.lost);
      expect(engine.state.tray, hasLength(7));
      expect(engine.state.tools_used, 0);
      expect(
        barrier.partner_ids.every((id) => !engine.tap_tile(id).accepted),
        isTrue,
      );
    });

    test('difficulty $difficulty wins legally with exactly one Remove', () {
      final state = mandatory_tool_fixture(difficulty: difficulty);
      expect(
        TileQuestValidator.validate_tool_solution(
          state,
          state.certified_solution,
          remove_uses: 0,
        ).valid,
        isFalse,
      );
      final one_remove = TileQuestValidator.validate_tool_solution(
        state,
        state.certified_solution,
        remove_uses: 1,
      );
      expect(one_remove.valid, isTrue, reason: one_remove.reason);
      expect(one_remove.max_tray_occupancy, lessThan(7));
      final engine = TileQuestEngine(state);
      for (final step in state.certified_solution) {
        final result = replay_step(engine, step);
        expect(result.accepted, isTrue, reason: result.reason);
        if (step == TileQuestExpertBarrier.remove_step) {
          expect(engine.state.reserve, hasLength(3));
          expect(
            engine.state.reserve.map(engine.state.reserve_column).toSet(),
            {0, 1, 2},
          );
        }
        expect_inventory(engine.state);
      }
      expect(engine.state.status, TileQuestStatus.won);
      expect(engine.state.tools_used, 1);
      expect(
        engine.state.tools[TileQuestTool.remove],
        TileQuestConfig.remove_uses_per_challenge - 1,
      );
      expect(engine.state.reserve, isEmpty);
      expect(engine.state.certified_solution, isEmpty);
    });
  }

  test(
    'Remove sentinel and reserve returns survive every snapshot boundary',
    () {
      var engine = TileQuestEngine(mandatory_tool_fixture());
      final path = List<int>.of(engine.state.certified_solution);
      for (final step in path) {
        engine = round_trip(engine);
        final result = replay_step(engine, step);
        expect(result.accepted, isTrue, reason: result.reason);
        expect_inventory(engine.state);
      }
      expect(round_trip(engine).state.status, TileQuestStatus.won);
    },
  );

  test(
    'Undo retains the spent Remove and a replayable reserve certificate',
    () {
      var engine = TileQuestEngine(mandatory_tool_fixture());
      final barrier = engine.state.expert_barrier!;
      for (final id in [
        ...barrier.lead_solution,
        ...barrier.front_ids.take(3),
      ]) {
        expect(engine.tap_tile(id).accepted, isTrue);
      }
      expect(engine.remove().accepted, isTrue);
      final reserve = List<int>.of(engine.state.reserve);
      final expected_path = List<int>.of(engine.state.certified_solution);
      expect(engine.tap_tile(barrier.front_ids[3]).accepted, isTrue);
      engine = round_trip(engine);
      expect(engine.undo().accepted, isTrue);
      expect(engine.state.reserve, reserve);
      expect(engine.state.certified_solution, expected_path);
      expect(engine.state.tools_used, 2);
      expect(
        engine.state.tools[TileQuestTool.remove],
        TileQuestConfig.remove_uses_per_challenge - 1,
      );
      expect_inventory(engine.state);
      for (final step in expected_path) {
        expect(replay_step(engine, step).accepted, isTrue);
      }
      expect(engine.state.status, TileQuestStatus.won);
    },
  );

  test('Undo on an opened gate retains its necessary physical Remove', () {
    var engine = TileQuestEngine(mandatory_tool_fixture());
    final barrier = engine.state.expert_barrier!;
    final path = List<int>.of(engine.state.certified_solution);
    for (final step in path) {
      expect(replay_step(engine, step).accepted, isTrue);
      if (step == barrier.front_ids.last) break;
    }
    expect(barrier.is_closed(engine.state), isFalse);
    final expected_path = List<int>.of(engine.state.certified_solution);
    expect(engine.return_reserve(barrier.front_ids.first).accepted, isTrue);
    engine = round_trip(engine);
    expect(engine.undo().accepted, isTrue);
    expect(barrier.is_closed(engine.state), isFalse);
    expect(engine.state.certified_solution, expected_path);
    expect(engine.state.tools_used, 2);
    expect_inventory(engine.state);
    for (final step in expected_path) {
      expect(replay_step(engine, step).accepted, isTrue);
    }
    expect(engine.state.status, TileQuestStatus.won);
    expect_inventory(engine.state);
  });

  test('Shuffle after a lead tap keeps gate tiles and still succeeds', () {
    final engine = TileQuestEngine(mandatory_tool_fixture());
    expect(
      engine.tap_tile(engine.state.certified_solution.first).accepted,
      isTrue,
    );
    final before = engine.state;
    final barrier = before.expert_barrier!;
    final result = engine.shuffle(seed: 2026);
    expect(result.accepted, isTrue, reason: result.reason);
    expect(engine.state.tools_used, 1);
    // 专家门正/配对牌保持不变，其余棋盘牌可被纯随机重排。
    for (final id in [...barrier.front_ids, ...barrier.partner_ids]) {
      expect(
        engine.state.tile_by_id(id).to_json(),
        before.tile_by_id(id).to_json(),
      );
    }
    expect(engine.state.certified_solution, isEmpty);
    expect_inventory(engine.state);
  });

  test(
    'high difficulty rejects missing cores and fabricated zero-tool wins',
    () {
      final state = mandatory_tool_fixture();
      final hard = TileQuestGenerator.generate(
        level: 2,
        difficulty: 10,
        seed: 730,
      );
      final no_core = Map<String, dynamic>.from(hard.to_json())
        ..['expert_barrier'] = null;
      expect(() => TileQuestState.from_json(no_core), throwsFormatException);
      final removed = state.tiles
          .map((tile) => tile.copy_with(is_removed: true))
          .toList();
      final fabricated = state.copy_with(
        tiles: TileQuestGeometry(removed).refresh(removed),
        status: TileQuestStatus.won,
        matched_count: state.total_count,
        certified_solution: const [],
      );
      expect(
        () => TileQuestValidator.validate_state(fabricated),
        throwsFormatException,
      );
    },
  );

  test('spending only Shuffle cannot forge a won tool gate or expert game', () {
    for (final state in [
      mandatory_tool_fixture(),
      TileQuestGenerator.generate(level: 2, difficulty: 10, seed: 730),
    ]) {
      final removed = state.tiles
          .map((tile) => tile.copy_with(is_removed: true))
          .toList();
      final fabricated = state.copy_with(
        tiles: TileQuestGeometry(removed).refresh(removed),
        status: TileQuestStatus.won,
        matched_count: state.total_count,
        certified_solution: const [],
        tools: {...state.tools, TileQuestTool.shuffle: 0},
        tools_used: 1,
      );
      expect(
        () => TileQuestValidator.validate_state(fabricated),
        throwsFormatException,
      );
      expect(
        () => TileQuestState.from_json(fabricated.to_json()),
        throwsFormatException,
      );
    }
  });

  test('barrier dimensions and type isolation cannot be forged in saves', () {
    final state = mandatory_tool_fixture();
    for (final lengths in [
      <int>[7, 8],
      <int>[13, 5],
      <int>[6, 5],
    ]) {
      expect(
        () => TileQuestExpertBarrier.from_json({
          'front_ids': List.generate(lengths[0], (index) => index),
          'partner_ids': List.generate(lengths[1], (index) => index + 20),
        }),
        throwsFormatException,
      );
    }
    final escaped_core = state.tiles
        .map((tile) => tile.type == 4 ? tile.copy_with(type: 0) : tile)
        .toList();
    expect(
      () => TileQuestValidator.validate_state(
        state.copy_with(tiles: escaped_core, certified_solution: const []),
      ),
      throwsFormatException,
    );
    final wrong_difficulty = Map<String, dynamic>.from(state.to_json())
      ..['difficulty'] = 10;
    expect(
      () => TileQuestState.from_json(wrong_difficulty),
      throwsFormatException,
    );
  });

  test(
    'generated challenges enforce the threshold and keep ten unwinnable',
    () {
      for (var difficulty = 1; difficulty <= 10; difficulty++) {
        for (final seed in [0, 730]) {
          final state = TileQuestGenerator.generate(
            level: 2,
            difficulty: difficulty,
            seed: seed,
          );
          TileQuestValidator.validate_state(state);
          final barrier = state.expert_barrier;
          if (difficulty < TileQuestConfig.trap_difficulty) {
            expect(barrier, isNull);
            expect(TileQuestValidator.validate_solution(state).valid, isTrue);
            continue;
          }
          expect(barrier, isNotNull);
          final required_removes = 3;
          expect(barrier!.minimum_remove_uses, required_removes);
          expect(
            TileQuestValidator.validate_tool_solution(
              state,
              barrier.witness,
              remove_uses: required_removes - 1,
            ).valid,
            isFalse,
          );
          final check = TileQuestValidator.validate_tool_solution(
            state,
            barrier.witness,
            remove_uses: required_removes,
          );
          expect(
            check.valid,
            isTrue,
            reason: '$difficulty/$seed: ${check.reason}',
          );
          expect(
            state.certified_solution.isEmpty,
            difficulty == 10 &&
                TileQuestConfig.remove_uses_per_challenge < required_removes,
          );
        }
      }
    },
  );
}
