import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:app/components/content_category_tag/index.dart';
import 'package:app/config/color_config.dart';
import './style.dart';

/// 阅读页标签区块组件。
///
/// 展示小说的分类标签（如：奇幻、玄幻、都市等）。
/// 左侧为固定标题，右侧为自动换行的彩色标签。
class ReadTagSection extends StatelessWidget {
  /// 当前是否为夜间主题。
  final bool is_dark;

  /// 标签文本列表。
  final List<String> tag_list;

  const ReadTagSection({
    super.key,
    required this.is_dark,
    required this.tag_list,
  });

  @override
  Widget build(BuildContext context) {
    // 标题文字颜色
    final Color title_color = is_dark
        ? TagStyle.tag_text_color_dark
        : const Color(0xFF1F1A12);

    // 标签区左侧显示标题，右侧使用自动换行布局展示多标签。
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(top: TagStyle.tag_title_top_padding),
            child: Text(
              easy.tr('comics.genres'),
              style: TextStyle(
                color: title_color,
                fontSize: TagStyle.section_title_font_size,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
              ),
            ),
          ),
        ),
        const SizedBox(width: TagStyle.tag_wrap_left_spacing),
        Expanded(
          child: Wrap(
            spacing: TagStyle.tag_spacing,
            runSpacing: TagStyle.tag_run_spacing,
            alignment: WrapAlignment.end,
            children: List<Widget>.generate(tag_list.length, (int index) {
              return ContentCategoryTag(
                label: tag_list[index],
                color: ColorConstants.resolveTagColor(index),
                is_dark: is_dark,
              );
            }),
          ),
        ),
      ],
    );
  }
}
