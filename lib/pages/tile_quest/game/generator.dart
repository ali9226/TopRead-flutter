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

/// Seeded geometric templates, a gentle visible opening, then hidden hard phases.
class TileQuestGenerator {
  /// [seed] 每局随机种子（run_seed）；[layout_seed] 当日共享布局种子，
  /// 缺省回退 seed。两者独立时「同题」= 同骨架，图案/陷阱/辅助堆每局随机。
  /// [difficulty] 支持两位小数（如 8.25）；10.00 才是数学必败档。
  static TileQuestState generate({
    required int level,
    required int seed,
    String? challenge_id,
    int unlocked_level = 1,
    int? layout_seed,
    num? difficulty,
  }) {
    if (level < 1 || level > 2 || seed < 0 || seed > TileQuestConfig.max_seed) {
      throw ArgumentError('Unsupported level or seed');
    }
    final int geometry_seed = layout_seed ?? seed;
    if (geometry_seed < 0 || geometry_seed > TileQuestConfig.max_seed) {
      throw ArgumentError('Unsupported layout seed');
    }
    if (level == 1) {
      return TileQuestTutorial.generate_state(
        seed: seed,
        challenge_id: challenge_id,
        unlocked_level: unlocked_level,
      );
    }
    final double raw_difficulty = (difficulty ?? TileQuestConfig.gameDifficulty)
        .toDouble();
    if (raw_difficulty < 1 || raw_difficulty > 10) {
      throw ArgumentError.value(difficulty, 'difficulty', 'Must be 1–10');
    }
    // 旧 profile 表按整数档查表；floor 保证 9.99 不会误入 10 的必败档。
    final int tier = raw_difficulty.floor().clamp(1, 10);
    final profile = DifficultyProfile.for_difficulty(tier);
    // 日常难度（1-9）全面去门：难度只来自盘面本身。难度10 是「暗坑必败」
    // 运维开关，容量核保证道具 1/1/2 全用完仍无法通关。
    final needs_barrier =
        raw_difficulty >= TileQuestConfig.trap_difficulty;
    final lead_profile = needs_barrier
        ? profile.with_inventory(
            tile_count:
                profile.tile_count -
                TileQuestExpertBarrier.tile_count_for_difficulty(raw_difficulty),
            type_count:
                profile.type_count -
                TileQuestExpertBarrier.type_count_for_difficulty(raw_difficulty),
          )
        : profile;
    // 共享几何只依赖 layout_seed 与难度；同日全服骨架一致。
    // run 侧（图案/顺序/陷阱/门锚点）在同骨架上重试；骨架级重试仅作罕见兜底。
    StateError? last_failure;
    final stopwatch = Stopwatch()..start();
    outer:
    for (
      var layout_attempt = 0;
      layout_attempt < TileQuestConfig.max_generation_attempts;
      layout_attempt++
    ) {
      List<TileQuestTile> lead_tiles;
      try {
        lead_tiles = TileQuestLayoutPatterns.generate(
          lead_profile,
          Random(geometry_seed + layout_attempt),
        );
      } on StateError catch (error) {
        last_failure = error;
        continue;
      }
      for (
        var attempt = 0;
        attempt < TileQuestConfig.max_generation_attempts;
        attempt++
      ) {
        try {
          final random = Random(seed ^ (attempt * 7919));
          final graph = TileQuestGeometry(lead_tiles);
          final opening =
              graph
                  .refresh(lead_tiles)
                  .where((tile) => !tile.is_blocked)
                  .map((tile) => tile.id)
                  .toList()
                ..shuffle(random);
          final cleared_opening = opening.toSet();
          // The easy cap is intentionally first. Hidden order is a fully
          // randomized topological walk: spatially scattered, unguessable, and
          // identical sprites never settle into mechanical local clusters.
          final lead_order = <int>[
            ...opening,
            ...graph.removal_order(
              lead_tiles
                  .map(
                    (tile) => tile.copy_with(
                      is_removed: cleared_opening.contains(tile.id),
                    ),
                  )
                  .toList(),
              random,
            ),
          ];
          // 暗坑锚点先于图案分配选定：暗坑图案的库存只落在「强制祖先集」
          // ——暗坑激活前被强制清空的主区牌。每种张数为 3 的倍数，清空后
          // 槽位零残留；暗坑前无外援，容量证明成立。图案全部取自普通池，
          // 玩家看到的是深区常见图案，而非只在门区出现的独立图案。
          final Point<double>? trap_anchor = needs_barrier
              ? _pick_capacity_anchor(lead_tiles, random)
              : null;
          final Set<int> forced_ids = trap_anchor == null
              ? const <int>{}
              : _forced_ancestor_ids(lead_tiles, graph, trap_anchor);
          final int trap_type_start = lead_profile.type_count;
          // 暗坑图案只落隐藏区（不进开局）：开局仍是温和暖场，且
          // (隐藏区数 - 暗坑占位) 恒为 3 的倍数，分配器库存恰好铺满。
          final Set<int> trap_positions = <int>{};
          if (forced_ids.isNotEmpty) {
            final candidates = <int>[
              for (final id in forced_ids)
                if (!cleared_opening.contains(id)) id,
            ]..shuffle(random);
            final int per_type = candidates.length ~/ 7 ~/ 3 * 3;
            if (per_type >= 3) {
              trap_positions.addAll(candidates.take(per_type * 7));
            }
          }
          final free_order = <int>[
            for (final id in lead_order)
              if (!trap_positions.contains(id)) id,
          ];
          final free_opening = <int>[
            for (final id in opening)
              if (!trap_positions.contains(id)) id,
          ].length;
          final free_sequence = TileQuestTypeAllocator.initial(
            lead_profile.with_inventory(
              tile_count: free_order.length,
              type_count: lead_profile.type_count,
            ),
            opening_count: free_opening,
            random: random,
            // 暗坑三连在解序上连续成组，途中最多临时占用 trap_pair_hold 槽；
            // 暗坑盘的免费区按 留出这些槽位 规划，合并占用恒 < 槽位上限。
            capacity: trap_positions.isEmpty
                ? TileQuestConfig.tray_capacity
                : TileQuestConfig.tray_capacity - TileQuestConfig.trap_pair_hold,
          );
          final assigned = <int, int>{};
          for (var index = 0; index < free_order.length; index++) {
            assigned[free_order[index]] = free_sequence[index];
          }
          final trap_order = <int>[
            for (final id in lead_order)
              if (trap_positions.contains(id)) id,
          ];
          for (var index = 0; index < trap_order.length; index += 3) {
            final type = trap_type_start + (index ~/ 3) % 7;
            assigned[trap_order[index]] = type;
            if (index + 1 < trap_order.length) {
              assigned[trap_order[index + 1]] = type;
            }
            if (index + 2 < trap_order.length) {
              assigned[trap_order[index + 2]] = type;
            }
          }
          final lead_layer_offset = needs_barrier
              ? TileQuestExpertBarrier.tile_count_for_difficulty(raw_difficulty)
              : 0;
          final types_by_id = {
            for (final tile in lead_tiles) tile.id: assigned[tile.id]!,
          };
          _disperse_stack_repeats(
            lead_tiles,
            types_by_id,
            random,
            forced_ids: forced_ids,
            trap_type_start: trap_type_start,
          );
          final tiles = lead_tiles
              .map(
                (tile) => tile.copy_with(
                  type: types_by_id[tile.id]!,
                  layer: tile.layer + lead_layer_offset,
                ),
              )
              .toList();
          final front_ids = <int>[];
          final partner_ids = <int>[];
          if (needs_barrier) {
            _append_barrier(
              tiles,
              front_ids,
              partner_ids,
              anchor: trap_anchor!,
              type_start: trap_type_start,
              difficulty: raw_difficulty,
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
                      region_id: mirror_y
                          ? switch (tile.region_id) {
                              'side_top' => 'side_bottom',
                              'side_bottom' => 'side_top',
                              _ => tile.region_id,
                            }
                          : tile.region_id,
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
            difficulty: raw_difficulty,
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
          if (check.valid && _late_variety_ok(lead_order, assigned, tier)) {
            barrier?.validate(state);
            return state;
          }
        } on StateError catch (error) {
          last_failure = error;
          // Retry a complete seeded construction, never force a player's result.
        } on FormatException catch (error) {
          last_failure = StateError(error.message);
        }
        if (stopwatch.elapsedMilliseconds >=
            TileQuestConfig.generation_budget_ms) {
          break outer;
        }
      }
    }
    throw StateError(
      'A verified phased board could not be generated within its budget '
      '(difficulty $raw_difficulty, seed $seed): $last_failure',
    );
  }

  /// 高难度后段路径必须保持图案多样性，否则重试整盘构造（与难度验收同口径）。
  static bool _late_variety_ok(
    List<int> lead_order,
    Map<int, int> assigned,
    int tier,
  ) {
    if (tier < 8) return true;
    final int floor = tier == 10 ? 5 : 8;
    final late_types = <int>{};
    for (var index = lead_order.length * 2 ~/ 3; index < lead_order.length; index++) {
      late_types.add(assigned[lead_order[index]]!);
    }
    return late_types.length >= floor;
  }

  /// 暗坑锚点：主区下方一个被真实覆盖的 2x1 基槽，永不使用固定边位。
  static Point<double> _pick_capacity_anchor(
    List<TileQuestTile> tiles,
    Random random,
  ) {
    final candidates = <Point<double>>[];
    for (var row = 0; row < TileQuestLayoutPatterns.main_rows; row++) {
      for (
        var column = 0;
        column < TileQuestLayoutPatterns.main_columns - 1;
        column++
      ) {
        final x = column + TileQuestLayoutPatterns.grid_gap / 2;
        final y =
            TileQuestLayoutPatterns.main_top +
            row +
            TileQuestLayoutPatterns.grid_gap / 2;
        final covered = [x, x + 1].every(
          (left) => tiles.any(
            (tile) =>
                (tile.region_id == 'main' || tile.region_id == 'core') &&
                (tile.x - left).abs() < .000001 &&
                (tile.y - y).abs() < .000001,
          ),
        );
        if (covered) candidates.add(Point(x, y));
      }
    }
    if (candidates.isEmpty) throw StateError('No covered capacity basin');
    return candidates[random.nextInt(candidates.length)];
  }

  /// 暗坑正上方必须先清空的主区牌（含传递遮挡）。这些牌先于暗坑被强制
  /// 点走，暗坑图案的库存只放在这里即可保证零残留、无外援。
  static Set<int> _forced_ancestor_ids(
    List<TileQuestTile> lead_tiles,
    TileQuestGeometry graph,
    Point<double> anchor,
  ) {
    final left = anchor.x + .5;
    final right = left + 1;
    final top = anchor.y;
    final bottom = top + 1;
    final roots = <int>[];
    for (final tile in lead_tiles) {
      final overlaps =
          tile.x < right &&
          tile.x + tile.width > left &&
          tile.y < bottom &&
          tile.y + tile.height > top;
      if (overlaps) roots.add(tile.id);
    }
    final forced = <int>{};
    final pending = [...roots];
    while (pending.isNotEmpty) {
      final id = pending.removeLast();
      for (final blocker in graph.blockers[id]!) {
        if (forced.add(blocker)) pending.add(blocker);
      }
    }
    return forced;
  }

  /// 同一叠柱内相邻层禁止同图：消除「点开一张，正下方又是同一张」的机械感。
  /// 跨柱交换类型修正，每图总数（3 的倍数）不变；解的可行性由校验兜底。
  static void _disperse_stack_repeats(
    List<TileQuestTile> lead_tiles,
    Map<int, int> types,
    Random random, {
    Set<int> forced_ids = const {},
    int trap_type_start = 1 << 30,
  }) {
    final stacks = <String, List<TileQuestTile>>{};
    for (final tile in lead_tiles) {
      stacks.putIfAbsent('${tile.x}:${tile.y}', () => []).add(tile);
    }
    for (final stack in stacks.values) {
      stack.sort((a, b) => a.layer.compareTo(b.layer));
    }
    final stack_of = <int, String>{
      for (final entry in stacks.entries)
        for (final tile in entry.value) tile.id: entry.key,
    };
    bool violates(TileQuestTile tile, int new_type) {
      final stack = stacks[stack_of[tile.id]!]!;
      final index = stack.indexWhere((candidate) => candidate.id == tile.id);
      for (final neighbor in [index - 1, index + 1]) {
        if (neighbor < 0 || neighbor >= stack.length) continue;
        if ((stack[neighbor].layer - tile.layer).abs() != 1) continue;
        if (types[stack[neighbor].id] == new_type) return true;
      }
      return false;
    }

    for (var pass = 0; pass < 4; pass++) {
      var repaired = 0;
      for (final entry in stacks.entries) {
        final stack = entry.value;
        for (var index = 1; index < stack.length; index++) {
          final lower = stack[index - 1];
          final upper = stack[index];
          if (upper.layer - lower.layer != 1) continue;
          if (types[lower.id] != types[upper.id]) continue;
          final partners = lead_tiles
              .where(
                (tile) =>
                    stack_of[tile.id] != entry.key &&
                    types[tile.id] != types[upper.id] &&
                    // 暗坑图案的库存必须留在强制祖先集内，交换不得外溢。
                    (types[upper.id]! < trap_type_start ||
                        forced_ids.contains(tile.id)) &&
                    (types[tile.id]! < trap_type_start ||
                        forced_ids.contains(upper.id)),
              )
              .toList();
          partners.shuffle(random);
          for (final partner in partners) {
            final held = types[upper.id]!;
            if (violates(partner, held)) continue;
            final recycled = types[partner.id]!;
            types[partner.id] = held;
            types[upper.id] = recycled;
            repaired++;
            break;
          }
        }
      }
      if (repaired == 0) break;
    }
  }

  /// Thirteen front tiles contain at most two copies of any real type.
  /// Every closing partner is below the final front, so no front can disappear
  /// before all thirteen have left the board. Seven sprites suffice for this
  /// strict 6 + 2×3 < 13 capacity proof; eight stay available to the lead-in.
  static void _append_barrier(
    List<TileQuestTile> tiles,
    List<int> front_ids,
    List<int> partner_ids, {
    required Point<double> anchor,
    required int type_start,
    required num difficulty,
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
          region_id: 'core',
          layer: core_count - 1 - index,
          x: anchor.x + .5,
          y: anchor.y,
          width: TileQuestLayoutPatterns.tile_extent,
          height: TileQuestLayoutPatterns.tile_extent,
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
          region_id: 'core',
          layer: (partners.length - 1 - index) ~/ 2,
          x: anchor.x + index % 2,
          y: anchor.y,
          width: TileQuestLayoutPatterns.tile_extent,
          height: TileQuestLayoutPatterns.tile_extent,
        ),
      );
    }
  }
}
