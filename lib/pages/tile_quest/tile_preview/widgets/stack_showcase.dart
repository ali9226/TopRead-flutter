// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';
import '../../widgets/tile_quest_tile.dart';
import '../style.dart';

/// 多层堆叠展示：上层压住下层、投影落在下层表面，呈现真实堆叠感。
class TileStackShowcase extends StatelessWidget {
  const TileStackShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    final tile = TilePreviewStyle.stack_tile;
    final gap = TilePreviewStyle.stack_gap;
    final dx = TilePreviewStyle.stack_layer_dx;
    final dy = TilePreviewStyle.stack_layer_dy;

    // 三层错位布局：底层最大阵列、中层收窄、顶层居中，俯视金字塔。
    final width = tile * 3 + gap * 2 + dx * 2;
    final height = tile + dy * 2 + tile * 0.15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STACK  多层堆叠', style: TilePreviewStyle.section()),
        const SizedBox(height: TilePreviewStyle.header_gap),
        Center(
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 底层：三枚并排，最左最右的两枚被上层压住一角。
                for (var i = 0; i < 3; i++)
                  Positioned(
                    left: i * (tile + gap),
                    top: dy * 2,
                    child: TileQuestTile(
                      size: tile,
                      is_blocked: i != 1,
                      elevation: 1.15,
                    ),
                  ),
                // 中层：两枚，压在底层中段，产生遮挡关系。
                for (var i = 0; i < 2; i++)
                  Positioned(
                    left: dx + i * (tile + gap) - gap * 0.5,
                    top: dy,
                    child: TileQuestTile(
                      size: tile,
                      is_blocked: false,
                      elevation: 1.25,
                    ),
                  ),
                // 顶层：单枚居中，完全露出，投影落在中层牌面上。
                Positioned(
                  left: dx * 2 - gap,
                  top: 0,
                  child: TileQuestTile(size: tile, elevation: 1.45),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
