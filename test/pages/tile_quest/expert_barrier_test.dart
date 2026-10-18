// ignore_for_file: non_constant_identifier_names
import 'dart:convert';

import 'package:app/pages/tile_quest/game/config.dart';
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/expert_barrier.dart';
import 'package:app/pages/tile_quest/game/geometry.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/game/validator.dart';
import 'package:flutter_test/flutter_test.dart';

TileQuestState expert_fixture() {
  final tiles = <TileQuestTile>[
    for (var id = 0; id < 9; id++)
      TileQuestTile(
        id: id,
        type: 7 + id ~/ 3,
        layer: 0,
        x: (id % 6).toDouble(),
        y: (id ~/ 6).toDouble(),
      ),
    for (var index = 0; index < 13; index++)
      TileQuestTile(
        id: 9 + index,
        type: TileQuestExpertBarrier.front_types[index],
        layer: TileQuestExpertBarrier.tile_count - 1 - index,
        x: .5,
        y: 2,
      ),
    for (var index = 0; index < TileQuestExpertBarrier.partner_count; index++)
      TileQuestTile(
        id: 22 + index,
        type: TileQuestExpertBarrier.partner_types[index],
        layer: (TileQuestExpertBarrier.partner_count - 1 - index) ~/ 2,
        x: (index % 2).toDouble(),
        y: 2,
      ),
  ];
  return TileQuestState(
    tiles: TileQuestGeometry(tiles).refresh(tiles),
    level: 2,
    difficulty: 10,
    seed: 42,
    challenge_id: 'static-13-gates',
    unlocked_level: 2,
    expert_barrier: TileQuestExpertBarrier(
      front_ids: List.generate(13, (index) => index + 9),
      partner_ids: List.generate(
        TileQuestExpertBarrier.partner_count,
        (index) => index + 22,
      ),
      lead_solution: List.generate(9, (index) => index),
    ),
  );
}

void clear_lead(TileQuestEngine engine) {
  for (final id in engine.state.expert_barrier!.lead_solution) {
    expect(engine.tap_tile(id).accepted, isTrue);
  }
  expect(engine.state.tray, isEmpty);
}

void assert_inventory(TileQuestState state) {
  expect(
    state.remaining_count +
        state.tray.length +
        state.reserve.length +
        state.matched_count,
    state.total_count,
  );
  TileQuestValidator.validate_state(state);
}

