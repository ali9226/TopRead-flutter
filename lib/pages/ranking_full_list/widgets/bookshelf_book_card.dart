import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:app/components/novel_cover/index.dart';
import 'package:app/models/recommend_ranking_item.dart';
import 'package:app/pages/ranking_full_list/style.dart';

/// 完整榜单书籍卡片组件。
///
/// 展示真实数据：封面图、标题、分类标签和热度信息。
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

    /// 热度文字颜色。
    final Color meta_text_color = is_dark
        ? Colors.white.withValues(alpha: 0.52)
        : const Color(0xFF6F7785);

    /// 热度文字样式。
    final TextStyle meta_text_style = TextStyle(
      color: meta_text_color,
      fontSize: Style.book_meta_font_size,
      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
    );

    /// 分类标签文本。
    final String category_text = book_item.formatted_categories;

    /// 阅读数文本。
    final String heat_text = RecommendRankingItem.format_count_text(
      book_item.read_count,
      Localizations.localeOf(context).languageCode,
    );

    return GestureDetector(
      onTap: on_tap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 封面图（使用统一的 NovelCover 组件）
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
          // 底部信息：分类 · 热度
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  category_text.isNotEmpty
                      ? '$category_text · $heat_text'
                      : heat_text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: meta_text_style,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
