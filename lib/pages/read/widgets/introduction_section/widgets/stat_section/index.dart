import 'package:flutter/material.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/read/logic.dart';
import './style.dart';
import 'package:app/config/font_config.dart';

/// 阅读页顶部统计区块组件。
///
/// 展示小说的评分、在读人数和总字数。
/// 采用三列等分布局，中间以细分割线隔离。
class ReadStatSection extends StatelessWidget {
  /// 当前是否为夜间主题。
  final bool is_dark;

  /// 详情数据。
  final ReadDetail detail;

  const ReadStatSection({
    super.key,
    required this.is_dark,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    // 统计分割线颜色按主题设置透明度，弱化分割感避免喧宾夺主。
    final Color divider_color = is_dark
        ? Colors.white.withValues(alpha: StatStyle.stat_divider_night_alpha)
        : Colors.black.withValues(alpha: StatStyle.stat_divider_light_alpha);

    return IntrinsicHeight(
      child: Row(
        children: <Widget>[
          // 第一列：评分信息，显示右箭头表示可深入查看点评。
          Expanded(
            child: _ReaderStatItem(
              is_dark: is_dark,
              major_text: detail.score_major_text,
              minor_text: detail.score_minor_text,
              subtitle_text: detail.review_count_text,
              show_arrow: true,
            ),
          ),
          // 第一、二列之间的分割线。
          VerticalDivider(
            color: divider_color,
            width: StatStyle.stat_divider_width,
          ),
          // 第二列：在读人数信息。
          Expanded(
            child: _ReaderStatItem(
              is_dark: is_dark,
              major_text: detail.reading_major_text,
              minor_text: detail.reading_minor_text,
              subtitle_text: detail.reading_subtitle_text,
            ),
          ),
          // 第二、三列之间的分割线。
          VerticalDivider(
            color: divider_color,
            width: StatStyle.stat_divider_width,
          ),
          // 第三列：字数信息。
          Expanded(
            child: _ReaderStatItem(
              is_dark: is_dark,
              major_text: detail.word_count_major_text,
              minor_text: detail.word_count_minor_text,
              subtitle_text: detail.word_count_subtitle_text,
            ),
          ),
        ],
      ),
    );
  }
}

/// 阅读页顶部统计单项组件。
class _ReaderStatItem extends StatelessWidget {
  /// 当前是否为夜间主题。
  final bool is_dark;

  /// 主数值文案。
  final String major_text;

  /// 单位文案。
  final String minor_text;

  /// 副标题文案。
  final String subtitle_text;

  /// 是否显示右箭头。
  final bool show_arrow;

  const _ReaderStatItem({
    required this.is_dark,
    required this.major_text,
    required this.minor_text,
    required this.subtitle_text,
    this.show_arrow = false,
  });

  @override
  Widget build(BuildContext context) {
    // 主数字颜色用于突出指标值。
    final Color title_color = is_dark
        ? ColorConstants.whiteColor
        : ColorConstants.lightTextColor;
    // 次要颜色用于单位和副标题，弱化层级避免与主数字抢视觉焦点。
    final Color secondary_text_color = is_dark
        ? ColorConstants.whiteColor.withValues(
            alpha: StatStyle.secondary_text_night_alpha,
          )
        : ColorConstants.hintColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        // 主数字 + 单位使用 RichText 组合，便于精细控制基线和字号。
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: major_text,
                style: TextStyle(
                  color: title_color,
                  fontSize: StatStyle.stat_major_font_size,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                ),
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.bottom,
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: StatStyle.stat_minor_bottom_padding,
                    left: StatStyle.stat_minor_left_padding,
                  ),
                  child: Text(
                    minor_text,
                    style: TextStyle(
                      color: secondary_text_color,
                      fontSize: StatStyle.stat_minor_font_size,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // 主数字与副标题之间的固定间距。
        const SizedBox(height: StatStyle.stat_subtitle_top_spacing),
        // 副标题行：可选地在末尾展示右箭头。
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: Text(
                subtitle_text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: secondary_text_color,
                  fontSize: StatStyle.stat_subtitle_font_size,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                ),
              ),
            ),
            if (show_arrow) ...<Widget>[
              const SizedBox(width: StatStyle.stat_subtitle_icon_gap),
              SvgIcon(
                name: 'right',
                width: StatStyle.stat_subtitle_icon_size,
                height: StatStyle.stat_subtitle_icon_size,
                color: secondary_text_color,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
