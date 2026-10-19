// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';
import 'tile_quest_tile_painter.dart';
import 'tile_quest_tile_style.dart';

/// 可复用的 2.5D 卡通方块底板组件。
///
/// 只负责绘制方块底板（投影 / 厚度 / 倒角 / 高光），不绘制任何图标；
/// 图标通过 [child] 叠加在正面中心，占正面宽度约 62.5%。
/// 组件整体尺寸为 [size] × [size]，内部为底部厚度与落影预留了空间，
/// 投影不会被裁切。支持普通、遮挡、选中、按压四种状态。
class TileQuestTile extends StatefulWidget {
  const TileQuestTile({
    super.key,
    this.size = 64,
    this.is_selected = false,
    this.is_blocked = false,
    this.elevation = 1,
    this.child,
    this.on_tap,
  });

  /// 方块尺寸（逻辑像素），推荐 40～120 之间；绘制严格等比缩放。
  final double size;

  /// 是否选中：略微上抬，阴影稍增强。
  final bool is_selected;

  /// 是否被其他方块遮挡：亮度降低、加暖灰，但保留立体结构。
  final bool is_blocked;

  /// 阴影强度，1 为标准；越大落影越重。
  final double elevation;

  /// 叠加在正面中心的图标组件，占正面宽度 [TileQuestTileStyle.icon_scale]。
  final Widget? child;

  /// 点击回调；触发时播放轻微下压缩放动画。
  final VoidCallback? on_tap;

  @override
  State<TileQuestTile> createState() => _TileQuestTileState();
}

class _TileQuestTileState extends State<TileQuestTile> {
  /// 是否处于按压下压态。
  bool _pressed = false;

  /// 按压态缩放系数；未按压时为 1。
  double get _scale => _pressed
      ? TileQuestTileStyle.pressed_scale
      : 1.0;

  @override
  Widget build(BuildContext context) {
    final icon_rect = TileQuestTileStyle.icon_rect(Size.square(widget.size));
    // 选中态牌体上抬时图标跟随，与 Painter 内的 lift 保持一致。
    final lift = widget.is_selected
        ? widget.size * TileQuestTileStyle.selected_lift
        : 0.0;

    return Semantics(
      button: widget.on_tap != null,
      enabled: !widget.is_blocked && widget.on_tap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // 被遮挡的牌不可点击。
        onTap: widget.is_blocked ? null : widget.on_tap,
        onTapDown: widget.is_blocked || widget.on_tap == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapCancel: widget.is_blocked || widget.on_tap == null
            ? null
            : () => setState(() => _pressed = false),
        onTapUp: widget.is_blocked || widget.on_tap == null
            ? null
            : (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _scale,
          duration: TileQuestTileStyle.motion_duration,
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              children: [
                // 底板：五层矢量材质一体绘制。
                Positioned.fill(
                  child: CustomPaint(
                    painter: TileQuestTilePainter(
                      is_blocked: widget.is_blocked,
                      is_selected: widget.is_selected,
                      elevation: widget.elevation,
                    ),
                  ),
                ),
                // 图标：放在正面中心，尺寸固定比例，不画进底板；
                // 选中上浮时跟随牌体，保持图案始终贴在瓷面上。
                if (widget.child != null)
                  Positioned.fromRect(
                    rect: icon_rect.shift(Offset(0, -lift)),
                    child: widget.child!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
