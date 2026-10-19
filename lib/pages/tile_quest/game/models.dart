// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'config.dart';
import 'expert_barrier.dart';
import 'validator.dart';

enum TileQuestStatus { playing, won, lost }

enum TileQuestTool { undo, shuffle, remove }

enum TileQuestAction { tap, return_reserve, undo, shuffle, remove }

/// Immutable logical rectangle. A removed tile may be in a tray or already matched.
class TileQuestTile {
  final int id;
  final int type;
  final int layer;

  /// Stable template region; it never changes when a tile enters the tray.
  final String region_id;
  final double x;
  final double y;
  final double width;
  final double height;
  final bool is_removed;
  final bool is_blocked;
  const TileQuestTile({
    required this.id,
    required this.type,
    required this.layer,
    required this.x,
    required this.y,
    this.region_id = 'main',
    this.width = 1,
    this.height = 1,
    this.is_removed = false,
    this.is_blocked = false,
  });

  /// Grid coordinates and template offsets derive from the authoritative x/y.
  /// Half-cell staggering therefore needs no second, potentially stale position.
  int get grid_row => y.floor();
  int get grid_column => x.floor();
  double get offset_x => x - grid_column;
  double get offset_y => y - grid_row;

  TileQuestTile copy_with({
    int? type,
    int? layer,
    String? region_id,
    bool? is_removed,
    bool? is_blocked,
  }) => TileQuestTile(
    id: id,
    type: type ?? this.type,
    layer: layer ?? this.layer,
    region_id: region_id ?? this.region_id,
    x: x,
    y: y,
    width: width,
    height: height,
    is_removed: is_removed ?? this.is_removed,
    is_blocked: is_blocked ?? this.is_blocked,
  );

  Map<String, dynamic> to_json() => {
    'id': id,
    'type': type,
    'layer': layer,
    'region_id': region_id,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'is_removed': is_removed,
    'is_blocked': is_blocked,
  };
}

/// Immutable, independently serializable game snapshot used by logic and animation.
class TileQuestState {
  final List<TileQuestTile> tiles;

  /// Each immutable snapshot owns its lazy index. Animation and settlement can
  /// resolve hundreds of identities without scanning the full board per lookup.
  late final Map<int, TileQuestTile> _tiles_by_id = {
    for (final tile in tiles) tile.id: tile,
  };
  final List<int> tray;
  final List<int> reserve;

  /// Stable physical columns: returning a tile never slides another stack.
  final Map<int, int> reserve_columns;
  final TileQuestStatus status;
  final int level;
  final int difficulty;
  final int seed;
  final String challenge_id;
  final int elapsed_ms;
  final int unlocked_level;
  final Map<TileQuestTool, int> tools;
  final List<int> certified_solution;
  final int matched_count;
  final int tools_used;
  final bool sound_enabled;
  final TileQuestExpertBarrier? expert_barrier;

  TileQuestState({
    required List<TileQuestTile> tiles,
    List<int> tray = const [],
    List<int> reserve = const [],
    Map<int, int>? reserve_columns,
    this.status = TileQuestStatus.playing,
    required this.level,
    required this.seed,
    required this.challenge_id,
    int? difficulty,
    this.elapsed_ms = 0,
    this.unlocked_level = 1,
    Map<TileQuestTool, int>? tools,
    List<int> certified_solution = const [],
    this.matched_count = 0,
    this.tools_used = 0,
    this.sound_enabled = true,
    this.expert_barrier,
  }) : tiles = List.unmodifiable(tiles),
       tray = List.unmodifiable(tray),
       reserve = List.unmodifiable(reserve),
       reserve_columns = Map.unmodifiable(
         reserve_columns ??
             {
               for (var index = 0; index < reserve.length; index++)
                 reserve[index]: index % TileQuestConfig.reserve_columns,
             },
       ),
       difficulty =
           difficulty ??
           (level == 1
               ? TileQuestConfig.level1Difficulty
               : TileQuestConfig.gameDifficulty),
       tools = Map.unmodifiable(
         tools ??
             {
               for (final tool in TileQuestTool.values)
                 tool: TileQuestConfig.initial_tool_uses(tool),
             },
       ),
       certified_solution = List.unmodifiable(certified_solution);

  int get remaining_count => tiles.where((tile) => !tile.is_removed).length;
  int get total_count => tiles.length;
  List<TileQuestTile> get clickable_tiles => List.unmodifiable(
    tiles.where((tile) => !tile.is_removed && !tile.is_blocked),
  );
  TileQuestTile tile_by_id(int id) =>
      _tiles_by_id[id] ?? (throw StateError('No element'));

  int reserve_column(int id) => reserve_columns[id] ?? -1;

