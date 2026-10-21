import 'package:flutter/material.dart';

import 'package:app/components/content_category_tag/index.dart';

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
      spacing: ContentCategoryTagStyle.spacing,
      runSpacing: ContentCategoryTagStyle.spacing,
      children: List<Widget>.generate(
        tags.length,
        (index) => ContentCategoryTag(
          label: tags[index],
          color: ContentCategoryTagStyle.color_for(
            content_id: story_id,
            index: index,
          ),
          is_dark: is_dark,
          is_cjk: is_cjk,
        ),
      ),
    );
  }
}
