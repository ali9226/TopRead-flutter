// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'package:flutter/painting.dart';
import '../style.dart';

/// 立体底板与图标共用 Flutter ImageCache；每个场景仅持有独立的解码引用。
class QuestTileSkin {
  const QuestTileSkin._();

  static const asset = 'assets/img/game/quest_tile_body_v4.png';

  /// 皮肤和图集像素一一对应，避免将原始高分辨率素材上传到每个场景。
  static ImageProvider<Object> get provider => ResizeImage.resizeIfNeeded(
    TileQuestStyle.tile_cache_width,
    null,
    const AssetImage(asset),
  );
}
