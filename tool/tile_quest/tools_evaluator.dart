// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/config.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/geometry.dart';
import 'package:app/pages/tile_quest/game/models.dart';

class _ToolEvaluationWorld {
  final TileQuestGeometry graph;
  final int size;
  late List<int> types;
  _ToolEvaluationWorld(TileQuestState state)
    : graph = TileQuestGeometry(state.tiles),
      size = state.tiles.map((t) => t.id).reduce(max) + 1 {
    update(state);
  }
  void update(TileQuestState state) {
    types = List.filled(size, 0);
    for (final t in state.tiles) {
      types[t.id] = t.type;
    }
  }

  _ToolEvaluationPosition snapshot(TileQuestState s) {
    final alive = Uint8List(size);
    for (final t in s.tiles) {
      if (!t.is_removed) alive[t.id] = 1;
    }
    final counts = Int16List(size);
    for (final t in s.tiles) {
      if (alive[t.id] == 1) {
        counts[t.id] = graph.blockers[t.id]!
            .where((id) => alive[id] == 1)
            .length;
      }
    }
    final cols = List<int>.filled(size, -1);
    for (final id in s.reserve) {
      cols[id] = s.reserve_column(id);
    }
    return _ToolEvaluationPosition(
      this,
      alive,
      counts,
      s.clickable_tiles.map((t) => t.id).toList(),
      List.from(s.tray),
      List.from(s.reserve),
      cols,
      s.remaining_count,
      0,
    );
  }
}

class _ToolEvaluationPosition {
  final _ToolEvaluationWorld w;
  final Uint8List alive;
  final Int16List blockers;
  final List<int> available, tray, reserve, cols;
  int remaining, matched;
  _ToolEvaluationPosition(
    this.w,
    this.alive,
    this.blockers,
    this.available,
    this.tray,
    this.reserve,
    this.cols,
    this.remaining,
    this.matched,
  );
  List<int> choices() {
    final result = List<int>.from(available);
    for (var i = 0; i < reserve.length; i++) {
      final id = reserve[i];
      if (!reserve.skip(i + 1).any((j) => cols[j] == cols[id])) result.add(id);
    }
    return result;
  }

  int count(int type) => tray.where((id) => w.types[id] == type).length;
  double priority(int id) {
    final c = count(w.types[id]);
    var release = 0;
    if (alive[id] == 1) {
      for (final lower in w.graph.supported[id]!) {
        if (alive[lower] == 1 && blockers[lower] == 1) release++;
      }
    }
    return c * 100 + release * .6 + (alive[id] == 0 ? .2 : 0);
  }

  _ToolEvaluationPosition? move(int id) {
    if (tray.length >= 7) return null;
    final next = _ToolEvaluationPosition(
      w,
      Uint8List.fromList(alive),
      Int16List.fromList(blockers),
      List.from(available),
      List.from(tray),
      List.from(reserve),
      cols,
      remaining,
      matched,
    );
    if (next.alive[id] == 1) {
      next.alive[id] = 0;
      next.remaining--;
      next.available.remove(id);
      for (final lower in w.graph.supported[id]!) {
        if (next.alive[lower] == 0) continue;
        next.blockers[lower]--;
        if (next.blockers[lower] == 0) next.available.add(lower);
      }
    } else {
      next.reserve.remove(id);
    }
    final type = w.types[id];
    final at = next.tray.lastIndexWhere((j) => w.types[j] == type);
    next.tray.insert(at < 0 ? next.tray.length : at + 1, id);
    final group = next.tray.where((j) => w.types[j] == type).toList();
    if (group.length == 3) {
      next.tray.removeWhere(group.contains);
      next.matched += 3;
    }
    if (next.tray.length >= 7) return null;
    return next;
  }

  double score() {
    if (remaining == 0 && tray.isEmpty && reserve.isEmpty) return 1000000;
    final c = <int, int>{};
    for (final id in tray) {
      c[w.types[id]] = (c[w.types[id]] ?? 0) + 1;
    }
    const pressure = [0.0, 1.0, 3.0, 6.0, 11.0, 20.0, 48.0];
    return matched * 28 -
        pressure[tray.length] +
        c.values.where((v) => v == 2).length * 1.3 +
        available.length * .025 -
        reserve.length * .25;
  }
}

