// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';
import '../../widgets/tile_quest_tile.dart';
import '../style.dart';

/// 尺寸系列展示：40 / 48 / 56 / 64 / 80 / 96 六种边长的单个方块。
class TileSizeShowcase extends StatelessWidget {
  const TileSizeShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SIZES  尺寸系列', style: TilePreviewStyle.section()),
        const SizedBox(height: TilePreviewStyle.header_gap),
        // 尺寸从小到大排开，用底部基线对齐，方便观察厚度与投影的比例。
        Wrap(
          spacing: 18,
          runSpacing: 20,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            for (final size in TilePreviewStyle.sample_sizes)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TileQuestTile(size: size),
                  const SizedBox(height: 8),
                  Text('${size.toInt()}', style: TilePreviewStyle.label()),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
