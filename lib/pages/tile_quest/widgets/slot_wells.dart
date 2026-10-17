// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'package:flutter/material.dart';
import '../style.dart';
import 'quest_text.dart';
import 'scene_layout.dart';

/// 槽背景只绘制统一坐标表，不再通过 Row/Expanded 单独推算尺寸。
class QuestSlotWell extends StatelessWidget {
  const QuestSlotWell({
    super.key,
    required this.layout,
    required this.caption,
    required this.cjk,
  });

  final QuestSceneLayout layout;
  final String caption;
  final bool cjk;
  static const double _radius = 19;
  static const double _border_width = 1.5;
  static const double _slot_radius = 9;
  static const double _caption_size_cjk = 8;
  static const double _caption_size_alphabetic = 7;
  static const double _caption_line_height = 1.1;
  static const double _caption_letter_spacing = 1.5;

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
      Positioned.fromRect(
        rect: layout.tray_caption.shift(-layout.tray.topLeft),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            caption,
            style: TileQuestStyle.caption(cjk).copyWith(
              fontSize: cjk ? _caption_size_cjk : _caption_size_alphabetic,
              height: _caption_line_height,
              letterSpacing: _caption_letter_spacing,
            ),
            maxLines: 1,
            softWrap: false,
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
  static const double _hint_minimum_height = 40;
  static const double _hint_size_cjk = 10;
  static const double _hint_size_alphabetic = 9;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Positioned.fromRect(
        rect: layout.reserve_label.shift(-layout.reserve.topLeft),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quest_text(context, 'reserve', 'RESERVE'),
              style: TileQuestStyle.caption(cjk),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
            ),
            if (layout.reserve.height >= _hint_minimum_height)
              Text(
                quest_text(context, 'reserve_hint', 'Tap the top tile to return'),
                style: TileQuestStyle.caption(cjk).copyWith(
                  fontSize: cjk ? _hint_size_cjk : _hint_size_alphabetic,
                  letterSpacing: 0,
                  color: TileQuestStyle.pale.withValues(alpha: .65),
                ),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
              ),
          ],
        ),
      ),
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
  );
}