class _ToolEvaluationPlanner {
  static const int search_depth = 3;
  static const int expansion_budget = 144;
  static const int root_candidates = 7;
  static const int branch_candidates = 4;
  int nodes = 0;
  double search(_ToolEvaluationPosition s, int depth) {
    if (depth == 0 || ++nodes >= expansion_budget) return s.score();
    final candidates = s.choices();
    final priorities = {for (final id in candidates) id: s.priority(id)};
    candidates.sort((a, b) => priorities[b]!.compareTo(priorities[a]!));
    if (candidates.isEmpty) {
      return s.remaining == 0 && s.tray.isEmpty && s.reserve.isEmpty
          ? 1000000
          : -1000000;
    }
    var best = -1000000.0;
    for (final id in candidates.take(branch_candidates)) {
      final next = s.move(id);
      if (next == null) continue;
      final value = search(next, depth - 1);
      if (value > best) best = value;
      if (nodes >= expansion_budget) break;
    }
    return best;
  }

  int? choose(_ToolEvaluationPosition s, Set<int> banned) {
    nodes = 0;
    var choices = s.choices().where((id) => !banned.contains(id)).toList();
    if (choices.isEmpty) choices = s.choices();
    if (choices.isEmpty) return null;
    final priorities = {for (final id in choices) id: s.priority(id)};
    choices.sort((a, b) => priorities[b]!.compareTo(priorities[a]!));
    // Always accept an immediately completing triple; inspect alternatives within
    // the same greedy class, then prefer safe three-move continuation.
    final top = s.count(s.w.types[choices.first]);
    final pool = top == 2
        ? choices.where((id) => s.count(s.w.types[id]) == 2).toList()
        : choices;
    var best = pool.first;
    var score = -10000000.0;
    for (final id in pool.take(root_candidates)) {
      final next = s.move(id);
      final value = next == null ? -1000000.0 : search(next, search_depth - 1);
      if (value > score) {
        score = value;
        best = id;
      }
    }
    return best;
  }
}

Map<String, Object> run(int seed, int difficulty, {bool allow_shuffle = true}) {
  final engine = TileQuestEngine(
    TileQuestGenerator.generate(level: 2, seed: seed, difficulty: difficulty),
  );
  final inventory = <int, int>{};
  for (final t in engine.state.tiles) {
    inventory[t.type] = (inventory[t.type] ?? 0) + 1;
  }
  final barrier_types =
      engine.state.expert_barrier?.front_ids
          .map((id) => engine.state.tile_by_id(id).type)
          .toSet() ??
      <int>{};
  final key_types = inventory.entries
      .where((e) => e.value == 3 && !barrier_types.contains(e.key))
      .map((e) => e.key)
      .toSet();
  int shuffle_at = -1,
      key_board = -1,
      key_reserve = -1,
      key_tray = -1,
      changed_faces = 0;
  final world = _ToolEvaluationWorld(engine.state);
  final planner = _ToolEvaluationPlanner();
  final banned = <int>{};
  var steps = 0,
      taps = 0,
      returns = 0,
      remove = 0,
      undo = 0,
      shuffle = 0,
      shuffle_rejected = 0;
  final shuffle_states = <String>{};
  int? last_id;
  final watch = Stopwatch()..start();
  for (var turn = 0; turn < 2500; turn++) {
    final state = engine.state;
    if (state.status == TileQuestStatus.won) break;
    if (state.status == TileQuestStatus.lost) {
      final r = engine.undo();
      if (!r.accepted) break;
      undo++;
      if (last_id != null) banned.add(last_id);
      world.update(engine.state);
      continue;
    }
    world.update(state);
    final sim = world.snapshot(state);
    final choices = sim.choices();
    if (choices.isEmpty) break;
    final immediate = choices.any((id) => sim.count(world.types[id]) == 2);
    if (state.tray.length >= 5 && !immediate) {
      if ((state.tools[TileQuestTool.remove] ?? 0) > 0) {
        final r = engine.remove();
        if (r.accepted) {
          remove++;
          continue;
        }
      }
      final shuffle_key =
          '${state.remaining_count}/${state.tray.join(',')}/${state.reserve.join(',')}';
      if (allow_shuffle &&
          (state.tools[TileQuestTool.shuffle] ?? 0) > 0 &&
          shuffle_states.add(shuffle_key)) {
        shuffle_at = steps;
        key_board = state.tiles
            .where((t) => !t.is_removed && key_types.contains(t.type))
            .length;
        key_reserve = state.reserve
            .where((id) => key_types.contains(world.types[id]))
            .length;
        key_tray = state.tray
            .where((id) => key_types.contains(world.types[id]))
            .length;
        final r = engine.shuffle(seed: 918731);
        if (r.accepted) {
          shuffle++;
          changed_faces = engine.state.tiles
              .where((t) => !t.is_removed && t.type != world.types[t.id])
              .length;
          world.update(engine.state);
          continue;
        }
        shuffle_rejected++;
      }
      // Undo the preceding choice BEFORE making an inevitable seventh singleton.
      if (state.tray.length == 6 && engine.can_undo) {
        final r = engine.undo();
        if (r.accepted) {
          undo++;
          if (last_id != null) banned.add(last_id);
          world.update(engine.state);
          continue;
        }
      }
    }
    final id = planner.choose(sim, banned);
    if (id == null) break;
    final is_reserve = state.reserve.contains(id);
    final result = is_reserve ? engine.return_reserve(id) : engine.tap_tile(id);
    if (!result.accepted) {
      throw StateError('bot emitted illegal choice: ${result.reason}');
    }
    steps++;
    if (is_reserve) {
      returns++;
    } else {
      taps++;
    }
    last_id = id;
    banned.clear();
  }
  if (difficulty >= TileQuestConfig.mandatory_tool_difficulty &&
      engine.state.status == TileQuestStatus.won &&
      remove == 0) {
    throw StateError('Mandatory tool barrier cleared without Remove');
  }
  return {
    'seed': seed,
    'minimum_remove_uses':
        engine.state.expert_barrier?.minimum_remove_uses ?? 0,
    'won': engine.state.status == TileQuestStatus.won,
    'status': engine.state.status.name,
    'steps': steps,
    'board_taps': taps,
    'reserve_returns': returns,
    'remaining': engine.state.remaining_count,
    'remove': remove,
    'undo': undo,
    'shuffle': shuffle,
    'shuffle_rejected': shuffle_rejected,
    'shuffle_at': shuffle_at,
    'key_board': key_board,
    'key_reserve': key_reserve,
    'key_tray': key_tray,
    'changed_faces': changed_faces,
    'ms': watch.elapsedMilliseconds,
  };
}

