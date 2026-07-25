import 'package:flutter/material.dart';

import 'package:app/config/color_config.dart';
import 'package:app/pages/short_story_read/style.dart';

/// 标签列表组件。
///
/// 展示小说的分类标签，每个标签使用不同的颜色。
/// 颜色通过 [story_id] 和标签索引生成固定的颜色索引，
/// 保证同一小说的标签颜色在不同场景下保持一致。
///
/// 支持 CJK 和非 CJK 语系的间距适配。
class TagList extends StatelessWidget {
  /// 标签文本列表。
  final List<String> tags;

  /// 是否为夜间模式。
  final bool is_dark;

  /// 小说 ID（用于生成固定的颜色索引）。
  final int story_id;

  /// 当前语种是否为 CJK（影响标签内边距）。
  final bool is_cjk;

  const TagList({
    super.key,
    required this.tags,
    required this.is_dark,
    required this.story_id,
    this.is_cjk = true,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: ShortStoryReadStyle.tag_spacing,
      runSpacing: ShortStoryReadStyle.tag_spacing,
      children: List<Widget>.generate(tags.length, (int index) {
        /// 从 tagColorList 取色，使用 story_id 和 index 生成固定的颜色索引。
        final Color tag_color = ColorConstants.tagColorList[
            (story_id * 7 + index * 3) % ColorConstants.tagColorList.length];

        /// 标签背景色（使用 12% 透明度）。
        final Color tag_bg = tag_color.withValues(alpha: 0.12);

        return Container(
          padding: EdgeInsets.symmetric(
            /// CJK 语系水平间距较小，非 CJK 语系稍宽以适配较长单词。
            horizontal: is_cjk ? 6 : 8,
            vertical: ShortStoryReadStyle.tag_vertical_padding,
          ),
          decoration: BoxDecoration(
            color: tag_bg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            tags[index],
            style: TextStyle(
              fontSize: ShortStoryReadStyle.tag_font_size,
              color: tag_color,
            ),
          ),
        );
      }),
    );
  }
}
