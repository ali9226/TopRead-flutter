// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math';

import 'package:app/pages/tile_quest/game/config.dart';
import 'package:app/pages/tile_quest/game/geometry.dart';
import 'package:app/pages/tile_quest/game/models.dart';

/// Development-only policies. No player session imports or runs this evaluator.
enum TileQuestStrategy {
  random,
  complete_triple,
  release_blockers,
  limited_search,
  id_ascending,
  id_descending,
  row_major,
  reverse_row_major,
  column_major,
  top_layer_first,
  bottom_layer_first,
}

/// One deterministic, tool-free playthrough. Occupancy is measured after settlement.
class TileQuestSimulation {
  const TileQuestSimulation({
    required this.won,
    required this.steps,
    required this.occupancy_sum,
    required this.available_sum,
    required this.remaining_tiles,
    this.max_search_nodes = 0,
  });

  final bool won;
  final int steps;
  final int occupancy_sum;
  final int available_sum;
  final int remaining_tiles;
  final int max_search_nodes;

  Map<String, dynamic> to_json() => {
    'won': won,
    'steps': steps,
    'mean_tray_occupancy': steps == 0 ? 0 : occupancy_sum / steps,
    'mean_tray_fill_ratio': steps == 0
        ? 0
        : occupancy_sum / steps / TileQuestConfig.tray_capacity,
    'mean_available_moves': steps == 0 ? 0 : available_sum / steps,
    'remaining_board_tiles': remaining_tiles,
    'max_search_nodes_in_one_decision': max_search_nodes,
  };
}

/// Bounded forward search shares one cached geometric graph for the entire run.
/// The search policy can inspect future revealed patterns, providing an optimistic
/// benchmark. No policy reads the certificate or changes the generated board.
class TileQuestEvaluator {
  TileQuestEvaluator({this.search_depth = 3, this.node_budget = 96});

  final int search_depth;
  final int node_budget;

  TileQuestSimulation simulate(
    TileQuestState state,
    TileQuestStrategy strategy, {
    required int policy_seed,
  }) {
    if (search_depth < 1 || node_budget < 1) {
      throw ArgumentError('Search bounds must be positive.');
    }
    final geometry = TileQuestGeometry(state.tiles);
    final tiles = {for (final tile in state.tiles) tile.id: tile};
    final random = Random(policy_seed);
    var position = _Position(
      state.tiles
          .where((tile) => !tile.is_removed)
          .map((tile) => tile.id)
          .toSet(),
      state.tray.map((id) => tiles[id]!.type).toList(),
    );
    if (state.reserve.isNotEmpty) {
      throw ArgumentError(
        'Evaluation requires an initial board without reserves.',
      );
    }
    int steps = 0;
    int occupancy_sum = 0;
    int available_sum = 0;
    int max_search_nodes = 0;
    while (position.active.isNotEmpty && !position.lost) {
      final choices = _available(position, geometry)..shuffle(random);
      if (choices.isEmpty) break;
      available_sum += choices.length;
      final int chosen;
      switch (strategy) {
        case TileQuestStrategy.random:
          chosen = choices.first;
        case TileQuestStrategy.complete_triple:
          chosen = _best(
            choices,
            (id) => _tray_count(position, tiles[id]!.type) * 100.0,
          );
        case TileQuestStrategy.release_blockers:
          chosen = _best(
            choices,
            (id) =>
                _released(id, position, geometry) * 100.0 +
                _tray_count(position, tiles[id]!.type) * 10.0,
          );
        case TileQuestStrategy.limited_search:
          final search = _search_choice(choices, position, geometry, tiles);
          chosen = search.id;
          max_search_nodes = max(max_search_nodes, search.nodes);
        case TileQuestStrategy.id_ascending:
        case TileQuestStrategy.id_descending:
        case TileQuestStrategy.row_major:
        case TileQuestStrategy.reverse_row_major:
        case TileQuestStrategy.column_major:
        case TileQuestStrategy.top_layer_first:
        case TileQuestStrategy.bottom_layer_first:
          chosen = _scan_choice(choices, strategy, tiles);
      }
      position = _advance(position, chosen, tiles);
      steps++;
      occupancy_sum += position.tray.length;
    }
    return TileQuestSimulation(
      won: position.active.isEmpty && position.tray.isEmpty,
      steps: steps,
      occupancy_sum: occupancy_sum,
      available_sum: available_sum,
      remaining_tiles: position.active.length,
      max_search_nodes: max_search_nodes,
    );
  }

  /// Deliberately simple scans catch accidental solutions encoded in IDs,
  /// serialization order, screen position, or the visible layer stack.
  int _scan_choice(
    List<int> choices,
    TileQuestStrategy strategy,
    Map<int, TileQuestTile> tiles,
  ) {
    int compare(int a, int b) {
      final left = tiles[a]!, right = tiles[b]!;
      final int primary;
      final int secondary;
      switch (strategy) {
        case TileQuestStrategy.id_ascending:
          return a.compareTo(b);
        case TileQuestStrategy.id_descending:
          return b.compareTo(a);
        case TileQuestStrategy.row_major:
        case TileQuestStrategy.reverse_row_major:
          primary = left.y.compareTo(right.y);
          secondary = left.x.compareTo(right.x);
        case TileQuestStrategy.column_major:
          primary = left.x.compareTo(right.x);
          secondary = left.y.compareTo(right.y);
        case TileQuestStrategy.top_layer_first:
          primary = right.layer.compareTo(left.layer);
          secondary = left.y.compareTo(right.y);
        case TileQuestStrategy.bottom_layer_first:
          primary = left.layer.compareTo(right.layer);
          secondary = left.y.compareTo(right.y);
        default:
          throw ArgumentError('Not a spatial scan strategy');
      }
      final order = primary != 0
          ? primary
          : secondary != 0
          ? secondary
          : a.compareTo(b);
      return strategy == TileQuestStrategy.reverse_row_major ? -order : order;
    }

    return (List<int>.from(choices)..sort(compare)).first;
  }

