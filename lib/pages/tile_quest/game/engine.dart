// ignore_for_file: constant_identifier_names, non_constant_identifier_names
import 'dart:math';
import 'config.dart';
import 'geometry.dart';
import 'expert_barrier.dart';
import 'models.dart';
import 'type_allocator.dart';
import 'validator.dart';

/// All actions commit synchronously and publish immutable snapshots. Animations
/// cannot duplicate taps, race a save, or partially consume a tool.
class TileQuestEngine {
  TileQuestState _state;
  TileQuestState? _undo_state;
  late final TileQuestGeometry _geometry;
  TileQuestEngine(TileQuestState state) : _state = state {
    TileQuestValidator.validate_state(state);
    _geometry = TileQuestGeometry(state.tiles);
  }
  TileQuestState get state => _state;
  List<TileQuestTile> get clickable_tiles => _state.clickable_tiles;
  bool get can_undo =>
      _undo_state != null && (_state.tools[TileQuestTool.undo] ?? 0) > 0;

  void update_metadata({
    int? elapsed_ms,
    int? unlocked_level,
    bool? sound_enabled,
  }) {
    if (elapsed_ms != null &&
        (elapsed_ms < _state.elapsed_ms || elapsed_ms > 31536000000)) {
      throw ArgumentError('Elapsed time must be monotonic');
    }
    if (unlocked_level != null &&
        (unlocked_level < _state.unlocked_level || unlocked_level > 2)) {
      throw ArgumentError('Unlocked level must be monotonic and supported');
    }
    _state = _state.copy_with(
      elapsed_ms: elapsed_ms,
      unlocked_level: unlocked_level,
      sound_enabled: sound_enabled,
    );
  }

  TileQuestActionResult _reject(TileQuestAction action, String reason) =>
      TileQuestActionResult(
        accepted: false,
        before: _state,
        after: _state,
        action: action,
        reason: reason,
      );

  TileQuestActionResult tap_tile(int id) {
    if (_state.status != TileQuestStatus.playing || _state.tray.length >= 7) {
      return _reject(TileQuestAction.tap, 'Challenge has ended');
    }
    final candidates = _state.tiles.where((tile) => tile.id == id);
    if (candidates.isEmpty ||
        candidates.first.is_removed ||
        candidates.first.is_blocked) {
      return _reject(TileQuestAction.tap, 'Tile is blocked or unavailable');
    }
    final before = _state;
    final tiles = _geometry.refresh(
      before.tiles
          .map(
            (tile) => tile.id == id ? tile.copy_with(is_removed: true) : tile,
          )
          .toList(),
    );
    _undo_state = before;
    return _settle(
      before,
      tiles,
      List<int>.from(before.tray),
      List<int>.from(before.reserve),
      id,
      TileQuestAction.tap,
    );
  }

  TileQuestActionResult return_reserve(int id) {
    if (_state.status != TileQuestStatus.playing ||
        !_state.is_reserve_available(id) ||
        _state.tray.length >= 7) {
      return _reject(
        TileQuestAction.return_reserve,
        'Reserve tile is unavailable',
      );
    }
    final before = _state;
    final reserve = List<int>.from(before.reserve)..remove(id);
    _undo_state = before;
    return _settle(
      before,
      before.tiles,
      List<int>.from(before.tray),
      reserve,
      id,
      TileQuestAction.return_reserve,
    );
  }

