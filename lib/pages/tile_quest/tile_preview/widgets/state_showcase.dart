// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';
import '../../widgets/tile_quest_tile.dart';
import '../style.dart';

/// 状态对比展示：普通 / 选中 / 遮挡三种状态的同尺寸方块。
class TileStateShowcase extends StatelessWidget {
  const TileStateShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STATES  状态对比', style: TilePreviewStyle.section()),
        const SizedBox(height: TilePreviewStyle.header_gap),
        Wrap(
          spacing: 28,
          runSpacing: 20,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            _state_item('普通', const TileQuestTile(size: 64)),
            _state_item(
              '选中',
              const TileQuestTile(size: 64, is_selected: true, elevation: 1.3),
            ),
            _state_item(
              '遮挡',
              const TileQuestTile(size: 64, is_blocked: true),
            ),
          ],
        ),
      ],
    );
  }

  /// 单个状态：方块 + 下方说明文字。
  Widget _state_item(String label, Widget tile) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      tile,
      const SizedBox(height: 8),
      Text(label, style: TilePreviewStyle.label()),
    ],
  );
}
