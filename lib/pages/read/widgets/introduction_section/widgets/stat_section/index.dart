import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/stores/project_config_store.dart';
import './style.dart';
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';

/// 阅读页顶部统计区块组件。
///
/// 展示小说的评分、在读人数和总字数。
/// 采用三列等分布局，中间以细分割线隔离。
class ReadStatSection extends StatelessWidget {
  /// 当前是否为夜间主题。
  final bool is_dark;

  /// 详情数据。
  final ReadDetail detail;
  final bool hero;
  final VoidCallback? on_rating_tap;

  const ReadStatSection({
    super.key,
    required this.is_dark,
    required this.detail,
    this.hero = false,
    this.on_rating_tap,
  });

  @override
  Widget build(BuildContext context) {
    // 统计分割线颜色按主题设置透明度，弱化分割感避免喧宾夺主。
    final Color divider_color = is_dark
        ? Colors.white.withValues(alpha: StatStyle.stat_divider_night_alpha)
        : Colors.black.withValues(alpha: StatStyle.stat_divider_light_alpha);

    // iOS 审核模式下隐藏评分/评论列。
    final bool show_review =
        !Get.find<ProjectConfigStore>().current.is_apple_review_mode;

    if (hero) {
      return _build_hero_stats(context, show_review: show_review);
    }
    return IntrinsicHeight(
      child: Row(
        children: <Widget>[
          // 第一列：评分信息，显示右箭头表示可深入查看点评。
          if (show_review) ...[
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
          ],
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

  /// TODO 海报统计保留原有文案与审核开关，只改变对齐和颜色；评分回调由阅读页注入。
  Widget _build_hero_stats(BuildContext context, {required bool show_review}) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (show_review) ...[
            Expanded(
              child: _HeroStatItem(
                major_text: detail.score_major_text,
                minor_text: detail.score_minor_text,
                subtitle_text: detail.review_count_text,
                icon: Icons.star_rounded,
                on_tap: on_rating_tap,
              ),
            ),
            _hero_divider(),
          ],
          Expanded(
            child: _HeroStatItem(
              major_text: detail.reading_major_text,
              minor_text: detail.reading_minor_text,
              subtitle_text: detail.reading_subtitle_text,
              icon: Icons.local_fire_department_rounded,
            ),
          ),
          _hero_divider(),
          Expanded(
            child: _HeroStatItem(
              major_text: detail.word_count_major_text,
              minor_text: detail.word_count_minor_text,
              subtitle_text: detail.word_count_subtitle_text,
              icon: Icons.notes_rounded,
            ),
          ),
        ],
      );

  Widget _hero_divider() => Container(
    width: StatStyle.hero_divider_width,
    height: StatStyle.hero_divider_height,
    margin: const EdgeInsets.symmetric(
      horizontal: StatStyle.hero_gap,
      vertical: StatStyle.hero_gap,
    ),
    color: Colors.white.withValues(alpha: StatStyle.hero_divider_alpha),
  );
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

/// TODO 海报单项数字在窄列中等比缩放，保留真实单位和完整数据，不让数值挤出封面区域。
class _HeroStatItem extends StatelessWidget {
  const _HeroStatItem({
    required this.major_text,
    required this.minor_text,
    required this.subtitle_text,
    required this.icon,
    this.on_tap,
  });
  final String major_text;
  final String minor_text;
  final String subtitle_text;
  final IconData icon;
  final VoidCallback? on_tap;

  @override
  Widget build(BuildContext context) {
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    return InkWell(
      key: on_tap == null ? null : const ValueKey('novel_hero_rating'),
      onTap: on_tap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: ColorConstants.themeColor,
                  size: StatStyle.hero_icon_size,
                ),
                const SizedBox(width: StatStyle.hero_icon_gap),
                Text(
                  '$major_text$minor_text',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: cjk
                        ? StatStyle.hero_value_size_cjk
                        : StatStyle.hero_value_size_alphabetic,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: StatStyle.hero_label_gap),
          Text(
            subtitle_text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: StatStyle.hero_label_alpha),
              fontSize: cjk
                  ? StatStyle.hero_label_size_cjk
                  : StatStyle.hero_label_size_alphabetic,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}