  TileQuestActionResult _settle(
    TileQuestState before,
    List<TileQuestTile> tiles,
    List<int> tray,
    List<int> reserve,
    int id,
    TileQuestAction action,
  ) {
    final type = before.tile_by_id(id).type;
    final previous_same = tray.lastIndexWhere(
      (held) => before.tile_by_id(held).type == type,
    );
    tray.insert(previous_same < 0 ? tray.length : previous_same + 1, id);
    final settlement_tray = List<int>.from(tray);
    final matches = tray
        .where((held) => before.tile_by_id(held).type == type)
        .toList();
    if (matches.length == 3) {
      tray.removeWhere(matches.contains);
    } else {
      matches.clear();
    }
    // Settlement always precedes the seventh-slot failure check.
    final won =
        tiles.every((tile) => tile.is_removed) &&
        tray.isEmpty &&
        reserve.isEmpty;
    final status = won
        ? TileQuestStatus.won
        : tray.length == 7
        ? TileQuestStatus.lost
        : TileQuestStatus.playing;
    final certificate =
        before.certified_solution.isNotEmpty &&
            before.certified_solution.first == id
        ? before.certified_solution.sublist(1)
        : <int>[];
    _state = before.copy_with(
      tiles: tiles,
      tray: tray,
      reserve: reserve,
      status: status,
      matched_count: before.matched_count + matches.length,
      certified_solution: certificate,
      unlocked_level: won
          ? max(before.unlocked_level, min(2, before.level + 1))
          : null,
    );
    final unblocked = tiles
        .where(
          (tile) =>
              !tile.is_removed &&
              !tile.is_blocked &&
              before.tile_by_id(tile.id).is_blocked,
        )
        .map((tile) => tile.id)
        .toList();
    return TileQuestActionResult(
      accepted: true,
      before: before,
      after: _state,
      action: action,
      moved_ids: [id],
      matched_ids: matches,
      settlement_tray: settlement_tray,
      unblocked_ids: unblocked,
    );
  }

  Map<TileQuestTool, int> _consume(TileQuestTool tool) =>
      Map<TileQuestTool, int>.from(_state.tools)
        ..[tool] = _state.tools[tool]! - 1;

  TileQuestActionResult undo() {
    if (!can_undo) return _reject(TileQuestAction.undo, 'Undo is unavailable');
    final before = _state;
    final restored = _undo_state!;
    _state = restored.copy_with(
      tools: _consume(TileQuestTool.undo),
      tools_used: before.tools_used + 1,
      elapsed_ms: before.elapsed_ms,
      unlocked_level: max(before.unlocked_level, restored.unlocked_level),
      sound_enabled: before.sound_enabled,
    );
    if (_state.certified_solution.isNotEmpty &&
        !TileQuestValidator.validate_solution(_state).valid) {
      _state = _state.copy_with(certified_solution: const []);
    }
    _undo_state = null;
    // Include held tiles restored by a reversed triple and reserve returns;
    // their board removal flags can remain unchanged while containers differ.
    final restored_ids = _state.tiles
        .where((tile) {
          final previous = before.tile_by_id(tile.id);
          return tile.is_removed != previous.is_removed ||
              tile.type != previous.type ||
              before.tray.indexOf(tile.id) != _state.tray.indexOf(tile.id) ||
              before.reserve.indexOf(tile.id) !=
                  _state.reserve.indexOf(tile.id);
        })
        .map((tile) => tile.id)
        .toList();
    return TileQuestActionResult(
      accepted: true,
      before: before,
      after: _state,
      action: TileQuestAction.undo,
      moved_ids: restored_ids,
    );
  }

  TileQuestActionResult remove() {
    if (_state.status != TileQuestStatus.playing ||
        (_state.tools[TileQuestTool.remove] ?? 0) <= 0 ||
        _state.tray.isEmpty ||
        _state.reserve.length +
                min(TileQuestConfig.remove_batch_size, _state.tray.length) >
            TileQuestConfig.reserve_capacity) {
      return _reject(TileQuestAction.remove, 'Remove is unavailable');
    }
    final before = _state;
    final moved = before.tray.take(TileQuestConfig.remove_batch_size).toList();
    final tray = before.tray.skip(moved.length).toList();
    final columns = Map<int, int>.from(before.reserve_columns);
    for (var index = 0; index < moved.length; index++) {
      columns[moved[index]] = index % TileQuestConfig.reserve_columns;
    }
    _state = before.copy_with(
      tray: tray,
      reserve: [...before.reserve, ...moved],
      reserve_columns: columns,
      tools: _consume(TileQuestTool.remove),
      tools_used: before.tools_used + 1,
      certified_solution:
          before.certified_solution.isNotEmpty &&
              before.certified_solution.first ==
                  TileQuestExpertBarrier.remove_step
          ? before.certified_solution.sublist(1)
          : const [],
    );
    return TileQuestActionResult(
      accepted: true,
      before: before,
      after: _state,
      action: TileQuestAction.remove,
      moved_ids: moved,
    );
  }

