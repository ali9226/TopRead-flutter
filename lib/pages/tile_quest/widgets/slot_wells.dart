// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'package:flutter/material.dart';
import '../style.dart';
import 'scene_layout.dart';

/// 槽背景只绘制统一坐标表，不再通过 Row/Expanded 单独推算尺寸。
class QuestSlotWell extends StatelessWidget {
  const QuestSlotWell({super.key, required this.layout});

  final QuestSceneLayout layout;
  static const double _radius = 19;
  static const double _border_width = 1.5;
  static const double _slot_radius = 9;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      // DecoratedBox 不像带 border 的 Container 那样给子节点隐式加 padding。
      Positioned.fill(
        child: DecoratedBox(
          decoration: TileQuestStyle.glass(radius: _radius).copyWith(
            border: Border.all(
              color: const Color(0xFF9DBCDC).withValues(alpha: .58),
              width: _border_width,
            ),
          ),
        ),
      ),
      for (var index = 0; index < QuestSceneLayout.slot_count; index++)
        Positioned.fromRect(
          key: ValueKey('tile_quest_slot_$index'),
          rect: layout.tray_tile(index).shift(-layout.tray.topLeft),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF0B1931).withValues(alpha: .73),
              borderRadius: BorderRadius.circular(_slot_radius),
              border: Border.all(
                color: const Color(0xFF7796BA).withValues(alpha: .35),
              ),
            ),
          ),
        ),
    ],
  );
}

/// 备用区的三个空槽与备用牌共用矩形，确保移出、返回时完全重合。
class QuestReserveWell extends StatelessWidget {
  const QuestReserveWell({
    super.key,
    required this.layout,
    required this.cjk,
    required this.occupied,
  });

  final QuestSceneLayout layout;
  final bool cjk, occupied;
  static const double _slot_radius = 9;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    child: Stack(
      fit: StackFit.expand,
      children: [
        for (var index = 0; index < QuestSceneLayout.reserve_count; index++)
          Positioned.fromRect(
            key: ValueKey('tile_quest_reserve_slot_$index'),
            rect: layout.reserve_tile(index).shift(-layout.reserve.topLeft),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(
                  0xFF142544,
                ).withValues(alpha: occupied ? .7 : .3),
                borderRadius: BorderRadius.circular(_slot_radius),
                border: Border.all(
                  color: TileQuestStyle.pale.withValues(alpha: .25),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
