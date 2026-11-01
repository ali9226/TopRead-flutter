// ignore_for_file: avoid_print, dangling_library_doc_comments, non_constant_identifier_names
/// 辅助牌岛结构体检：同位叠柱、并排遮挡张数、开局数。
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/geometry.dart';
import 'package:app/pages/tile_quest/game/models.dart';

void main(List<String> args) {
  final difficulty = args.isNotEmpty ? double.parse(args[0]) : 9.5;
  final seeds = args.length > 1 ? int.parse(args[1]) : 3;
  for (var seed = 1; seed <= seeds; seed++) {
    final state = TileQuestGenerator.generate(
      level: 2,
      seed: seed * 7919 + 13,
      difficulty: difficulty,
    );
    print('=== seed=$seed ===');
    for (final region in ['side_top', 'side_bottom']) {
      final cells = <String, List<TileQuestTile>>{};
      for (final t in state.tiles.where((t) => t.region_id == region)) {
        cells.putIfAbsent('${t.x}:${t.y}', () => []).add(t);
      }
      final sorted = cells.entries.toList()
        ..sort((a, b) {
          final ta = a.value.first;
          final tb = b.value.first;
          return ta.x != tb.x ? ta.x.compareTo(tb.x) : ta.y.compareTo(tb.y);
        });
      print(' $region: ${cells.length} 格');
      for (final e in sorted) {
        final cell = e.value.first;
        final cover = <String>{};
        for (final other in state.tiles) {
          if (other.id == cell.id) continue;
          if ((other.y - cell.y).abs() > 1.2) continue;
          final dx = (other.x - cell.x).abs();
          if (dx < .2 || dx > .9) continue;
          if (!TileQuestGeometry.overlaps(cell, other) &&
              !TileQuestGeometry.overlaps(other, cell)) continue;
          cover.add('${other.x}:${other.y}');
        }
        print('   x=${cell.x.toStringAsFixed(2)} n=${e.value.length} '
            'cover=${cover.length} layers=${e.value.map((t) => t.layer).toList()}');
      }
    }
    final opening = TileQuestGeometry(state.tiles)
        .refresh(state.tiles)
        .where((t) => !t.is_blocked)
        .length;
    print(' opening=$opening');
  }
}
