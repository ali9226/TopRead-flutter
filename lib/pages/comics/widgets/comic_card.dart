// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/pages/comics/widgets/comic_image.dart';
import 'package:app/util/router/router_util.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 瀑布流漫画卡片，视觉语言与首页推荐卡片保持一致。
///
/// 结构：封面（角标 + 渐变信息条）→ 标题 → 简介 → 分类标签。
/// 标签颜色按漫画 id 稳定取色，日夜主题下均保持可读对比度。
/// 设计参数统一由 [ComicCardStyle] 管理。
class ComicCard extends StatelessWidget {
  /// 漫画数据。
  final ComicItem comic;

  /// 点击回调；为空时默认跳转漫画详情页。
  final VoidCallback? on_tap;

  const ComicCard({super.key, required this.comic, this.on_tap});

  @override
  Widget build(BuildContext context) {
    /// 卡片背景色：日间纯白，夜间深蓝灰。
    final bool is_dark = ComicsStyle.is_dark(context);
    final bool is_cjk = ComicsStyle.is_cjk(context);
    final Color card_bg = is_dark
        ? ComicCardStyle.card_dark_bg
        : ComicCardStyle.card_light_bg;

    /// 标题颜色。
    final Color title_color = is_dark
        ? ComicCardStyle.title_dark
        : ComicCardStyle.title_light;

    /// 简介颜色。
    final Color description_color = is_dark
        ? ComicCardStyle.description_dark
        : ComicCardStyle.description_light;

    /// 点击波纹色。
    final Color ripple_color = ColorConstants.themeColor.withValues(
      alpha: ComicCardStyle.ripple_opacity,
    );

    /// 点击高亮色。
    final Color highlight_color = ColorConstants.themeColor.withValues(
      alpha: ComicCardStyle.highlight_opacity,
    );

    /// CJK 与拉丁语系使用不同字阶、行高与字距。
    final double title_font_size = is_cjk
        ? ComicCardStyle.title_font_size_cjk
        : ComicCardStyle.title_font_size_alphabetic;
    final double title_height = is_cjk
        ? ComicCardStyle.title_height_cjk
        : ComicCardStyle.title_height_alphabetic;
    final double description_font_size = is_cjk
        ? ComicCardStyle.description_font_size_cjk
        : ComicCardStyle.description_font_size_alphabetic;
    final double description_height = is_cjk
        ? ComicCardStyle.description_height_cjk
        : ComicCardStyle.description_height_alphabetic;
    final double description_top_spacing = is_cjk
        ? ComicCardStyle.description_top_spacing_cjk
        : ComicCardStyle.description_top_spacing_alphabetic;
    final double? title_letter_spacing = is_cjk
        ? null
        : ComicCardStyle.title_letter_spacing_alphabetic;
    final double? description_letter_spacing = is_cjk
        ? null
        : ComicCardStyle.description_letter_spacing_alphabetic;

    final String display_title = comic.title.trim();
    final String display_description = comic.description.trim();
    final List<Map<String, dynamic>> tags = comic.categories;

    return Semantics(
      button: true,
      label: comic.author_name.isEmpty
          ? display_title
          : tr(
              'comics.card_semantic',
              namedArgs: <String, String>{
                'title': display_title,
                'author': comic.author_name,
              },
            ),
      child: Material(
        color: card_bg,
        borderRadius: BorderRadius.circular(ComicCardStyle.card_radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: on_tap ?? () => routerUtil(path: '/comics/detail?id=${comic.id}'),
          splashFactory: InkRipple.splashFactory,
          splashColor: ripple_color,
          highlightColor: highlight_color,
          radius: 240,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// 封面区域：角标 + 底部信息条。
              _build_cover_area(),

              /// 文字区域。
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ComicCardStyle.content_padding_h,
                  ComicCardStyle.content_padding_top,
                  ComicCardStyle.content_padding_h,
                  ComicCardStyle.content_padding_bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    /// 标题。
                    Text(
                      display_title,
                      maxLines: ComicCardStyle.title_max_lines,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: title_color,
                        fontSize: title_font_size,
                        height: title_height,
                        letterSpacing: title_letter_spacing,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                      ),
                    ),

                    /// 简介。
                    if (display_description.isNotEmpty) ...<Widget>[
                      SizedBox(height: description_top_spacing),
                      Text(
                        display_description,
                        maxLines: ComicCardStyle.description_max_lines,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: description_color,
                          fontSize: description_font_size,
                          height: description_height,
                          letterSpacing: description_letter_spacing,
                          fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                        ),
                      ),
                    ],

                    /// 分类标签。
                    if (tags.isNotEmpty) ...<Widget>[
                      const SizedBox(height: ComicCardStyle.tag_top_spacing),
                      Wrap(
                        spacing: ComicCardStyle.tag_spacing,
                        runSpacing: ComicCardStyle.tag_run_spacing,
                        children: List<Widget>.generate(tags.length, (int index) {
                          return _build_tag_item(
                            label: ComicsStyle.category_name(context, tags[index]),
                            color: _tag_color(index),
                            card_bg: card_bg,
                            is_cjk: is_cjk,
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建封面区域：封面图、完结/连载角标、底部章节信息条。
  Widget _build_cover_area() {
    return Stack(
      children: <Widget>[
        /// 封面图：上圆角裁切，保持漫画竖版比例。
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(ComicCardStyle.card_radius),
            topRight: Radius.circular(ComicCardStyle.card_radius),
          ),
          child: AspectRatio(
            aspectRatio: ComicsStyle.cover_ratio,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ComicImage(
                  url: comic.cover_url,
                  semantic_label: comic.title,
                ),

                /// 底部渐变 + 章节信息。
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(
                      ComicCardStyle.cover_meta_padding_h,
                      ComicCardStyle.cover_meta_padding_top,
                      ComicCardStyle.cover_meta_padding_h,
                      0,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.black.withValues(
                            alpha: ComicCardStyle.cover_gradient_top_opacity,
                          ),
                          Colors.black.withValues(
                            alpha: ComicCardStyle.cover_gradient_bottom_opacity,
                          ),
                        ],
                      ),
                    ),
                    child: Text(
                      tr(
                        'comics.chapter_count',
                        namedArgs: <String, String>{'count': '${comic.chapter_count}'},
                      ),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ComicCardStyle.cover_meta_font_size,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                        shadows: <Shadow>[
                          Shadow(
                            color: Colors.black.withValues(
                              alpha: ComicCardStyle.cover_meta_shadow_opacity,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        /// 完结 / 连载角标。
        Positioned(
          top: ComicCardStyle.cover_badge_margin.top,
          left: ComicCardStyle.cover_badge_margin.left,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(
                alpha: ComicCardStyle.cover_badge_background_opacity,
              ),
              borderRadius: BorderRadius.circular(ComicCardStyle.cover_badge_radius),
            ),
            child: Padding(
              padding: ComicCardStyle.cover_badge_padding,
              child: Text(
                tr(
                  comic.completion_status == 'completed'
                      ? 'comics.completed'
                      : 'comics.ongoing',
                ),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ComicCardStyle.cover_badge_font_size,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建单个分类标签：浅色底 + 同色文字。
  ///
  /// [label] 标签文案。
  /// [color] 标签主色。
  /// [card_bg] 卡片背景色，用于混合出浅色底。
  /// [is_cjk] 当前语种是否为 CJK，决定标签字阶与内边距。
  Widget _build_tag_item({
    required String label,
    required Color color,
    required Color card_bg,
    required bool is_cjk,
  }) {
    /// 标签背景：主色以固定不透明度叠在卡片底色上。
    final Color tag_background_color = Color.alphaBlend(
      color.withValues(alpha: ComicCardStyle.tag_background_opacity),
      card_bg,
    );

    /// CJK 与拉丁语系标签字号一致地做微调。
    final double tag_font_size = is_cjk
        ? ComicCardStyle.tag_font_size_cjk
        : ComicCardStyle.tag_font_size_alphabetic;
    final double tag_padding_h = is_cjk
        ? ComicCardStyle.tag_padding_h_cjk
        : ComicCardStyle.tag_padding_h_alphabetic;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tag_padding_h,
        vertical: ComicCardStyle.tag_padding_v,
      ),
      decoration: BoxDecoration(
        color: tag_background_color,
        borderRadius: BorderRadius.circular(ComicCardStyle.tag_radius),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withValues(alpha: ComicCardStyle.tag_text_opacity),
          fontSize: tag_font_size,
          fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
        ),
      ),
    );
  }

  /// 按漫画 id 与标签序号稳定取色，保证同一漫画的标签颜色不随刷新变化。
  ///
  /// [index] 标签在列表中的序号。
  Color _tag_color(int index) {
    if (ColorConstants.tagColorList.isEmpty) return ColorConstants.themeColor;
    final int safe_index =
        (comic.id * ComicCardStyle.tag_color_id_factor +
            index * ComicCardStyle.tag_color_index_factor) %
        ColorConstants.tagColorList.length;
    return ColorConstants.tagColorList[safe_index];
  }
}