void main() {
  test('static prerequisites imply a strict 13-gate capacity bound', () {
    final state = expert_fixture();
    TileQuestValidator.validate_state(state);
    final barrier = state.expert_barrier!;
    expect(
      barrier.front_ids.map((id) => state.tile_by_id(id).type).toSet(),
      hasLength(TileQuestExpertBarrier.type_count),
    );
    final front_stock = <int, int>{};
    for (final id in barrier.front_ids) {
      final type = state.tile_by_id(id).type;
      front_stock[type] = (front_stock[type] ?? 0) + 1;
    }
    expect(front_stock.values.where((count) => count == 2), hasLength(6));
    expect(front_stock.values.where((count) => count == 1), hasLength(1));
    expect(front_stock.values.every((count) => count < 3), isTrue);
    expect(
      state.tiles
          .map((tile) => tile.type)
          .every((type) => type >= 0 && type < TileQuestConfig.max_tile_types),
      isTrue,
    );
    // This arithmetic invariant covers every action order, not a finite search:
    // before the last gate no gate type can match; all removed gates must be held.
    for (var uses = 0; uses < 3; uses++) {
      expect(TileQuestExpertBarrier.safe_capacity(uses), lessThan(13));
    }
    expect(TileQuestExpertBarrier.safe_capacity(3), greaterThanOrEqualTo(13));
    for (final type in barrier.front_ids.map(
      (id) => state.tile_by_id(id).type,
    )) {
      expect(state.tiles.where((tile) => tile.type == type), hasLength(3));
    }
    expect(
      barrier.partner_ids.every((id) => state.tile_by_id(id).is_blocked),
      isTrue,
    );
  });

  test(
    'independent replay needs three Remove charges and respects LIFO returns',
    () {
      final state = expert_fixture();
      final path = state.expert_barrier!.witness;
      expect(
        path.where((id) => id == TileQuestExpertBarrier.remove_step),
        hasLength(3),
      );
      for (var uses = 0; uses <= 2; uses++) {
        expect(
          TileQuestValidator.validate_tool_solution(
            state,
            path,
            remove_uses: uses,
          ).valid,
          isFalse,
        );
      }
      final three = TileQuestValidator.validate_tool_solution(
        state,
        path,
        remove_uses: 3,
      );
      expect(three.valid, isTrue, reason: three.reason);
      expect(three.max_tray_occupancy, lessThan(7));
      expect(TileQuestValidator.validate_solution(state).valid, isFalse);
    },
  );

  for (var uses = 0; uses <= 2; uses++) {
    test(
      'real engine with $uses Removes reaches a static capacity failure',
      () {
        final engine = TileQuestEngine(expert_fixture());
        clear_lead(engine);
        var moved = 0;
        for (final id in engine.state.expert_barrier!.front_ids) {
          if (engine.state.status != TileQuestStatus.playing) break;
          expect(engine.tap_tile(id).accepted, isTrue);
          if (engine.state.tray.length == 3 && moved < uses) {
            expect(engine.remove().accepted, isTrue);
            moved++;
          }
          assert_inventory(engine.state);
        }
        expect(engine.state.status, TileQuestStatus.lost);
        expect(engine.state.matched_count, 9);
        expect(engine.state.reserve.length, uses * 3);
        expect(engine.remove().accepted, isFalse);
        expect(engine.shuffle().accepted, isFalse);
        expect(engine.undo().accepted, isTrue);
        expect(engine.state.status, TileQuestStatus.playing);
        expect(engine.state.expert_barrier!.is_closed(engine.state), isTrue);
        expect(
          engine.state.expert_barrier!.partner_ids.every(
            (id) => engine.state.tile_by_id(id).is_blocked,
          ),
          isTrue,
        );
        final before = engine.export_json();
        expect(engine.shuffle(seed: 78).accepted, isFalse);
        expect(engine.export_json(), before);
        assert_inventory(engine.state);
      },
    );
  }

  test(
    'opening Shuffle changes real lead faces and preserves the exact barrier',
    () {
      final engine = TileQuestEngine(expert_fixture());
      final before = engine.state;
      final result = engine.shuffle(seed: 99);
      expect(result.accepted, isTrue, reason: result.reason);
      expect(engine.state.tools[TileQuestTool.shuffle], 0);
      expect(
        engine.state.tiles.where(
          (tile) => tile.type != before.tile_by_id(tile.id).type,
        ),
        isNotEmpty,
      );
      for (final id in [
        ...before.expert_barrier!.front_ids,
        ...before.expert_barrier!.partner_ids,
      ]) {
        expect(
          engine.state.tile_by_id(id).to_json(),
          before.tile_by_id(id).to_json(),
        );
      }
      final inventory = before.tiles.map((tile) => tile.type).toList()..sort();
      expect(
        engine.state.tiles.map((tile) => tile.type).toList()..sort(),
        inventory,
      );
      expect(
        TileQuestValidator.validate_tool_solution(
          engine.state,
          before.expert_barrier!.witness,
          remove_uses: 3,
        ).valid,
        isTrue,
      );
      assert_inventory(engine.state);
    },
  );

  test('snapshot round trip keeps barrier identity and initial witness', () {
    final engine = TileQuestEngine(expert_fixture());
    clear_lead(engine);
    engine.tap_tile(engine.state.expert_barrier!.front_ids.first);
    final json =
        jsonDecode(jsonEncode(engine.export_json())) as Map<String, dynamic>;
    final restored = TileQuestEngine.restore(json);
    expect(restored.export_json(), json);
    expect(
      restored.state.expert_barrier!.front_ids,
      engine.state.expert_barrier!.front_ids,
    );
    assert_inventory(restored.state);
  });

  test(
    'an exposed partner or broken dependency cannot masquerade as a barrier',
    () {
      final state = expert_fixture();
      final saved = state.to_json();
      for (final mutation in <void Function(Map<String, dynamic>)>[
        (json) => json['expert_barrier']['front_ids'][1] = 0,
        (json) => json['expert_barrier']['partner_ids'][0] = 1,
        (json) => json['expert_barrier']['partner_ids'][0] =
            json['expert_barrier']['partner_ids'][1],
        (json) => json['tiles'][22]['type'] = 13,
      ]) {
        final damaged = jsonDecode(jsonEncode(saved)) as Map<String, dynamic>;
        mutation(damaged);
        expect(() => TileQuestState.from_json(damaged), throwsFormatException);
      }
      expect(TileQuestConfig.remove_uses_per_challenge, 2);
    },
  );
}
