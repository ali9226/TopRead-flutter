// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'package:flutter/material.dart';
import '../style.dart';

/// 图案索引与引擎一一对应；只使用单个、带透明圆角的完整方块素材。
const quest_tile_assets = <String>[
  'star',
  'moon',
  'sun',
  'apple',
  'strawberry',
  'grapes',
  'heart',
  'leaf',
  'purple_gem',
  'blue_gem',
  'clover',
  'carrot',
  'avocado',
  'blueberries',
  'watermelon',
  'lemon',
  'peach',
  'mushroom',
  'cactus',
  'snowflake',
  'pink_flower',
  'rose',
  'flower',
  'butterfly',
  'rainbow',
  'shell',
  'crown',
  'pine_tree',
  'daisy',
  'lotus',
  'maple_leaf',
  'potion',
];

/// 点击缩放与解除遮挡动画局限于单张牌，避免每帧重建整个棋盘。
class QuestTileCard extends StatefulWidget {
  const QuestTileCard({
    super.key,
    required this.type,
    this.blocked = false,
    this.on_tap,
    this.label,
  });
  final int type;
  final bool blocked;
  final VoidCallback? on_tap;
  final String? label;

  @override
  State<QuestTileCard> createState() => _QuestTileCardState();
}

class _QuestTileCardState extends State<QuestTileCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        widget.label ??
        quest_tile_assets[widget.type % quest_tile_assets.length],
    button: widget.on_tap != null,
    enabled: !widget.blocked && widget.on_tap != null,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.blocked ? null : widget.on_tap,
      onTapDown: widget.blocked || widget.on_tap == null
          ? null
          : (_) => setState(() => _pressed = true),
      onTapCancel: widget.blocked || widget.on_tap == null
          ? null
          : () => setState(() => _pressed = false),
      onTapUp: widget.blocked || widget.on_tap == null
          ? null
          : (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? .88 : 1,
        duration: TileQuestStyle.quick_duration,
        curve: Curves.easeOutCubic,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/img/game/tile_${quest_tile_assets[widget.type % quest_tile_assets.length]}.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              cacheWidth: 192,
              excludeFromSemantics: true,
            ),
            AnimatedContainer(
              duration: TileQuestStyle.reveal_duration,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: widget.blocked ? .39 : 0),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
