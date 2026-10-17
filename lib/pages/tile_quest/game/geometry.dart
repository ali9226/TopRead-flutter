// ignore_for_file: non_constant_identifier_names
import 'dart:math';
import 'models.dart';

/// Static rectangle intersections are cached once per board, independent of frames.
class TileQuestGeometry {
  final Map<int, Set<int>> blockers = {};
  final Map<int, Set<int>> supported = {};
  TileQuestGeometry(List<TileQuestTile> tiles) {
    for (final tile in tiles) {
      blockers[tile.id] = {};
      supported[tile.id] = {};
    }
    for (final lower in tiles) {
      for (final upper in tiles) {
        if (overlaps(lower, upper)) {
          blockers[lower.id]!.add(upper.id);
          supported[upper.id]!.add(lower.id);
        }
      }
    }
  }

  /// Merely touching edges do not block; any positive geometric intersection does.
  static bool overlaps(TileQuestTile lower, TileQuestTile upper) =>
      upper.layer > lower.layer &&
      min(lower.x + lower.width, upper.x + upper.width) -
              max(lower.x, upper.x) >
          .000001 &&
      min(lower.y + lower.height, upper.y + upper.height) -
              max(lower.y, upper.y) >
          .000001;

  List<TileQuestTile> refresh(List<TileQuestTile> tiles) {
    final remaining = tiles
        .where((tile) => !tile.is_removed)
        .map((tile) => tile.id)
        .toSet();
    return tiles
        .map(
          (tile) => tile.copy_with(
            is_blocked:
                !tile.is_removed && blockers[tile.id]!.any(remaining.contains),
          ),
        )
        .toList();
  }

  /// A randomized topological removal order guarantees every planned tap is exposed.
  List<int> removal_order(List<TileQuestTile> tiles, Random random) {
    final remaining = tiles
        .where((tile) => !tile.is_removed)
        .map((tile) => tile.id)
        .toSet();
    final order = <int>[];
    while (remaining.isNotEmpty) {
      final available = remaining
          .where((id) => !blockers[id]!.any(remaining.contains))
          .toList();
      if (available.isEmpty) throw StateError('Cyclic geometry');
      final chosen = available[random.nextInt(available.length)];
      remaining.remove(chosen);
      order.add(chosen);
    }
    return order;
  }
}
