// ignore_for_file: non_constant_identifier_names
import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'style.dart';
import 'widgets/size_showcase.dart';
import 'widgets/stack_showcase.dart';
import 'widgets/state_showcase.dart';

/// 方块材质独立预览页。
///
/// 深蓝夜空背景，分三段展示：尺寸系列、状态对比、多层堆叠，
/// 用于验收 2.5D 卡通方块的视觉品质，不接入游戏业务逻辑。
class TilePreviewPage extends StatelessWidget {
  const TilePreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: TilePreviewStyle.sky,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              TilePreviewStyle.page_padding,
              LayoutConfig.space_28,
              TilePreviewStyle.page_padding,
              LayoutConfig.space_40,
            ),
            children: [
              Text(
                'Tile Quest · 方块材质',
                style: TilePreviewStyle.heading_style(),
              ),
              const SizedBox(height: LayoutConfig.space_6),
              Text('2.5D 立体卡通底板 · 矢量绘制', style: TilePreviewStyle.label()),
              const SizedBox(height: TilePreviewStyle.section_gap),
              const TileSizeShowcase(),
              const SizedBox(height: TilePreviewStyle.section_gap),
              const TileStateShowcase(),
              const SizedBox(height: TilePreviewStyle.section_gap),
              const TileStackShowcase(),
            ],
          ),
        ),
      ),
    );
  }
}
