// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/components/content_category_tag/style.dart';
import 'package:app/components/work_detail_skeleton/index.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

/// 漫画卡片骨架与实际瀑布流共用列数、封面、字阶、行盒和标签尺寸。
/// 动效仅重绘占位表面，不每帧重新构建网格；减少动画时保留静态占位。
class ComicsGridSkeleton extends StatelessWidget {
  const ComicsGridSkeleton({super.key, required this.is_dark});

  final bool is_dark;

  /// 标题和简介使用有限的自然行数，保留真实卡片的疏密变化。
  static const _card_data_pool = [
    _SkeletonCardData(title_lines: 2, description_lines: 2, tag_count: 2),
    _SkeletonCardData(title_lines: 1, description_lines: 2, tag_count: 1),
    _SkeletonCardData(title_lines: 2, description_lines: 0, tag_count: 0),
    _SkeletonCardData(title_lines: 1, description_lines: 2, tag_count: 2),
    _SkeletonCardData(title_lines: 2, description_lines: 0, tag_count: 1),
    _SkeletonCardData(title_lines: 1, description_lines: 2, tag_count: 1),
  ];

  @override
  Widget build(BuildContext context) => Semantics(
    label: tr('comics.loading'),
    child: ExcludeSemantics(
      child: SkeletonPulse(
        is_dark: is_dark,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = (constraints.maxWidth / ComicsStyle.grid_card_width)
                .floor()
                .clamp(
                  ComicCardStyle.grid_min_column_count,
                  ComicCardStyle.grid_max_column_count,
                );
            // 使用真实网格的 masonry 排列，三列以上同样保持等宽与相等列距。
            return MasonryGridView.count(
              shrinkWrap: true,
              primary: false,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              mainAxisSpacing: ComicCardStyle.grid_item_spacing,
              crossAxisSpacing: ComicCardStyle.grid_column_spacing,
              itemCount: columns * ComicCardStyle.skeleton_row_count,
              itemBuilder: (context, index) => _ComicSkeletonCard(
                key: ValueKey('comic_grid_skeleton_card_$index'),
                data: _card_data_pool[index % _card_data_pool.length],
                is_dark: is_dark,
                index: index,
              ),
            );
          },
        ),
      ),
    ),
  );
}

/// 一张卡片的外部几何来自 ComicCard；字形条居中放在真实行盒中。
class _ComicSkeletonCard extends StatelessWidget {
  const _ComicSkeletonCard({
    super.key,
    required this.data,
    required this.is_dark,
    required this.index,
  });

  final _SkeletonCardData data;
  final bool is_dark;
  final int index;