  /// Depth increases from the bottom of a column to its currently visible top.
  int reserve_depth(int id) {
    final index = reserve.indexOf(id);
    if (index < 0) return -1;
    return reserve
        .take(index)
        .where((held) => reserve_column(held) == reserve_column(id))
        .length;
  }

  bool is_reserve_available(int id) {
    final index = reserve.indexOf(id);
    return index >= 0 &&
        !reserve
            .skip(index + 1)
            .any((held) => reserve_column(held) == reserve_column(id));
  }

  TileQuestState copy_with({
    List<TileQuestTile>? tiles,
    List<int>? tray,
    List<int>? reserve,
    Map<int, int>? reserve_columns,
    TileQuestStatus? status,
    int? elapsed_ms,
    int? unlocked_level,
    Map<TileQuestTool, int>? tools,
    List<int>? certified_solution,
    int? matched_count,
    int? tools_used,
    bool? sound_enabled,
    TileQuestExpertBarrier? expert_barrier,
  }) => TileQuestState(
    tiles: tiles ?? this.tiles,
    tray: tray ?? this.tray,
    reserve: reserve ?? this.reserve,
    reserve_columns:
        reserve_columns ??
        {
          for (final id in reserve ?? this.reserve)
            id:
                this.reserve_columns[id] ??
                (reserve ?? this.reserve).indexOf(id) %
                    TileQuestConfig.reserve_columns,
        },
    status: status ?? this.status,
    level: level,
    difficulty: difficulty,
    seed: seed,
    challenge_id: challenge_id,
    elapsed_ms: elapsed_ms ?? this.elapsed_ms,
    unlocked_level: unlocked_level ?? this.unlocked_level,
    tools: tools ?? this.tools,
    certified_solution: certified_solution ?? this.certified_solution,
    matched_count: matched_count ?? this.matched_count,
    tools_used: tools_used ?? this.tools_used,
    sound_enabled: sound_enabled ?? this.sound_enabled,
    expert_barrier: expert_barrier ?? this.expert_barrier,
  );

  Map<String, dynamic> to_json() => {
    'version': TileQuestConfig.save_version,
    'tiles': tiles.map((tile) => tile.to_json()).toList(),
    'tray': tray,
    'reserve': reserve,
    'reserve_columns': {
      for (final entry in reserve_columns.entries)
        entry.key.toString(): entry.value,
    },
    'status': status.name,
    'level': level,
    'difficulty': difficulty,
    'seed': seed,
    'challenge_id': challenge_id,
    'elapsed_ms': elapsed_ms,
    'unlocked_level': unlocked_level,
    'tools': {for (final item in tools.entries) item.key.name: item.value},
    'tool_limits': {
      for (final tool in TileQuestTool.values)
        tool.name: TileQuestConfig.initial_tool_uses(tool),
    },
    'certified_solution': certified_solution,
    'matched_count': matched_count,
    'tools_used': tools_used,
    'sound_enabled': sound_enabled,
    'expert_barrier': expert_barrier?.to_json(),
  };