  /// Shuffle constructs and independently replays a complete continuation that
  /// includes existing tray and reserve contents. Failure never mutates or charges.
  TileQuestActionResult shuffle({int? seed}) {
    if (_state.status != TileQuestStatus.playing ||
        (_state.tools[TileQuestTool.shuffle] ?? 0) <= 0 ||
        _state.remaining_count == 0) {
      return _reject(TileQuestAction.shuffle, 'Shuffle is unavailable');
    }
    final before = _state;
    if (before.expert_barrier?.is_closed(before) ?? false) {
      return _shuffle_closed_barrier(seed: seed);
    }
    final inventory = <int, int>{};
    for (final tile in before.tiles) {
      inventory[tile.type] = (inventory[tile.type] ?? 0) + 1;
    }
    final protected_types = before.difficulty == 9
        ? inventory.entries
              .where((entry) => entry.value == 3)
              .map((entry) => entry.key)
              .toSet()
        : <int>{};
    if (before.difficulty == 9) {
      return _shuffle_hard_board(protected_types, seed: seed);
    }
    final fixed_types = {
      for (final tile in before.tiles)
        if (!tile.is_removed && protected_types.contains(tile.type))
          tile.id: tile.type,
    };
    if (fixed_types.isNotEmpty &&
        before.certified_solution.isNotEmpty &&
        TileQuestValidator.validate_solution(before).valid) {
      return _shuffle_preserving_types(protected_types, seed: seed);
    }
    final random = Random(
      seed ?? before.seed ^ before.matched_count ^ before.tray.length * 997,
    );
    final stopwatch = Stopwatch()..start();
    final board_order = _geometry.removal_order(before.tiles, random);
    final continuation = _ShuffleContinuation(
      before,
      board_order,
      random,
      stopwatch,
      fixed_types: fixed_types,
      protected_types: protected_types,
    ).build();
    if (continuation == null) {
      return _reject(
        TileQuestAction.shuffle,
        'No safe continuation found within budget',
      );
    }
    final assignments = continuation.assignments;
    final path = continuation.path;
    final tiles = before.tiles
        .map(
          (tile) => tile.is_removed
              ? tile
              : tile.copy_with(type: assignments[tile.id]!),
        )
        .toList();
    final candidate = before.copy_with(
      tiles: tiles,
      certified_solution: path,
      tools: _consume(TileQuestTool.shuffle),
      tools_used: before.tools_used + 1,
    );
    final check = TileQuestValidator.validate_solution(candidate);
    if (!check.valid) {
      return _reject(
        TileQuestAction.shuffle,
        'Continuation verification failed',
      );
    }
    _state = candidate;
    return TileQuestActionResult(
      accepted: true,
      before: before,
      after: _state,
      action: TileQuestAction.shuffle,
      moved_ids: tiles
          .where((tile) => !tile.is_removed)
          .map((tile) => tile.id)
          .toList(),
    );
  }

