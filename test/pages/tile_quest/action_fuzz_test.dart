// ignore_for_file: constant_identifier_names, non_constant_identifier_names
import 'dart:convert';
import 'dart:math';
import 'package:app/pages/tile_quest/game/config.dart';
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/game/validator.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _disk_copy(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

/// A small fully exposed inventory makes boundary and tool-order cases explicit.
TileQuestEngine _flat_board(List<int> types) => TileQuestEngine(
  TileQuestState(
    tiles: [
      for (var id = 0; id < types.length; id++)
        TileQuestTile(
          id: id,
          type: types[id],
          layer: 0,
          x: (id % 8).toDouble(),
          y: (id ~/ 8).toDouble(),
        ),
    ],
    level: 1,
    seed: 1,
    challenge_id: 'action-boundary',
  ),
);

/// Check independently visible conservation, stable topology and spent quotas.
/// The strict production validator additionally checks geometric blockers,
/// settled groups, stack capacities, exact per-type conservation and any proof.
void _invariants(
  TileQuestState state,
  TileQuestState initial,
  Map<TileQuestTool, int> previous_tools,
) {
  expect(
    state.remaining_count +
        state.tray.length +
        state.reserve.length +
        state.matched_count,
    initial.total_count,
  );
  final old_types = initial.tiles.map((tile) => tile.type).toList()..sort();
  final new_types = state.tiles.map((tile) => tile.type).toList()..sort();
  expect(new_types, old_types);
  for (final tool in TileQuestTool.values) {
    expect(state.tools[tool], lessThanOrEqualTo(previous_tools[tool]!));
  }
  for (final tile in state.tiles) {
    final original = initial.tile_by_id(tile.id);
    expect(
      [tile.x, tile.y, tile.width, tile.height, tile.layer],
      [original.x, original.y, original.width, original.height, original.layer],
    );
  }
  for (var column = 0; column < TileQuestConfig.reserve_columns; column++) {
    final stack = state.reserve
        .where((id) => state.reserve_column(id) == column)
        .toList();
    for (var depth = 0; depth < stack.length; depth++) {
      expect(state.reserve_depth(stack[depth]), depth);
      expect(
        state.is_reserve_available(stack[depth]),
        depth == stack.length - 1,
      );
    }
  }
  TileQuestValidator.validate_state(state);
}

/// Verify rejection includes private Undo history, not just the public snapshot.
void _rejected_unchanged(
  TileQuestEngine engine,
  TileQuestActionResult Function() attempt,
) {
  final saved = _disk_copy(engine.export_json());
  final result = attempt();
  expect(result.accepted, isFalse, reason: result.reason);
  expect(engine.export_json(), saved);
}

void main() {
  test('seventh-slot settlement, loss and restored Undo stay atomic', () {
    final match = _flat_board([0, 0, 1, 2, 3, 4, 0, 1, 1, 2, 2, 3, 3, 4, 4]);
    for (var id = 0; id < 6; id++) {
      expect(match.tap_tile(id).accepted, isTrue);
    }
    final sixth = match.state;
    final action = match.tap_tile(6);
    expect(action.settlement_tray, [0, 1, 6, 2, 3, 4, 5]);
    expect(action.matched_ids.toSet(), {0, 1, 6});
    expect(match.state.status, TileQuestStatus.playing);
    final restored = TileQuestEngine.restore(_disk_copy(match.export_json()));
    expect(restored.undo().accepted, isTrue);
    expect(restored.state.tray, sixth.tray);
    expect(restored.state.matched_count, sixth.matched_count);
    expect(restored.state.tile_by_id(6).is_removed, isFalse);
    _rejected_unchanged(restored, restored.undo);
    _invariants(restored.state, sixth, sixth.tools);

    var loss = _flat_board([
      for (var copy = 0; copy < 3; copy++) ...List.generate(7, (type) => type),
    ]);
    final initial = loss.state;
    for (var id = 0; id < 7; id++) {
      expect(loss.tap_tile(id).accepted, isTrue);
    }
    expect(loss.state.status, TileQuestStatus.lost);
    _rejected_unchanged(loss, () => loss.tap_tile(7));
    _rejected_unchanged(loss, loss.remove);
    _rejected_unchanged(loss, () => loss.shuffle(seed: 3));
    _rejected_unchanged(loss, () => loss.return_reserve(0));
    loss = TileQuestEngine.restore(_disk_copy(loss.export_json()));
    expect(loss.undo().accepted, isTrue);
    expect(loss.state.status, TileQuestStatus.playing);
    expect(loss.state.tray, [0, 1, 2, 3, 4, 5]);
    expect(loss.state.tile_by_id(6).is_removed, isFalse);
    _invariants(loss.state, initial, initial.tools);
  });

  test(
    'partial Remove then full Remove retains physical stack tops after Undo',
    () {
      var engine = _flat_board([
        for (var copy = 0; copy < 3; copy++) ...[0, 1, 2, 3, 4, 5],
      ]);
      final initial = engine.state;
      _rejected_unchanged(engine, engine.undo);
      _rejected_unchanged(engine, engine.remove);
      expect(engine.tap_tile(0).accepted, isTrue);
      expect(engine.remove().moved_ids, [0]);
      for (var id = 1; id <= 3; id++) {
        expect(engine.tap_tile(id).accepted, isTrue);
      }
      expect(engine.remove().moved_ids, [1, 2, 3]);
      expect(engine.state.reserve_columns, {0: 0, 1: 0, 2: 1, 3: 2});
      _rejected_unchanged(engine, engine.remove);
      _rejected_unchanged(engine, () => engine.return_reserve(0));
      expect(engine.return_reserve(1).accepted, isTrue);
      _rejected_unchanged(engine, () => engine.return_reserve(1));
      expect(engine.state.is_reserve_available(0), isTrue);
      engine = TileQuestEngine.restore(_disk_copy(engine.export_json()));
      expect(engine.undo().accepted, isTrue);
      expect(engine.state.reserve_columns, {0: 0, 1: 0, 2: 1, 3: 2});
      expect(engine.state.is_reserve_available(0), isFalse);
      expect(engine.state.tools[TileQuestTool.remove], 0);
      _invariants(engine.state, initial, initial.tools);
    },
  );

  test('two Removes then Shuffle and restored Undo never refund any tool', () {
    var engine = _flat_board([
      for (var copy = 0; copy < 3; copy++) ...[0, 1, 2, 3, 4, 5],
    ]);
    final initial = engine.state;
    for (var id = 0; id < 3; id++) {
      expect(engine.tap_tile(id).accepted, isTrue);
    }
    expect(engine.remove().accepted, isTrue);
    expect(engine.tap_tile(3).accepted, isTrue);
    expect(engine.tap_tile(4).accepted, isTrue);
    final before_last_tap = engine.state;
    expect(engine.tap_tile(5).accepted, isTrue);
    expect(engine.remove().accepted, isTrue);
    final shuffled = engine.shuffle(seed: 2026);
    expect(shuffled.accepted, isTrue, reason: shuffled.reason);
    expect(engine.state.reserve, [0, 1, 2, 3, 4, 5]);
    engine = TileQuestEngine.restore(_disk_copy(engine.export_json()));
    expect(engine.undo().accepted, isTrue);
    expect(engine.state.tray, before_last_tap.tray);
    expect(engine.state.reserve, before_last_tap.reserve);
    expect(engine.state.reserve_columns, before_last_tap.reserve_columns);
    expect(
      engine.state.tiles.map((tile) => tile.to_json()).toList(),
      before_last_tap.tiles.map((tile) => tile.to_json()).toList(),
    );
    expect(engine.state.tools.values, everyElement(0));
    expect(engine.state.tools_used, 4);
    _rejected_unchanged(engine, engine.undo);
    _rejected_unchanged(engine, engine.remove);
    _rejected_unchanged(engine, () => engine.shuffle(seed: 2026));
    _invariants(engine.state, initial, initial.tools);
  });

  test('seeded real-engine action sequences preserve every invariant', () {
    const seed_count = 40;
    const actions_per_seed = 96;
    final coverage = <String, int>{};
    void count(String key) => coverage[key] = (coverage[key] ?? 0) + 1;
    for (var sample = 0; sample < seed_count; sample++) {
      final random = Random(341873 + sample * 104729);
      final difficulty = 1 + sample % 10;
      var engine = TileQuestEngine(
        TileQuestGenerator.generate(
          level: sample % 5 == 0 ? 1 : 2,
          difficulty: difficulty,
          seed: 67867967 + sample * 8191,
        ),
      );
      final initial = engine.state;
      final old_snapshots = <(TileQuestState, String)>[];
      for (var turn = 0; turn < actions_per_seed; turn++) {
        final before = engine.state;
        final previous_tools = before.tools;
        final exported = _disk_copy(engine.export_json());
        TileQuestActionResult result;
        final pick = random.nextInt(100);
        if (pick < 43) {
          final choices = engine.clickable_tiles;
          final pairs = choices
              .where(
                (tile) =>
                    before.tray
                        .where((id) => before.tile_by_id(id).type == tile.type)
                        .length ==
                    2,
              )
              .toList();
          final pool = sample.isEven && pairs.isNotEmpty ? pairs : choices;
          final id = pool.isEmpty ? -999 : pool[random.nextInt(pool.length)].id;
          result = engine.tap_tile(id);
          count('tap_${result.accepted}');
          if (result.accepted) {
            // The same native event arriving again must never duplicate a tile.
            _rejected_unchanged(engine, () => engine.tap_tile(id));
            count('rapid_duplicate_rejected');
          }
        } else if (pick < 54) {
          final invalid = before.tiles
              .where((tile) => tile.is_removed || tile.is_blocked)
              .toList();
          final id = invalid.isEmpty
              ? -999
              : invalid[random.nextInt(invalid.length)].id;
          result = engine.tap_tile(id);
          expect(result.accepted, isFalse);
          count('blocked_or_removed_rejected');
        } else if (pick < 68) {
          final id = before.reserve.isEmpty
              ? -999
              : before.reserve[random.nextInt(before.reserve.length)];
          final available = before.is_reserve_available(id);
          result = engine.return_reserve(id);
          if (!available) expect(result.accepted, isFalse);
          count('return_${result.accepted}');
        } else if (pick < 81) {
          result = engine.remove();
          count('remove_${result.accepted}');
        } else if (pick < 91) {
          result = engine.undo();
          count('undo_${result.accepted}');
        } else {
          result = engine.shuffle(seed: random.nextInt(1 << 30));
          count('shuffle_${result.accepted}');
        }
        expect(result.before, same(before));
        expect(result.after, same(engine.state));
        if (!result.accepted) expect(engine.export_json(), exported);
        if (result.matched_ids.isNotEmpty) {
          expect(result.matched_ids.length, 3);
          count('triple');
        }
        _invariants(engine.state, initial, previous_tools);
        if (turn % 11 == 0) {
          final saved = _disk_copy(engine.export_json());
          engine = TileQuestEngine.restore(saved);
          expect(engine.export_json(), saved);
          count('roundtrip');
          old_snapshots.add((before, jsonEncode(before.to_json())));
        }
        if (engine.state.status == TileQuestStatus.lost) count('loss_state');
      }
      for (final (snapshot, encoded) in old_snapshots) {
        expect(jsonEncode(snapshot.to_json()), encoded);
      }
    }
    expect(coverage['rapid_duplicate_rejected'], greaterThan(300));
    expect(coverage['triple'], greaterThan(20));
    expect(coverage['return_true'], greaterThan(10));
    expect(coverage['remove_true'], greaterThan(30));
    expect(coverage['undo_true'], greaterThan(20));
    expect(coverage['shuffle_true'], greaterThan(5));
    expect(coverage['roundtrip'], seed_count * 9);
    // A compact reproducible tally makes the actual audit scope reviewable.
    // ignore: avoid_print
    print(
      'ACTION_FUZZ seeds=$seed_count scheduled=${seed_count * actions_per_seed} $coverage',
    );
  });
}
