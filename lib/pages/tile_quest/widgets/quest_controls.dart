// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';
import '../game/models.dart';
import '../style.dart';
import 'package:app/config/font_config.dart';
import 'quest_text.dart';
import 'powerup_icon.dart';
import 'scene_assets.dart';

/// 顶栏按钮保留至少 44px 点击区域，文字由 tooltip 和语义朗读共同提供。
/// 按下即缩小，松开弹性回弹，给出按压反馈。
class QuestIconButton extends StatefulWidget {
  const QuestIconButton({
    super.key,
    required this.label,
    required this.on_tap,
    this.icon,
    this.asset,
    this.icon_size = TileQuestStyle.header_icon_size,
  }) : assert(
         icon != null || asset != null,
         'icon 或 asset 必须提供一个',
       );

  /// Material 图标兜底或非图片按钮。
  final IconData? icon;

  /// 图片图标（返回/声音/静音）。优先于 [icon]。
  final ImageProvider? asset;
  final String label;
  final VoidCallback? on_tap;
  final double icon_size;

  @override
  State<QuestIconButton> createState() => _QuestIconButtonState();
}

class _QuestIconButtonState extends State<QuestIconButton> {
  bool _pressed = false;

  // Listener 立刻收到按下事件，不等手势竞技场判定，按下就有缩小反馈。
  void _handle_down(PointerDownEvent _) {
    if (_pressed) return;
    setState(() => _pressed = true);
  }

  void _handle_up(PointerUpEvent _) {
    final was = _pressed;
    if (was) setState(() => _pressed = false);
    if (was && widget.on_tap != null) widget.on_tap!();
  }

  void _handle_cancel(PointerCancelEvent _) {
    if (_pressed) setState(() => _pressed = false);
  }

  Widget _icon() {
    final asset = widget.asset;
    if (asset != null) {
      return Image(
        image: asset,
        width: widget.icon_size,
        height: widget.icon_size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        errorBuilder: (context, error, stack_trace) => Icon(
          widget.icon ?? Icons.circle_outlined,
          color: TileQuestStyle.cream,
          size: widget.icon_size,
        ),
      );
    }
    return Icon(
      widget.icon,
      color: TileQuestStyle.cream,
      size: widget.icon_size,
    );
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label,
    button: true,
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handle_down,
      onPointerUp: _handle_up,
      onPointerCancel: _handle_cancel,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: AnimatedScale(
            scale: _pressed ? TileQuestStyle.press_scale : 1,
            duration: Duration(
              milliseconds: _pressed
                  ? TileQuestStyle.press_down_ms
                  : TileQuestStyle.press_up_ms,
            ),
            curve: _pressed ? Curves.easeOut : Curves.elasticOut,
            child: _icon(),
          ),
        ),
      ),
    ),
  );
}

/// 顶栏：返回 + logo + 右侧动作区。
/// 默认只显示分享与设置；点设置展开声音/重置并换成收起图标，再点收回。
class QuestHeader extends StatefulWidget {
  const QuestHeader({
    super.key,
    required this.state,
    required this.sound_enabled,
    required this.on_back,
    required this.on_restart,
    required this.on_sound,
    this.compact = false,
  });
  final TileQuestState state;
  final bool sound_enabled;
  final bool compact;
  final VoidCallback on_back, on_restart, on_sound;

  @override
  State<QuestHeader> createState() => _QuestHeaderState();
}

