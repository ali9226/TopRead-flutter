// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:math';
import 'geometry.dart';
import 'models.dart';
import 'tile_palette.dart';
import 'validator.dart';

/// 教学关固定为两层 3×3。只随机图案与身份，不改变教学用的空间关系。
class TileQuestTutorial {
  const TileQuestTutorial._();
  static const int columns = 3;
  static const int rows = 3;
  static const double grid_pitch = 2;
  static const double upper_offset_y = .5;

  /// 从规则与绘图共用的图案表解析类型，素材重排不会改变颜色分组。
  /// 红、蓝、绿各取一种；草莓和蓝宝石加权以强化教学辨识度。
  static final List<int> _red_types = <String>[
    'strawberry',
    'strawberry',
    'strawberry',
    'apple',
    'watermelon',
  ].map(quest_tile_assets.indexOf).toList(growable: false);
  static final List<int> _blue_types = <String>[
    'blue_gem',
    'blue_gem',
    'blue_gem',
    'snowflake',
    'blueberries',
  ].map(quest_tile_assets.indexOf).toList(growable: false);
  static final List<int> _green_types = <String>[
    'leaf',
    'avocado',
  ].map(quest_tile_assets.indexOf).toList(growable: false);

  /// seed 决定三种图案及其顺序；两层共享这一组图案，库存仍各为六张。
  static List<int> _palette(Random random) => <int>[
    _red_types[random.nextInt(_red_types.length)],
    _blue_types[random.nextInt(_blue_types.length)],
    _green_types[random.nextInt(_green_types.length)],
  ]..shuffle(random);

  static TileQuestState generate_state({
    required int seed,
    String? challenge_id,
    int unlocked_level = 1,
  }) {
    final random = Random(seed);
    final palette = _palette(random);
    final identities = List<int>.generate(18, (index) => index)
      ..shuffle(random);
    final tiles = <TileQuestTile>[];
    for (var layer = 0; layer < 2; layer++) {
      final types = <int>[
        for (final type in palette) ...<int>[type, type, type],
      ]..shuffle(random);
      for (var cell = 0; cell < rows * columns; cell++) {
        tiles.add(
          TileQuestTile(
            id: identities[layer * rows * columns + cell],
            type: types[cell],
            layer: layer,
            x: (cell % columns) * grid_pitch,
            y:
                (cell ~/ columns) * grid_pitch +
                (layer == 1 ? upper_offset_y : 0),
          ),
        );
      }
    }
    final path = <int>[];
    for (final layer in [1, 0]) {
      final types = List<int>.from(palette)..shuffle(random);
      for (final type in types) {
        path.addAll(
          tiles
              .where((tile) => tile.layer == layer && tile.type == type)
              .map((tile) => tile.id),
        );
      }
    }
    final state = TileQuestState(
      tiles: TileQuestGeometry(tiles).refresh(tiles),
      level: 1,
      difficulty: 1,
      seed: seed,
      challenge_id: challenge_id ?? 'tile_quest_1_$seed',
      unlocked_level: unlocked_level.clamp(1, 2),
      certified_solution: path,
    );
    if (!TileQuestValidator.validate_solution(state).valid) {
      throw StateError('Tutorial layout failed its complete legal replay');
    }
    return state;
  }
}
