import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:app/components/novel_cover/index.dart';
import 'package:app/pages/bookshelf/logic.dart';
import 'package:app/pages/bookshelf/style.dart';

/// 书籍卡片组件。
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
    /// 标题文字颜色。
    final Color title_color = is_dark ? Colors.white : const Color(0xFF2B2F36);

    /// 进度文字颜色。
    final Color meta_text_color = is_dark
        ? Colors.white.withValues(alpha: 0.52)
        : const Color(0xFF6F7785);

    /// 进度文字样式（图标颜色与该样式颜色保持一致）。
    final TextStyle meta_text_style = TextStyle(
      color: meta_text_color,
      fontSize: Style.book_meta_font_size,
      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
    );

    return GestureDetector(
      onTap: on_tap,
      onLongPress: on_long_press,
      behavior: HitTestBehavior.opaque,
      child: Column(
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
                          borderRadius: BorderRadius.circular(Style.tag_radius),
                        ),
                        child: Text(
                          easy.tr(book_item.tag_key!),
                          style: TextStyle(
                            color: is_dark
                                ? Colors.white
                                : const Color(0xFF23262D),
                            fontSize: Style.tag_font_size,
                            fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Style.book_title_top_spacing),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: Style.book_title_min_height,
            ),
            child: Text(
              book_item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: title_color,
                fontSize: Style.book_title_font_size,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                height: Style.book_title_height,
              ),
            ),
          ),
          const SizedBox(height: Style.book_meta_top_spacing),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  easy.tr(
                    book_item.progress_key,
                    namedArgs: book_item.progress_args,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: meta_text_style,
                ),
              ),
              const SizedBox(width: Style.book_meta_icon_spacing),
              _BookMetaDots(color: meta_text_color),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建封面图。
  Widget _build_cover_image() {
    return NovelCover(
      image_url: book_item.cover_image_url,
      description: book_item.introduction,
      is_dark: is_dark,
      border_radius: Style.cover_radius,
    );
  }
}

/// 进度右侧的三点竖排组件。
class _BookMetaDots extends StatelessWidget {
  /// 三点颜色。
  final Color color;

  const _BookMetaDots({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _build_dot(),
        const SizedBox(height: Style.book_meta_dot_spacing),
        _build_dot(),
        const SizedBox(height: Style.book_meta_dot_spacing),
        _build_dot(),
      ],
    );
  }

  /// 构建单个圆点。
  Widget _build_dot() {
    return Container(
      width: Style.book_meta_dot_size,
      height: Style.book_meta_dot_size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
