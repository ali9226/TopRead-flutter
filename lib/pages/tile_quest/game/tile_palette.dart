// ignore_for_file: constant_identifier_names, non_constant_identifier_names

/// 规则类型与透明 PNG 一一对应；生成、教学、棋盘及动画共用此顺序。
/// 顺序对应用户提供的 3×5 图集，不能用取余将不同规则类型合并成同一图标。
const quest_tile_assets = <String>[
  'mushroom',
  'carrot',
  'watermelon',
  'lemon',
  'shovel',
  'glove',
  'leaf',
  'strawberry',
  'milk_bottle',
  'scissors',
  'hay',
  'yarn',
  'star',
  'grapes',
  'snowflake',
];

/// 返回规则类型对应的独立透明图标；所有预载、静态棋盘及动画共用此路径。
String quest_tile_asset_path(int type) =>
    'assets/img/tile_quest/icons/tile_${quest_tile_assets[type]}.png';
