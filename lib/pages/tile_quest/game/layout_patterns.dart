// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:math';
import 'config.dart';
import 'models.dart';

/// Seeded polyomino growth replaces the former finite silhouette catalogue.
/// All occupied coordinates stay inside one shared seven-by-nine logical board.
class TileQuestLayoutPatterns {
  static const int minimum_envelope_cells = 48;
  static const int envelope_cell_variation = 7;
  static const int minimum_half_cells = 18;
  static const int envelope_attempts = 16;

  static int get columns => TileQuestConfig.board_logical_width.toInt();
  static int get rows => TileQuestConfig.board_logical_height.toInt();

  /// Grow several random dense seeds, then carve random recesses. No layout id,
  /// named template, fixed auxiliary pile or small catalogue determines a board.
  static List<TileQuestTile> generate(
    DifficultyProfile profile,
    Random random,
  ) {
    final envelope = _envelope(random, expert: profile.difficulty == 10);
    final even_cells = envelope
        .map((point) => Point<double>(point.x.toDouble(), point.y.toDouble()))
        .toList();
    final half_cells = _half_cells(envelope);
    final cap_count =
        (profile.min_initial_choices ~/ 3 + random.nextInt(3)) * 3;
    var upper = _spread(even_cells, cap_count, random);
    var remaining = profile.tile_count;
    final tiles = <TileQuestTile>[];
    double weight(int depth) {
      final capacity = depth.isEven ? even_cells.length : half_cells.length;
      final progress = depth / max(1, profile.layers - 1);
      return capacity * (.8 + 1.2 * pow(1 - progress, 1.5));
    }

    for (var depth = 0; depth < profile.layers; depth++) {
      final allowed = depth.isEven ? even_cells : half_cells;
      final shift = depth.isEven ? 0.0 : profile.overlap_offset;
      final candidates = depth == 0
          ? upper
          : _lower_candidates(upper, allowed.toSet(), shift);
      final layers_left = profile.layers - depth;
      final future_depths = List<int>.generate(
        layers_left - 1,
        (index) => depth + index + 1,
      );
      final future_capacity = future_depths.fold<int>(
        0,
        (sum, next) =>
            sum + (next.isEven ? even_cells.length : half_cells.length),
      );
      final minimum = max(1, remaining - future_capacity);
      final maximum = min(candidates.length, remaining - layers_left + 1);
      if (minimum > maximum) throw StateError('Random footprint inventory gap');
      final weighted_share =
          (remaining *
                  weight(depth) /
                  (weight(depth) +
                      future_depths.fold<double>(
                        0,
                        (sum, next) => sum + weight(next),
                      )))
              .round();
      final count = depth == 0
          ? cap_count
          : weighted_share.clamp(minimum, maximum);
      final footprint = depth == 0
          ? upper
          : _cluster(candidates, count, random);
      if (footprint.length != count || count > remaining) {
        throw StateError('Random footprint cannot fit its inventory');
      }
      for (final point in footprint) {
        tiles.add(
          TileQuestTile(
            id: tiles.length,
            type: 0,
            layer: profile.layers - depth - 1,
            x: point.x,
            y: point.y,
          ),
        );
      }
      upper = footprint;
      remaining -= count;
    }
    if (remaining != 0) {
      throw StateError('Random footprint inventory incomplete');
    }
    return tiles;
  }

  static bool _inside(Point<int> point, bool expert) =>
      point.x >= 0 &&
      point.x < columns &&
      point.y >= 0 &&
      point.y < rows &&
      !(expert && point.x >= 5 && point.y == 7);

  static Iterable<Point<int>> _neighbors(Point<int> point) sync* {
    yield Point(point.x - 1, point.y);
    yield Point(point.x + 1, point.y);
    yield Point(point.x, point.y - 1);
    yield Point(point.x, point.y + 1);
  }

  static List<Point<double>> _half_cells(Set<Point<int>> envelope) => [
    for (final point in envelope)
      if (envelope.contains(Point(point.x + 1, point.y)) &&
          envelope.contains(Point(point.x, point.y + 1)) &&
          envelope.contains(Point(point.x + 1, point.y + 1)))
        Point<double>(point.x + .5, point.y + .5),
  ];

