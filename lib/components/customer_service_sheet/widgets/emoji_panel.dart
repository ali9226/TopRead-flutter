// ignore_for_file: non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import '../style.dart';
import 'package:app/config/color_config.dart';

/// 表情面板组件。
///
/// 展示预置表情网格，点击选中后回调。
class EmojiPanel extends StatelessWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  /// 表情选中回调。
  final void Function(String emoji) on_emoji_selected;

  const EmojiPanel({
    super.key,
    required this.is_dark,
    required this.on_emoji_selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: CustomerServiceSheetStyle.emoji_panel_height,
      color: is_dark
          ? CustomerServiceSheetStyle.emoji_panel_bg_dark
          : CustomerServiceSheetStyle.emoji_panel_bg_light,
      child: GridView.builder(
        padding: const EdgeInsets.all(LayoutConfig.space_12),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: CustomerServiceSheetStyle.emoji_columns,
          mainAxisSpacing: LayoutConfig.space_8,
          crossAxisSpacing: LayoutConfig.space_8,
        ),
        itemCount: CustomerServiceSheetStyle.emoji_list.length,
        itemBuilder: (context, index) {
          final String emoji = CustomerServiceSheetStyle.emoji_list[index];
          return GestureDetector(
            onTap: () => on_emoji_selected(emoji),
            child: Container(
              decoration: BoxDecoration(
                color: ColorConstants.transparent,
                borderRadius: BorderRadius.circular(LayoutConfig.radius_8),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
          );
        },
      ),
    );
  }
}
