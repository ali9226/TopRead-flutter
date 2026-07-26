import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:app/components/novel_cover/index.dart';
import 'package:app/models/recommend_ranking_item.dart';
import 'package:app/pages/ranking_full_list/style.dart';

/// 完整榜单书籍卡片组件。
///
/// 底部信息行布局规则：
/// - 标题占 1 行时：分类、阅读数分两行显示。
/// - 标题占 2 行时：分类和阅读数在同一行，中间用分隔点隔开。
class BookshelfBookCard extends StatefulWidget {
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
  State<BookshelfBookCard> createState() => _BookshelfBookCardState();
}

class _BookshelfBookCardState extends State<BookshelfBookCard> {
  /// 标题文本的 GlobalKey，用于测量实际渲染高度。
  final GlobalKey _title_key = GlobalKey();

  /// 标题是否为单行显示。
  bool _is_single_line = true;

  /// 是否已完成标题行数计算。
  bool _has_calculated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculate_title_lines();
    });
  }

  /// 计算标题实际占用的行数。
  ///
  /// 通过测量标题 RenderBox 的实际高度，与单行标题的理论高度对比，
  /// 判断标题是单行还是双行显示。
  void _calculate_title_lines() {
    if (_has_calculated) return;

    final RenderBox? title_box =
        _title_key.currentContext?.findRenderObject() as RenderBox?;
    if (title_box == null) return;

    final double title_height = title_box.size.height;
    final double single_line_height =
        Style.book_title_font_size * Style.book_title_height;

    final bool is_single_line = title_height <= single_line_height + 2;

    if (mounted) {
      setState(() {
        _is_single_line = is_single_line;
        _has_calculated = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    /// 标题文字颜色。
    final Color title_color = widget.is_dark
        ? Colors.white
        : const Color(0xFF2B2F36);

    /// 底部信息文字颜色。
    final Color meta_text_color = widget.is_dark
        ? Colors.white.withValues(alpha: 0.52)
        : const Color(0xFF6F7785);

    /// 底部信息文字样式。
    final TextStyle meta_text_style = TextStyle(
      color: meta_text_color,
      fontSize: Style.book_meta_font_size,
      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
    );

    /// 分类标签文本。
    final String category_text = widget.book_item.formatted_categories;

    /// 阅读数文本。
    final String heat_text = RecommendRankingItem.format_count_text(
      widget.book_item.read_count,
      Localizations.localeOf(context).languageCode,
    );

    return GestureDetector(
      onTap: widget.on_tap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 封面图
          AspectRatio(
            aspectRatio: Style.cover_aspect_ratio,
            child: NovelCover(
              image_url: widget.book_item.cover_url,
              description: widget.book_item.introduction,
              border_radius: Style.cover_radius,
              is_dark: widget.is_dark,
            ),
          ),
          const SizedBox(height: Style.book_title_top_spacing),
          // 标题（最多 2 行）
          Text(
            key: _title_key,
            widget.book_item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: title_color,
              fontSize: Style.book_title_font_size,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
              height: Style.book_title_height,
            ),
          ),
          const SizedBox(height: Style.book_meta_top_spacing),
          // 底部信息：根据标题行数选择不同布局
          if (_is_single_line)
            _build_single_line_meta(meta_text_style, category_text, heat_text)
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
        if (category_text.isNotEmpty) const SizedBox(height: 2),
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
      builder: (context, constraints) {
        final double available_width = constraints.maxWidth;

        final TextPainter category_painter = TextPainter(
          text: TextSpan(text: category_text, style: meta_text_style),
          textDirection: TextDirection.ltr,
        )..layout();

        final TextPainter heat_painter = TextPainter(
          text: TextSpan(text: heat_text, style: meta_text_style),
          textDirection: TextDirection.ltr,
        )..layout();

        const double separator_gap = 4;
        const double dot_size = 2.4;
        const double separator_total = separator_gap + dot_size + separator_gap;

        final double total_width =
            category_painter.width + separator_total + heat_painter.width;

        final bool show_heat = total_width <= available_width;

        return SizedBox(
          height: Style.book_meta_font_size * 1.4,
          child: show_heat
              ? Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        category_text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: meta_text_style,
                      ),
                    ),
                    const SizedBox(width: separator_gap),
                    Container(
                      width: dot_size,
                      height: dot_size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dot_color,
                      ),
                    ),
                    const SizedBox(width: separator_gap),
                    Flexible(
                      child: Text(
                        heat_text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: meta_text_style,
                      ),
                    ),
                  ],
                )
              : Text(
                  category_text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: meta_text_style,
                ),
        );
      },
    );
  }
}
