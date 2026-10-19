// ignore_for_file: non_constant_identifier_names
import 'package:flutter/painting.dart';
import '../game/models.dart';
import '../style.dart';

/// 页面、按钮与性能入口共用同一缓存键，旋转屏幕后不重复解码背景。
class QuestSceneAssets {
  const QuestSceneAssets._();

  static const background = AssetImage('assets/img/tile_quest/background.png');

  /// 原图已裁出透明边缘和内部镂空；按显示所需分辨率解码，避免按钮
  /// 动画期间处理整张素材表，也不额外添加实时模糊或颜色过滤。
  static final Map<TileQuestTool, ImageProvider> powerups = {
    for (final tool in TileQuestTool.values)
      tool: ResizeImage(
        AssetImage('assets/img/tile_quest/powerups/${tool.name}.png'),
        width: TileQuestStyle.tool_icon_cache_width,
      ),
  };
}
