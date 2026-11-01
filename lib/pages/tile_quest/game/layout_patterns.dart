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
  static const int cap_capacity = 6;
  static const int deep_core_min_layers = 40;
  static const int deep_core_cap_capacity = 8;

  /// TODO 同位叠柱上限：同一 (x,y) 最多 4 张。叠太深会让玩家在同一处反复点
  /// TODO 同一张牌，像被耍。4 是足迹 6×5、孔洞贯穿、主阵与牌堆间距≥1 这些
  /// TODO 约束下的几何下限（相位格被孔洞挖到 16 格时，16×4 才装得下该相位）。
  static const int max_exact_stack = 4;

  /// TODO 主阵细分相位：x 保持 0.5 半格（一张牌正好遮住并排两张各一半），
  /// TODO y 用 0.25 细分把同位叠柱摊薄。相位 8 个，40 层每个相位只摊 5 层。
  static const int phase_count = 8;

  /// TODO 羊了个羊式镜像卡扇：列间水平重叠只露细边，牌端逐列揭开。
  /// TODO 底部一排卡扇朝中央出牌。
  static const double fan_stride = .16;
  static const int fan_max_columns = 12;
  static const int fan_min_columns = 3;
  static const int fan_max_passes = 3;
  static const double fan_min_gap = .12;

  /// TODO 顶部牌岛：半格错位的砖砌牌列，不是孤立牌柱。相邻列错开半格，
  /// TODO 每张牌正好压住并排两张各一半；揭开后下一张被「一对」牌挡着，
  /// TODO 深度看不穿。孤立的单格叠柱会让人一直点同一处、像被耍。
  static const double top_row_stride = .5;
  static const int top_row_columns = 7;
  static const int top_row_layers = 4;
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
    final fan_layout = _fan_layout(random);
    // Search template stock, not random points. Every returned candidate has an
    // independently measured opening, exact inventory and long main corridors.
    final fan_options = <({int columns, int passes, int chains})>[];
    // TODO 先长卡扇（细边列多、最接近参考布局的镜像扇堆），再补叠深与条数。
    // TODO 宽度可行性必须用实际 stride 计算，保证扇体互不相交且不出足迹。
    final max_columns = min(fan_max_columns, profile.layers);
    // 参考布局是一对镜像扇堆：双扇方案全部先于三扇，三扇只作库存兜底。
    for (final chains in [2, 3]) {
      for (
        var candidate = max_columns;
        candidate >= fan_min_columns;
        candidate--
      ) {
        final width = (candidate - 1) * fan_layout.stride + tile_extent;
        final spread = _fan_spread(width, chains);
        if (spread == null) continue;
        for (final passes in [1, 2, fan_max_passes]) {
          if (candidate * passes > profile.layers) continue;
          fan_options.add((columns: candidate, passes: passes, chains: chains));
        }
      }
    }
    if (fan_options.isEmpty) {
      fan_options.add((columns: fan_min_columns, passes: 1, chains: 2));
    }

    List<TileQuestTile>? build(
      int main_count,
      int columns,
      int passes,
      int chains,
    ) {
      final auxiliary_layers = _fan_layers(
        fan_layout,
        columns,
        passes,
        chains,
        layer_count: profile.layers,
      );
      final counts = _layer_counts(
        main_count,
        footprints,
        cap_count: cap_count,
      );
      if (counts == null) return null;
      final tiles = <TileQuestTile>[];
      // TODO 同位叠柱上限：候选格按（已叠层数, 分数）摊派，叠满 max_exact_stack
      // TODO 的格位让给还没叠起来的格位。既保证同位不再无限叠，又让并排牌
      // TODO 一起遮住下方，深度看不穿。按层数优先摊派数学上保证放得下。
      final depth = <String, int>{};
      for (var layer = 0; layer < footprints.length; layer++) {
        final cells = footprints[layer];
        final order = [for (var index = 0; index < cells.length; index++) index]
          ..sort((left, right) {
            final compared = (depth['${cells[left].x}:${cells[left].y}'] ?? 0)
                .compareTo(depth['${cells[right].x}:${cells[right].y}'] ?? 0);
            return compared != 0 ? compared : left.compareTo(right);
          });
        var placed = 0;
        for (final index in order) {
          if (placed >= counts[layer]) break;
          final point = cells[index];
          final key = '${point.x}:${point.y}';
          if ((depth[key] ?? 0) >= max_exact_stack) continue;
          depth[key] = (depth[key] ?? 0) + 1;
          // Core is a logical depth basin, not necessarily the screen center.
          final core = peaks.any(
            (peak) =>
                (point.x + .5 - peak.x).abs() <= 1 &&
                (point.y + .5 - peak.y).abs() <= 1,
          );
          _add(tiles, point, layer, core ? 'core' : 'main');
          placed++;
        }
        if (placed < counts[layer]) return null;
      }
      for (var layer = 0; layer < auxiliary_layers.length; layer++) {
        for (final slot in auxiliary_layers[layer]) {
          _add(tiles, slot, layer, slot.y == 0 ? 'side_top' : 'side_bottom');
        }
      }
      return tiles;
    }

    bool acceptable(List<TileQuestTile> tiles) {
      final opening = TileQuestGeometry(
        tiles,
      ).refresh(tiles).where((tile) => !tile.is_blocked).length;
      return opening >= TileQuestConfig.minimum_opening_tiles &&
          opening <= TileQuestConfig.maximum_opening_tiles &&
          opening % 3 == 0;
    }

    int stock_of(int columns, int passes, int chains) => _fan_layers(
      fan_layout,
      columns,
      passes,
      chains,
      layer_count: profile.layers,
    ).fold<int>(0, (sum, layer) => sum + layer.length);

    for (final option in fan_options) {
      final main_count =
          profile.tile_count -
          stock_of(option.columns, option.passes, option.chains);
      final tiles = build(
        main_count,
        option.columns,
        option.passes,
        option.chains,
      );
      if (tiles != null && acceptable(tiles)) return tiles;
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
    // TODO 中央孔洞（回字心）贯穿全部普通层，与参考布局的镂空中区一致。
    final heart = Rectangle<double>(
      2 + random.nextInt(2).toDouble(),
      main_top + 1 + random.nextInt(2).toDouble(),
      1,
      1,
    );
    return [notch, heart];
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
    // TODO x 半格（0/.5）保证并排两牌各挡一半；y 四分格（0/.25/.5/.75）
    // TODO 把同位叠柱摊薄到上限内。同层仍取整格间距，不会互相重叠。
    final phase = (layer + template) % phase_count;
    final half_x = phase.isOdd ? .5 : 0.0;
    final half_y = (phase ~/ 2) * .25;
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

  /// TODO 卡扇列间距：整格（同层牌距合法）、不小于扇宽（扇体不相交），
  /// TODO 并尽量铺满足迹，使牌堆贴住底部两角（参考布局的镜像扇堆）。
  static double? _fan_spread(double width, int chains) {
    if (chains <= 1) return 0.0;
    final ideal = ((footprint_width - width) / (chains - 1)).floorToDouble();
    final spread = max(width.ceilToDouble(), ideal);
    return (chains - 1) * spread + width <= footprint_width + .000001
        ? spread
        : null;
  }

  /// TODO 羊了个羊式辅助牌岛锚点：底部一排镜像卡扇 + 顶部半格砖砌牌列。
  /// TODO 锚点取 0.5 整数倍，保证同层相邻牌正好差一格、浮点零重叠。
  static ({double top_anchor, double stride}) _fan_layout(Random random) => (
    top_anchor: .5 * (1 + random.nextInt(3)),
    stride: fan_stride + (random.nextInt(3) - 1) * .015,
  );

  /// TODO 每层返回该层牌位。卡扇列 c（0=细边端）占 layer = c*passes + p，
  /// TODO 同列 [passes] 副完全叠放；牌端朝棋盘中央，同层永不重叠。
  /// TODO 顶部是半格错位的砖砌牌列：列 i 落在 layer = i%2 + 2k，
  /// TODO 同层列距整格不重叠，跨层相邻列各挡一半——每张牌都被并排两张
  /// TODO 压住，下方深度看不穿。两端列只放一张（棋盘外没有牌可并排遮挡，
  /// TODO 端点不叠柱，避免「孤零零一直点」）。
  static List<List<Point<double>>> _fan_layers(
    ({double top_anchor, double stride}) layout,
    int columns,
    int passes,
    int chains, {
    required int layer_count,
  }) {
    final fan_span = columns * passes;
    final top_span = min(top_row_layers, layer_count);
    final span = max(fan_span, top_span);
    final width = (columns - 1) * layout.stride + tile_extent;
    final spread = chains <= 1 ? 0.0 : _fan_spread(width, chains)!;
    return [
      for (var layer = 0; layer < span; layer++)
        [
          if (layer < top_span)
            for (var column = 0; column < top_row_columns; column++)
              if (column.isOdd == layer.isOdd &&
                  (layer < 2 || (column > 0 && column < top_row_columns - 1)))
                Point(layout.top_anchor + column * top_row_stride, 0),
          for (var chain = 0; chain < chains; chain++)
            if (layer < fan_span)
              _fan_slot(layout, columns, passes, chain, spread, layer),
        ],
    ];
  }

  /// TODO 单条卡扇在 [layer] 的牌位。牌端朝中央：左半区列号向右递增出牌，
  /// TODO 右半区镜像，使左右两堆的牌端相对、细边朝外。
  static Point<double> _fan_slot(
    ({double top_anchor, double stride}) layout,
    int columns,
    int passes,
    int chain,
    double spread,
    int layer,
  ) {
    final column = layer ~/ passes;
    final start = chain * spread;
    final faces_right =
        start + ((columns - 1) * layout.stride + tile_extent) / 2 <
        footprint_width / 2;
    final x = faces_right
        ? start + column * layout.stride
        : start + (columns - 1 - column) * layout.stride;
    return Point(x, 8);
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
