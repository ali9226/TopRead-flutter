import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:app/components/novel_cover/index.dart';
import 'package:app/pages/bookshelf/style.dart';
import 'package:app/stores/bookshelf_store.dart';
import 'package:app/util/text/text_layout_measure.dart';

/// 书籍卡片组件。
///
/// 底部信息行布局规则：
/// - 标题占 1 行时：分类、进度、章节数分三行显示。
/// - 标题占 2 行时：分类和进度在同一行，中间用分隔点隔开。
class BookshelfBookCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final Color title_color = is_dark ? Colors.white : const Color(0xFF2B2F36);

    final Color meta_text_color = is_dark
        ? Colors.white.withValues(alpha: 0.52)
        : const Color(0xFF6F7785);

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
          onLongPress: on_long_press,
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
                      if (book_item.tag_key != null)
                        Positioned(
                          top: Style.tag_offset,
                          right: Style.tag_offset,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Style.tag_horizontal_padding,
                              vertical: Style.tag_vertical_padding,
                            ),
                            decoration: BoxDecoration(
                              color: is_dark
                                  ? Colors.black.withValues(alpha: 0.45)
                                  : Colors.white.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(
                                Style.tag_radius,
                              ),
                            ),
                            child: Text(
                              easy.tr(book_item.tag_key!),
                              style: TextStyle(
                                color: is_dark
                                    ? Colors.white
                                    : const Color(0xFF23262D),
                                fontSize: Style.tag_font_size,
                                fontWeight: FontConfig.adjustedWeight(
                                  FontWeight.w500,
                                ),
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
                book_item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: title_text_style,
              ),
              const SizedBox(height: Style.book_meta_top_spacing),
              if (is_single_line)
                _build_single_line_meta(meta_text_style)
              else
                _build_multi_line_meta(meta_text_style, meta_text_color),
            ],
          ),
        );
      },
    );
  }

  /// 标题单行时：分类、进度、章节数分三行显示。
  Widget _build_single_line_meta(TextStyle meta_text_style) {
    final String category_text = _get_category_text();
    final String progress_text = easy.tr(
      book_item.progress_key,
      namedArgs: book_item.progress_args,
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
        if (category_text.isNotEmpty)
          const SizedBox(height: Style.book_single_line_meta_gap),
        Text(
          progress_text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: meta_text_style,
        ),
        if (chapter_text.isNotEmpty)
          const SizedBox(height: Style.book_single_line_meta_gap),
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
      book_item.progress_key,
      namedArgs: book_item.progress_args,
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
      builder: (BuildContext context, BoxConstraints constraints) {
        final double available_width = constraints.maxWidth;
        final double category_width = measure_single_line_text_width(
          context: context,
          text: category_text,
          text_style: meta_text_style,
        );
        final double progress_width = measure_single_line_text_width(
          context: context,
          text: progress_text,
          text_style: meta_text_style,
        );
        const double separator_total =
            Style.book_meta_separator_gap +
            Style.book_meta_dot_size +
            Style.book_meta_separator_gap;
        final bool show_progress =
            category_width + separator_total + progress_width <=
            available_width;

        if (!show_progress) {
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
                progress_text,
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

  /// 获取分类文本。
  String _get_category_text() {
    if (book_item.category_names.isEmpty) return '';
    return book_item.category_names.split(',').take(2).join(' · ');
  }

  /// 获取章节数文本（仅收藏 tab 有 chapter_count > 0 时显示）。
  String _get_chapter_text() {
    if (book_item.progress_key == 'bookshelf.progress.chapters') {
      return easy.tr(
        book_item.progress_key,
        namedArgs: book_item.progress_args,
      );
    }
    return '';
  }

  Widget _build_cover_image() {
    return NovelCover(
      image_url: book_item.cover_image_url,
      description: book_item.introduction,
      is_dark: is_dark,
      border_radius: Style.cover_radius,
    );
  }
}