  /// Difficulty nine keeps the entire matching relation, including ordinary
  /// hidden helpers. Reassigning only the rare key in place is insufficient:
  /// rebuilding all other faces can turn its surrounding corridor into a much
  /// easier sequence. A whole-type bijection is an exact renaming of the same
  /// puzzle, so it cannot create an easier path through the dependency graph.
  TileQuestActionResult _shuffle_hard_board(
    Set<int> protected_types, {
    int? seed,
  }) {
    final before = _state;
    if (before.certified_solution.isNotEmpty &&
        TileQuestValidator.validate_solution(before).valid) {
      return _shuffle_preserving_types(protected_types, seed: seed);
    }
    final random = Random(seed ?? before.seed ^ before.matched_count);
    final stopwatch = Stopwatch()..start();
    final fixed_types = {
      for (final tile in before.tiles)
        if (!tile.is_removed) tile.id: tile.type,
    };
    // Search is only evidence that the current faces still admit a legal
    // continuation. It never assigns a different type to an individual tile.
    // Several geometric orders avoid making one arbitrary scan a requirement.
    const max_orders = 8;
    for (var attempt = 0; attempt < max_orders; attempt++) {
      if (stopwatch.elapsedMilliseconds >= TileQuestConfig.shuffle_budget_ms) {
        break;
      }
      final continuation = _ShuffleContinuation(
        before,
        _geometry.removal_order(before.tiles, random),
        random,
        stopwatch,
        fixed_types: fixed_types,
        protected_types: protected_types,
      ).build();
      if (continuation != null) {
        return _shuffle_preserving_types(
          protected_types,
          seed: seed,
          certified_solution: continuation.path,
        );
      }
    }
    return _reject(
      TileQuestAction.shuffle,
      'No verified continuation preserving the original matching relations',
    );
  }

  /// A whole-type bijection in an untouched lead area preserves every matching
  /// schedule and the fixed 13-front capacity proof. Equal counts preserve the
  /// exact inventory. Closed barriers after player moves safely refuse a shuffle
  /// for which this restricted transformation has no current continuation proof.
  TileQuestActionResult _shuffle_closed_barrier({int? seed}) {
    final before = _state;
    if (before.tiles.any((tile) => tile.is_removed) ||
        before.tray.isNotEmpty ||
        before.reserve.isNotEmpty) {
      return _reject(
        TileQuestAction.shuffle,
        'No verified barrier-preserving continuation',
      );
    }
    final protected_types = before.expert_barrier!.front_ids
        .map((id) => before.tile_by_id(id).type)
        .toSet();
    return _shuffle_preserving_types(protected_types, seed: seed);
  }

  /// Rename complete unheld groups while retaining a current certificate and
  /// every protected key identity. Equal remaining counts preserve inventory.
  TileQuestActionResult _shuffle_preserving_types(
    Set<int> protected_types, {
    int? seed,
    List<int>? certified_solution,
  }) {
    final before = _state;
    final held_types = {
      ...before.tray,
      ...before.reserve,
    }.map((id) => before.tile_by_id(id).type).toSet();
    final counts = <int, int>{};
    for (final tile in before.tiles) {
      if (!tile.is_removed &&
          !protected_types.contains(tile.type) &&
          !held_types.contains(tile.type)) {
        counts[tile.type] = (counts[tile.type] ?? 0) + 1;
      }
    }
    final random = Random(seed ?? before.seed);
    final types = counts.keys.toList()..shuffle(random);
    int? left;
    int? right;
    for (final type in types) {
      final equal = types.where(
        (other) => other != type && counts[other] == counts[type],
      );
      if (equal.isNotEmpty) {
        left = type;
        right = equal.first;
        break;
      }
    }
    if (left == null || right == null) {
      return _reject(
        TileQuestAction.shuffle,
        'No equal-count lead types to permute',
      );
    }
    final tiles = before.tiles
        .map(
          (tile) => tile.is_removed
              ? tile
              : tile.type == left
              ? tile.copy_with(type: right)
              : tile.type == right
              ? tile.copy_with(type: left)
              : tile,
        )
        .toList();
    final candidate = before.copy_with(
      tiles: tiles,
      certified_solution: certified_solution,
      tools: _consume(TileQuestTool.shuffle),
      tools_used: before.tools_used + 1,
    );
    try {
      TileQuestValidator.validate_state(candidate);
    } on FormatException {
      return _reject(
        TileQuestAction.shuffle,
        'Barrier-preserving permutation failed validation',
      );
    }
    _state = candidate;
    return TileQuestActionResult(
      accepted: true,
      before: before,
      after: _state,
      action: TileQuestAction.shuffle,
      moved_ids: tiles
          .where((tile) => !tile.is_removed)
          .map((tile) => tile.id)
          .toList(),
    );
  }

