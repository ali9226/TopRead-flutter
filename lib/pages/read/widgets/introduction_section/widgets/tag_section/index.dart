import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:app/pages/read/logic.dart';
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
        Padding(
          padding: const EdgeInsets.only(top: TagStyle.tag_title_top_padding),
          child: Text(
            easy.tr('read.intro_title'),
            style: TextStyle(
              color: title_color,
              fontSize: TagStyle.section_title_font_size,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
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
              // 标签颜色从逻辑层复用，避免每个组件重复维护同一组色值。
              final List<int> tag_color_value_list = Logic.tag_color_value_list;
              // 根据索引循环取色，让标签数量增加时也能保持颜色轮换规则。
              final List<Color> tag_color_list = tag_color_value_list
                  .map((int color_value) => Color(color_value))
                  .toList();
              // 按索引对颜色列表取模，实现无限标签场景下的稳定循环配色。
              final Color tag_color =
                  tag_color_list[index % tag_color_list.length];

              // 单个标签样式由“半透明底色 + 实色文字”组成。
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TagStyle.tag_horizontal_padding,
                  vertical: TagStyle.tag_vertical_padding,
                ),
                decoration: BoxDecoration(
                  color: tag_color.withValues(
                    alpha: is_dark
                        ? TagStyle.tag_background_night_alpha
                        : TagStyle.tag_background_light_alpha,
                  ),
                  borderRadius: BorderRadius.circular(TagStyle.tag_radius),
                ),
                child: Text(
                  tag_list[index],
                  style: TextStyle(
                    color: tag_color,
                    fontSize: TagStyle.tag_font_size,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
