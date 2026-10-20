// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'package:flutter/painting.dart';
import '../game/models.dart';
import '../style.dart';

/// 页面、按钮与性能入口共用同一缓存键，旋转屏幕后不重复解码背景。
class QuestSceneAssets {
  const QuestSceneAssets._();

  static const background = AssetImage('assets/img/tile_quest/background.png');

  /// 顶栏图标：返回、声音、静音。原图自带高光，按显示尺寸解码。
  static const step_back = AssetImage('assets/img/tile_quest/step_back.png');
  static const sound = AssetImage('assets/img/tile_quest/sound.png');
  static const mute = AssetImage('assets/img/tile_quest/mute.png');
  static const reset = AssetImage('assets/img/tile_quest/reset.png');
  static const logo = AssetImage('assets/img/tile_quest/logo.png');

  /// 顶栏右侧：分享、设置、收起。
  static const share = AssetImage('assets/img/tile_quest/share.png');
  static const set_up = AssetImage('assets/img/tile_quest/set_up.png');
  static const closure = AssetImage('assets/img/tile_quest/closure.png');

  /// 道具用尽后右上角的补充入口图标，按道具区分。
  static final Map<TileQuestTool, ImageProvider> tool_add_icons = {
    TileQuestTool.undo: const AssetImage(
      'assets/img/tile_quest/powerups/withdraw_add.png',
    ),
    TileQuestTool.shuffle: const AssetImage(
      'assets/img/tile_quest/powerups/shuffle_add.png',
    ),
    TileQuestTool.remove: const AssetImage(
      'assets/img/tile_quest/powerups/remove_add.png',
    ),
  };

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