  Map<String, dynamic> export_json() => {
    'version': TileQuestConfig.save_version,
    'state': _state.to_json(),
    'undo_state': _undo_state?.to_json(),
  };

  static TileQuestEngine restore(Map<String, dynamic> json) {
    try {
      if ((json['version'] != 1 &&
              json['version'] != TileQuestConfig.save_version) ||
          json['state'] is! Map ||
          (json['undo_state'] != null && json['undo_state'] is! Map)) {
        throw const FormatException('Malformed engine save');
      }
      final state = TileQuestState.from_json(
        Map<String, dynamic>.from(json['state'] as Map),
      );
      final engine = TileQuestEngine(state);
      if (json['undo_state'] != null) {
        final undo_state = TileQuestState.from_json(
          Map<String, dynamic>.from(json['undo_state'] as Map),
        );
        if (undo_state.challenge_id != state.challenge_id ||
            undo_state.seed != state.seed ||
            undo_state.level != state.level ||
            undo_state.difficulty != state.difficulty ||
            undo_state.tiles.length != state.tiles.length ||
            undo_state.tools_used > state.tools_used ||
            undo_state.elapsed_ms > state.elapsed_ms ||
            undo_state.tiles.any((tile) {
              final matches = state.tiles.where((item) => item.id == tile.id);
              if (matches.length != 1) return true;
              final current = matches.single;
              return current.x != tile.x ||
                  current.y != tile.y ||
                  current.layer != tile.layer ||
                  current.width != tile.width ||
                  current.height != tile.height;
            })) {
          throw const FormatException('Undo belongs to a different challenge');
        }
        engine._undo_state = undo_state;
      }
      return engine;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Malformed engine save');
    }
  }
}

/// Small bounded search over held types and the three physical reserve stacks.
/// The board removal order is already geometric; assigning a remaining type to
/// its next position cannot change which board tile is legally exposed.
class _ShuffleContinuation {
  final TileQuestState state;
  final List<int> board_order;
  final Random random;
  final Stopwatch stopwatch;
  final List<int> board_supply = List.filled(TileQuestConfig.max_tile_types, 0);
  final List<int> tray_counts = List.filled(TileQuestConfig.max_tile_types, 0);
  late final List<List<int>> stacks;
  late final List<int> stack_sizes;
  final Set<String> visited = {};
  final List<int> path = [];
  final Map<int, int> assignments = {};
  final Set<int> reserve_types = {};
  late final Map<int, int> tile_types;
  final Map<int, int> fixed_types;
  final Set<int> protected_types;
  late final int last_fixed_index;
  var nodes = 0;

  _ShuffleContinuation(
    this.state,
    this.board_order,
    this.random,
    this.stopwatch, {
    this.fixed_types = const {},
    this.protected_types = const {},
  }) {
    last_fixed_index = fixed_types.keys.fold<int>(
      -1,
      (last, id) => max(last, board_order.indexOf(id)),
    );
    tile_types = {for (final tile in state.tiles) tile.id: tile.type};
    for (final tile in state.tiles.where((tile) => !tile.is_removed)) {
      board_supply[tile.type]++;
    }
    for (final id in state.tray) {
      tray_counts[tile_types[id]!]++;
    }
    stacks = List.generate(TileQuestConfig.reserve_columns, (_) => <int>[]);
    for (final id in state.reserve) {
      stacks[state.reserve_column(id)].add(id);
      reserve_types.add(tile_types[id]!);
    }
    stack_sizes = stacks.map((stack) => stack.length).toList();
  }

  _ShuffleContinuation? build() => _search(0, state.tray.length) ? this : null;