  /// Aggregate rates are bot behavior, never a claim about human failure rates.
  Map<String, dynamic> summarize(List<TileQuestSimulation> runs) {
    final failures = runs.where((run) => !run.won).toList();
    final steps = runs.fold<int>(0, (sum, run) => sum + run.steps);
    return {
      'samples': runs.length,
      'simulated_clear_rate': runs.isEmpty
          ? 0.0
          : runs.where((run) => run.won).length / runs.length,
      'average_failure_steps': failures.isEmpty
          ? null
          : failures.fold<int>(0, (sum, run) => sum + run.steps) /
                failures.length,
      'average_tray_occupancy': steps == 0
          ? 0.0
          : runs.fold<int>(0, (sum, run) => sum + run.occupancy_sum) / steps,
      'average_tray_fill_ratio': steps == 0
          ? 0.0
          : runs.fold<int>(0, (sum, run) => sum + run.occupancy_sum) /
                steps /
                TileQuestConfig.tray_capacity,
      'average_failure_remaining_board_tiles': failures.isEmpty
          ? null
          : failures.fold<int>(0, (sum, run) => sum + run.remaining_tiles) /
                failures.length,
      'average_available_moves': steps == 0
          ? 0.0
          : runs.fold<int>(0, (sum, run) => sum + run.available_sum) / steps,
      'maximum_search_nodes_in_one_decision': runs.fold<int>(
        0,
        (largest, run) => max(largest, run.max_search_nodes),
      ),
    };
  }

  List<int> _available(_Position position, TileQuestGeometry geometry) =>
      position.active
          .where((id) => !geometry.blockers[id]!.any(position.active.contains))
          .toList();

  int _tray_count(_Position position, int type) =>
      position.tray.where((item) => item == type).length;

  _Position _advance(
    _Position position,
    int id,
    Map<int, TileQuestTile> tiles,
  ) {
    final tray = [...position.tray, tiles[id]!.type];
    final type = tiles[id]!.type;
    if (tray.where((item) => item == type).length == 3) {
      tray.removeWhere((item) => item == type);
    }
    return _Position({...position.active}..remove(id), tray);
  }

  /// Count newly exposed rectangles, not the number of nominal lower layers.
  int _released(int id, _Position position, TileQuestGeometry geometry) =>
      geometry.supported[id]!
          .where(
            (lower) =>
                position.active.contains(lower) &&
                geometry.blockers[lower]!.every(
                  (upper) => upper == id || !position.active.contains(upper),
                ),
          )
          .length;

  int _best(List<int> choices, double Function(int) score) {
    int best_id = choices.first;
    double best_score = double.negativeInfinity;
    for (final id in choices) {
      final value = score(id);
      if (value > best_score) {
        best_id = id;
        best_score = value;
      }
    }
    return best_id;
  }

  /// Root expansions count against the same hard bound as descendants. When
  /// the budget is smaller than the legal action set, inspect a seeded subset.
  ({int id, int nodes}) _search_choice(
    List<int> choices,
    _Position position,
    TileQuestGeometry geometry,
    Map<int, TileQuestTile> tiles,
  ) {
    final considered = choices.take(node_budget).toList();
    final per_root_budget = node_budget ~/ considered.length;
    int expanded = 0;
    final id = _best(considered, (id) {
      final budget = _Budget(per_root_budget - 1);
      final score =
          _search(
            _advance(position, id, tiles),
            geometry,
            tiles,
            search_depth - 1,
            budget,
          ) +
          _released(id, position, geometry) * .05;
      expanded += per_root_budget - budget.left;
      return score;
    });
    return (id: id, nodes: expanded);
  }

  double _search(
    _Position position,
    TileQuestGeometry geometry,
    Map<int, TileQuestTile> tiles,
    int depth,
    _Budget budget,
  ) {
    if (position.lost) return -100000;
    if (position.active.isEmpty && position.tray.isEmpty) return 100000;
    final choices = _available(position, geometry);
    final counts = <int, int>{};
    for (final type in position.tray) {
      counts[type] = (counts[type] ?? 0) + 1;
    }
    final heuristic =
        -position.active.length.toDouble() -
        position.tray.length * 8.0 -
        counts.length * 2.0 +
        choices.length * .25;
    if (depth == 0 || budget.left <= 0 || choices.isEmpty) return heuristic;
    // Promising moves are expanded first within the hard expansion budget.
    choices.sort(
      (a, b) =>
          ((_tray_count(position, tiles[b]!.type) * 10) +
                  _released(b, position, geometry))
              .compareTo(
                (_tray_count(position, tiles[a]!.type) * 10) +
                    _released(a, position, geometry),
              ),
    );
    double best = double.negativeInfinity;
    for (final id in choices.take(8)) {
      if (budget.left <= 0) break;
      budget.left--;
      final value = _search(
        _advance(position, id, tiles),
        geometry,
        tiles,
        depth - 1,
        budget,
      );
      best = max(best, value);
    }
    return best.isFinite ? best : heuristic;
  }
}

class _Position {
  const _Position(this.active, this.tray);
  final Set<int> active;
  final List<int> tray;
  bool get lost => tray.length >= TileQuestConfig.tray_capacity;
}

class _Budget {
  _Budget(this.left);
  int left;
}
