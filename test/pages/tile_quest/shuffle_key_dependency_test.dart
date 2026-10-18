// ignore_for_file: non_constant_identifier_names
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/expert_barrier.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/geometry.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/game/validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'certificate_replay.dart';

TileQuestState key_fixture() {
  final tiles = <TileQuestTile>[
    for (var id = 0; id < 18; id++)
      TileQuestTile(
        id: id,
        type: 1 + id ~/ 6,
        layer: 0,
        x: 2 + (id % 6).toDouble(),
        y: (id ~/ 6).toDouble(),
      ),
    for (var index = 0; index < 3; index++)
      TileQuestTile(id: 18 + index, type: 0, layer: 2 - index, x: 0, y: 0),
    for (
      var index = 0;
      index < TileQuestExpertBarrier.tool_front_types.length;
      index++
    )
      TileQuestTile(
        id: 21 + index,
        type: 4 + TileQuestExpertBarrier.tool_front_types[index],
        layer: TileQuestExpertBarrier.tool_tile_count - 1 - index,
        x: 5.5,
        y: 7,
      ),
    for (
      var index = 0;
      index < TileQuestExpertBarrier.tool_partner_types.length;
      index++
    )
      TileQuestTile(
        id: 28 + index,
        type: 4 + TileQuestExpertBarrier.tool_partner_types[index],
        layer:
            (TileQuestExpertBarrier.tool_partner_types.length - 1 - index) ~/ 2,
        x: 5.0 + index % 2,
        y: 7,
      ),
  ];
  final barrier = TileQuestExpertBarrier(
    front_ids: List.generate(
      TileQuestExpertBarrier.tool_front_types.length,
      (index) => 21 + index,
    ),
    partner_ids: List.generate(
      TileQuestExpertBarrier.tool_partner_types.length,
      (index) => 28 + index,
    ),
    lead_solution: List.generate(21, (index) => index),
  );
  return TileQuestState(
    tiles: TileQuestGeometry(tiles).refresh(tiles),
    level: 2,
    difficulty: 9,
    seed: 712,
    challenge_id: 'rare-key-dependency',
    unlocked_level: 2,
    expert_barrier: barrier,
    certified_solution: barrier.witness,
  );
}

void fixed_keys(TileQuestState before, TileQuestState after) {
  for (var id = 18; id < 21; id++) {
    expect(after.tile_by_id(id).to_json(), before.tile_by_id(id).to_json());
  }
  expect(
    after.tiles.where((tile) => tile.type == 0).map((tile) => tile.id).toSet(),
    {18, 19, 20},
  );
}

/// Ordinary hidden helpers are part of the puzzle too: no original type may
/// split into several new types, and distinct original groups must stay distinct.
void same_matching_relations(TileQuestState before, TileQuestState after) {
  final renamed = <int, int>{};
  final held = {...before.tray, ...before.reserve};
  for (final tile in before.tiles) {
    final next = after.tile_by_id(tile.id);
    expect(next.x, tile.x);
    expect(next.y, tile.y);
    expect(next.layer, tile.layer);
    expect(next.is_removed, tile.is_removed);
    if (tile.is_removed) {
      expect(next.type, tile.type);
      continue;
    }
    final previous = renamed.putIfAbsent(tile.type, () => next.type);
    expect(next.type, previous);
  }
  expect(renamed.values.toSet().length, renamed.length);
  for (final id in held) {
    expect(after.tile_by_id(id).type, before.tile_by_id(id).type);
    final held_type = before.tile_by_id(id).type;
    if (renamed.containsKey(held_type)) expect(renamed[held_type], held_type);
  }
}

void main() {
  test('generated ninth difficulty preserves every rare key on Shuffle', () {
    for (final seed in [0, 17, 730, 104729]) {
      final engine = TileQuestEngine(
        TileQuestGenerator.generate(level: 2, difficulty: 9, seed: seed),
      );
      final before = engine.state;
      final counts = <int, int>{};
      for (final tile in before.tiles) {
        counts[tile.type] = (counts[tile.type] ?? 0) + 1;
      }
      final rare_keys = before.tiles
          .where((tile) => counts[tile.type] == 3)
          .toList();
      final core_types = before.expert_barrier!.front_ids
          .map((id) => before.tile_by_id(id).type)
          .toSet();
      expect(
        rare_keys.where((tile) => !core_types.contains(tile.type)),
        hasLength(6),
      );
      expect(engine.shuffle(seed: seed + 63).accepted, isTrue);
      for (final tile in rare_keys) {
        expect(engine.state.tile_by_id(tile.id).to_json(), tile.to_json());
      }
      same_matching_relations(before, engine.state);
      expect(TileQuestValidator.validate_solution(engine.state).valid, isTrue);
    }
  });

  test(
    'a valid witness uses a real type bijection without moving rare keys',
    () {
      final engine = TileQuestEngine(key_fixture());
      final before = engine.state;
      expect(engine.shuffle(seed: 63).accepted, isTrue);
      fixed_keys(before, engine.state);
      same_matching_relations(before, engine.state);
      expect(engine.state.certified_solution, before.certified_solution);
      expect(
        engine.state.tiles.where(
          (tile) => tile.type != before.tile_by_id(tile.id).type,
        ),
        isNotEmpty,
      );
      expect(TileQuestValidator.validate_solution(engine.state).valid, isTrue);
      TileQuestValidator.validate_state(engine.state);
    },
  );

  test('off-path search fixes key identities or refuses atomically', () {
    var accepted = 0;
    for (var seed = 0; seed < 12; seed++) {
      final engine = TileQuestEngine(
        key_fixture().copy_with(certified_solution: const []),
      );
      final before = engine.state;
      final snapshot = engine.export_json();
      final result = engine.shuffle(seed: seed);
      fixed_keys(before, engine.state);
      same_matching_relations(before, engine.state);
      if (result.accepted) {
        accepted++;
        expect(
          TileQuestValidator.validate_solution(
            engine.state,
            engine.state.expert_barrier!.witness,
          ).valid,
          isTrue,
        );
        final inventory = before.tiles.map((tile) => tile.type).toList()
          ..sort();
        expect(
          engine.state.tiles.map((tile) => tile.type).toList()..sort(),
          inventory,
        );
        for (final id in engine.state.expert_barrier!.witness) {
          expect(replay_certificate_step(engine, id).accepted, isTrue);
        }
        expect(engine.state.status, TileQuestStatus.won);
        expect(engine.state.tools_used, greaterThanOrEqualTo(1));
      } else {
        expect(engine.export_json(), snapshot);
        expect(engine.state.tools[TileQuestTool.shuffle], 1);
      }
    }
    expect(accepted, greaterThan(0));
  });

  test('a held key is never remapped by fallback search or Undo', () {
    final engine = TileQuestEngine(key_fixture());
    expect(
      engine.tap_tile(18).accepted,
      isTrue,
    ); // Deliberately off the witness.
    expect(engine.remove().accepted, isTrue);
    final before = engine.state;
    final result = engine.shuffle(seed: 312);
    fixed_keys(before, engine.state);
    same_matching_relations(before, engine.state);
    if (result.accepted) {
      expect(TileQuestValidator.validate_solution(engine.state).valid, isTrue);
    }
    expect(engine.undo().accepted, isTrue);
    expect(engine.state.tile_by_id(18).is_removed, isFalse);
    expect(
      engine.state.tiles
          .where((tile) => tile.type == 0)
          .map((tile) => tile.id)
          .toSet(),
      {18, 19, 20},
    );
    TileQuestValidator.validate_state(engine.state);
  });
}