/// Reproduce the independent three-move tool policy without reading certificates.
/// Usage: fvm dart run tool/tile_quest/tools_evaluator.dart [count=40]
/// [difficulty=9] [cohort=baseline|heldout|confirmation].
void main(List<String> args) {
  final count = args.isEmpty ? 40 : int.tryParse(args[0]) ?? 0;
  final difficulty = args.length < 2 ? 9 : int.tryParse(args[1]) ?? 0;
  final cohort = args.length < 3 ? 'baseline' : args[2];
  const cohorts = {
    'baseline': (start: 1200007, stride: 524287),
    'heldout': (start: 91000009, stride: 104729),
    'confirmation': (start: 137000003, stride: 15485863),
  };
  final seeds = cohorts[cohort];
  if (count < 1 ||
      count > 10000 ||
      difficulty < 1 ||
      difficulty > 10 ||
      seeds == null) {
    throw ArgumentError(
      'Expected 1–10000 samples, difficulty 1–10 and a known cohort.',
    );
  }
  final results = <Map<String, Object>>[];
  for (var index = 0; index < count; index++) {
    results.add(
      run((seeds.start + seeds.stride * index) % 2147483648, difficulty),
    );
  }
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'schema_version': 1,
      'note':
          'A finite optimistic policy sample is not a human win probability. '
          'The policy reads no certificate, uses the real engine and actual reserve stacks, '
          'and may attempt Shuffle without a successful continuation. '
          'Key inventory diagnostics count rare ordinary lead types; static '
          'mandatory-tool barrier types are excluded.',
      'difficulty': difficulty,
      'cohort': cohort,
      'seed_start': seeds.start,
      'seed_stride': seeds.stride,
      'seed_modulus': 2147483648,
      'search_depth': _ToolEvaluationPlanner.search_depth,
      'search_expansion_budget_per_decision':
          _ToolEvaluationPlanner.expansion_budget,
      'samples': count,
      'wins': results.where((result) => result['won'] == true).length,
      'results': results,
    }),
  );
}