  bool _search(int board_index, int occupancy) {
    if (++nodes > 30000 ||
        stopwatch.elapsedMilliseconds > TileQuestConfig.shuffle_budget_ms) {
      return false;
    }
    final reserve_left = stack_sizes.fold<int>(0, (sum, size) => sum + size);
    if (board_index == board_order.length && reserve_left == 0) {
      return occupancy == 0;
    }
    if (occupancy == 0 &&
        reserve_left == 0 &&
        state.difficulty >= 4 &&
        board_index > last_fixed_index) {
      try {
        final sequence = TileQuestTypeAllocator.remaining(
          board_supply,
          profile: DifficultyProfile.for_difficulty(state.difficulty),
          random: random,
        );
        if (sequence.length != board_order.length - board_index ||
            stopwatch.elapsedMilliseconds > TileQuestConfig.shuffle_budget_ms) {
          return false;
        }
        for (var index = 0; index < sequence.length; index++) {
          final id = board_order[board_index + index];
          assignments[id] = sequence[index];
          path.add(id);
        }
        return true;
      } on StateError {
        // Keep the original state rather than silently replacing a hard board
        // with a certificate consisting entirely of consecutive easy triples.
        return false;
      }
    }
    final key =
        '${board_supply.join(',')}/${tray_counts.join(',')}/'
        '${stack_sizes.join(',')}';
    if (!visited.add(key)) return false;

    // Prefer completing a pair, then extending a group already in the tray.
    // A buried reserve is never offered as a legal choice.
    final choices = <({int type, int column})>[];
    for (var column = 0; column < stacks.length; column++) {
      if (stack_sizes[column] == 0) continue;
      final id = stacks[column][stack_sizes[column] - 1];
      choices.add((type: tile_types[id]!, column: column));
    }
    for (var type = 0; type < board_supply.length; type++) {
      if (board_supply[type] == 0) continue;
      final fixed = board_index < board_order.length
          ? fixed_types[board_order[board_index]]
          : null;
      if (fixed != null ? type != fixed : protected_types.contains(type)) {
        continue;
      }
      // An unrelated complete group can wait until the held inventory clears.
      if (protected_types.isEmpty &&
          tray_counts[type] == 0 &&
          !reserve_types.contains(type) &&
          (reserve_left > 0 || occupancy > 0)) {
        continue;
      }
      choices.add((type: type, column: -1));
    }
    choices.shuffle(random);
    choices.sort((a, b) {
      if (protected_types.isNotEmpty) {
        int pressure_rank(int type) {
          final count = tray_counts[type];
          if (occupancy >= 6) return count == 2 ? 100 : 0;
          if (occupancy == 5) {
            return count == 1
                ? 80
                : count == 2
                ? 60
                : 0;
          }
          return count < 2 ? 40 - count : 0;
        }

        final pressure = pressure_rank(b.type).compareTo(pressure_rank(a.type));
        if (pressure != 0) return pressure;
      }
      final group_order = tray_counts[b.type].compareTo(tray_counts[a.type]);
      if (group_order != 0) return group_order;
      return (b.column >= 0 ? 1 : 0).compareTo(a.column >= 0 ? 1 : 0);
    });
    for (final choice in choices) {
      final type = choice.type;
      final old_count = tray_counts[type];
      final next_occupancy = occupancy + (old_count == 2 ? -2 : 1);
      if (next_occupancy >= TileQuestConfig.tray_capacity) continue;
      final from_reserve = choice.column >= 0;
      final id = from_reserve
          ? stacks[choice.column][stack_sizes[choice.column] - 1]
          : board_order[board_index];
      tray_counts[type] = (old_count + 1) % 3;
      if (from_reserve) {
        stack_sizes[choice.column]--;
      } else {
        board_supply[type]--;
        assignments[id] = type;
      }
      path.add(id);
      if (_search(board_index + (from_reserve ? 0 : 1), next_occupancy)) {
        return true;
      }
      path.removeLast();
      tray_counts[type] = old_count;
      if (from_reserve) {
        stack_sizes[choice.column]++;
      } else {
        board_supply[type]++;
        assignments.remove(id);
      }
    }
    return false;
  }
}
