// ignore_for_file: non_constant_identifier_names
import 'dart:math';
import 'config.dart';
import 'expert_barrier.dart';
import 'geometry.dart';
import 'layout_patterns.dart';
import 'models.dart';
import 'tutorial_layout.dart';
import 'type_allocator.dart';
import 'validator.dart';

/// Seeded random footprints, a gentle visible opening, then harder hidden phases.
class TileQuestGenerator {
  static TileQuestState generate({
    required int level,
    required int seed,
    String? challenge_id,
    int unlocked_level = 1,
    int? difficulty,
  }) {
    if (level < 1 || level > 2 || seed < 0 || seed > TileQuestConfig.max_seed) {
      throw ArgumentError('Unsupported level or seed');
    }
    if (level == 1) {
      return TileQuestTutorial.generate_state(
        seed: seed,
        challenge_id: challenge_id,
        unlocked_level: unlocked_level,
      );
    }
    final chosen_difficulty = difficulty ?? TileQuestConfig.gameDifficulty;
    final profile = DifficultyProfile.for_difficulty(chosen_difficulty);
    final stopwatch = Stopwatch()..start();
    for (
      var attempt = 0;
      attempt < TileQuestConfig.max_generation_attempts;
      attempt++
    ) {
      try {
        final random = Random(seed ^ (attempt * 7919));
        final expert = chosen_difficulty == 10;
        final lead_profile = expert
            ? profile.with_inventory(
                tile_count: profile.tile_count - 39,
                type_count: profile.type_count - 13,
              )
            : profile;
        final lead_tiles = TileQuestLayoutPatterns.generate(
          lead_profile,
          random,
        );
        final graph = TileQuestGeometry(lead_tiles);
        final opening =
            graph
                .refresh(lead_tiles)
                .where((tile) => !tile.is_blocked)
                .map((tile) => tile.id)
                .toList()
              ..shuffle(random);
        final cleared_opening = opening.toSet();
        // The easy cap is intentionally first. Hidden runs choose random local
        // branches, then jump to another seeded region; there is no fixed scan.
        final lead_order = <int>[
          ...opening,
          ..._hidden_order(
            lead_tiles
                .map(
                  (tile) => tile.copy_with(
                    is_removed: cleared_opening.contains(tile.id),
                  ),
                )
                .toList(),
            graph,
            lead_profile,
            random,
          ),
        ];
        final sequence = TileQuestTypeAllocator.initial(
          lead_profile,
          opening_count: opening.length,
          random: random,
          delayed_match_groups: chosen_difficulty == 9
              ? _delayed_groups(lead_tiles, graph, lead_order, random)
              : const [],
        );
        final assigned = {
          for (var index = 0; index < lead_order.length; index++)
            lead_order[index]: sequence[index],
        };
        final tiles = lead_tiles
            .map((tile) => tile.copy_with(type: assigned[tile.id]!))
            .toList();
        final front_ids = <int>[];
        final partner_ids = <int>[];
        if (expert) _append_barrier(tiles, front_ids, partner_ids);

        // Identity, storage order and sprite palette are independent of the
        // witness order. Iterating ids or walking left-to-right cannot reveal it.
        final identities = List<int>.generate(tiles.length, (index) => index)
          ..shuffle(random);
        final new_id = {
          for (var index = 0; index < tiles.length; index++)
            tiles[index].id: identities[index],
        };
        final palette = List<int>.generate(
          TileQuestConfig.max_tile_types,
          (index) => index,
        )..shuffle(random);
        final mirror_x = random.nextBool();
        final mirror_y = random.nextBool();
        final remapped =
            tiles
                .map(
                  (tile) => TileQuestTile(
                    id: new_id[tile.id]!,
                    type: palette[tile.type],
                    layer: tile.layer,
                    x: mirror_x
                        ? TileQuestConfig.board_logical_width -
                              tile.x -
                              tile.width
                        : tile.x,
                    y: mirror_y
                        ? TileQuestConfig.board_logical_height -
                              tile.y -
                              tile.height
                        : tile.y,
                    width: tile.width,
                    height: tile.height,
                  ),
                )
                .toList()
              ..shuffle(random);
        final final_order = lead_order.map((id) => new_id[id]!).toList();
        final barrier = expert
            ? TileQuestExpertBarrier(
                front_ids: front_ids.map((id) => new_id[id]!).toList(),
                partner_ids: partner_ids.map((id) => new_id[id]!).toList(),
                lead_solution: final_order,
              )
            : null;
        final tool_witness = barrier?.solution(final_order);
        final state = TileQuestState(
          tiles: TileQuestGeometry(remapped).refresh(remapped),
          level: 2,
          difficulty: chosen_difficulty,
          seed: seed,
          challenge_id: challenge_id ?? 'tile_quest_2_$seed',
          unlocked_level: max(2, unlocked_level).clamp(1, 2),
          expert_barrier: barrier,
          certified_solution: barrier == null
              ? final_order
              : TileQuestConfig.remove_uses_per_challenge >=
                    TileQuestExpertBarrier.required_remove_uses
              ? tool_witness!
              : const [],
        );
        final check = barrier == null
            ? TileQuestValidator.validate_solution(state)
            : TileQuestValidator.validate_tool_solution(
                state,
                tool_witness!,
                remove_uses: TileQuestExpertBarrier.required_remove_uses,
              );
        if (check.valid) {
          barrier?.validate(state);
          return state;
        }
      } on StateError {
        // Retry a complete seeded construction, never force a player's result.
      }
      if (stopwatch.elapsedMilliseconds >=
          TileQuestConfig.generation_budget_ms) {
        break;
      }
    }
    throw StateError(
      'A verified phased board could not be generated within its budget',
    );
  }

