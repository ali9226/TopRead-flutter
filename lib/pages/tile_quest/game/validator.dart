// ignore_for_file: non_constant_identifier_names
import 'config.dart';
import 'geometry.dart';
import 'expert_barrier.dart';
import 'models.dart';

class TileQuestSolutionCheck {
  final bool valid;
  final String? reason;
  final int max_tray_occupancy;
  const TileQuestSolutionCheck(
    this.valid, {
    this.reason,
    this.max_tray_occupancy = 0,
  });
}

/// Independent replay deliberately does not depend on the mutable game engine.
class TileQuestValidator {
  static TileQuestSolutionCheck validate_solution(
    TileQuestState state, [
    List<int>? solution,
  ]) {
    return _replay(state, solution ?? state.certified_solution);
  }

  /// Explicit tool budget is a constructive witness, not a claim that the
  /// currently configured two-charge challenge can win with three charges.
  static TileQuestSolutionCheck validate_tool_solution(
    TileQuestState state,
    List<int> solution, {
    required int remove_uses,
  }) => _replay(state, solution, remove_uses: remove_uses);

  static TileQuestSolutionCheck _replay(
    TileQuestState state,
    List<int> path, {
    int? remove_uses,
    TileQuestGeometry? geometry,
  }) {
    final by_id = {for (final tile in state.tiles) tile.id: tile};
    // State validation already built this immutable dependency graph. Reuse it
    // for the certificate instead of scanning every rectangle pair again.
    final graph = geometry ?? TileQuestGeometry(state.tiles);
    final remaining = state.tiles
        .where((tile) => !tile.is_removed)
        .map((tile) => tile.id)
        .toSet();
    final tray = List<int>.from(state.tray);
    final reserve = List<int>.from(state.reserve);
    final columns = Map<int, int>.from(state.reserve_columns);
    var remove_left = remove_uses ?? state.tools[TileQuestTool.remove] ?? 0;
    if (remove_left < 0) {
      return const TileQuestSolutionCheck(
        false,
        reason: 'Invalid Remove budget',
      );
    }
    final spent =
        TileQuestConfig.initial_tool_uses(TileQuestTool.remove) -
        (state.tools[TileQuestTool.remove] ?? 0);
    final reserve_capacity =
        (spent + remove_left) * TileQuestConfig.reserve_columns;
    var maximum = tray.length;
    for (final id in path) {
      if (tray.length >= TileQuestConfig.tray_capacity ||
          state.status == TileQuestStatus.lost) {
        return const TileQuestSolutionCheck(
          false,
          reason: 'Challenge has ended',
        );
      }
      if (id == TileQuestExpertBarrier.remove_step) {
        final count = tray.length < TileQuestConfig.remove_batch_size
            ? tray.length
            : TileQuestConfig.remove_batch_size;
        if (remove_left <= 0 ||
            count == 0 ||
            reserve.length + count > reserve_capacity) {
          return const TileQuestSolutionCheck(
            false,
            reason: 'Remove is unavailable',
          );
        }
        final moved = tray.take(count).toList();
        tray.removeRange(0, count);
        for (var index = 0; index < moved.length; index++) {
          columns[moved[index]] = index % TileQuestConfig.reserve_columns;
        }
        reserve.addAll(moved);
        remove_left--;
        continue;
      }
      final tile = by_id[id];
      if (tile == null) {
        return const TileQuestSolutionCheck(false, reason: 'Unknown tile');
      }
      if (reserve.contains(id)) {
        final index = reserve.indexOf(id);
        if (reserve
            .skip(index + 1)
            .any((held) => columns[held] == columns[id])) {
          return const TileQuestSolutionCheck(
            false,
            reason: 'Reserve tile is covered by its stack',
          );
        }
        reserve.removeAt(index);
        columns.remove(id);
        // A reserved tile is returned through exactly the same settlement rules.
      } else if (remaining.contains(id) &&
          !graph.blockers[id]!.any(remaining.contains)) {
        remaining.remove(id);
      } else {
        return const TileQuestSolutionCheck(
          false,
          reason: 'Blocked or repeated tile',
        );
      }
      if (tray.length >= TileQuestConfig.tray_capacity) {
        return const TileQuestSolutionCheck(false, reason: 'Eighth tile');
      }
      final same = tray.lastIndexWhere(
        (held) => by_id[held]!.type == tile.type,
      );
      tray.insert(same < 0 ? tray.length : same + 1, id);
      while (true) {
        final group = tray
            .where((item) => by_id[item]!.type == tile.type)
            .toList();
        if (group.length < 3) break;
        final triple = group.take(3).toList();
        tray.removeWhere(triple.contains);
      }
      if (tray.length > maximum) maximum = tray.length;
      if (tray.length >= TileQuestConfig.tray_capacity) {
        return TileQuestSolutionCheck(
          false,
          reason: 'Tray filled before completion',
          max_tray_occupancy: maximum,
        );
      }
    }
    return TileQuestSolutionCheck(
      remaining.isEmpty && tray.isEmpty && reserve.isEmpty,
      reason: remaining.isEmpty && tray.isEmpty && reserve.isEmpty
          ? null
          : 'Incomplete solution',
      max_tray_occupancy: maximum,
    );
  }

