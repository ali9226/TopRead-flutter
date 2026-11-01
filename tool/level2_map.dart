// ignore_for_file: non_constant_identifier_names, constant_identifier_names
/// 打印第二关牌阵 ASCII 图（每格显示顶层图案字母）。
/// 用法: fvm dart run tool/level2_map.dart [difficulty] [seed]
import 'dart:io';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/models.dart';

void main(List<String> args) {
  final difficulty = args.isNotEmpty ? double.parse(args[0]) : 9.5;
  final seed = args.length > 1 ? int.parse(args[1]) : 17;
  final state = TileQuestGenerator.generate(
    level: 2,
    seed: seed,
    difficulty: difficulty,
  );
  const letters = 'abcdefghijklmnopqrstuvwxyz';
  final types = <int>{for (final t in state.tiles) t.type}.toList()..sort();
  final letter_of = {
    for (var i = 0; i < types.length; i++) types[i]: letters[i],
  };
  stdout.writeln('tiles=${state.tiles.length} types=${types.length} seed=$seed diff=$difficulty');
  final layers = <int>{for (final t in state.tiles) t.layer}.toList()..sort();
  for (final layer in layers) {
    final row = state.tiles.where((t) => t.layer == layer).toList()
      ..sort((a, b) => a.y != b.y ? a.y.compareTo(b.y) : a.x.compareTo(b.x));
    if (row.isEmpty) continue;
    final buffer = StringBuffer('L$layer: ');
    TileQuestTile? prev;
    for (final t in row) {
      if (prev != null && (prev.y - t.y).abs() > .1) {
        buffer.write(' | ');
      } else if (prev != null) {
        buffer.write(' ');
      }
      buffer.write('${letter_of[t.type]}${t.region_id[0]}');
      prev = t;
    }
    stdout.writeln(buffer);
  }
  stdout.writeln('--- topmost tile per cell, y>=5 ---');
  final bottom = state.tiles.where((t) => t.y >= 5).toList();
  final by_cell = <String, TileQuestTile>{};
  for (final t in bottom) {
    final key = '${t.x.toStringAsFixed(1)},${t.y.toStringAsFixed(1)}';
    final old = by_cell[key];
    if (old == null || old.layer < t.layer) by_cell[key] = t;
  }
  final cells = by_cell.values.toList()
    ..sort((a, b) => a.y != b.y ? a.y.compareTo(b.y) : a.x.compareTo(b.x));
  TileQuestTile? p;
  final line = StringBuffer();
  for (final t in cells) {
    if (p != null && (p.y - t.y).abs() > .1) {
      stdout.writeln(line);
      line.clear();
    } else if (p != null) {
      line.write(' ');
    }
    line.write(letter_of[t.type]);
    p = t;
  }
  if (line.isNotEmpty) stdout.writeln(line);
}
