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
    StateError? last_failure;
    for (
      var attempt = 0;
      attempt < TileQuestConfig.max_generation_attempts;
      attempt++
    ) {
      try {
        final random = Random(seed ^ (attempt * 7919));
        final needs_barrier =
            chosen_difficulty >= TileQuestConfig.mandatory_tool_difficulty;
        final lead_profile = needs_barrier
            ? profile.with_inventory(
                tile_count:
                    profile.tile_count -
                    TileQuestExpertBarrier.tile_count_for_difficulty(
                      chosen_difficulty,
                    ),
                type_count:
                    profile.type_count -
                    TileQuestExpertBarrier.type_count_for_difficulty(
                      chosen_difficulty,
                    ),
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
          delayed_match_groups: chosen_difficulty >= 6 && chosen_difficulty <= 9
              ? _delayed_groups(
                  lead_tiles,
                  graph,
                  lead_order,
                  lead_profile,
                  random,
                )
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
        if (needs_barrier) {
          _append_barrier(
            tiles,
            front_ids,
            partner_ids,
            type_start: lead_profile.type_count,
            difficulty: chosen_difficulty,
          );
        }

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
        final barrier = needs_barrier
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
                    barrier.minimum_remove_uses
              ? tool_witness!
              : const [],
        );
        final check = barrier == null
            ? TileQuestValidator.validate_solution(state)
            : TileQuestValidator.validate_tool_solution(
                state,
                tool_witness!,
                remove_uses: barrier.minimum_remove_uses,
              );
        if (check.valid) {
          barrier?.validate(state);
          return state;
        }
      } on StateError catch (error) {
        last_failure = error;
        // Retry a complete seeded construction, never force a player's result.
      }
      if (stopwatch.elapsedMilliseconds >=
          TileQuestConfig.generation_budget_ms) {
        break;
      }
    }
    throw StateError(
      'A verified phased board could not be generated within its budget '
      '(difficulty $chosen_difficulty, seed $seed): $last_failure',
    );
  }

  /// Difficulties 6–8 hold one real rare pair through a mandatory corridor;
  /// difficulty 9 holds two, leaving just two ordinary slots in its long middle
  /// section. Every candidate is scored by actual geometric dependencies, never
  /// by a certificate-only delay that another exposed branch could bypass.
  static List<List<int>> _delayed_groups(
    List<TileQuestTile> tiles,
    TileQuestGeometry graph,
    List<int> order,
    DifficultyProfile profile,
    Random random,
  ) {
    final by_id = {for (final tile in tiles) tile.id: tile};
    final max_layer = tiles.map((tile) => tile.layer).reduce(max);
    final candidates =
        tiles.where((tile) => tile.layer <= max_layer ~/ 8).toList()
          ..shuffle(random);
    final extreme = profile.difficulty == 9;
    final minimum_chain = extreme ? 24 : profile.layers - 2;
    var best_score = -1;
    List<List<int>>? best_groups;
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
      if (chain.length < minimum_chain || current.layer != max_layer) continue;
      final ordered = chain.reversed.toList();
      final groups = extreme
          ? [
              [ordered[1], ordered[2], ordered[ordered.length - 3]],
              [ordered[3], ordered[4], ordered.last],
            ]
          : [
              [
                ordered[1],
                ordered[profile.difficulty == 8 ? 2 : 3],
                ordered[ordered.length - (profile.difficulty == 8 ? 2 : 3)],
              ],
            ];
      final before_first_close = _reachable(groups.first.last, graph.blockers);
      final after_overlap = _reachable(groups.last[1], graph.supported);
      final score = before_first_close.intersection(after_overlap).length;
      if ((extreme && score < 12) || score <= best_score) continue;
      best_score = score;
      best_groups = groups;
    }
    if (best_groups != null) {
      return best_groups.map((ids) => ids.map(order.indexOf).toList()).toList();
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

  /// Thirteen front tiles contain at most two copies of any real type.
  /// Every closing partner is below the final front, so no front can disappear
  /// before all thirteen have left the board. Seven sprites suffice for this
  /// strict 6 + 2×3 < 13 capacity proof; eight stay available to the lead-in.
  static void _append_barrier(
    List<TileQuestTile> tiles,
    List<int> front_ids,
    List<int> partner_ids, {
    required int type_start,
    required int difficulty,
  }) {
    final fronts = TileQuestExpertBarrier.front_types_for_difficulty(
      difficulty,
    );
    final partners = TileQuestExpertBarrier.partner_types_for_difficulty(
      difficulty,
    );
    final core_count = TileQuestExpertBarrier.tile_count_for_difficulty(
      difficulty,
    );
    for (var index = 0; index < fronts.length; index++) {
      final id = tiles.length;
      front_ids.add(id);
      tiles.add(
        TileQuestTile(
          id: id,
          type: type_start + fronts[index],
          layer: core_count - 1 - index,
          x: 5.5,
          y: 7,
        ),
      );
    }
    for (var index = 0; index < partners.length; index++) {
      final id = tiles.length;
      partner_ids.add(id);
      tiles.add(
        TileQuestTile(
          id: id,
          type: type_start + partners[index],
          layer: (partners.length - 1 - index) ~/ 2,
          x: 5.0 + index % 2,
          y: 7,
        ),
      );
    }
  }
}
