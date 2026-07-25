import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:app/components/novel_cover/index.dart';
import 'package:app/pages/bookshelf/logic.dart';
import 'package:app/pages/bookshelf/style.dart';

/// 书籍卡片组件。
///
/// 底部信息行布局规则：
/// - 标题占 1 行时：分类、进度、章节数分三行显示。
/// - 标题占 2 行时：分类和进度在同一行，中间用分隔点隔开。
class BookshelfBookCard extends StatefulWidget {
  /// 当前书籍数据。
  final BookshelfBookItem book_item;

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 点击卡片时触发。
  final VoidCallback on_tap;

  /// 长按卡片时触发。
  final VoidCallback on_long_press;

  const BookshelfBookCard({
    super.key,
    required this.book_item,
    required this.is_dark,
    required this.on_tap,
    required this.on_long_press,
  });

  @override
  State<BookshelfBookCard> createState() => _BookshelfBookCardState();
}

class _BookshelfBookCardState extends State<BookshelfBookCard> {
  final GlobalKey _title_key = GlobalKey();
  bool _is_single_line = true;
  bool _has_calculated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculate_title_lines();
    });
  }

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
    final Color title_color =
        widget.is_dark ? Colors.white : const Color(0xFF2B2F36);

    final Color meta_text_color = widget.is_dark
        ? Colors.white.withValues(alpha: 0.52)
        : const Color(0xFF6F7785);

    final TextStyle meta_text_style = TextStyle(
      color: meta_text_color,
      fontSize: Style.book_meta_font_size,
      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
    );

    final String category_text = _get_category_text();
    final String progress_text = easy.tr(
      widget.book_item.progress_key,
      namedArgs: widget.book_item.progress_args,
    );

    return GestureDetector(
      onTap: widget.on_tap,
      onLongPress: widget.on_long_press,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AspectRatio(
            aspectRatio: Style.cover_aspect_ratio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Style.cover_radius),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _build_cover_image(),
                  if (widget.book_item.tag_key != null)
                    Positioned(
                      top: Style.tag_offset,
                      right: Style.tag_offset,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Style.tag_horizontal_padding,
                          vertical: Style.tag_vertical_padding,
                        ),
                        decoration: BoxDecoration(
                          color: widget.is_dark
                              ? Colors.black.withValues(alpha: 0.45)
                              : Colors.white.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(Style.tag_radius),
                        ),
                        child: Text(
                          easy.tr(widget.book_item.tag_key!),
                          style: TextStyle(
                            color: widget.is_dark
                                ? Colors.white
                                : const Color(0xFF23262D),
                            fontSize: Style.tag_font_size,
                            fontWeight:
                                FontConfig.adjustedWeight(FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Style.book_title_top_spacing),
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
          if (_is_single_line)
            _build_single_line_meta(meta_text_style)
          else
            _build_multi_line_meta(meta_text_style, meta_text_color),
        ],
      ),
    );
  }

  /// 标题单行时：分类、进度、章节数分三行显示。
  Widget _build_single_line_meta(TextStyle meta_text_style) {
    final String category_text = _get_category_text();
    final String progress_text = easy.tr(
      widget.book_item.progress_key,
      namedArgs: widget.book_item.progress_args,
    );
    final String chapter_text = _get_chapter_text();

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
          progress_text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: meta_text_style,
        ),
        if (chapter_text.isNotEmpty) const SizedBox(height: 2),
        if (chapter_text.isNotEmpty)
          Text(
            chapter_text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: meta_text_style,
          ),
      ],
    );
  }

  /// 标题双行时：分类和进度在同一行，中间用分隔点隔开。
  Widget _build_multi_line_meta(TextStyle meta_text_style, Color dot_color) {
    final String category_text = _get_category_text();
    final String progress_text = easy.tr(
      widget.book_item.progress_key,
      namedArgs: widget.book_item.progress_args,
    );

    if (category_text.isEmpty) {
      return Text(
        progress_text,
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

        final TextPainter progress_painter = TextPainter(
          text: TextSpan(text: progress_text, style: meta_text_style),
          textDirection: TextDirection.ltr,
        )..layout();

        const double separator_gap = 4;
        const double dot_size = 2.4;
        const double separator_total = separator_gap + dot_size + separator_gap;

        final double total_width =
            category_painter.width + separator_total + progress_painter.width;

        final bool show_progress = total_width <= available_width;

        return SizedBox(
          height: Style.book_meta_font_size * 1.4,
          child: show_progress
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
                        progress_text,
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

  /// 获取分类文本。
  String _get_category_text() {
    if (widget.book_item.category_names.isEmpty) return '';
    return widget.book_item.category_names.split(',').take(2).join(' · ');
  }

  /// 获取章节数文本（仅收藏 tab 有 chapter_count > 0 时显示）。
  String _get_chapter_text() {
    if (widget.book_item.progress_key == 'bookshelf.progress.chapters') {
      return easy.tr(
        widget.book_item.progress_key,
        namedArgs: widget.book_item.progress_args,
      );
    }
    return '';
  }

  Widget _build_cover_image() {
    return NovelCover(
      image_url: widget.book_item.cover_image_url,
      description: widget.book_item.introduction,
      is_dark: widget.is_dark,
      border_radius: Style.cover_radius,
    );
  }
}
