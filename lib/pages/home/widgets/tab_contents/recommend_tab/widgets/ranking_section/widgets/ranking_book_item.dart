import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:app/components/novel_cover/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/story_item.dart';
import 'package:app/models/recommend_ranking_item.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/style.dart';
import 'package:app/util/novel_navigation/index.dart';
import 'package:app/util/text/text_layout_measure.dart';

/// 榜单书籍项组件。
///
/// 展示单个书籍的封面图片、排名序号、书名、分类和热度信息。
///
/// 底部信息行布局规则：
/// - 标题占 1 行时：分类在第一行，热度在第二行。
/// - 标题占 2 行时：分类和热度在同一行，中间用分隔点隔开。
class RankingBookItem extends StatelessWidget {
  /// 书籍数据。
  final StoryItem book;

  /// 排名序号（从 1 开始）。
  final int ranking_index;

  /// 当前是否为夜间模式。
  final bool is_dark;

  const RankingBookItem({
    super.key,
    required this.book,
    required this.ranking_index,
    required this.is_dark,
  });

  @override
  Widget build(BuildContext context) {
    /// 排名序号颜色：前 3 名使用彩色，其余使用灰色。
    final Color index_color =
        ranking_index <= RankingSectionStyle.top_rank_count
        ? ColorConstants.resolveMessageTypeAccentColor(ranking_index - 1)
        : (is_dark
              ? Colors.white.withValues(alpha: 0.74)
              : RankingSectionStyle.secondary_color_light);

    /// 书名文字颜色。
    final Color title_color = is_dark
        ? Colors.white
        : RankingSectionStyle.title_color_light;

    /// 分类文字颜色。
    final Color category_color = is_dark
        ? Colors.white.withValues(alpha: 0.54)
        : RankingSectionStyle.secondary_color_light;

    /// 热度文字颜色。
    final Color heat_color = is_dark
        ? Colors.white.withValues(alpha: 0.54)
        : RankingSectionStyle.secondary_color_light;

    /// 分类标签文本。
    final String category_text = _get_category_label(ranking_index);

    /// 标题样式同时用于真实渲染和换行测量，确保测量结果完全一致。
    final TextStyle title_text_style = TextStyle(
      fontSize: RankingSectionStyle.title_font_size,
      fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
      color: title_color,
      height: RankingSectionStyle.title_line_height,
    );

    /// 分类样式同时用于真实渲染和宽度测量。
    final TextStyle category_text_style = TextStyle(
      fontSize: RankingSectionStyle.category_font_size,
      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
      color: category_color,
      height: RankingSectionStyle.category_line_height,
    );

    /// 热度样式同时用于真实渲染和宽度测量。
    final TextStyle heat_text_style = TextStyle(
      fontSize: RankingSectionStyle.category_font_size,
      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
      color: heat_color,
      height: RankingSectionStyle.category_line_height,
    );

    /// 根据系统文字缩放比例动态扩展卡片高度，避免大字号裁剪第二行。
    final TextScaler text_scaler = MediaQuery.textScalerOf(context);
    final double item_height = RankingSectionStyle.resolve_item_height(
      text_scaler,
    );
    final double item_content_height =
        RankingSectionStyle.resolve_item_content_height(text_scaler);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        navigate_to_novel(
          id: book.id,
          title: book.title,
          publish_status: book.publish_status,
        );
      },
      child: SizedBox(
        height: item_height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 封面图片
            NovelCover(
              image_url: book.cover_url,
              description: book.introduction,
              width: RankingSectionStyle.cover_width,
              height: RankingSectionStyle.cover_height,
              border_radius: RankingSectionStyle.cover_border_radius,
              is_dark: is_dark,
              error_text: '$ranking_index',
            ),
            // 封面与排名序号间距
            const SizedBox(width: RankingSectionStyle.cover_to_rank_gap),
            // 排名序号
            Padding(
              padding: const EdgeInsets.only(
                top: RankingSectionStyle.rank_number_top_offset,
              ),
              child: SizedBox(
                width: RankingSectionStyle.rank_number_width,
                child: Text(
                  '$ranking_index',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: RankingSectionStyle.rank_number_font_size,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                    color: index_color,
                  ),
                ),
              ),
            ),
            // 排名序号与书籍信息间距
            const SizedBox(width: RankingSectionStyle.rank_to_info_gap),
            // 书籍信息（书名、分类、热度）
            Expanded(
              child: LayoutBuilder(
                builder:
                    (BuildContext context, BoxConstraints info_constraints) {
                      /// 使用标题最终获得的真实宽度预判是否换行。
                      final bool is_single_line = !text_requires_multiple_lines(
                        context: context,
                        text: book.title,
                        text_style: title_text_style,
                        max_width: info_constraints.maxWidth,
                      );
                      final String heat_text = _get_heat_text(context);

                      return SizedBox(
                        height: item_content_height,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // 书名（最多显示 2 行）
                            Text(
                              book.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: title_text_style,
                            ),
                            // 底部信息区域
                            if (is_single_line)
                              // 标题单行：分类和热度分两行显示
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    category_text,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: category_text_style,
                                  ),
                                  Text(
                                    heat_text,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: heat_text_style,
                                  ),
                                ],
                              )
                            else
                              _build_multi_line_meta(
                                context: context,
                                available_width: info_constraints.maxWidth,
                                category_text: category_text,
                                heat_text: heat_text,
                                category_text_style: category_text_style,
                                heat_text_style: heat_text_style,
                                dot_color: category_color,
                              ),
                          ],
                        ),
                      );
                    },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 标题双行时构建单行分类和热度信息。
  ///
  /// [context] 提供当前语种、文字方向和系统文字缩放比例。
  /// [available_width] 是底部信息能够使用的真实宽度。
  /// [category_text] 是分类文本。
  /// [heat_text] 是热度文本。
  /// [category_text_style] 是分类文本的真实渲染样式。
  /// [heat_text_style] 是热度文本的真实渲染样式。
  /// [dot_color] 是分类和热度之间分隔点的颜色。
  Widget _build_multi_line_meta({
    required BuildContext context,
    required double available_width,
    required String category_text,
    required String heat_text,
    required TextStyle category_text_style,
    required TextStyle heat_text_style,
    required Color dot_color,
  }) {
    final double category_width = measure_single_line_text_width(
      context: context,
      text: category_text,
      text_style: category_text_style,
    );
    final double heat_width = measure_single_line_text_width(
      context: context,
      text: heat_text,
      text_style: heat_text_style,
    );
    const double separator_total =
        RankingSectionStyle.category_to_dot_gap +
        RankingSectionStyle.separator_dot_size +
        RankingSectionStyle.dot_to_heat_gap;
    final bool show_heat =
        category_width + separator_total + heat_width <= available_width;

    if (!show_heat) {
      return Text(
        category_text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: category_text_style,
      );
    }

    return Row(
      children: <Widget>[
        Flexible(
          child: Text(
            category_text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: category_text_style,
          ),
        ),
        const SizedBox(width: RankingSectionStyle.category_to_dot_gap),
        Container(
          width: RankingSectionStyle.separator_dot_size,
          height: RankingSectionStyle.separator_dot_size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dot_color),
        ),
        const SizedBox(width: RankingSectionStyle.dot_to_heat_gap),
        Flexible(
          child: Text(
            heat_text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: heat_text_style,
          ),
        ),
      ],
    );
  }

  /// 获取热度显示文本。
  ///
  /// 优先使用书籍数据中的热度文本，
  /// 无数据时根据当前语种格式化默认值。
  String _get_heat_text(BuildContext context) {
    if (book.heat_text.isNotEmpty) return book.heat_text;
    return RecommendRankingItem.format_count_text(
      0,
      Localizations.localeOf(context).languageCode,
    );
  }

  /// 获取分类标签文本。
  ///
  /// 优先使用书籍数据中的真实分类文本，
  /// 无数据时根据排名索引返回兜底分类标签。
  ///
  /// [index] - 排名索引（从 1 开始）。
  String _get_category_label(int index) {
    // 优先使用真实分类数据。
    if (book.category_text.isNotEmpty) return book.category_text;

    // 兜底：使用本地化分类标签（复用 installation 题材文案）。
    const List<String> category_keys = <String>[
      'installation.genre_urban',
      'installation.genre_fantasy',
      'installation.genre_history',
      'installation.genre_fantasy',
      'installation.genre_history',
      'installation.genre_history',
      'installation.genre_urban',
      'installation.genre_fantasy',
    ];
    return easy.tr(category_keys[(index - 1) % category_keys.length]);
  }
}
