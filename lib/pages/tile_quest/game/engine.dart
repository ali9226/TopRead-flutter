// ignore_for_file: constant_identifier_names, non_constant_identifier_names
import 'dart:math';
import 'config.dart';
import 'geometry.dart';
import 'expert_barrier.dart';
import 'models.dart';
import 'validator.dart';

/// All actions commit synchronously and publish immutable snapshots. Animations
/// cannot duplicate taps, race a save, or partially consume a tool.
class TileQuestEngine {
  TileQuestState _state;
  TileQuestState? _undo_state;
  final TileQuestGeometry _geometry;
  TileQuestEngine(TileQuestState state)
    : _state = state,
      _geometry = TileQuestValidator.validate_state(state);

  /// Parsing a save already performs every state and certificate invariant.
  /// Build the retained graph without replaying the same save again.
  TileQuestEngine._validated(TileQuestState state)
    : _state = state,
      _geometry = TileQuestGeometry(state.tiles);
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
    // Settle every complete triple of the inserted type. A strict equality
    // check would leave four or more identical tiles stranded in the tray.
    final matches = <int>[];
    while (true) {
      final group = tray
          .where((held) => before.tile_by_id(held).type == type)
          .toList();
      if (group.length < 3) break;
      final triple = group.take(3).toList();
      matches.addAll(triple);
      tray.removeWhere(triple.contains);
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

  /// 纯随机洗牌：打乱仍在棋盘上的牌面，不保证有解。
  /// 只要道具可用就一定成功；托盘与备用堆的牌面保持不变。
  TileQuestActionResult shuffle({int? seed}) {
    if (_state.status != TileQuestStatus.playing ||
        (_state.tools[TileQuestTool.shuffle] ?? 0) <= 0 ||
        _state.remaining_count == 0) {
      return _reject(TileQuestAction.shuffle, 'Shuffle is unavailable');
    }
    final before = _state;
    // 专家门的正面/配对牌保持原样，避免洗牌后门槛结构非法；
    // 其余仍在棋盘上的牌面纯随机重排。
    final locked_ids = <int>{
      if (before.expert_barrier != null) ...before.expert_barrier!.front_ids,
      if (before.expert_barrier != null) ...before.expert_barrier!.partner_ids,
    };
    final board = [
      for (final tile in before.tiles)
        if (!tile.is_removed && !locked_ids.contains(tile.id)) tile,
    ];
    if (board.isEmpty) {
      return _reject(TileQuestAction.shuffle, 'No board tiles to shuffle');
    }
    final random = Random(
      seed ?? before.seed ^ before.matched_count ^ before.tray.length * 997,
    );
    final types = [for (final tile in board) tile.type]..shuffle(random);
    final by_id = {
      for (var index = 0; index < board.length; index++)
        board[index].id: types[index],
    };
    final tiles = [
      for (final tile in before.tiles)
        tile.is_removed || locked_ids.contains(tile.id)
            ? tile
            : tile.copy_with(type: by_id[tile.id]!),
    ];
    _state = before.copy_with(
      tiles: tiles,
      certified_solution: const [],
      tools: _consume(TileQuestTool.shuffle),
      tools_used: before.tools_used + 1,
    );
    return TileQuestActionResult(
      accepted: true,
      before: before,
      after: _state,
      action: TileQuestAction.shuffle,
      moved_ids: [
        for (final tile in before.tiles)
          if (!tile.is_removed) tile.id,
      ],
    );
  }

  TileQuestEngineSnapshot capture_snapshot() =>
      TileQuestEngineSnapshot(state: _state, undo_state: _undo_state);

  Map<String, dynamic> export_json() => capture_snapshot().export_json();

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
      final engine = TileQuestEngine._validated(state);
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

/// 可跨 isolate 发送的轻量存档快照，始终指向调用时的不可变状态。
class TileQuestEngineSnapshot {
  const TileQuestEngineSnapshot({
    required this.state,
    required this.undo_state,
  });

  final TileQuestState state;
  final TileQuestState? undo_state;

  Map<String, dynamic> export_json() => {
    'version': TileQuestConfig.save_version,
    'state': state.to_json(),
    'undo_state': undo_state?.to_json(),
  };
}