  /// Reject partial, malformed and inconsistent saves rather than guessing defaults.
  static TileQuestState from_json(Map<String, dynamic> json) {
    try {
      int read_int(dynamic value) {
        if (value is! int) throw const FormatException('Expected integer');
        return value;
      }

      double read_double(dynamic value) {
        if (value is! num || !value.isFinite) {
          throw const FormatException('Expected finite number');
        }
        return value.toDouble();
      }

      bool read_bool(dynamic value) {
        if (value is! bool) throw const FormatException('Expected boolean');
        return value;
      }

      List<int> read_ids(dynamic value) {
        if (value is! List || value.length > TileQuestConfig.max_tiles * 2) {
          throw const FormatException('Invalid ID list');
        }
        return value.map(read_int).toList();
      }

      final version = json['version'];
      if ((version != 1 && version != TileQuestConfig.save_version) ||
          json['tiles'] is! List ||
          (json['tiles'] as List).length > TileQuestConfig.max_tiles ||
          json['tools'] is! Map ||
          (json['tools'] as Map).length != TileQuestTool.values.length ||
          json['challenge_id'] is! String) {
        throw const FormatException('Unsupported or malformed save');
      }
      final tiles = (json['tiles'] as List).map((raw) {
        if (raw is! Map) throw const FormatException('Invalid tile');
        // Older saves predate template regions and retain their original shape.
        // An explicitly malformed new field must not silently become "main".
        if (raw.containsKey('region_id') && raw['region_id'] is! String) {
          throw const FormatException('Invalid tile region');
        }
        return TileQuestTile(
          id: read_int(raw['id']),
          type: read_int(raw['type']),
          layer: read_int(raw['layer']),
          region_id: raw['region_id'] as String? ?? 'main',
          x: read_double(raw['x']),
          y: read_double(raw['y']),
          width: read_double(raw['width']),
          height: read_double(raw['height']),
          is_removed: read_bool(raw['is_removed']),
          is_blocked: read_bool(raw['is_blocked']),
        );
      }).toList();
      final reserve = read_ids(json['reserve']);
      Map<int, int>? columns;
      if (version == TileQuestConfig.save_version) {
        final raw_columns = json['reserve_columns'];
        if (raw_columns is! Map || raw_columns.length != reserve.length) {
          throw const FormatException('Invalid reserve columns');
        }
        columns = {};
        for (final entry in raw_columns.entries) {
          if (entry.key is! String) {
            throw const FormatException('Invalid reserve column key');
          }
          final id = int.tryParse(entry.key as String);
          if (id == null || !reserve.contains(id) || columns.containsKey(id)) {
            throw const FormatException('Unknown reserve column');
          }
          columns[id] = read_int(entry.value);
        }
      }
      final tools = {
        for (final tool in TileQuestTool.values)
          tool: read_int((json['tools'] as Map)[tool.name]),
      };
      // Quotas belong to the saved rules, not whichever build is reading them.
      // v1 shipped with one Remove; early v2 saves had two and no limits field.
      final raw_limits = version == 1 ? null : json['tool_limits'];
      if (raw_limits != null &&
          (raw_limits is! Map ||
              raw_limits.length != TileQuestTool.values.length)) {
        throw const FormatException('Invalid saved tool limits');
      }
      final limits = {
        for (final tool in TileQuestTool.values)
          tool: raw_limits == null
              ? (tool == TileQuestTool.remove && version != 1 ? 2 : 1)
              : read_int((raw_limits as Map)[tool.name]),
      };
      var saved_tools_used = 0;
      for (final tool in TileQuestTool.values) {
        final limit = limits[tool]!;
        final remaining = tools[tool]!;
        if (limit < 1 ||
            limit > TileQuestConfig.max_tiles ||
            remaining < 0 ||
            remaining > limit) {
          throw const FormatException('Invalid saved tool inventory');
        }
        final spent = limit - remaining;
        saved_tools_used += spent;
        // Raising the testing quota preserves the exact number already spent.
        tools[tool] = TileQuestConfig.initial_tool_uses(tool) - spent;
      }
      if (saved_tools_used != read_int(json['tools_used'])) {
        throw const FormatException('Inconsistent saved tool usage');
      }
      if (version == 1) {
        if (reserve.length > TileQuestConfig.remove_batch_size) {
          throw const FormatException('Invalid legacy tool inventory');
        }
      }
      final state = TileQuestState(
        tiles: tiles,
        tray: read_ids(json['tray']),
        reserve: reserve,
        reserve_columns: columns,
        status: TileQuestStatus.values.byName(json['status'] as String),
        level: read_int(json['level']),
        difficulty: read_int(json['difficulty']),
        seed: read_int(json['seed']),
        challenge_id: json['challenge_id'] as String,
        elapsed_ms: read_int(json['elapsed_ms']),
        unlocked_level: read_int(json['unlocked_level']),
        tools: tools,
        certified_solution: read_ids(json['certified_solution']),
        matched_count: read_int(json['matched_count']),
        tools_used: read_int(json['tools_used']),
        sound_enabled: read_bool(json['sound_enabled']),
        expert_barrier: json['expert_barrier'] == null
            ? null
            : TileQuestExpertBarrier.from_json(json['expert_barrier']),
      );
      TileQuestValidator.validate_state(state);
      return state;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Malformed Tile Quest save');
    }
  }
}

/// Explicit before/after state lets rendering animate without owning game rules.
class TileQuestActionResult {
  final bool accepted;
  final TileQuestState before;
  final TileQuestState after;
  final TileQuestAction action;
  final List<int> moved_ids;
  final List<int> matched_ids;
  final List<int> unblocked_ids;

  /// Exact slot order after insertion and before triple settlement. Presentation
  /// uses this snapshot rather than guessing a destination from the tray length.
  final List<int> settlement_tray;
  final String? reason;
  TileQuestActionResult({
    required this.accepted,
    required this.before,
    required this.after,
    required this.action,
    List<int> moved_ids = const [],
    List<int> matched_ids = const [],
    List<int> unblocked_ids = const [],
    List<int> settlement_tray = const [],
    this.reason,
  }) : moved_ids = List.unmodifiable(moved_ids),
       matched_ids = List.unmodifiable(matched_ids),
       unblocked_ids = List.unmodifiable(unblocked_ids),
       settlement_tray = List.unmodifiable(settlement_tray);
}
