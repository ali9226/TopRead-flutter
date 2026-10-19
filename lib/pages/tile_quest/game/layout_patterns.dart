// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:math';
import 'config.dart';
import 'geometry.dart';
import 'models.dart';

/// Seeded original grid templates. A complete silhouette and several depth
/// basins are chosen before sprites are allocated; coordinates never scatter.
class TileQuestLayoutPatterns {
  static const int template_count = 64;
  static const int main_columns = 6;
  static const int main_rows = 5;
  static const double footprint_width = 6;
  static const double main_top = 2;
  // Adjacent logical faces meet exactly. Only the supplied PNG silhouette
  // determines corner transparency; no artificial backing fills those corners.
  static const double grid_gap = 0;
  static const double tile_extent = 1 - grid_gap;
  static const int base_capacity = 26;
  static const int cap_capacity = 4;
  static const int deep_core_min_layers = 40;
  static const int deep_core_cap_capacity = 6;
  static const int maximum_auxiliary_stacks = 9;
  static const int minimum_auxiliary_stacks = 6;
  static const int maximum_auxiliary_depth = 24;
  static const int contour_search_steps = 40;
  static const double contour_min_power = .01;
  static const double contour_max_power = 10;

  static int cap_count_for_layers(int layers) =>
      layers >= deep_core_min_layers ? deep_core_cap_capacity : cap_capacity;

  /// Main contours grow around several independently seeded peaks, with a
  /// coherent hole/branch motif instead of shrinking toward one fixed center.
  /// The outer helper columns receive a meaningful part of the real inventory,
  /// so several edge stacks have depth rather than advertising a unique gate.
  static List<TileQuestTile> generate(
    DifficultyProfile profile,
    Random random,
  ) {
    for (
      var attempt = 0;
      attempt < TileQuestConfig.max_generation_attempts;
      attempt++
    ) {
      final tiles = _template(profile, random);
      if (tiles != null) return tiles;
    }
    throw StateError('The seeded multi-peak template has no balanced opening');
  }

  /// An accepted template must satisfy the opening bound as a whole. If one
  /// silhouette does not fit this inventory, advance the seeded template stream.
  static List<TileQuestTile>? _template(
    DifficultyProfile profile,
    Random random,
  ) {
    final template = random.nextInt(template_count);
    final channels = _channels(random);
    final peaks = _peaks(random, channels);
    final cap_count = cap_count_for_layers(profile.layers);
    final footprints = [
      for (var layer = 0; layer < profile.layers; layer++)
        _ordered_cells(layer, template, peaks, channels),
    ];
    final auxiliary_layout = _auxiliary_layout(random);
    final preferred_depth = min(
      min(maximum_auxiliary_depth, profile.layers),
      max(3, (profile.layers * .45).round()),
    );
    // Search template stock, not random points. Every returned candidate has an
    // independently measured opening, exact inventory and long main corridors.
    final depths = [
      preferred_depth,
      for (
        var depth = preferred_depth + 1;
        depth <= min(maximum_auxiliary_depth, profile.layers);
        depth++
      )
        depth,
      for (var depth = preferred_depth - 1; depth >= 1; depth--) depth,
    ];
    for (final depth in depths) {
      for (
        var auxiliary_count = maximum_auxiliary_stacks;
        auxiliary_count >= minimum_auxiliary_stacks;
        auxiliary_count--
      ) {
        final auxiliary_layers = _auxiliary_layers(
          auxiliary_layout,
          auxiliary_count,
          depth,
        );
        final auxiliary_stock = auxiliary_layers.fold<int>(
          0,
          (sum, layer) => sum + layer.length,
        );
        final main_count = profile.tile_count - auxiliary_stock;
        final counts = _layer_counts(
          main_count,
          footprints,
          cap_count: cap_count,
        );
        if (counts == null) continue;
        final tiles = <TileQuestTile>[];
        for (var layer = 0; layer < footprints.length; layer++) {
          for (final point in footprints[layer].take(counts[layer])) {
            // Core is a logical depth basin, not necessarily the screen center.
            final core = peaks.any(
              (peak) =>
                  (point.x + .5 - peak.x).abs() <= 1 &&
                  (point.y + .5 - peak.y).abs() <= 1,
            );
            _add(tiles, point, layer, core ? 'core' : 'main');
          }
        }
        for (var layer = 0; layer < auxiliary_layers.length; layer++) {
          for (final slot in auxiliary_layers[layer]) {
            _add(tiles, slot, layer, slot.y == 0 ? 'side_top' : 'side_bottom');
          }
        }
        final opening = TileQuestGeometry(
          tiles,
        ).refresh(tiles).where((tile) => !tile.is_blocked).length;
        if (opening >= TileQuestConfig.minimum_opening_tiles &&
            opening <= TileQuestConfig.maximum_opening_tiles &&
            opening % 3 == 0) {
          return tiles;
        }
      }
    }
    return null;
  }

