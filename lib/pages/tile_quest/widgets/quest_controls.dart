// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';
import '../game/models.dart';
import '../game/config.dart';
import '../style.dart';
import 'quest_text.dart';
import 'powerup_icon.dart';

/// 顶栏按钮保留至少 44px 点击区域，文字由 tooltip 和语义朗读共同提供。
class QuestIconButton extends StatelessWidget {
  const QuestIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.on_tap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? on_tap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: on_tap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 44,
            height: 44,
            decoration: TileQuestStyle.glass(radius: 16),
            child: Icon(icon, color: TileQuestStyle.cream, size: 22),
          ),
        ),
      ),
    ),
  );
}

/// 顶栏操作、关卡与提示分行展示，使小屏和较长翻译仍有足够空间。
class QuestHeader extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cjk = quest_is_cjk(context);
    // 标题区高度固定；大字号系统设置下只压缩两行说明文字，工具栏按钮不换行。
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: TileQuestStyle.toolbar_height,
          child: Row(
            children: [
              QuestIconButton(
                key: const ValueKey('tile_quest_back'),
                icon: Icons.arrow_back_rounded,
                label: quest_text(context, 'back', 'Back'),
                on_tap: on_back,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest_text(context, 'title', 'Tile Quest'),
                        style: compact
                            ? TileQuestStyle.title(cjk).copyWith(
                                fontSize: cjk
                                    ? TileQuestStyle.compact_title_size_cjk
                                    : TileQuestStyle
                                          .compact_title_size_alphabetic,
                                height: 1.1,
                              )
                            : TileQuestStyle.title(cjk),
                      ),
                      if (compact)
                        Text(
                          quest_text(
                            context,
                            'level',
                            'Level {level}',
                            args: {'level': '${state.level}'},
                          ),
                          style: TileQuestStyle.caption(
                            cjk,
                            color: TileQuestStyle.gold,
                          ).copyWith(letterSpacing: 0),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              QuestIconButton(
                key: const ValueKey('tile_quest_sound'),
                icon: sound_enabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                label: quest_text(
                  context,
                  sound_enabled ? 'sound_on' : 'sound_off',
                  sound_enabled ? 'Sound on' : 'Sound off',
                ),
                on_tap: on_sound,
              ),
              const SizedBox(width: 7),
              QuestIconButton(
                key: const ValueKey('tile_quest_restart'),
                icon: Icons.refresh_rounded,
                label: quest_text(context, 'restart', 'Restart'),
                on_tap: on_restart,
              ),
            ],
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 9),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                quest_text(
                  context,
                  'level',
                  'Level {level}',
                  args: {'level': '${state.level}'},
                ),
                maxLines: 1,
                style: TileQuestStyle.body(
                  cjk,
                  color: TileQuestStyle.gold,
                  emphasis: true,
                ),
              ),
            ),
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                quest_text(
                  context,
                  state.level == 1 ? 'level_one_hint' : 'level_two_hint',
                  state.level == 1
                      ? 'A little match. A little magic.'
                      : 'Think ahead. Find your way.',
                ),
                style: TileQuestStyle.caption(cjk).copyWith(letterSpacing: 0),
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 用户提供的透明图标与动态次数独立展示，横竖屏保留完整触摸区域。
class QuestToolButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cjk = quest_is_cjk(context);
    final colors = switch (tool) {
      TileQuestTool.undo => TileQuestStyle.undo_colors,
      TileQuestTool.shuffle => TileQuestStyle.shuffle_colors,
      TileQuestTool.remove => TileQuestStyle.remove_colors,
    };
    final name = quest_text(context, tool.name, switch (tool) {
      TileQuestTool.undo => 'Undo',
      TileQuestTool.shuffle => 'Shuffle',
      TileQuestTool.remove => 'Remove',
    });
    final total = TileQuestConfig.initial_tool_uses(tool);
    return Semantics(
      label: '$name $remaining/$total',
      button: true,
      enabled: enabled,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : .44,
        duration: TileQuestStyle.quick_duration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('tile_quest_tool_${tool.name}'),
            onTap: enabled ? on_tap : null,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: .38)),
                boxShadow: [
                  BoxShadow(
                    color: colors.last.withValues(alpha: .28),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final narrow =
                      constraints.maxWidth < TileQuestStyle.narrow_tool_width;
                  final compact =
                      constraints.maxHeight <
                      TileQuestStyle.tool_tall_threshold;
                  Widget labels() => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        softWrap: false,
                        style: TileQuestStyle.body(
                          cjk,
                          color: Colors.white,
                          emphasis: true,
                        ),
                      ),
                      Text(
                        '$remaining/$total',
                        style: TileQuestStyle.caption(
                          cjk,
                          color: Colors.white,
                        ).copyWith(letterSpacing: 0, height: 1.1),
                      ),
                    ],
                  );
                  return Padding(
                    padding: EdgeInsets.all(
                      narrow
                          ? TileQuestStyle.narrow_tool_content_inset
                          : TileQuestStyle.tool_content_inset,
                    ),
                    // 矮按钮左右排布，完整保留原图；长翻译仅缩放文字，
                    // 不会连带把图标和点击区域压成很小的一整行。
                    child: narrow
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              QuestPowerupIcon(
                                tool: tool,
                                size: TileQuestStyle.narrow_tool_icon_size,
                              ),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: labels(),
                                ),
                              ),
                            ],
                          )
                        : compact
                        ? Row(
                            children: [
                              QuestPowerupIcon(
                                tool: tool,
                                size: TileQuestStyle.tool_icon_compact_size,
                              ),
                              const SizedBox(
                                width: TileQuestStyle.tool_content_gap,
                              ),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: labels(),
                                ),
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
                                    tool: tool,
                                    size: TileQuestStyle.tool_icon_size,
                                  ),
                                  const SizedBox(
                                    height: TileQuestStyle.tool_content_gap,
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: labels(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 统一主要按钮，结果弹层和确认弹层使用相同按压反馈。
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