class _QuestHeaderState extends State<QuestHeader> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cjk = quest_is_cjk(context);
    const gap = SizedBox(width: TileQuestStyle.header_action_gap);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: TileQuestStyle.toolbar_height,
          child: Row(
            children: [
              QuestIconButton(
                key: const ValueKey('tile_quest_back'),
                asset: QuestSceneAssets.step_back,
                icon: Icons.arrow_back_rounded,
                label: quest_text(context, 'back', 'Back'),
                on_tap: widget.on_back,
              ),
              const SizedBox(width: 10),
              // logo 始终靠左；展开设置时缩放淡出，收起再淡回。
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedSwitcher(
                    duration: const Duration(
                      milliseconds: TileQuestStyle.header_expand_ms,
                    ),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: animation,
                        alignment: Alignment.centerLeft,
                        child: child,
                      ),
                    ),
                    child: _expanded
                        ? const SizedBox.shrink(
                            key: ValueKey('tile_quest_logo_hidden'),
                          )
                        : Image(
                            key: const ValueKey('tile_quest_logo'),
                            image: QuestSceneAssets.logo,
                            height: widget.compact ? 32 : 40,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                            gaplessPlayback: true,
                            excludeFromSemantics: true,
                            errorBuilder: (context, error, stack_trace) =>
                                Text(
                                  quest_text(context, 'title', 'Tile Quest'),
                                  style: TileQuestStyle.title(cjk),
                                ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              QuestIconButton(
                key: const ValueKey('tile_quest_share'),
                asset: QuestSceneAssets.share,
                icon: Icons.share_rounded,
                label: 'Share',
                on_tap: () {
                  // 分享点击暂不处理。
                },
              ),
              // 声音/重置宽度动画与分享位移同帧进行，收起时不排队等待。
              ClipRect(
                child: AnimatedAlign(
                  duration: const Duration(
                    milliseconds: TileQuestStyle.header_expand_ms,
                  ),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerRight,
                  widthFactor: _expanded ? 1 : 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: TileQuestStyle.header_share_gap),
                      QuestIconButton(
                        key: const ValueKey('tile_quest_sound'),
                        asset: widget.sound_enabled
                            ? QuestSceneAssets.sound
                            : QuestSceneAssets.mute,
                        icon: widget.sound_enabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        label: quest_text(
                          context,
                          widget.sound_enabled ? 'sound_on' : 'sound_off',
                          widget.sound_enabled ? 'Sound on' : 'Sound off',
                        ),
                        on_tap: widget.on_sound,
                      ),
                      gap,
                      QuestIconButton(
                        key: const ValueKey('tile_quest_restart'),
                        asset: QuestSceneAssets.reset,
                        icon: Icons.refresh_rounded,
                        label: quest_text(context, 'restart', 'Restart'),
                        on_tap: widget.on_restart,
                      ),
                    ],
                  ),
                ),
              ),
              gap,
              QuestIconButton(
                key: const ValueKey('tile_quest_settings'),
                asset: _expanded
                    ? QuestSceneAssets.closure
                    : QuestSceneAssets.set_up,
                icon: _expanded
                    ? Icons.close_rounded
                    : Icons.settings_rounded,
                label: _expanded ? 'Close' : 'Settings',
                on_tap: () => setState(() => _expanded = !_expanded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class QuestToolButton extends StatefulWidget {
  const QuestToolButton({
    super.key,
    required this.tool,
    required this.remaining,
    required this.enabled,
    required this.on_tap,
  });
  final TileQuestTool tool;
  final int remaining;
  final bool enabled;
  final VoidCallback on_tap;

  @override
  State<QuestToolButton> createState() => _QuestToolButtonState();
}

class _QuestToolButtonState extends State<QuestToolButton> {
  bool _pressed = false;

  // 禁用也给按压回弹，只是不触发道具动作。
  void _handle_down(PointerDownEvent _) {
    if (_pressed) return;
    setState(() => _pressed = true);
  }

  void _handle_up(PointerUpEvent _) {
    final was = _pressed;
    if (was) setState(() => _pressed = false);
    if (was && widget.enabled) widget.on_tap();
  }

  void _handle_cancel(PointerCancelEvent _) {
    if (_pressed) setState(() => _pressed = false);
  }

  /// 右上角剩余次数角标：主题色圆形 + 外发光 + 白字，无描边。
  Widget _badge(List<Color> colors) {
    final text_scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.25);
    final size = TileQuestStyle.tool_badge_min_size * text_scale;
    final glow = colors.last;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-.35, -.45),
          radius: 1.1,
          colors: [colors.first, colors.last],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: .88),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: glow.withValues(alpha: .55),
            blurRadius: 16,
            spreadRadius: .5,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        widget.remaining > 0 ? '${widget.remaining}' : '',
        style: TextStyle(
          color: Colors.white,
          fontSize: TileQuestStyle.tool_badge_font * text_scale,
          height: .95,
          letterSpacing: -.4,
          fontWeight: FontConfig.adjustedWeight(FontWeight.w900),
          shadows: [
            Shadow(
              color: glow.withValues(alpha: .9),
              blurRadius: 2,
              offset: const Offset(0, 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _add_icon() {
    final size = TileQuestStyle.tool_badge_add_size;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .22),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: .18),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Image(
        image: QuestSceneAssets.tool_add_icons[widget.tool]!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        errorBuilder: (context, error, stack_trace) => Icon(
          Icons.add_circle_rounded,
          size: size,
          color: TileQuestStyle.mint,
        ),
      ),
    );
  }

  /// 角标槽位：常驻子树，靠缩放+透明度做 1↔0 切换动画。
  Widget _badge_slot({required bool visible, required Widget child}) {
    return AnimatedScale(
      scale: visible ? 1 : 0,
      duration: const Duration(
        milliseconds: TileQuestStyle.tool_badge_switch_ms,
      ),
      curve: visible ? Curves.easeOutBack : Curves.easeIn,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(
          milliseconds: TileQuestStyle.tool_badge_switch_ms,
        ),
        curve: visible ? Curves.easeOut : Curves.easeIn,
        child: child,
      ),
    );
  }

  /// 按钮主体：主题渐变 + 顶部果冻高光 + 同色外投影。
  Widget _face(List<Color> colors, Widget content) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.first, colors.last],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .42), width: 1.2),
        // 收紧投影，避免三个按钮的光晕连成整条光带。
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: .38),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: colors.first.withValues(alpha: .18),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: .34),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            content,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cjk = quest_is_cjk(context);
    final colors = switch (widget.tool) {
      TileQuestTool.undo => TileQuestStyle.undo_colors,
      TileQuestTool.shuffle => TileQuestStyle.shuffle_colors,
      TileQuestTool.remove => TileQuestStyle.remove_colors,
    };
    final name = quest_text(context, widget.tool.name, switch (widget.tool) {
      TileQuestTool.undo => 'Undo',
      TileQuestTool.shuffle => 'Shuffle',
      TileQuestTool.remove => 'Remove',
    });
    Widget labels() => Text(
      name,
      maxLines: 1,
      softWrap: false,
      style: TileQuestStyle.body(cjk, color: Colors.white, emphasis: true),
    );
    Widget body() => LayoutBuilder(
      builder: (context, constraints) {
        final narrow =
            constraints.maxWidth < TileQuestStyle.narrow_tool_width;
        final compact =
            constraints.maxHeight < TileQuestStyle.tool_tall_threshold;
        return Padding(
          padding: EdgeInsets.all(
            narrow
                ? TileQuestStyle.narrow_tool_content_inset
                : TileQuestStyle.tool_content_inset,
          ),
          child: narrow
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    QuestPowerupIcon(
                      tool: widget.tool,
                      size: TileQuestStyle.narrow_tool_icon_size,
                    ),
                    Flexible(
                      child: FittedBox(fit: BoxFit.scaleDown, child: labels()),
                    ),
                  ],
                )
              : compact
              ? Row(
                  children: [
                    QuestPowerupIcon(
                      tool: widget.tool,
                      size: TileQuestStyle.tool_icon_compact_size,
                    ),
                    const SizedBox(width: TileQuestStyle.tool_content_gap),
                    Expanded(
                      child: FittedBox(fit: BoxFit.scaleDown, child: labels()),
                    ),
                  ],
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width:
                        constraints.maxWidth -
                        TileQuestStyle.tool_content_inset * 2,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        QuestPowerupIcon(
                          tool: widget.tool,
                          size: TileQuestStyle.tool_icon_size,
                        ),
                        const SizedBox(height: TileQuestStyle.tool_content_gap),
                        FittedBox(fit: BoxFit.scaleDown, child: labels()),
                      ],
                    ),
                  ),
                ),
        );
      },
    );

    return Semantics(
      label: '$name ${widget.remaining}',
      button: true,
      enabled: widget.enabled,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _handle_down,
        onPointerUp: _handle_up,
        onPointerCancel: _handle_cancel,
        child: AnimatedScale(
          scale: _pressed ? TileQuestStyle.press_scale : 1,
          duration: Duration(
            milliseconds: _pressed
                ? TileQuestStyle.press_down_ms
                : TileQuestStyle.press_up_ms,
          ),
          curve: _pressed ? Curves.easeOut : Curves.elasticOut,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _face(colors, body()),
              // 双层常驻 + 交叉缩放淡入，元素树数量稳定，1↔0 切换有过渡。
              Positioned(
                top: TileQuestStyle.tool_badge_top,
                right: TileQuestStyle.tool_badge_right,
                child: IgnorePointer(
                  child: _badge_slot(
                    visible: widget.remaining > 0,
                    child: _badge(colors),
                  ),
                ),
              ),
              Positioned(
                top: TileQuestStyle.tool_badge_top,
                right: TileQuestStyle.tool_badge_add_right,
                child: IgnorePointer(
                  child: _badge_slot(
                    visible: widget.remaining <= 0,
                    child: _add_icon(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuestPrimaryButton extends StatelessWidget {
  const QuestPrimaryButton({
    super.key,
    required this.label,
    required this.on_tap,
    this.primary = true,
    this.icon,
  });
  final String label;
  final VoidCallback? on_tap;
  final bool primary;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: on_tap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: primary
                ? [const Color(0xFFFFE6A0), const Color(0xFFF4BC54)]
                : [const Color(0xFF344F78), const Color(0xFF263E64)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: .25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 19,
                color: primary ? TileQuestStyle.ink : TileQuestStyle.cream,
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TileQuestStyle.body(
                    quest_is_cjk(context),
                    color: primary ? TileQuestStyle.ink : TileQuestStyle.cream,
                    emphasis: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