  static Set<Point<int>> _envelope(Random random, {required bool expert}) {
    for (var attempt = 0; attempt < envelope_attempts; attempt++) {
      final occupied = <Point<int>>{};
      final seed_count = 2 + random.nextInt(4);
      for (var seed = 0; seed < seed_count; seed++) {
        final x = random.nextInt(columns - 1);
        final y = random.nextInt(rows - 1);
        for (var dy = 0; dy < 2; dy++) {
          for (var dx = 0; dx < 2; dx++) {
            final point = Point(x + dx, y + dy);
            if (_inside(point, expert)) occupied.add(point);
          }
        }
      }
      final target =
          minimum_envelope_cells + random.nextInt(envelope_cell_variation);
      while (occupied.length < target) {
        final frontier = occupied
            .expand(_neighbors)
            .where(
              (point) => _inside(point, expert) && !occupied.contains(point),
            )
            .toSet()
            .toList();
        if (frontier.isEmpty) break;
        final scores = {
          for (final point in frontier)
            point:
                pow(_neighbors(point).where(occupied.contains).length, 2) +
                random.nextDouble() * 5,
        };
        frontier.sort((left, right) => scores[right]!.compareTo(scores[left]!));
        occupied.add(frontier.first);
      }
      // Internal voids and edge recesses are retained by every layer's mask.
      final carve = occupied.toList()..shuffle(random);
      var removed = 0;
      for (final point in carve) {
        if (_neighbors(point).where(occupied.contains).length < 2) continue;
        occupied.remove(point);
        if (_half_cells(occupied).length < minimum_half_cells ||
            occupied.length < 40) {
          occupied.add(point);
        } else if (++removed >= 2 + attempt % 3) {
          break;
        }
      }
      if (occupied.length >= 40 &&
          _half_cells(occupied).length >= minimum_half_cells) {
        return occupied;
      }
    }
    throw StateError('A dense random envelope could not be grown');
  }

  static List<Point<double>> _lower_candidates(
    List<Point<double>> upper,
    Set<Point<double>> allowed,
    double shift,
  ) {
    final candidates = <Point<double>>{};
    for (final point in upper) {
      for (final x in [(point.x - shift).floor(), (point.x - shift).ceil()]) {
        for (final y in [(point.y - shift).floor(), (point.y - shift).ceil()]) {
          final candidate = Point<double>(x + shift, y + shift);
          if (allowed.contains(candidate)) candidates.add(candidate);
        }
      }
    }
    return candidates.toList();
  }

  /// A broad easy cap covers several branches instead of one aligned rectangle.
  static List<Point<double>> _spread(
    List<Point<double>> cells,
    int count,
    Random random,
  ) {
    final available = List<Point<double>>.from(cells)..shuffle(random);
    if (count > available.length) {
      throw StateError('Opening exceeds its envelope');
    }
    final selected = <Point<double>>[];
    while (selected.length < count) {
      if (selected.isNotEmpty) {
        double nearest(Point<double> point) =>
            selected.map((other) => point.squaredDistanceTo(other)).reduce(min);
        available.sort(
          (left, right) => nearest(right).compareTo(nearest(left)),
        );
      }
      selected.add(available.removeAt(0));
    }
    return selected;
  }

  /// Each hidden layer grows its own small clusters within its actual blockers.
  static List<Point<double>> _cluster(
    List<Point<double>> cells,
    int count,
    Random random,
  ) {
    final selected = _spread(cells, min(count, 2 + random.nextInt(4)), random);
    final available = List<Point<double>>.from(cells)
      ..removeWhere(selected.contains);
    final noise = {for (final point in available) point: random.nextDouble()};
    while (selected.length < count) {
      double score(Point<double> point) =>
          selected.map((other) => point.squaredDistanceTo(other)).reduce(min) +
          noise[point]! * 1.6;
      available.sort((left, right) => score(left).compareTo(score(right)));
      selected.add(available.removeAt(0));
    }
    return selected;
  }
}
