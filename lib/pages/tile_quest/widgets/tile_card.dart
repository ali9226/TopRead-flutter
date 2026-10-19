// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'package:flutter/material.dart';
import '../style.dart';
import 'shuffle_textures.dart';
import 'tile_assets.dart';
import 'tile_surface_style.dart';

export 'tile_assets.dart' show quest_tile_assets, quest_tile_asset_path;

/// 独立使用的立体牌组件；游戏主场景直接复用相同图集进行批量绘制。
class QuestTileCard extends StatefulWidget {
  const QuestTileCard({
    super.key,
    required this.type,
    this.blocked = false,
    this.on_tap,
    this.label,
    this.textures,
  });
  final int type;
  final bool blocked;
  final VoidCallback? on_tap;
  final String? label;

  /// 场景预载的完整牌图集；传入后静态卡不再单独持有图标监听。
  final QuestShuffleTextures? textures;

  @override
  State<QuestTileCard> createState() => _QuestTileCardState();
}

class _QuestTileCardState extends State<QuestTileCard> {
  bool _pressed = false;
  QuestShuffleTextures? _local_textures;

  /// 独立牌拥有自己的图集引用，场景牌只借用场景的统一预载图集。
  QuestShuffleTextures get _textures => widget.textures ?? _local_textures!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve_textures();
  }

  @override
  void didUpdateWidget(covariant QuestTileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type ||
        oldWidget.textures != widget.textures) {
      _resolve_textures();
    }
  }

  /// 共用场景加载、迟到结果解绑、失败回退和图集绘制，避免独立牌产生另一种材质。
  void _resolve_textures() {
    if (widget.textures != null) {
      _local_textures?.dispose();
      _local_textures = null;
      return;
    }
    final textures = _local_textures ??= QuestShuffleTextures();
    textures.resolve(context, [widget.type]);
  }

  @override
  void dispose() {
    _local_textures?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label ?? quest_tile_assets[widget.type],
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
        scale: _pressed ? QuestTileSurfaceStyle.pressed_scale : 1,
        duration: TileQuestStyle.quick_duration,
        curve: Curves.easeOutCubic,
        child: CustomPaint(
          painter: _QuestTileCardPainter(
            type: widget.type,
            blocked: widget.blocked,
            textures: _textures,
          ),
          size: Size.infinite,
        ),
      ),
    ),
  );
}

/// 牌在未烘焙前后使用同一皮肤，图集到达只触发重绘而非重新布局。
class _QuestTileCardPainter extends CustomPainter {
  _QuestTileCardPainter({
    required this.type,
    required this.blocked,
    required this.textures,
  }) : super(repaint: textures);

  final int type;
  final bool blocked;
  final QuestShuffleTextures textures;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    textures.paint_tile(canvas, bounds, type, blocked: blocked);
  }

  @override
  bool shouldRepaint(covariant _QuestTileCardPainter oldDelegate) =>
      type != oldDelegate.type ||
      blocked != oldDelegate.blocked ||
      textures != oldDelegate.textures;
}