  static void _add(
    List<TileQuestTile> tiles,
    Point<double> point,
    int layer,
    String region,
  ) => tiles.add(
    TileQuestTile(
      id: tiles.length,
      type: 0,
      region_id: region,
      layer: layer,
      x: point.x + grid_gap / 2,
      y: point.y + grid_gap / 2,
      width: tile_extent,
      height: tile_extent,
    ),
  );

  /// Pick separated depth centers across opposing edges. The third center is
  /// seeded from the remaining corners/shoulders, yielding forked, diagonal and
  /// split silhouettes, not four mirrors of the same central pyramid.
  /// A notch is empty through every ordinary layer, not merely a darkened
  /// lower tile. Half-grid rectangles crossing that cut are removed as well.
  static List<Rectangle<double>> _channels(Random random) {
    final side = random.nextInt(4);
    final inset = 1 + random.nextInt(4).toDouble();
    final cross = main_top + 1 + random.nextInt(3).toDouble();
    final notch = switch (side) {
      0 => Rectangle<double>(inset, main_top, 1, 2),
      1 => Rectangle<double>(inset, main_top + main_rows - 2, 1, 2),
      2 => Rectangle<double>(0, cross, 2, 1),
      _ => Rectangle<double>(main_columns - 2, cross, 2, 1),
    };
    return [
      notch,
      if (random.nextBool())
        Rectangle<double>(2 + random.nextInt(2).toDouble(), main_top + 2, 1, 1),
    ];
  }

  static bool _outside_channels(
    Point<double> point,
    List<Rectangle<double>> channels,
  ) => !channels.any(
    (cut) =>
        point.x < cut.right &&
        point.x + 1 > cut.left &&
        point.y < cut.bottom &&
        point.y + 1 > cut.top,
  );

  static List<Point<double>> _peaks(
    Random random,
    List<Rectangle<double>> channels,
  ) {
    final candidates = <Point<double>>[
      for (var row = 0; row < main_rows; row++)
        for (var column = 0; column < main_columns; column++)
          if (_outside_channels(
            Point(column.toDouble(), main_top + row),
            channels,
          ))
            Point(column + .5, main_top + row + .5),
    ]..shuffle(random);
    final peaks = <Point<double>>[candidates.removeLast()];
    while (peaks.length < 3) {
      final separated = candidates
          .where(
            (point) => peaks.every(
              (peak) =>
                  (point.x - peak.x) * (point.x - peak.x) +
                      (point.y - peak.y) * (point.y - peak.y) >=
                  4,
            ),
          )
          .toList();
      final pool = separated.isEmpty ? candidates : separated;
      final chosen = pool[random.nextInt(pool.length)];
      peaks.add(chosen);
      candidates.remove(chosen);
    }
    return peaks;
  }

  /// Whole/half phases use a stable spatial ranking around the seeded basins.
  /// The low-amplitude motif changes which shoulders and notches survive while
  /// keeping the deep basins connected through every adjacent logical layer.
  static List<Point<double>> _ordered_cells(
    int layer,
    int template,
    List<Point<double>> peaks,
    List<Rectangle<double>> channels,
  ) {
    final phase = (layer + template) % 4;
    final half_x = phase == 1 || phase == 2 ? .5 : 0.0;
    final half_y = phase == 2 || phase == 3 ? .5 : 0.0;
    final cells = <Point<double>>[
      for (var row = 0; row < main_rows - (half_y > 0 ? 1 : 0); row++)
        for (
          var column = 0;
          column < main_columns - (half_x > 0 ? 1 : 0);
          column++
        )
          if (_outside_channels(
            Point(column + half_x, main_top + row + half_y),
            channels,
          ))
            Point(column + half_x, main_top + row + half_y),
    ];
    double score(Point<double> point) {
      var nearest = double.infinity;
      for (var index = 0; index < peaks.length; index++) {
        final peak = peaks[index];
        final dx = (point.x + .5 - peak.x).abs();
        final dy = (point.y + .5 - peak.y).abs();
        final distance = dx * dx + dy * dy * (template.isEven ? 1.1 : .9);
        nearest = min(nearest, distance + ((index + layer ~/ 3) % 3) * .19);
      }
      final row = (point.y - main_top).floor();
      final column = point.x.floor();
      final motif = ((column * 3 + row * 5 + template) % 7) * .017;
      return nearest + motif;
    }

    cells.sort((left, right) {
      final difference = score(left).compareTo(score(right));
      if (difference != 0) return difference;
      final row = left.y.compareTo(right.y);
      return row == 0 ? left.x.compareTo(right.x) : row;
    });
    return cells.take(base_capacity).toList();
  }

