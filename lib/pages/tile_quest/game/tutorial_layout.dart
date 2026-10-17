// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:math';
import 'geometry.dart';
import 'models.dart';
import 'validator.dart';

/// 教学关固定为两层 3×3。只随机图案与身份，不改变教学用的空间关系。
class TileQuestTutorial {
  const TileQuestTutorial._();
  static const int columns = 3;
  static const int rows = 3;
  static const double grid_pitch = 2;
  static const double upper_offset_y = .5;

  /// 图案索引沿用 QuestTileCard 的现有素材表，无需增加素材或 UI 依赖。
  /// 每局从红、蓝、绿三组各取一种，避免教学牌只凭相近暖色区分。
  /// 草莓和蓝宝石重复入池，优先使用最容易辨认的红色水果与蓝色切面。
  static const List<int> _red_types = <int>[
    4, 4, 4, // strawberry：红草莓。
    3, // apple：红苹果。
    6, // heart：粉红爱心。
    21, // rose：红玫瑰。
  ];
  static const List<int> _blue_types = <int>[
    9, 9, 9, // blue_gem：蓝宝石。
    19, // snowflake：浅蓝雪花。
  ];
  static const List<int> _green_types = <int>[
    7, // leaf：绿叶。
    10, // clover：绿色四叶草。
    18, // cactus：绿色仙人掌。
    27, // pine_tree：绿色松树。
  ];

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
