// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';
import '../game/models.dart';
import 'scene_assets.dart';
import 'package:app/config/color_config.dart';

/// 精确裁切的原图自带高光与投影；运行时只缩放一次透明纹理。
class QuestPowerupIcon extends StatelessWidget {
  const QuestPowerupIcon({super.key, required this.tool, required this.size});
  final TileQuestTool tool;
  final double size;

  @override
  Widget build(BuildContext context) => Image(
    image: QuestSceneAssets.powerups[tool]!,
    width: size,
    height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.medium,
    gaplessPlayback: true,
    excludeFromSemantics: true,
    errorBuilder: (context, error, stack_trace) => Icon(
      switch (tool) {
        TileQuestTool.undo => Icons.undo_rounded,
        TileQuestTool.shuffle => Icons.shuffle_rounded,
        TileQuestTool.remove => Icons.outbox_rounded,
      },
      size: size,
      color: ColorConstants.whiteColor,
    ),
  );
}