  /// Seed each independent helper island once. Anchors live on a half-grid;
  /// no individual tile receives a random position or independent z value.
  static ({bool top_longer, int top_anchor, int bottom_anchor})
  _auxiliary_layout(Random random) => (
    top_longer: random.nextBool(),
    top_anchor: random.nextInt(main_columns * 2),
    bottom_anchor: random.nextInt(main_columns * 2),
  );

  /// Lay actual brick bonds: an n-tile whole row alternates with an n−1-tile
  /// half-shifted row. Each narrow-row tile therefore covers two real lower
  /// tiles, and each internal wide-row tile covers two narrow-row tiles. The
  /// unavoidable outer shoulders have one support only on every other layer;
  /// they never form the old isolated vertical columns. All stock is measured
  /// from these rows before the main contour receives the remaining tiles.
  static List<List<Point<double>>> _auxiliary_layers(
    ({bool top_longer, int top_anchor, int bottom_anchor}) layout,
    int count,
    int depth,
  ) {
    final longer = (count + 1) ~/ 2;
    final shorter = count ~/ 2;
    final top_width = layout.top_longer ? longer : shorter;
    final bottom_width = layout.top_longer ? shorter : longer;
    List<Point<double>> row(int width, int anchor, double y, int layer) {
      final half_phase = layer.isOdd;
      final start = (anchor % ((main_columns - width) * 2 + 1)) / 2;
      return [
        for (var column = 0; column < width - (half_phase ? 1 : 0); column++)
          Point(start + column + (half_phase ? .5 : 0), y),
      ];
    }

    return [
      for (var layer = 0; layer < depth; layer++)
        [
          ...row(top_width, layout.top_anchor, 0, layer),
          ...row(bottom_width, layout.bottom_anchor, 8, layer),
        ],
    ];
  }

  /// Fit exact inventory to the basin footprints. A shared contour curve keeps
  /// lower stock broad, while the seed controls which several peaks persist.
  static List<int>? _layer_counts(
    int total,
    List<List<Point<double>>> footprints, {
    required int cap_count,
  }) {
    final layers = footprints.length;
    List<int> curve(double power) {
      final result = <int>[];
      for (var layer = 0; layer < layers; layer++) {
        final progress = 1 - layer / max(1, layers - 1);
        final desired =
            cap_count +
            ((base_capacity - cap_count) * pow(progress, power)).floor();
        final capacity = min(footprints[layer].length, desired);
        result.add(capacity);
      }
      return result;
    }

    int inventory(List<int> counts) =>
        counts.fold<int>(0, (sum, count) => sum + count);
    if (total < inventory(curve(contour_max_power)) ||
        total > inventory(curve(contour_min_power))) {
      return null;
    }
    var low = contour_min_power;
    var high = contour_max_power;
    for (var step = 0; step < contour_search_steps; step++) {
      final middle = (low + high) / 2;
      if (inventory(curve(middle)) > total) {
        low = middle;
      } else {
        high = middle;
      }
    }
    final counts = curve(high);
    for (var extra = total - inventory(counts); extra > 0; extra--) {
      var chosen = -1;
      var highest_score = double.negativeInfinity;
      for (var layer = 0; layer < layers; layer++) {
        if (counts[layer] >= footprints[layer].length ||
            (layer == layers - 1 && counts[layer] >= cap_count)) {
          continue;
        }
        final score =
            (footprints[layer].length - counts[layer]) / pow(layer + 1, .1);
        if (score > highest_score) {
          chosen = layer;
          highest_score = score;
        }
      }
      if (chosen < 0) return null;
      counts[chosen]++;
    }
    return counts;
  }
}
