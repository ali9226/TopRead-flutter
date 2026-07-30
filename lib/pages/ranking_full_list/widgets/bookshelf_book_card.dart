import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:app/components/novel_cover/index.dart';
import 'package:app/models/recommend_ranking_item.dart';
import 'package:app/pages/ranking_full_list/style.dart';
import 'package:app/util/text/text_layout_measure.dart';

/// 完整榜单书籍卡片组件。
///
/// 底部信息行布局规则：
/// - 标题占 1 行时：分类、阅读数分两行显示。
/// - 标题占 2 行时：分类和阅读数在同一行，中间用分隔点隔开。
class BookshelfBookCard extends StatelessWidget {
  /// 当前书籍数据。
  final RecommendRankingItem book_item;

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 标签颜色池。
  final List<Color> tag_color_pool;

  /// 点击卡片时触发。
  final VoidCallback on_tap;

  const BookshelfBookCard({
    super.key,
    required this.book_item,
    required this.is_dark,
    required this.tag_color_pool,
    required this.on_tap,
  });

  @override
  Widget build(BuildContext context) {
    /// 标题文字颜色。
    final Color title_color = is_dark ? Colors.white : const Color(0xFF2B2F36);

    /// 底部信息文字颜色。
    final Color meta_text_color = is_dark
        ? Colors.white.withValues(alpha: 0.52)
        : const Color(0xFF6F7785);

    /// 底部信息文字样式。
    final TextStyle meta_text_style = TextStyle(
      color: meta_text_color,
      fontSize: Style.book_meta_font_size,
      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
      height: Style.book_meta_line_height,
    );

    /// 标题样式同时用于真实渲染和换行测量，确保测量结果完全一致。
    final TextStyle title_text_style = TextStyle(
      color: title_color,
      fontSize: Style.book_title_font_size,
      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
      height: Style.book_title_height,
    );

    /// 分类标签文本。
    final String category_text = book_item.formatted_categories;

    /// 阅读数文本。
    final String heat_text = RecommendRankingItem.format_count_text(
      book_item.read_count,
      Localizations.localeOf(context).languageCode,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        /// 使用标题最终获得的真实宽度预判是否换行。
        final bool is_single_line = !text_requires_multiple_lines(
          context: context,
          text: book_item.title,
          text_style: title_text_style,
          max_width: constraints.maxWidth,
        );

        return GestureDetector(
          onTap: on_tap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 封面图
              AspectRatio(
                aspectRatio: Style.cover_aspect_ratio,
                child: NovelCover(
                  image_url: book_item.cover_url,
                  description: book_item.introduction,
                  border_radius: Style.cover_radius,
                  is_dark: is_dark,
                ),
              ),
              const SizedBox(height: Style.book_title_top_spacing),
              // 标题（最多 2 行）
              Text(
                book_item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: title_text_style,
              ),
              const SizedBox(height: Style.book_meta_top_spacing),
              // 底部信息：根据标题行数选择不同布局
              if (is_single_line)
                _build_single_line_meta(
                  meta_text_style,
                  category_text,
                  heat_text,
                )
              else
                _build_multi_line_meta(
                  meta_text_style,
                  meta_text_color,
                  category_text,
                  heat_text,
                ),
            ],
          ),
        );
      },
    );
  }

  /// 标题单行时：分类、阅读数分两行显示。
  Widget _build_single_line_meta(
    TextStyle meta_text_style,
    String category_text,
    String heat_text,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (category_text.isNotEmpty)
          Text(
            category_text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: meta_text_style,
          ),
        if (category_text.isNotEmpty)
          const SizedBox(height: Style.book_single_line_meta_gap),
        Text(
          heat_text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: meta_text_style,
        ),
      ],
    );
  }

  /// 标题双行时：分类和阅读数在同一行，中间用分隔点隔开。
  Widget _build_multi_line_meta(
    TextStyle meta_text_style,
    Color dot_color,
    String category_text,
    String heat_text,
  ) {
    if (category_text.isEmpty) {
      return Text(
        heat_text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: meta_text_style,
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double available_width = constraints.maxWidth;
        final double category_width = measure_single_line_text_width(
          context: context,
          text: category_text,
          text_style: meta_text_style,
        );
        final double heat_width = measure_single_line_text_width(
          context: context,
          text: heat_text,
          text_style: meta_text_style,
        );
        const double separator_total =
            Style.book_meta_separator_gap +
            Style.book_meta_dot_size +
            Style.book_meta_separator_gap;
        final bool show_heat =
            category_width + separator_total + heat_width <= available_width;

        if (!show_heat) {
          return Text(
            category_text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: meta_text_style,
          );
        }

        return Row(
          children: <Widget>[
            Flexible(
              child: Text(
                category_text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: meta_text_style,
              ),
            ),
            const SizedBox(width: Style.book_meta_separator_gap),
            Container(
              width: Style.book_meta_dot_size,
              height: Style.book_meta_dot_size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dot_color,
              ),
            ),
            const SizedBox(width: Style.book_meta_separator_gap),
            Flexible(
              child: Text(
                heat_text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: meta_text_style,
              ),
            ),
          ],
        );
      },
    );
  }
}
