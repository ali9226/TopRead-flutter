// ignore_for_file: non_constant_identifier_names
import 'dart:convert';
import 'package:app/pages/tile_quest/game/config.dart';
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/game/validator.dart';
import 'package:flutter_test/flutter_test.dart';

TileQuestEngine reserve_board([List<int>? pattern]) {
  final types =
      pattern ??
      [
        for (var copy = 0; copy < 3; copy++) ...[0, 1, 2, 3, 4, 5],
      ];
  return TileQuestEngine(
    TileQuestState(
      tiles: List.generate(
        types.length,
        (index) => TileQuestTile(
          id: index,
          type: types[index],
          layer: 0,
          x: (index % 8).toDouble(),
          y: (index ~/ 8).toDouble(),
        ),
      ),
      level: 1,
      seed: 1,
      challenge_id: 'reserve-stacks',
    ),
  );
}

void move_two_batches(TileQuestEngine engine) {
  for (var id = 0; id < 6; id++) {
    expect(engine.tap_tile(id).accepted, isTrue);
    if (id == 2 || id == 5) expect(engine.remove().accepted, isTrue);
  }
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

Map<String, dynamic> copy_json(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

void main() {
  test('two Remove batches stack in stable columns; a third is rejected', () {
    final engine = reserve_board();
    expect(engine.state.tools[TileQuestTool.remove], 2);
    expect(TileQuestConfig.initial_tool_uses(TileQuestTool.remove), 2);
    move_two_batches(engine);
    expect(engine.state.reserve, [0, 1, 2, 3, 4, 5]);
    expect(engine.state.tray, isEmpty);
    expect(engine.state.tools[TileQuestTool.remove], 0);
    for (var id = 0; id < 6; id++) {
      expect(engine.state.reserve_column(id), id % 3);
      expect(engine.state.reserve_depth(id), id ~/ 3);
      expect(engine.state.is_reserve_available(id), id >= 3);
    }
    final before = engine.export_json();
    expect(engine.remove().accepted, isFalse);
    expect(engine.export_json(), before);
    expect_inventory(engine.state);
  });

  test('only a stack top returns and neighboring stacks never slide', () {
    final engine = reserve_board();
    move_two_batches(engine);
    expect(engine.return_reserve(0).accepted, isFalse);
    expect(engine.return_reserve(3).accepted, isTrue);
    expect(engine.state.reserve_column(4), 1);
    expect(engine.state.reserve_depth(4), 1);
    expect(engine.state.reserve_column(0), 0);
    expect(engine.state.is_reserve_available(0), isTrue);
    expect(engine.state.reserve_column(3), -1);
    expect_inventory(engine.state);
    expect(engine.return_reserve(0).accepted, isTrue);
    expect_inventory(engine.state);
  });

  test('a returned stack top participates in ordinary triple settlement', () {
    final engine = reserve_board();
    move_two_batches(engine);
    expect(engine.tap_tile(9).accepted, isTrue);
    expect(engine.tap_tile(15).accepted, isTrue);
    expect(engine.return_reserve(3).matched_ids.toSet(), {3, 9, 15});
    expect(engine.state.tray, isEmpty);
    expect(engine.state.reserve.length, 5);
    expect_inventory(engine.state);
  });

  test(
    'Undo after two Removes preserves both spent charges and valid stacks',
    () {
      final engine = reserve_board();
      move_two_batches(engine);
      final restored = TileQuestEngine.restore(copy_json(engine.export_json()));
      expect(restored.undo().accepted, isTrue);
      expect(restored.state.reserve, [0, 1, 2]);
      expect(restored.state.tray, [3, 4]);
      expect(restored.state.tile_by_id(5).is_removed, isFalse);
      expect(restored.state.tools[TileQuestTool.remove], 0);
      expect(restored.state.tools[TileQuestTool.undo], 0);
      expect(restored.state.tools_used, 3);
      expect_inventory(restored.state);
    },
  );

  test(
    'save round trip preserves columns, depth, quotas and returned gaps',
    () {
      final engine = reserve_board();
      move_two_batches(engine);
      engine.return_reserve(4);
      final saved = copy_json(engine.export_json());
      final restored = TileQuestEngine.restore(saved);
      expect(restored.export_json(), saved);
      expect(restored.state.reserve_column(5), 2);
      expect(restored.state.reserve_depth(5), 1);
      expect(restored.state.is_reserve_available(1), isTrue);
      expect_inventory(restored.state);
    },
  );

  test(
    'legacy saves migrate a used Remove and derive its physical columns',
    () {
      final engine = reserve_board();
      engine.tap_tile(0);
      engine.tap_tile(1);
      engine.remove();
      final old = copy_json(engine.export_json());
      old['version'] = 1;
      for (final key in ['state', 'undo_state']) {
        final state = old[key] as Map<String, dynamic>?;
        if (state == null) continue;
        state['version'] = 1;
        state.remove('reserve_columns');
        (state['tools'] as Map)['remove']--;
      }
      final migrated = TileQuestEngine.restore(old);
      expect(migrated.state.tools[TileQuestTool.remove], 1);
      expect(migrated.state.tools_used, 1);
      expect(migrated.state.reserve_columns, {0: 0, 1: 1});
      expect(migrated.export_json()['version'], TileQuestConfig.save_version);
      expect_inventory(migrated.state);
    },
  );

  test('corrupt reserve columns, depth and quota are rejected', () {
    final engine = reserve_board();
    move_two_batches(engine);
    final mutations = <void Function(Map<String, dynamic>)>[
      (json) => (json['state']['reserve_columns'] as Map).remove('0'),
      (json) => json['state']['reserve_columns']['0'] = 3,
      (json) => json['state']['reserve_columns']['1'] = 0,
      (json) => json['state']['reserve_columns']['999'] = 0,
      (json) => json['state']['tools']['remove'] = 3,
      (json) => json['state']['tool_limits']['remove'] = 9,
      (json) => json['state']['tool_limits']['remove'] = 'two',
      (json) => (json['state']['tool_limits'] as Map).remove('remove'),
    ];
    for (final mutate in mutations) {
      final saved = copy_json(engine.export_json());
      mutate(saved);
      expect(() => TileQuestEngine.restore(saved), throwsFormatException);
    }
  });

  test('v2 saves persist original tool quotas and migrate a changed quota', () {
    final engine = reserve_board();
    engine.update_metadata(unlocked_level: 2, sound_enabled: false);
    engine.tap_tile(0);
    engine.remove();
    final saved = copy_json(engine.export_json());
    expect(saved['state']['tool_limits']['remove'], 2);
    // This challenge used one of three prior charges. A build with a quota of
    // two must still read the same one spent charge and preserve preferences.
    for (final key in ['state', 'undo_state']) {
      final state = saved[key] as Map<String, dynamic>?;
      if (state == null) continue;
      state['tool_limits']['remove'] = 3;
      state['tools']['remove']++;
    }
    final restored = TileQuestEngine.restore(saved);
    expect(restored.state.tools[TileQuestTool.remove], 1);
    expect(restored.state.tools_used, 1);
    expect(restored.state.unlocked_level, 2);
    expect(restored.state.sound_enabled, isFalse);
    expect_inventory(restored.state);
  });

  test(
    'early v2 without tool limits keeps settings and spent Remove count',
    () {
      final engine = reserve_board();
      engine.update_metadata(unlocked_level: 2, sound_enabled: false);
      engine.tap_tile(0);
      engine.remove();
      final saved = copy_json(engine.export_json());
      for (final key in ['state', 'undo_state']) {
        (saved[key] as Map<String, dynamic>?)?.remove('tool_limits');
      }
      final restored = TileQuestEngine.restore(saved);
      expect(restored.state.tools[TileQuestTool.remove], 1);
      expect(restored.state.tools_used, 1);
      expect(restored.state.unlocked_level, 2);
      expect(restored.state.sound_enabled, isFalse);
      expect_inventory(restored.state);
    },
  );

  test('solution certificates reject covered reserve returns', () {
    final engine = reserve_board();
    move_two_batches(engine);
    final check = TileQuestValidator.validate_solution(engine.state, [0]);
    expect(check.valid, isFalse);
    expect(check.reason, contains('covered'));
  });

  test('Shuffle certifies all six reserve tiles using only exposed tops', () {
    final engine = reserve_board();
    move_two_batches(engine);
    final before = engine.state;
    final result = engine.shuffle(seed: 2026);
    expect(result.accepted, isTrue, reason: result.reason);
    expect(engine.state.reserve, before.reserve);
    expect(engine.state.reserve_columns, before.reserve_columns);
    expect(TileQuestValidator.validate_solution(engine.state).valid, isTrue);
    for (final id in List<int>.from(engine.state.certified_solution)) {
      final action = engine.state.reserve.contains(id)
          ? engine.return_reserve(id)
          : engine.tap_tile(id);
      expect(action.accepted, isTrue, reason: '$id: ${action.reason}');
      expect_inventory(engine.state);
    }
    expect(engine.state.status, TileQuestStatus.won);
  });

  test(
    'Shuffle can unlock cyclic reserve dependencies without covered picks',
    () {
      // Bottom A B C, top B C A: no type has two immediately exposed reserves.
      final engine = reserve_board([0, 1, 2, 1, 2, 0, 0, 1, 2]);
      move_two_batches(engine);
      final result = engine.shuffle(seed: 99);
      expect(result.accepted, isTrue, reason: result.reason);
      expect(TileQuestValidator.validate_solution(engine.state).valid, isTrue);
      for (final id in List<int>.from(engine.state.certified_solution)) {
        final action = engine.state.reserve.contains(id)
            ? engine.return_reserve(id)
            : engine.tap_tile(id);
        expect(action.accepted, isTrue);
      }
      expect(engine.state.status, TileQuestStatus.won);
      expect_inventory(engine.state);
    },
  );

  test('an unsafe six-reserve Shuffle preserves inventory and its charge', () {
    final engine = reserve_board([
      for (var copy = 0; copy < 3; copy++)
        ...List.generate(12, (index) => index),
    ]);
    move_two_batches(engine);
    for (var id = 6; id < 12; id++) {
      expect(engine.tap_tile(id).accepted, isTrue);
    }
    expect(engine.state.tray.length, 6);
    expect(engine.state.reserve.length, 6);
    final before = copy_json(engine.export_json());
    expect(engine.shuffle(seed: 7).accepted, isFalse);
    expect(engine.export_json(), before);
    expect(engine.state.tools[TileQuestTool.shuffle], 1);
    expect_inventory(engine.state);
  });
}
