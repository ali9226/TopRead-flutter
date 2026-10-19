// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'package:flutter/painting.dart';
import 'tile_surface_style.dart';

/// 立体底板与图标共用 Flutter ImageCache；每个场景仅持有独立的解码引用。
class QuestTileSkin {
  const QuestTileSkin._();

  /// 用户提供的原始立体牌底，直接用于普通牌、飞牌和洗牌图集。
  static const asset = 'assets/img/tile_quest/lattice.png';

  /// 牌面和图集像素一一对应，原始大图仅解码到实际绘制尺寸。
  static ImageProvider<Object> get provider => ResizeImage.resizeIfNeeded(
    QuestTileSurfaceStyle.cell_edge,
    null,
    const AssetImage(asset),
  );
}