  /// Strict invariants protect gameplay from corrupted or stale disk state.
  /// Return the verified dependency graph so the engine can retain it for taps
  /// without rebuilding the same quadratic rectangle intersection table.
  static TileQuestGeometry validate_state(TileQuestState state) {
    Never invalid(String message) => throw FormatException(message);
    if (state.tiles.isEmpty ||
        state.tiles.length > TileQuestConfig.max_tiles ||
        state.tiles.length % 3 != 0 ||
        state.level < 1 ||
        state.level > 2 ||
        state.difficulty < 1 ||
        state.difficulty > 10 ||
        state.seed < 0 ||
        state.seed > TileQuestConfig.max_seed ||
        state.challenge_id.isEmpty ||
        state.challenge_id.length > 128 ||
        state.elapsed_ms < 0 ||
        state.elapsed_ms > 31536000000 ||
        state.unlocked_level < state.level ||
        state.unlocked_level > 2) {
      invalid('Invalid challenge metadata');
    }
    final by_id = <int, TileQuestTile>{};
    final original_counts = <int, int>{};
    for (final tile in state.tiles) {
      if (tile.id < 0 ||
          tile.id > TileQuestConfig.max_tiles * 100 ||
          by_id.containsKey(tile.id) ||
          tile.type < 0 ||
          tile.type >= TileQuestConfig.max_tile_types ||
          tile.layer < 0 ||
          tile.layer > 64 ||
          !tile.x.isFinite ||
          !tile.y.isFinite ||
          !tile.width.isFinite ||
          !tile.height.isFinite ||
          tile.x < 0 ||
          tile.y < 0 ||
          tile.x > 32 ||
          tile.y > 32 ||
          tile.width <= 0 ||
          tile.height <= 0 ||
          tile.width > 4 ||
          tile.height > 4) {
        invalid('Invalid tile geometry or identity');
      }
      by_id[tile.id] = tile;
      original_counts[tile.type] = (original_counts[tile.type] ?? 0) + 1;
    }
    if (original_counts.values.any((count) => count % 3 != 0)) {
      invalid('Unbalanced tile inventory');
    }
    if (state.tray.length > TileQuestConfig.tray_capacity ||
        state.reserve.length > TileQuestConfig.reserve_capacity ||
        {...state.tray, ...state.reserve}.length !=
            state.tray.length + state.reserve.length) {
      invalid('Invalid tray inventory');
    }
    final column_counts = <int, int>{};
    if (state.reserve_columns.length != state.reserve.length ||
        state.reserve_columns.keys.any((id) => !state.reserve.contains(id))) {
      invalid('Invalid reserve column inventory');
    }
    for (final id in state.reserve) {
      final column = state.reserve_column(id);
      if (column < 0 || column >= TileQuestConfig.reserve_columns) {
        invalid('Invalid reserve column');
      }
      column_counts[column] = (column_counts[column] ?? 0) + 1;
      if (column_counts[column]! > TileQuestConfig.remove_uses_per_challenge) {
        invalid('Reserve stack exceeds its capacity');
      }
    }
    final held_counts = <int, int>{};
    for (final id in [...state.tray, ...state.reserve]) {
      if (by_id[id] == null || !by_id[id]!.is_removed) {
        invalid('Held tile is still on board');
      }
      final type = by_id[id]!.type;
      held_counts[type] = (held_counts[type] ?? 0) + 1;
    }
    final tray_counts = <int, int>{};
    for (final id in state.tray) {
      final type = by_id[id]!.type;
      tray_counts[type] = (tray_counts[type] ?? 0) + 1;
    }
    if (tray_counts.values.any((count) => count >= 3)) {
      invalid('Unsettled match');
    }
    final removed_counts = <int, int>{};
    for (final tile in state.tiles.where((tile) => tile.is_removed)) {
      removed_counts[tile.type] = (removed_counts[tile.type] ?? 0) + 1;
    }
    for (final type in original_counts.keys) {
      if (((removed_counts[type] ?? 0) - (held_counts[type] ?? 0)) % 3 != 0) {
        invalid('Lost or duplicated matched inventory');
      }
    }
    final matched =
        state.tiles.where((tile) => tile.is_removed).length -
        state.tray.length -
        state.reserve.length;
    if (matched != state.matched_count ||
        matched < 0 ||
        matched % 3 != 0 ||
        state.tools.length != 3 ||
        TileQuestTool.values.any(
          (tool) =>
              state.tools[tool] == null ||
              state.tools[tool]! < 0 ||
              state.tools[tool]! > TileQuestConfig.initial_tool_uses(tool),
        ) ||
        state.tools_used !=
            TileQuestTool.values.fold<int>(
              0,
              (sum, tool) =>
                  sum +
                  TileQuestConfig.initial_tool_uses(tool) -
                  (state.tools[tool] ?? 0),
            ) ||
        state.reserve.length >
            (TileQuestConfig.initial_tool_uses(TileQuestTool.remove) -
                    (state.tools[TileQuestTool.remove] ?? 0)) *
                TileQuestConfig.remove_batch_size) {
      invalid('Inconsistent match or tool count');
    }
    final geometry = TileQuestGeometry(state.tiles);
    if (state.level == 2 &&
        state.difficulty >= TileQuestConfig.mandatory_tool_difficulty &&
        state.expert_barrier == null) {
      invalid('Required tool barrier is missing');
    }
    state.expert_barrier?.validate(state, geometry: geometry);
    final refreshed = geometry.refresh(state.tiles);
    for (var index = 0; index < refreshed.length; index++) {
      if (refreshed[index].is_blocked != state.tiles[index].is_blocked) {
        invalid('Stale blocker flags');
      }
    }
    final complete =
        state.remaining_count == 0 &&
        state.tray.isEmpty &&
        state.reserve.isEmpty;
    if ((state.status == TileQuestStatus.won) != complete ||
        (state.status == TileQuestStatus.lost) != (state.tray.length == 7) ||
        (state.status == TileQuestStatus.won &&
            state.level == 2 &&
            state.difficulty >= TileQuestConfig.mandatory_tool_difficulty &&
            state.tools_used == 0) ||
        (state.status == TileQuestStatus.won &&
            state.unlocked_level < (state.level + 1).clamp(1, 2))) {
      invalid('Inconsistent game status');
    }
    if (state.certified_solution.isNotEmpty &&
        !_replay(state, state.certified_solution, geometry: geometry).valid) {
      invalid('Invalid solution certificate');
    }
    return geometry;
  }
}
