// ignore_for_file: non_constant_identifier_names
import 'dart:math';
import 'geometry_style.dart';
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

  /// Area is computed from the actual logical rectangles, including fractional
  /// template offsets. Adjacency and disjoint rectangles have no covered area.
  static double overlap_area(TileQuestTile lower, TileQuestTile upper) {
    final width =
        min(lower.x + lower.width, upper.x + upper.width) -
        max(lower.x, upper.x);
    final height =
        min(lower.y + lower.height, upper.y + upper.height) -
        max(lower.y, upper.y);
    if (width <= 0 || height <= 0) return 0;
    return width * height;
  }

  /// The lower collision area is the reference even when tile dimensions differ.
  /// Rounded artwork, its shadow and atlas bleed do not enlarge that rectangle.
  static double occlusion_area_ratio(
    TileQuestTile lower,
    TileQuestTile upper,
  ) => overlap_area(lower, upper) / (lower.width * lower.height);

  /// Only a higher logical layer can cover a tile. A tiny tolerance eliminates
  /// numeric slivers without making visibly covered tiles available for tapping.
  static bool overlaps(TileQuestTile lower, TileQuestTile upper) =>
      upper.layer > lower.layer &&
      occlusion_area_ratio(lower, upper) >
          TileQuestGeometryStyle.minimum_occlusion_area_ratio;

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