  /// Two unique triples interleave along one real geometric corridor. The first
  /// pair and the other type's first tile must be held before either closure.
  /// Three persistent tiles leave room for mixed ordinary groups; two pairs
  /// would force ordinary triples into a more easily recognized sequence. The
  /// allocator still builds a complete legal path within the six safe slots.
  static List<List<int>> _delayed_groups(
    List<TileQuestTile> tiles,
    TileQuestGeometry graph,
    List<int> order,
    Random random,
  ) {
    final by_id = {for (final tile in tiles) tile.id: tile};
    final max_layer = tiles.map((tile) => tile.layer).reduce(max);
    final candidates =
        tiles.where((tile) => tile.layer <= max_layer ~/ 8).toList()
          ..shuffle(random);
    for (final target in candidates) {
      final chain = <int>[target.id];
      var current = target;
      while (current.layer < max_layer) {
        final above = graph.blockers[current.id]!
            .where((id) => by_id[id]!.layer == current.layer + 1)
            .toList();
        if (above.isEmpty) break;
        current = by_id[above[random.nextInt(above.length)]]!;
        chain.add(current.id);
      }
      if (chain.length < 24 || current.layer != max_layer) continue;
      final ordered = chain.reversed.toList();
      final groups = [
        [ordered[1], ordered[3], ordered[ordered.length - 5]],
        [ordered[5], ordered[ordered.length - 3], ordered.last],
      ];
      final before_first_close = _reachable(groups[0].last, graph.blockers);
      final after_overlap = _reachable(groups[1].first, graph.supported);
      if (before_first_close.intersection(after_overlap).length < 12) {
        continue;
      }
      return groups.map((ids) => ids.map(order.indexOf).toList()).toList();
    }
    throw StateError('A deep mandatory key corridor could not be constructed');
  }

  static Set<int> _reachable(int start, Map<int, Set<int>> edges) {
    final result = <int>{};
    final pending = edges[start]!.toList();
    while (pending.isNotEmpty) {
      final id = pending.removeLast();
      if (result.add(id)) pending.addAll(edges[id]!);
    }
    return result;
  }

  /// Commit to a random cluster for a bounded run, with random choices inside
  /// it. The witness no longer corresponds to nearest-neighbor or layer order,
  /// while distant exposed helpers receive later, potentially misleading types.
  static List<int> _hidden_order(
    List<TileQuestTile> tiles,
    TileQuestGeometry geometry,
    DifficultyProfile profile,
    Random random,
  ) {
    if (profile.difficulty <= 5) return geometry.removal_order(tiles, random);
    final by_id = {for (final tile in tiles) tile.id: tile};
    final remaining = tiles
        .where((tile) => !tile.is_removed)
        .map((tile) => tile.id)
        .toSet();
    final result = <int>[];
    TileQuestTile? anchor;
    var run_left = 0;
    var radius_squared = 0.0;
    final commitment = profile.difficulty >= 9
        ? .98
        : profile.difficulty == 8
        ? .9
        : .7;
    while (remaining.isNotEmpty) {
      final available = remaining
          .where((id) => !geometry.blockers[id]!.any(remaining.contains))
          .toList();
      if (available.isEmpty) throw StateError('Random hidden dependency cycle');
      if (run_left == 0 || anchor == null) {
        anchor = by_id[available[random.nextInt(available.length)]]!;
        run_left = 8 + random.nextInt(13);
        final radius = 1.1 + random.nextDouble() * 1.1;
        radius_squared = radius * radius;
      }
      final origin = anchor;
      final local = available.where((id) {
        final tile = by_id[id]!;
        final dx = tile.x - origin.x;
        final dy = tile.y - origin.y;
        return dx * dx + dy * dy <= radius_squared;
      }).toList();
      final pool = local.isNotEmpty && random.nextDouble() < commitment
          ? local
          : available;
      final chosen = pool[random.nextInt(pool.length)];
      remaining.remove(chosen);
      result.add(chosen);
      run_left--;
      if (local.isEmpty) run_left = 0;
    }
    return result;
  }

  /// Thirteen unmatched fronts precede all of their partners. The independent
  /// 2×1 area needs 13 held tiles, while two Removes hold only 6+2×3=12 safely.
  /// Two partner cards per layer compress the fully static proof to 26 layers.
  static void _append_barrier(
    List<TileQuestTile> tiles,
    List<int> front_ids,
    List<int> partner_ids,
  ) {
    for (var index = 0; index < TileQuestExpertBarrier.front_count; index++) {
      final id = tiles.length;
      front_ids.add(id);
      tiles.add(
        TileQuestTile(
          id: id,
          type: 19 + index,
          layer: 25 - index,
          x: 5.5,
          y: 7,
        ),
      );
    }
    for (var pair = 0; pair < TileQuestExpertBarrier.front_count; pair++) {
      for (var column = 0; column < 2; column++) {
        final id = tiles.length;
        partner_ids.add(id);
        tiles.add(
          TileQuestTile(
            id: id,
            type: 31 - pair,
            layer: 12 - pair,
            x: 5.0 + column,
            y: 7,
          ),
        );
      }
    }
  }
}
