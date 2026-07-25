import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:app/components/novel_cover/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/story_item.dart';
import 'package:app/models/recommend_ranking_item.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/style.dart';
import 'package:app/util/novel_navigation/index.dart';

/// 榜单书籍项组件。
///
/// 展示单个书籍的封面图片、排名序号、书名、分类和热度信息。
///
/// 底部信息行布局规则：
/// - 标题占 1 行时：分类在第一行，热度在第二行。
/// - 标题占 2 行时：分类和热度在同一行，中间用分隔点隔开。
class RankingBookItem extends StatefulWidget {
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
  State<RankingBookItem> createState() => _RankingBookItemState();
}

class _RankingBookItemState extends State<RankingBookItem> {
  /// 标题的 GlobalKey，用于获取实际高度。
  final GlobalKey _title_key = GlobalKey();

  /// 标题是否为单行（初始为 true，渲染后更新）。
  bool _is_single_line = true;

  /// 是否已经计算过行数。
  bool _has_calculated = false;

  @override
  void initState() {
    super.initState();
    // 在下一帧渲染完成后计算标题行数。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculate_title_lines();
    });
  }

  /// 计算标题的实际行数。
  void _calculate_title_lines() {
    if (_has_calculated) return;

    final RenderBox? title_box =
        _title_key.currentContext?.findRenderObject() as RenderBox?;
    if (title_box == null) return;

    final double title_height = title_box.size.height;

    // 计算单行标题的高度。
    final double single_line_height =
        RankingSectionStyle.title_font_size * RankingSectionStyle.title_line_height;

    // 如果标题高度 > 单行高度 + 2（容差），认为是多行。
    final bool is_single_line = title_height <= single_line_height + 2;

    if (mounted && is_single_line != _is_single_line) {
      setState(() {
        _is_single_line = is_single_line;
        _has_calculated = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    /// 排名序号颜色：前 3 名使用彩色，其余使用灰色。
    final Color index_color =
        widget.ranking_index <= RankingSectionStyle.top_rank_count
        ? ColorConstants.resolveMessageTypeAccentColor(widget.ranking_index - 1)
        : (widget.is_dark
              ? Colors.white.withValues(alpha: 0.74)
              : RankingSectionStyle.secondary_color_light);

    /// 书名文字颜色。
    final Color title_color = widget.is_dark
        ? Colors.white
        : RankingSectionStyle.title_color_light;

    /// 分类文字颜色。
    final Color category_color = widget.is_dark
        ? Colors.white.withValues(alpha: 0.54)
        : RankingSectionStyle.secondary_color_light;

    /// 热度文字颜色。
    final Color heat_color = widget.is_dark
        ? Colors.white.withValues(alpha: 0.54)
        : RankingSectionStyle.secondary_color_light;

    /// 分类标签文本。
    final String category_text = _get_category_label(widget.ranking_index);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        navigate_to_novel(
          id: widget.book.id,
          title: widget.book.title,
          publish_status: widget.book.publish_status,
        );
      },
      child: SizedBox(
        height: RankingSectionStyle.item_height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 封面图片
            NovelCover(
              image_url: widget.book.cover_url,
              description: widget.book.introduction,
              width: RankingSectionStyle.cover_width,
              height: RankingSectionStyle.cover_height,
              border_radius: RankingSectionStyle.cover_border_radius,
              is_dark: widget.is_dark,
              error_text: '${widget.ranking_index}',
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
                  '${widget.ranking_index}',
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
              child: SizedBox(
                height: RankingSectionStyle.cover_height,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // 书名（最多显示 2 行）
                    Flexible(
                      key: _title_key,
                      child: Text(
                        widget.book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: RankingSectionStyle.title_font_size,
                          fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                          color: title_color,
                          height: RankingSectionStyle.title_line_height,
                        ),
                      ),
                    ),
                    // 底部信息区域
                    if (_is_single_line)
                      // 标题单行：分类和热度分两行显示
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          // 第一行：分类标签
                          Text(
                            category_text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: RankingSectionStyle.category_font_size,
                              fontWeight: FontConfig.adjustedWeight(
                                FontWeight.w400,
                              ),
                              color: category_color,
                            ),
                          ),
                          // 第二行：热度数值
                          Text(
                            _get_heat_text(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: RankingSectionStyle.category_font_size,
                              fontWeight: FontConfig.adjustedWeight(
                                FontWeight.w400,
                              ),
                              color: heat_color,
                            ),
                          ),
                        ],
                      )
                    else
                      // 标题双行：分类和热度在同一行
                      // 如果分类+热度超过宽度，热度不展示
                      LayoutBuilder(
                        builder: (context, bottom_constraints) {
                          final String heat_text = _get_heat_text(context);
                          final double available_width = bottom_constraints.maxWidth;

                          // 测量分类文本宽度。
                          final TextPainter category_painter = TextPainter(
                            text: TextSpan(
                              text: category_text,
                              style: TextStyle(
                                fontSize: RankingSectionStyle.category_font_size,
                                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                              ),
                            ),
                            textDirection: TextDirection.ltr,
                          )..layout();

                          // 测量热度文本宽度。
                          final TextPainter heat_painter = TextPainter(
                            text: TextSpan(
                              text: heat_text,
                              style: TextStyle(
                                fontSize: RankingSectionStyle.category_font_size,
                                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                              ),
                            ),
                            textDirection: TextDirection.ltr,
                          )..layout();

                          // 计算分隔点+间距的总宽度。
                          const double separator_total =
                              RankingSectionStyle.category_to_dot_gap +
                              RankingSectionStyle.separator_dot_size +
                              RankingSectionStyle.dot_to_heat_gap;

                          // 判断分类+热度是否超过可用宽度。
                          final double total_width =
                              category_painter.width +
                              separator_total +
                              heat_painter.width;
                          final bool show_heat = total_width <= available_width;

                          return SizedBox(
                            height: RankingSectionStyle.category_font_size * 1.4,
                            child: show_heat
                                ? Row(
                                    children: <Widget>[
                                      Flexible(
                                        child: Text(
                                          category_text,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: RankingSectionStyle.category_font_size,
                                            fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                                            color: category_color,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: RankingSectionStyle.category_to_dot_gap),
                                      Container(
                                        width: RankingSectionStyle.separator_dot_size,
                                        height: RankingSectionStyle.separator_dot_size,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: category_color,
                                        ),
                                      ),
                                      const SizedBox(width: RankingSectionStyle.dot_to_heat_gap),
                                      Flexible(
                                        child: Text(
                                          heat_text,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: RankingSectionStyle.category_font_size,
                                            fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                                            color: heat_color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    category_text,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: RankingSectionStyle.category_font_size,
                                      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                                      color: category_color,
                                    ),
                                  ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取热度显示文本。
  ///
  /// 优先使用书籍数据中的热度文本，
  /// 无数据时根据当前语种格式化默认值。
  String _get_heat_text(BuildContext context) {
    if (widget.book.heat_text.isNotEmpty) return widget.book.heat_text;
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
    if (widget.book.category_text.isNotEmpty) return widget.book.category_text;

    // 兜底：使用模拟分类标签列表。
    const List<String> category_list = <String>[
      '都市日常',
      '都市脑洞',
      '历史古代',
      '都市脑洞',
      '历史古代',
      '历史古代',
      '都市日常',
      '历史脑洞',
    ];
    return category_list[(index - 1) % category_list.length];
  }
}