  @override
  Widget build(BuildContext context) {
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    final scaler = MediaQuery.textScalerOf(context);
    final title_font_size = cjk
        ? ComicCardStyle.title_font_size_cjk
        : ComicCardStyle.title_font_size_alphabetic;
    final description_font_size = cjk
        ? ComicCardStyle.description_font_size_cjk
        : ComicCardStyle.description_font_size_alphabetic;
    final title_size = scaler.scale(title_font_size);
    final description_size = scaler.scale(description_font_size);
    // 用真实字体引擎测量段落，避免分数行高和文字缩放的舍入累计漂移。
    final title_height = _paragraph_height(
      context,
      font_size: title_font_size,
      line_height: cjk
          ? ComicCardStyle.title_height_cjk
          : ComicCardStyle.title_height_alphabetic,
      lines: data.title_lines,
      strong: true,
    );
    final description_height = _paragraph_height(
      context,
      font_size: description_font_size,
      line_height: cjk
          ? ComicCardStyle.description_height_cjk
          : ComicCardStyle.description_height_alphabetic,
      lines: data.description_lines,
    );
    // 标签复用真实 ContentCategoryTag 的尺寸，避免旧 18px 占位偏矮。
    final tag_height =
        _paragraph_height(
          context,
          font_size: cjk
              ? ContentCategoryTagStyle.font_size_cjk
              : ContentCategoryTagStyle.font_size_alphabetic,
          line_height: cjk
              ? ContentCategoryTagStyle.line_height_cjk
              : ContentCategoryTagStyle.line_height_alphabetic,
          lines: 1,
        ) +
        ContentCategoryTagStyle.padding_v * 2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(ComicCardStyle.card_radius),
      child: ColoredBox(
        color: is_dark
            ? ComicCardStyle.card_dark_bg
            : ComicCardStyle.card_light_bg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              key: ValueKey('comic_grid_skeleton_cover_$index'),
              aspectRatio: ComicsStyle.cover_ratio,
              child: LayoutBuilder(
                builder: (context, constraints) =>
                    SkeletonBlock(height: constraints.maxHeight, radius: 0),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ComicCardStyle.content_padding_h,
                ComicCardStyle.content_padding_top,
                ComicCardStyle.content_padding_h,
                ComicCardStyle.content_padding_bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _text_lines(
                    lines: data.title_lines,
                    paragraph_height: title_height,
                    bar_height: title_size * ComicCardStyle.skeleton_ink_ratio,
                    trailing_ratio:
                        ComicCardStyle.skeleton_title_trailing_ratio,
                  ),
                  if (data.description_lines > 0) ...[
                    SizedBox(
                      height: cjk
                          ? ComicCardStyle.description_top_spacing_cjk
                          : ComicCardStyle.description_top_spacing_alphabetic,
                    ),
                    _text_lines(
                      lines: data.description_lines,
                      paragraph_height: description_height,
                      bar_height:
                          description_size * ComicCardStyle.skeleton_ink_ratio,
                      trailing_ratio:
                          ComicCardStyle.skeleton_description_trailing_ratio,
                    ),
                  ],
                  if (data.tag_count > 0) ...[
                    const SizedBox(height: ComicCardStyle.tag_top_spacing),
                    Wrap(
                      spacing: ComicCardStyle.tag_spacing,
                      runSpacing: ComicCardStyle.tag_run_spacing,
                      children: List.generate(
                        data.tag_count,
                        (tag_index) => SkeletonBlock(
                          key: ValueKey(
                            'comic_grid_skeleton_tag_${index}_$tag_index',
                          ),
                          width: ComicCardStyle.skeleton_tag_width,
                          height: tag_height,
                          radius: ContentCategoryTagStyle.radius,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 测量不会绘制的中性行，沿用真实卡片继承的字体与缩放策略。
  double _paragraph_height(
    BuildContext context, {
    required double font_size,
    required double line_height,
    required int lines,
    bool strong = false,
  }) {
    if (lines == 0) return 0;
    final painter = TextPainter(
      text: TextSpan(
        text: List.filled(lines, 'M').join('\n'),
        style: DefaultTextStyle.of(context).style.merge(
          TextStyle(
            fontSize: font_size,
            height: line_height,
            fontWeight: FontConfig.adjustedWeight(
              strong ? FontConfig.adjustedWeight(FontWeight.w500) : FontConfig.adjustedWeight(FontWeight.w400),
            ),
          ),
        ),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.localeOf(context),
      maxLines: lines,
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height;
  }

  /// 占位线不额外添加行距，防止多行标题和简介累计增高。
  Widget _text_lines({
    required int lines,
    required double paragraph_height,
    required double bar_height,
    required double trailing_ratio,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      lines,
      (line) => SizedBox(
        height: paragraph_height / lines,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: line == lines - 1 ? trailing_ratio : 1,
            child: SkeletonBlock(
              height: bar_height,
              radius: ComicCardStyle.skeleton_text_radius,
            ),
          ),
        ),
      ),
    ),
  );
}

/// 占位卡片只决定未知内容的自然行数，不携带虚构作品信息。
class _SkeletonCardData {
  const _SkeletonCardData({
    required this.title_lines,
    required this.description_lines,
    required this.tag_count,
  });

  final int title_lines;
  final int description_lines;
  final int tag_count;
}
