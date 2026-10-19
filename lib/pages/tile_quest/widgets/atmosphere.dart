// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';
import '../style.dart';
import 'scene_assets.dart';

/// 使用用户提供的山谷原图；独立静态图层不随洗牌、飞牌或粒子重绘。
class QuestAtmosphere extends StatelessWidget {
  const QuestAtmosphere({super.key, required this.is_dark});
  final bool is_dark;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: TileQuestStyle.sky(is_dark),
            ),
          ),
        ),
        Image(
          image: QuestSceneAssets.background,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.low,
          gaplessPlayback: true,
          excludeFromSemantics: true,
          errorBuilder: (context, error, stack_trace) =>
              const SizedBox.expand(),
        ),
        // 仅用静态渐变保证明暗主题下顶栏及底部文字的可读性。
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: TileQuestStyle.background_scrim(is_dark),
            ),
          ),
        ),
      ],
    ),
  );
}
